use std::collections::HashSet;

use crate::cli::prints::verbose_debug;
use crate::parser::Directive;

/// Orchestrates the execution of [Directive]s with the variables that are
/// defined with [`Define`] and the requirements expressed by [`IfDef`] and
/// [`IfNotDef`].
pub struct ExecutionOrchestrator<'a> {
  pub to_run: Vec<&'a Directive>,
  to_skip: Vec<&'a Directive>,

  iteration: usize,
  pub finished: bool
}

impl<'directives, 'defs> ExecutionOrchestrator<'directives>
where
  'defs: 'directives
{
  pub fn new(directives: &'directives Vec<Directive>, defs: &HashSet<&'defs str>) -> Self {
    Self::next_iteration(0, directives.iter(), defs)
  }

  pub fn next(&mut self, defs: &HashSet<&'defs str>) {
    // start from the directives that were previously skipped
    let new = Self::next_iteration(self.iteration + 1, self.to_skip.iter().map(|&d| d), defs);

    // a bit weird that it mutates itself off a new `Self` rather than returning
    // it here but the borrow rules don't allow it since the orchestrator will
    // often be used while in for loops
    self.iteration = new.iteration;
    self.to_run = new.to_run;
    self.to_skip = new.to_skip;
    self.finished = new.finished;
  }

  pub fn next_iteration<I>(iteration: usize, directives: I, defs: &HashSet<&'defs str>) -> Self
  where
    I: Iterator<Item = &'directives Directive>
  {
    let mut second_pass = Vec::new();
    let mut to_run = Vec::new();
    let mut to_skip = Vec::new();

    // the insertion of directives to run is done in two passes:
    // - #1 first any directive that fills its IfDef requirements or without any
    //   IfDef at all
    // - #2 then if after the first pass there is no directive to run finally start
    //   looking at directives with IfNotDef requirements

    // start looking for #1 directives
    for directive in directives {
      if directive.parameters().has_ifndefs() {
        second_pass.push(directive);
        continue;
      }

      if fits_requirements(directive, defs) {
        to_run.push(directive);
      } else {
        to_skip.push(directive);
      }
    }

    // look for #2 directives but only if there is no more #1 directives to run
    if to_run.is_empty() {
      for directive in second_pass {
        if !directive.parameters().has_ifndefs() {
          continue;
        }

        if fits_requirements(directive, defs) {
          to_run.push(directive);
        } else {
          to_skip.push(directive);
        }
      }
    } else {
      // otherwise mark the #2 directives as "to skip"
      to_skip.append(&mut second_pass);
    }

    if crate::VERBOSE {
      verbose_debug(format!("iteration={iteration}"));
      if !to_run.is_empty() {
        verbose_debug(format!("directives to run:"));

        for d in &to_run {
          verbose_debug(format!("- {}", d.id));
        }
      }

      if !to_skip.is_empty() {
        verbose_debug(format!("directives to skip:"));

        for d in &to_skip {
          verbose_debug(format!("- {}", d.id));
        }
      }
    }

    Self {
      finished: to_run.is_empty(),
      to_run,
      to_skip,
      iteration
    }
  }
}

fn fits_requirements(directive: &Directive, defs: &HashSet<&str>) -> bool {
  let all_ifdefs = directive
    .parameters()
    .ifdefs()
    .all(|var| defs.contains(var));

  let all_ifndefs = directive
    .parameters()
    .ifndefs()
    .all(|var| !defs.contains(var));

  all_ifdefs && all_ifndefs
}
