mod directives;
pub use directives::*;

mod directive;
pub use directive::Directive;

mod parameters;
pub use parameters::Parameter;
pub use parameters::Parameters;

pub mod prelude {
  pub use super::*;

  pub use nom::branch::alt;
  pub use nom::bytes::complete::is_a;
  pub use nom::bytes::complete::is_not;
  pub use nom::bytes::complete::tag;
  pub use nom::bytes::complete::take_till1;
  pub use nom::bytes::complete::take_until1;
  pub use nom::bytes::complete::take_while;
  pub use nom::character::complete::char;
  pub use nom::character::complete::crlf;
  pub use nom::character::is_newline;
  pub use nom::character::is_space;
  pub use nom::combinator::value;
  pub use nom::error::ParseError;
  pub use nom::multi::many0;
  pub use nom::multi::separated_list0;
  pub use nom::multi::separated_list1;
  pub use nom::sequence::delimited;
  pub use nom::sequence::pair;
  pub use nom::sequence::preceded;
  pub use nom::sequence::terminated;
  pub use nom::IResult;

  pub fn trim(i: &str) -> IResult<&str, &str> {
    take_while(|c| c == ' ' || c == '\n' || c == '\r')(i)
  }
}
