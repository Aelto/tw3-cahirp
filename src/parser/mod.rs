mod directives;
pub use directives::*;

mod context;
pub use context::Context;

mod parameters;
pub use parameters::{Parameter, Parameters};

pub mod prelude {
  pub use super::*;

  pub use nom::branch::alt;
  pub use nom::bytes::complete::{is_a, is_not, tag, take_till1, take_until1, take_while};
  pub use nom::character::complete::{char, crlf};
  pub use nom::character::{is_newline, is_space};
  pub use nom::combinator::value;
  pub use nom::error::ParseError;
  pub use nom::multi::{many0, separated_list0, separated_list1};
  pub use nom::sequence::{delimited, pair, preceded, terminated};
  pub use nom::IResult;

  pub fn trim(i: &str) -> IResult<&str, &str> {
    take_while(|c| c == ' ' || c == '\n' || c == '\r')(i)
  }
}
