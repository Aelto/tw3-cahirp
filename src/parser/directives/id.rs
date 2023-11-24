use std::fmt::Display;

#[derive(Debug, Clone, Copy, Eq, Hash, PartialEq)]
pub struct DirectiveId(usize);

impl DirectiveId {
  pub fn new(num: usize) -> Self {
    Self(num)
  }
}

impl Default for DirectiveId {
  fn default() -> Self {
    Self::new(0)
  }
}

impl Display for DirectiveId {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    write!(f, "{}", self.0)
  }
}
