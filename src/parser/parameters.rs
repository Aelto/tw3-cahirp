use std::ops::Deref;

pub use crate::parser::prelude::*;

#[derive(Debug)]
pub struct Parameters(Vec<Parameter>);

impl Parameters {
  pub fn parse(i: &str) -> IResult<&str, Self> {
    let (i, _) = trim(i)?;
    let (i, params) = many0(Parameter::parse)(i)?;
    let (i, _) = trim(i)?;

    Ok((i, Self(params)))
  }

  pub fn all<'a>(&'a self) -> impl Iterator<Item = &'a Parameter> {
    self.0.iter()
  }

  pub fn ats<'a>(&'a self) -> impl Iterator<Item = &'a str> {
    self.0.iter().filter_map(|p| match p {
      Parameter::At(s) => Some(s.deref()),
      _ => None
    })
  }

  pub fn files<'a>(&'a self) -> impl Iterator<Item = &'a str> {
    self.0.iter().filter_map(|p| match p {
      Parameter::File(s) => Some(s.deref()),
      _ => None
    })
  }

  pub fn belows<'a>(&'a self) -> impl Iterator<Item = &'a str> {
    self.0.iter().filter_map(|p| match p {
      Parameter::Below(s) => Some(s.deref()),
      _ => None
    })
  }

  pub fn aboves<'a>(&'a self) -> impl Iterator<Item = &'a str> {
    self.0.iter().filter_map(|p| match p {
      Parameter::Above(s) => Some(s.deref()),
      _ => None
    })
  }

  pub fn notes<'a>(&'a self) -> impl Iterator<Item = &'a str> {
    self.0.iter().filter_map(|p| match p {
      Parameter::Note(s) => Some(s.deref()),
      _ => None
    })
  }
}

#[derive(Debug)]
pub enum Parameter {
  /// Specifies one or many files to work on:
  /// - if no File directive is found then all files in the `mods` directory.
  /// - if one or more File directives are found, then these only the supplied
  /// files will be used.
  File(String),

  /// Specifies an exact pattern to look for and where to place the directive
  /// "cursor".
  ///
  /// Multiple At parameters can be used to progressively & precisely
  /// target a segment of the file. For example:
  /// - a first `At(class CInventoryComponent)` can be used to ensure we're
  /// in the class we need
  /// - a second `At(function EquipItem)` can be used to ensure we're in the
  /// method we need
  ///
  /// > The cursor controls where the provided code is emitted in the file.
  At(String),

  /// Specifies an exact pattern to look for and to place the directive
  /// "cursor" exactly on the line below the line where the pattern is found.
  ///
  /// Multiple At parameters can be used to progressively & precisely
  /// target a segment of the file. For example:
  /// - a first `Below(class CInventoryComponent)` can be used to ensure we're
  /// in the class we need
  /// - a second `Below(function EquipItem)` can be used to ensure we're in the
  /// method we need
  ///
  /// > The cursor controls where the provided code is emitted in the file.
  Below(String),

  /// Specifies an exact pattern to look for and to place the directive
  /// "cursor" exactly on the line above the line where the pattern is found.
  ///
  /// Multiple At parameters can be used to progressively & precisely
  /// target a segment of the file. For example:
  /// - a first `Above(class CInventoryComponent)` can be used to ensure we're
  /// in the class we need
  /// - a second `Above(function EquipItem)` can be used to ensure we're in the
  /// method we need
  ///
  /// > The cursor controls where the provided code is emitted in the file.
  Above(String),

  /// Specifies a pattern to select which should be replaced by the emitted
  /// code.
  Select(String),

  MultilineSelect(String),

  Note(String)
}

impl Parameter {
  fn parse(i: &str) -> IResult<&str, Self> {
    let (i, _) = trim(i)?;
    let (i, param) = alt((
      Self::parse_file,
      Self::parse_at,
      Self::parse_above,
      Self::parse_below,
      Self::parse_select,
      Self::parse_multiline_select,
      Self::parse_note
    ))(i)?;
    let (i, _) = trim(i)?;

    Ok((i, param))
  }

  fn parse_file(i: &str) -> IResult<&str, Self> {
    let (i, pattern) = Self::parse_parameter("file", i)?;

    Ok((i, Self::File(pattern)))
  }

  fn parse_at(i: &str) -> IResult<&str, Self> {
    let (i, pattern) = Self::parse_parameter("at", i)?;

    Ok((i, Self::At(pattern)))
  }

  fn parse_above(i: &str) -> IResult<&str, Self> {
    let (i, pattern) = Self::parse_parameter("above", i)?;

    Ok((i, Self::Above(pattern)))
  }

  fn parse_below(i: &str) -> IResult<&str, Self> {
    let (i, pattern) = Self::parse_parameter("below", i)?;

    Ok((i, Self::Below(pattern)))
  }

  fn parse_select(i: &str) -> IResult<&str, Self> {
    let (i, pattern) = Self::parse_parameter("select", i)?;

    Ok((i, Self::Select(pattern)))
  }

  fn parse_multiline_select(i: &str) -> IResult<&str, Self> {
    let (i, _) = tag("select")(i)?;
    let (i, _) = tag("[[")(i)?;
    let (i, pattern) = take_until1("]]\n")(i)?;
    let (i, _) = tag("]]\n")(i)?;

    Ok((i, Self::MultilineSelect(pattern.to_owned())))
  }

  fn parse_note(i: &str) -> IResult<&str, Self> {
    let (i, pattern) = Self::parse_parameter("note", i)?;

    Ok((i, Self::Note(pattern)))
  }

  fn parse_parameter<'a>(param_type: &'static str, i: &'a str) -> IResult<&'a str, String> {
    let (i, _) = tag(param_type)(i)?;
    let (i, _) = char('(')(i)?;
    let (i, pattern) = Self::parse_til_end_of_param(i)?;

    Ok((i, pattern.trim_matches('\"').to_owned()))
  }

  fn parse_til_end_of_param(i: &str) -> IResult<&str, &str> {
    let (i, pattern) = take_until1(")\n")(i)?;
    let (i, _) = tag(")\n")(i)?;

    Ok((i, pattern))
  }
}
