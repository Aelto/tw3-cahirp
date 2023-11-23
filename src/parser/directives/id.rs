#[derive(Debug, Clone, Copy, Eq, Hash, PartialEq)]
pub struct DirectiveId(usize);

impl DirectiveId {
  pub fn new(num: usize) -> Self {
    Self(num)
  }
}
