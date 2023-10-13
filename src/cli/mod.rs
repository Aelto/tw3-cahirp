use std::path::Path;

use crate::error::CResult;

mod commands;
pub use commands::Commands;

#[derive(Debug, clap::Parser)]
#[command(version)]
pub struct Cli {
  #[arg(short, long)]
  debug: bool,

  #[command(subcommand)]
  pub command: Commands
}

impl Cli {
  pub fn execute(self) -> CResult<()> {
    match self.command {
      Commands::Build { game, out, clean } => {
        // if using the default `out` folder it defaults to always cleaning
        // first
        let clean_before_build = clean || out.is_none();

        let game_root = game.unwrap_or_else(|| {
          #[cfg(debug_assertions)]
          let path = Path::new("fake-game");

          #[cfg(not(debug_assertions))]
          let path = Path::new(".");

          path.into()
        });

        let out = out.unwrap_or_else(|| game_root.join("mods").join("mod00000_Cahirp"));

        commands::build(game_root, out, clean_before_build)
      }
    }?;

    Ok(())
  }
}
