pub use crate::parser::prelude::*;

#[derive(Debug)]
pub struct Directive {
    pub variant: DirectiveType,
    pub code: String,
}

impl Directive {
    pub fn parse(i: &str) -> IResult<&str, Self> {
        let (i, _) = tag("@")(i)?;
        let (i, variant) = DirectiveType::parse(i)?;
        let code = i.trim().to_owned();

        Ok(("", Self { variant, code }))
    }
}
