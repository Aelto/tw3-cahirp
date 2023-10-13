use std::{error::Error, fmt::Display};

pub type CResult<T> = Result<T, CError>;

#[derive(Debug)]
pub enum CError {
  Io(std::io::Error)
}

impl Display for CError {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    match self {
      CError::Io(e) => write!(f, "Io({e}")
    }
  }
}

impl Error for CError {}

impl From<std::io::Error> for CError {
  fn from(value: std::io::Error) -> Self {
    Self::Io(value)
  }
}
