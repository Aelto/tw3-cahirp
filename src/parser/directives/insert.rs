use crate::{codegen::CodeEmitter, parser::Parameters};

#[derive(Debug)]
pub struct InsertDirective(Parameters);

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
