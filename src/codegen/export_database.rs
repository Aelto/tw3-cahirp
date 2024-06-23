use std::collections::HashMap;

use crate::parser::Directive;

#[derive(Debug)]
pub struct ExportDatabase {
  named_exports: HashMap<String, Directive>
}

impl ExportDatabase {
  pub fn collect_named_exports(directives: &mut Vec<Directive>) -> Self {
    let exports: Vec<Directive> = directives
      .extract_if(|d| d.parameters().has_export())
      .collect();

    let named_exports =
      HashMap::from_iter(exports.into_iter().filter_map(
        |d| match d.parameters().exports_first() {
          Some(key) => Some((key.to_owned(), d)),
          None => None
        }
      ));

    Self { named_exports }
  }

  pub fn feed_exports(&self, directives: &mut Vec<Directive>) {
    for directive in directives {
      directive.parameters_mut().feed_exports(self)
    }
  }

  pub fn get(&self, key: &str) -> Option<&Directive> {
    self.named_exports.get(key)
  }
}
