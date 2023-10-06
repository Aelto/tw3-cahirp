use std::str::Lines;

use crate::parser::{Parameter, Parameters};

#[derive(Debug)]
pub struct CodeCursor {
    pub pos: CursorPosition,
}

#[derive(Debug)]
pub struct CursorPosition {
    line: usize,
    pub idx: usize,

    _prev_line_len: usize,
}

impl CursorPosition {
    fn new() -> Self {
        CursorPosition {
            line: 0,
            idx: 0,

            _prev_line_len: 0,
        }
    }

    fn next_line<'a>(&'a mut self, lines: &'a mut std::iter::Peekable<Lines>) -> Option<&'a str> {
        self.idx += self._prev_line_len;
        self.line += 1;

        let line = lines.next();
        if let Some(line) = line {
            // +1 for the \n
            self._prev_line_len = line.len() + 1;
        }

        line
    }
}

impl CodeCursor {
    pub fn from_parameters(params: &Parameters, file: &str) -> Self {
        let mut pos = CursorPosition::new();

        let mut lines = file.lines().peekable();

        for param in params.all() {
            match param {
                Parameter::File(_) => continue,
                Parameter::Note(_) => continue,
                Parameter::At(pat) => {
                    while let Some(line) = pos.next_line(&mut lines) {
                        if line.contains(pat) {
                            break;
                        }
                    }
                }
                Parameter::Below(pat) => {
                    while let Some(line) = pos.next_line(&mut lines) {
                        if line.contains(pat) {
                            break;
                        }
                    }
                    pos.next_line(&mut lines);
                }
                Parameter::Above(pat) => {
                    while let Some(_) = pos.next_line(&mut lines) {
                        if let Some(peek) = lines.peek() {
                            if peek.contains(pat) {
                                break;
                            }
                        }
                    }
                }
            }
        }

        Self { pos }
    }
}
