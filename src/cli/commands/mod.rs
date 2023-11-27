use std::path::PathBuf;

mod build;
pub use build::{build, build_and_watch, BuildOptions};

#[derive(Debug, clap::Subcommand)]
pub enum Commands {
  Build {
    /// Path to game directory, defaults to the current working directory
    #[arg(short, long)]
    game: Option<PathBuf>,

    /// Path to the output mod folder, defaults to "<GAME>/mods/mod00000_Cahirp/content/scripts"
    #[arg(short, long)]
    out: Option<PathBuf>,

    /// A specific folder to read for recipes rather than all the mods from "<GAME>/mods"
    #[arg(short, long)]
    recipes: Option<PathBuf>,

    /// Instruct to clean the <OUT> directory before building, forced to "true" if <OUT> uses its default value
    #[arg(short, long, action)]
    clean: bool,

    /// Enables watch mode, rebuilds <OUT> on recipe changes and until a CTRL+C is received
    #[arg(short, long, action)]
    watch: bool
  }
}

impl Default for Commands {
  fn default() -> Self {
    Self::Build {
      game: None,
      out: None,
      recipes: None,
      clean: true,
      watch: false
    }
  }
}
