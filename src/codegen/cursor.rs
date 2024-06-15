use std::str::Lines;

use crate::parser::{Parameter, Parameters};

use super::ExportDatabase;

#[derive(Debug)]
pub struct CodeCursor {
  pub pos: CursorPosition
}

#[derive(Debug)]
pub struct CursorPosition {
  // line: usize,
  pub idx: usize,
  pub selection_len: usize,

  _prev_line_len: usize
}

impl CursorPosition {
  fn new() -> Self {
    CursorPosition {
      // line: 0,
      idx: 0,
      selection_len: 0,

      _prev_line_len: 0
    }
  }

  fn next_line<'a>(&'a mut self, lines: &'a mut std::iter::Peekable<Lines>) -> Option<&'a str> {
    self.idx += self._prev_line_len;

    let line = lines.next();
    if let Some(line) = line {
      // +1 for the \n
      self._prev_line_len = line.len() + 1;
    }

    line
  }
}

impl CodeCursor {
  pub fn advance(&mut self, params: &Parameters, export_db: &ExportDatabase, file: &str) {
    let mut lines = file.lines().peekable();

    for param in params.all() {
      match param {
        Parameter::File(_) => continue,
        Parameter::Note(_) => continue,
        Parameter::IfDef(_) => continue,
        Parameter::IfNotDef(_) => continue,
        Parameter::Define(_) => continue,
        Parameter::Export(_) => continue,
        Parameter::Use(key) => continue,
        Parameter::UseConstructed(params) => {
          self.advance(params, export_db, file);
        }
        Parameter::At(pat) => {
          while let Some(line) = self.pos.next_line(&mut lines) {
            if line.contains(pat) {
              break;
            }
          }
        }
        Parameter::Below(pat) => {
          while let Some(line) = self.pos.next_line(&mut lines) {
            if line.contains(pat) {
              break;
            }
          }
          self.pos.next_line(&mut lines);
        }
        Parameter::Above(pat) => {
          while let Some(_) = self.pos.next_line(&mut lines) {
            if let Some(peek) = lines.peek() {
              if peek.contains(pat) {
                break;
              }
            }
          }
        }
        Parameter::Select(pat) => {
          let current_slice = &file[self.pos.idx..];
          if let Some(pat_idx) = current_slice.find(pat) {
            let pat_len = pat.len();

            lines = current_slice[pat_idx..pat_idx + pat_len].lines().peekable();
            self.pos.idx += pat_idx;
            self.pos.selection_len = pat_len;
          }
        }
        Parameter::MultilineSelect(pat) => {
          let pat = pat.trim();

          'outer: while let Some(_) = self.pos.next_line(&mut lines) {
            let slice = &file[self.pos.idx..];
            let mut inner_lines = slice.lines();

            // from here we search for a series of lines where each line from
            // both the pattern and the file are identical

            // we keep an internal counter since we can't rely on the pattern
            // length because lines are trimmed, so instead the internal counter
            // uses the file's lines length.
            let mut internal_idx = self.pos.idx;
            for patl in pat.lines() {
              let filel = inner_lines.next();

              let lines_match = filel
                .map(|filel| filel.trim() == patl.trim())
                .unwrap_or(false);

              if !lines_match {
                continue 'outer;
              }

              let add = filel.map(|line| line.len()).unwrap_or(0);
              internal_idx += add + 1; // +1 for \n
            }

            self.pos.selection_len = internal_idx - self.pos.idx;
            // pos.idx = internal_idx;
            break 'outer;
          }
        }
      }
    }
  }
  pub fn from_parameters(params: &Parameters, export_db: &ExportDatabase, file: &str) -> Self {
    let mut s = Self {
      pos: CursorPosition::new()
    };

    s.advance(params, export_db, file);
    s
  }
}
