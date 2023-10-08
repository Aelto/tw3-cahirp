use crate::{codegen::CodeEmitter, parser::Parameters};

#[derive(Debug)]
pub struct InsertDirective(Parameters);

impl InsertDirective {
  pub fn with_context(self, mut parameters: Parameters) -> Self {
    parameters.append(self.0);
    parameters.into()
  }
}

impl From<Parameters> for InsertDirective {
  fn from(value: Parameters) -> Self {
    Self(value)
  }
}

impl CodeEmitter for InsertDirective {
  fn parameters(&self) -> &Parameters {
    &self.0
  }
}
