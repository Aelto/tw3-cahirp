use std::collections::HashSet;

use crate::parser::{Directive, DirectiveId};

use super::CodeEmitter;

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

  /// Stores the directives that were skipped in the previous pass and tha may
  /// need attention during the next pass.
  ///
  /// It assumes there will always be fewer skipped directives (that were locked
  /// by invalid conditions) than valid ones, which is why it stores the skipped
  /// ones instead of storing the successful ones.
  skipped_directives: HashSet<DirectiveId>,

  /// An internal counter that is used to generate unique IDs for the [Directive]s
  internal_id_counter: usize,

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
      skipped_directives: HashSet::new(),
      internal_id_counter: 0,
      mode: FileDefsMode::All
    };

    out.next_pass(FileDefsMode::All);
    out
  }

  pub fn contains(&self, var: &str) -> bool {
    self.variables.contains(var)
  }

  fn next_id(&mut self) -> usize {
    self.internal_id_counter += 1;

    self.internal_id_counter
  }

  pub fn mark_as_skipped(&mut self, directive: &mut Directive) {
    let id_to_insert = match directive.id {
      None => {
        let id = DirectiveId::new(self.next_id());

        directive.id = Some(id);
        id
      }
      Some(id) => id
    };

    self.skipped_directives.insert(id_to_insert);
  }

  pub fn mark_as_executed(&mut self, id: &DirectiveId) {
    self.skipped_directives.remove(&id);
  }

  pub fn is_directive_marked_as_skipped(&self, id: &DirectiveId) -> bool {
    self.skipped_directives.contains(&id)
  }

  pub fn should_skip_directive(&self, directive: &Directive) -> bool {
    !directive
      .insert
      .parameters()
      .ifdefs()
      .all(|variable| self.contains(variable))
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
