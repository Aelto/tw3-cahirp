use crate::parser::prelude::*;

#[derive(Debug)]
pub enum DirectiveType {
    Insert(Parameters),
    Replace(Parameters),
}

impl DirectiveType {
    pub fn parse(i: &str) -> IResult<&str, Self> {
        alt((Self::parse_insert, Self::parse_replace))(i)
    }

    fn parse_insert(i: &str) -> IResult<&str, Self> {
        let (i, _) = tag("insert")(i)?;
        let (i, params) = delimited(char('('), Parameters::parse, char(')'))(i)?;

        Ok((i, Self::Insert(params)))
    }

    fn parse_replace(i: &str) -> IResult<&str, Self> {
        let (i, _) = tag("replace")(i)?;
        let (i, params) = delimited(char('('), Parameters::parse, char(')'))(i)?;

        Ok((i, Self::Insert(params)))
    }
}
