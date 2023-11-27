use std::error::Error;
use std::fmt::Display;

pub type CResult<T> = Result<T, CError>;

#[derive(Debug)]
pub enum CError {
  Io(std::io::Error),
  WatchError(notify_debouncer_full::notify::Error)
}

impl Display for CError {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    match self {
      CError::Io(e) => write!(f, "Io({e}"),
      CError::WatchError(e) => write!(f, "WatchError({e}")
    }
  }
}

impl Error for CError {}

impl From<std::io::Error> for CError {
  fn from(value: std::io::Error) -> Self {
    Self::Io(value)
  }
}

impl From<notify_debouncer_full::notify::Error> for CError {
  fn from(value: notify_debouncer_full::notify::Error) -> Self {
    Self::WatchError(value)
  }
}
