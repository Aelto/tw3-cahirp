use std::collections::HashSet;

use crate::{
  cli::prints::verbose_debug,
  parser::{Directive, DirectiveId}
};

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

  /// Stores the directives that were executed in the previous passes
  executed_directives: HashSet<DirectiveId>,

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
      executed_directives: HashSet::new(),
      mode: FileDefsMode::All
    };

    out.next_pass(FileDefsMode::All);
    out
  }

  fn has_all_variable_requirements(&self, directive: &Directive) -> bool {
    directive
      .insert
      .parameters()
      .ifdefs()
      .all(|var| self.variables.contains(var))
  }

  pub fn can_execute_directive(&self, directive: &Directive) -> bool {
    match self.mode {
      FileDefsMode::All => {
        if self.has_all_variable_requirements(directive) {
          true
        } else {
          false
        }
      }
      // in this mode only the directives that were previously skipped are
      // treated, and only the ones that have all variables defined.
      FileDefsMode::OnlyNew => {
        if self.executed_directives.contains(&directive.id) {
          false
        } else if self.has_all_variable_requirements(directive) {
          true
        } else {
          false
        }
      }
    }
  }

  pub fn mark_as_executed<'b>(&mut self, directive: &'b Directive)
  where
    'b: 'a
  {
    if crate::VERBOSE {
      verbose_debug(format!("executed({directive})"));
    }

    self.executed_directives.insert(directive.id);
    self.register_defines(directive)
  }

  fn register_defines<'b>(&mut self, directive: &'b Directive)
  where
    'b: 'a
  {
    for define in directive.insert.parameters().defines() {
      self.register(define);
    }
  }

  fn register<'b>(&mut self, var: &'b str) -> bool
  where
    'b: 'a
  {
    if crate::VERBOSE {
      verbose_debug(format!("registered(define={var})"));
    }

    self.current_pass.insert(var);
    self.variables.insert(var)
  }

  /// Prepare for the next pass, and return whether the next pass is needed
  pub fn next_pass(&mut self, mode: FileDefsMode) -> bool {
    // a new pass is only needed if new variables were defined during the
    // previous pass
    let next_pass_needed = !self.current_pass.is_empty();

    if crate::VERBOSE {
      verbose_debug(format!(
        "code_emitting, next_pass(next_pass_needed={next_pass_needed})"
      ));

      for define in &self.current_pass {
        verbose_debug(format!("- define={define}"));
      }
    }

    self.current_pass.clear();
    self.mode = mode;

    next_pass_needed
  }
}
