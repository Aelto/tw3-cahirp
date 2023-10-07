use crate::parser::Parameters;

use super::CodeCursor;

pub trait CodeEmitter {
  fn parameters(&self) -> &Parameters;

  fn emit(&self, mut file: String, code: &str) -> String {
    let cursor = CodeCursor::from_parameters(self.parameters(), &file);

    let (left, right) = file.split_at_mut(cursor.pos.idx);

    let mut output = String::with_capacity(left.len() + code.len() + right.len());
    output.push_str(left.trim_end_matches('\t').trim_end_matches(' '));
    output.push_str(&match_line_indentation(code, left));
    output.push_str(&right[cursor.pos.selection_len..]);

    output
  }
}

/// generates a string of code whose indentation matches the last line of
/// `surrounding`
fn match_line_indentation(code: &str, surrounding: &str) -> String {
  let segment: String = surrounding
    .chars()
    .rev()
    .skip_while(|c| c != &'\n')
    .skip(1)
    .take_while(|c| c != &'\n')
    .collect();

  // trim_end as it is reversed so it is actually the start of the line
  let indents = &segment[segment.trim_end().len()..];

  let mut output = String::new();
  for line in code.lines() {
    // for each emitted line we copy the exact indentation of the last
    // line from the surrounding code:
    output.push_str(indents);
    output.push_str(line.trim());
    output.push('\n');
  }

  output
}
