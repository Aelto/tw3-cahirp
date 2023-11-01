use std::path::PathBuf;

mod build;
pub use build::build;
pub use build::build_and_watch;

#[derive(Debug, clap::Subcommand)]
pub enum Commands {
  Build {
    #[arg(short, long)]
    game: Option<PathBuf>,

    #[arg(short, long)]
    out: Option<PathBuf>,

    #[arg(short, long, action)]
    clean: bool,

    #[arg(short, long, action)]
    watch: bool
  }
}

impl Default for Commands {
  fn default() -> Self {
    Self::Build {
      game: None,
      out: None,
      clean: true,
      watch: false
    }
  }
}
