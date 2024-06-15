use std::fs::DirEntry;
use std::path::PathBuf;

use crate::codegen::{ExportDatabase, FilePool};
use crate::encoding::read_file;
use crate::error::CResult;
use crate::parser::{Context, Directive, DirectiveId};

mod watcher;
pub use watcher::build_and_watch;

use rayon::prelude::{IntoParallelIterator, ParallelIterator};

pub struct BuildOptions {
  pub clean_before_build: bool,
  pub recipes_dir: Option<PathBuf>
}

pub fn build(game_root: &PathBuf, out: &PathBuf, options: &BuildOptions) -> CResult<()> {
  crate::cli::prints::build(out);

  if options.clean_before_build {
    if out.exists() {
      crate::cli::prints::clean_files();
      std::fs::remove_dir_all(&out)?;
    }
  }

  scan_mods(game_root, out, &options)
}

fn scan_mods(game_root: &PathBuf, out: &PathBuf, options: &BuildOptions) -> CResult<()> {
  use rayon::prelude::*;
  let (mut directives, mod_names): (Vec<Directive>, Vec<String>) =
    match options.recipes_dir.as_ref() {
      // no mod override, scan the "mods" folder deduced from the game_root
      None => {
        let mod_names = list_mods(&game_root)
          .filter_map(|module| module.file_name().to_str().map(str::to_owned))
          .collect();

        let directives = list_mods(&game_root)
          .par_bridge()
          .into_par_iter()
          // recipes are expected to be in a `cahirp` folder inside the mods
          .flat_map(|module| parse_dir_recipes(module.path().join("cahirp")))
          .collect();

        (directives, mod_names)
      }
      // an override is provided, scan only this folder for recipes
      Some(dir) => (
        vec![dir]
          .into_par_iter()
          .flat_map(|module| parse_dir_recipes(module.to_path_buf()))
          .collect(),
        // with an override there is no installed mod since there is no mods folder
        vec![]
      )
    };

  // assigns ids to the directives
  let mut index = 0;
  for directive in &mut directives {
    directive.id = DirectiveId::new(index);
    index += 1;
  }

  let export_db = ExportDatabase::collect_named_exports(&mut directives);
  export_db.feed_exports(&mut directives);

  let file_pool = FilePool::new(directives, export_db, &game_root, &out)?;

  file_pool.emit(&out, &mod_names)?.persist()?;

  Ok(())
}

/// List the mods found in the mod directory while handling any eventual error
/// in the process, yielding only the Ok results.
fn list_mods(game_root: &PathBuf) -> impl Iterator<Item = DirEntry> {
  let mods_folder = game_root.join("mods");
  let Ok(mods) = std::fs::read_dir(mods_folder) else {
    panic!("Could not read mods folder");
  };

  mods.filter_map(|entry| match entry {
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
fn parse_dir_recipes<'a>(module: PathBuf) -> impl ParallelIterator<Item = Directive> + 'a {
  let files = match read_dir_directive_files(&module) {
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
    .flat_map_iter(|directives| directives)
}

fn read_dir_directive_files(folder: &PathBuf) -> CResult<Vec<String>> {
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

fn parse_directive_file(input: String) -> CResult<Vec<crate::parser::Directive>> {
  let mut output = Vec::new();

  // since we do not parse the code that a directive emits (to speed things up)
  // we must use some "clever" thinking to find exactly when the current directive
  // ends:
  // - if it's the last one in the file then it starts from the @ up until EOF
  // - if it's not the last one then it starts from the @ up until the next @
  let mut slice = &input[..];
  let mut context = Context::empty();

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

    match context.parse_with_context(directive_slice) {
      Err(e) => {
        println!("recipe syntax error: {e}");
      }
      Ok(some_directive) => {
        if let (_, Some(directive)) = some_directive {
          output.push(directive);
        }
      }
    }

    slice = &slice[end..];
  }

  Ok(output)
}
