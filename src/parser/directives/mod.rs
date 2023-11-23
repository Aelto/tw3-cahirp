use std::path::PathBuf;

use crate::codegen::CodeEmitter;
pub use crate::parser::prelude::*;

mod insert;
pub use insert::InsertDirective;

mod id;
pub use id::DirectiveId;

#[derive(Debug)]
pub struct Directive {
  /// An optional ID that can be obtained from a [FileDefsBuf](crate::codegen::FileDefsBuf)
  /// in order to reliably identify directives over multiple codegen passes.
  pub id: Option<DirectiveId>,

  pub insert: InsertDirective,
  pub code: String
}

impl Directive {
  pub fn parse(i: &str) -> IResult<&str, Self> {
    let (i, _) = tag("@")(i)?;
    let (i, insert) = Self::parse_insert(i)?;
    let code = i.trim().to_owned();

    Ok((
      "",
      Self {
        insert,
        code,
        id: None
      }
    ))
  }

  fn parse_insert(i: &str) -> IResult<&str, InsertDirective> {
    let (i, _) = tag("insert")(i)?;
    let (i, params) = delimited(char('('), Parameters::parse, char(')'))(i)?;

    Ok((i, params.into()))
  }

  pub fn with_context(mut self, parameters: Parameters) -> Self {
    self.insert = self.insert.with_context(parameters);
    self
  }

  pub fn file_suffixes<'a>(&'a self) -> impl Iterator<Item = PathBuf> + 'a {
    self
      .insert
      .parameters()
      .files()
      .map(|suffix| PathBuf::from(suffix))
  }
}
