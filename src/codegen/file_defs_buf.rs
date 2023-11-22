use std::collections::HashSet;

/// A buffer used by a [FilePool](super::FilePool) to keep track of the variable
/// definitions on each pass in order to execute only the directives that are
/// unlocked by the recent variable definitions
///
#[derive(Debug)]
pub struct FileDefsBuf<'a> {
  /// Stores the definitions from the current pass but also all of the past ones.
  variables: HashSet<&'a str>,

  /// Stores the definitions that were added during the current pass
  current_pass: HashSet<&'a str>,

  /// Controls how the file defs buffer operates, whether it yields the [`Directive`]s
  /// for all definitions or only the [`Directive`]s from definitions that changed
  /// in the current pass.
  mode: FileDefsMode
}

#[derive(Debug)]
pub enum FileDefsMode {
  All,
  OnlyNew
}

impl<'a> FileDefsBuf<'a> {
  pub fn new() -> Self {
    let mut out = Self {
      variables: HashSet::new(),
      current_pass: HashSet::new(),
      mode: FileDefsMode::All
    };

    out.next_pass(FileDefsMode::All);
    out
  }

  pub fn contains(&self, var: &str) -> bool {
    self.variables.contains(var)
  }

  pub fn register<'b>(&mut self, var: &'b str) -> bool
  where
    'b: 'a
  {
    self.current_pass.insert(var);
    self.variables.insert(var)
  }

  pub fn unregister(&mut self, var: &str) -> bool {
    self.current_pass.remove(var);
    self.variables.remove(var)
  }

  pub fn next_pass(&mut self, mode: FileDefsMode) {
    self.current_pass.clear();
    self.mode = mode;
  }
}
