use std::error::Error;

use crate::parser::Parameters;

use super::CodeCursor;

pub trait CodeEmitter {
    fn parameters(&self) -> &Parameters;

    fn emit(&self, mut file: String, code: &str) -> Result<String, Box<dyn Error>> {
        let cursor = CodeCursor::from_parameters(self.parameters(), &file);

        let (left, right) = file.split_at_mut(cursor.pos.idx);

        let mut output = String::with_capacity(left.len() + code.len() + right.len());
        output.push_str(left);
        // TODO: it could be interesting to match the indentation of the previous
        // lines on the code we insert here:
        output.push_str(code);
        output.push_str(right);

        Ok(output)
    }
}
