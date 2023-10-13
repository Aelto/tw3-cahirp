use std::path::PathBuf;

mod build;
pub use build::build;

#[derive(Debug, clap::Subcommand)]
pub enum Commands {
  Build {
    #[arg(short, long)]
    game: Option<PathBuf>,

    #[arg(short, long)]
    out: Option<PathBuf>
  }
}
