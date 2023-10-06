use crate::{codegen::CodeEmitter, parser::prelude::*};

use super::{InsertDirective, ReplaceDirective};

#[derive(Debug)]
pub enum DirectiveType {
    Insert(InsertDirective),
    Replace(ReplaceDirective),
}

impl DirectiveType {
    pub fn parse(i: &str) -> IResult<&str, Self> {
        alt((Self::parse_insert, Self::parse_replace))(i)
    }

    fn parse_insert(i: &str) -> IResult<&str, Self> {
        let (i, _) = tag("insert")(i)?;
        let (i, params) = delimited(char('('), Parameters::parse, char(')'))(i)?;

        Ok((i, Self::Insert(params.into())))
    }

    fn parse_replace(i: &str) -> IResult<&str, Self> {
        let (i, _) = tag("replace")(i)?;
        let (i, params) = delimited(char('('), Parameters::parse, char(')'))(i)?;

        Ok((i, Self::Replace(params.into())))
    }

    pub fn parameters(&self) -> &Parameters {
        match self {
            DirectiveType::Insert(i) => i.parameters(),
            DirectiveType::Replace(r) => r.parameters(),
        }
    }
}
