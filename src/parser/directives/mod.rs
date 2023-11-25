use std::{fmt::Display, path::PathBuf};

use crate::codegen::CodeEmitter;
pub use crate::parser::prelude::*;

mod insert;
pub use insert::InsertDirective;

mod id;
pub use id::DirectiveId;

#[derive(Debug)]
pub struct Directive {
  pub id: DirectiveId,

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
        id: DirectiveId::default()
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
      .parameters()
      .files()
      .map(|suffix| PathBuf::from(suffix))
  }

  pub fn parameters(&self) -> &Parameters {
    self.insert.parameters()
  }
}

impl Display for Directive {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    use owo_colors::OwoColorize;
    write!(f, "Directive(id={})", self.id.magenta())?;

    Ok(())
  }
}
