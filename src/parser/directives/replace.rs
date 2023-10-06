use crate::{codegen::CodeEmitter, parser::Parameters};

#[derive(Debug)]
pub struct ReplaceDirective(Parameters);

impl From<Parameters> for ReplaceDirective {
  fn from(value: Parameters) -> Self {
    Self(value)
  }
}

impl CodeEmitter for ReplaceDirective {
  fn parameters(&self) -> &Parameters {
    &self.0
  }
}
