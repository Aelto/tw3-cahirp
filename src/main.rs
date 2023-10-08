#![feature(map_try_insert)]

use std::error::Error;
use std::fs::DirEntry;
use std::path::{Path, PathBuf};

use encoding::read_file;
use parser::Directive;
use rayon::prelude::{IntoParallelIterator, ParallelBridge, ParallelIterator};

use crate::codegen::FilePool;

pub mod codegen;
pub mod encoding;
pub mod parser;

fn main() -> Result<(), Box<dyn Error>> {
  #[cfg(debug_assertions)]
  let path = Path::new("fake-game");

  #[cfg(not(debug_assertions))]
  let path = Path::new(".");

  scan_mods(path.into())?;

  Ok(())
}

fn scan_mods(game_root: PathBuf) -> Result<(), Box<dyn Error>> {
  let cahirp_merge = Directive::cahirp_merge_path(&game_root);
  if cahirp_merge.exists() {
    println!("clearing existing cahirp merged files");
    std::fs::remove_dir_all(cahirp_merge)?;
  }

  use rayon::prelude::*;
  let directives = list_mods(&game_root)
    .into_par_iter()
    .flat_map(|module| parse_mod_recipes(module.path()));

  let directives: Vec<Directive> = directives.collect();
  let file_pool = FilePool::new(directives, &game_root)?;

  file_pool.emit(&game_root)?.perist()?;

  Ok(())
}

/// List the mods found in the mod directory while handling any eventual error
/// in the process, yielding only the Ok results.
fn list_mods(game_root: &PathBuf) -> impl rayon::iter::ParallelIterator<Item = DirEntry> {
  let mods_folder = game_root.join("mods");
  let Ok(mods) = std::fs::read_dir(mods_folder) else {
    panic!("Could not read mods folder");
  };

  mods.par_bridge().filter_map(|entry| match entry {
    Ok(e) => Some(e),
    Err(e) => {
      println!("error reading mod: {e}");

      None
    }
  })
}

/// List the recipes for the given module, then parse them while also handling
/// any eventual error during the process then return an iterator of the parsed
/// directives from all recipes that were found.
fn parse_mod_recipes<'a>(module: PathBuf) -> impl ParallelIterator<Item = Directive> + 'a {
  let files = match read_mod_directive_files(&module) {
    Ok(f) => f,
    Err(e) => {
      panic!("error reading recipes for {module:?}: {e}");
    }
  };

  files
    .into_par_iter()
    .filter_map(move |recipe| match parse_directive_file(recipe) {
      Ok(directives) => Some(directives),
      Err(e) => {
        println!("error parsing recipe for {module:?}: {e}");

        None
      }
    })
    .flat_map(|directives| directives)
}

fn read_mod_directive_files(module: &PathBuf) -> Result<Vec<String>, Box<dyn Error>> {
  let folder = module.join("cahirp");

  match std::fs::read_dir(folder) {
    Err(_) => Ok(Vec::new()),
    Ok(dir) => {
      let mut output = Vec::new();

      for entry in dir {
        let entry = entry?;
        let content = read_file(&entry.path())?;

        output.push(content)
      }

      Ok(output)
    }
  }
}

fn parse_directive_file(input: String) -> Result<Vec<parser::Directive>, Box<dyn Error>> {
  let mut output = Vec::new();

  // since we do not parse the code that a directive emits (to speed things up)
  // we must use some clever thinking to find exactly when the current directive
  // ends:
  // - if it's the last one in the file then it starts from the @ up until EOF
  // - if it's not the last one then it starts from the @ up until the next @
  let mut slice = &input[..];

  loop {
    slice = slice.trim();
    let start = slice.find('@');

    if start.is_none() {
      break;
    }

    let _start = start.unwrap_or(0);
    let end = match slice[1..].find('@') {
      Some(other) => other - 1,
      None => slice.len() - 1
    };
    let directive_slice = slice[..=end].trim();

    match parser::Directive::parse(directive_slice) {
      Ok((_, directive)) => {
        output.push(directive);
      }
      Err(e) => {
        println!("recipe syntax error: {e}");
      }
    }

    slice = &slice[end..];
  }

  Ok(output)
}
