pub use crate::parser::prelude::*;

#[derive(Debug)]
pub struct Parameters(Vec<Parameter>);

impl Parameters {
    pub fn parse(i: &str) -> IResult<&str, Self> {
        println!("Parameters::parse({i})");

        let (i, _) = trim(i)?;
        let (i, params) = many0(Parameter::parse)(i)?;
        let (i, _) = trim(i)?;

        Ok((i, Self(params)))
    }
}

#[derive(Debug)]
pub enum Parameter {
    File(String),
    At(String),
    Note(String),
}

impl Parameter {
    fn parse(i: &str) -> IResult<&str, Self> {
        let (i, _) = trim(i)?;
        let (i, param) = alt((Self::parse_file, Self::parse_at, Self::parse_note))(i)?;
        let (i, _) = trim(i)?;

        Ok((i, param))
    }

    fn parse_file(i: &str) -> IResult<&str, Self> {
        let (i, _) = tag("file")(i)?;
        let (i, _) = char('(')(i)?;
        let (i, file) = Self::parse_til_end_of_param(i)?;

        Ok((i, Self::File(file.to_owned())))
    }

    fn parse_at(i: &str) -> IResult<&str, Self> {
        let (i, _) = tag("at")(i)?;
        let (i, _) = char('(')(i)?;
        let (i, pattern) = Self::parse_til_end_of_param(i)?;

        Ok((i, Self::At(pattern.to_owned())))
    }

    fn parse_note(i: &str) -> IResult<&str, Self> {
        let (i, _) = tag("note")(i)?;
        let (i, _) = char('(')(i)?;
        let (i, pattern) = Self::parse_til_end_of_param(i)?;

        Ok((i, Self::Note(pattern.to_owned())))
    }

    fn parse_til_end_of_param(i: &str) -> IResult<&str, &str> {
        let (i, pattern) = take_until1(")\n")(i)?;
        let (i, _) = tag(")\n")(i)?;

        Ok((i, pattern))
    }
}
