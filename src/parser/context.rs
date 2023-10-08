use crate::parser::prelude::*;

pub struct Context(Parameters);

impl Context {
  pub fn empty() -> Self {
    Self(Parameters::empty())
  }

  pub fn parse_with_context<'a>(&'a mut self, i: &'a str) -> IResult<&str, Option<Directive>> {
    let (i, item) = DirectiveOrContext::parse(i)?;

    match item {
      DirectiveOrContext::Directive(d) => Ok((i, Some(d.with_context(self.0.clone())))),
      DirectiveOrContext::Context(c) => {
        self.merge(c);

        Ok((i, None))
      }
    }
  }

  fn parse(i: &str) -> IResult<&str, Self> {
    let (i, _) = tag("@")(i)?;
    let (i, _) = tag("context")(i)?;
    let (i, params) = delimited(char('('), Parameters::parse, char(')'))(i)?;

    Ok((i, Self(params)))
  }

  /// Merge both Contexts into this one
  fn merge(&mut self, other: Self) {
    self.0.append(other.0)
  }
}

enum DirectiveOrContext {
  Directive(Directive),
  Context(Context)
}

impl DirectiveOrContext {
  pub fn parse(i: &str) -> IResult<&str, Self> {
    alt((Self::generic_context, Self::generic_directive))(i)
  }

  fn generic_directive(i: &str) -> IResult<&str, Self> {
    let (i, directive) = Directive::parse(i)?;

    Ok((i, Self::Directive(directive)))
  }

  fn generic_context(i: &str) -> IResult<&str, Self> {
    let (i, context) = Context::parse(i)?;

    Ok((i, Self::Context(context)))
  }
}
