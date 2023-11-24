#![feature(map_try_insert)]

pub const VERBOSE: bool = cfg!(debug_assertions);

use error::CResult;

pub mod cli;
pub mod codegen;
pub mod encoding;
pub mod error;
pub mod game;
pub mod parser;

fn main() -> CResult<()> {
  use clap::Parser;
  cli::Cli::parse().execute()?;

  Ok(())
}
