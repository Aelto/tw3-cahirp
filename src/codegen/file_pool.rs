use std::cell::Cell;
use std::collections::{HashMap, HashSet};
use std::path::PathBuf;
use std::sync::{Arc, Mutex};

use rayon::prelude::*;

use crate::cli::prints::verbose_debug;
use crate::encoding::read_file;
use crate::error::CResult;
use crate::game::paths;
use crate::parser::Directive;

use super::{CodeEmitter, ExecutionOrchestrator, ExportDatabase};

type FileLockMap = HashMap<PathBuf, Arc<Mutex<Cell<String>>>>;

/// A thread-safe pool that holds the content of the files in memory and ensures
/// only one thread has access to a given file at once. Allowing to throw any
/// amount of threads at it so the work is spread without fearing data races.
pub struct FilePool {
  directives: Vec<Directive>,
  export_db: ExportDatabase,

  /// The file locks is what  ensure only a single thread has access to the
  /// underlying Cell to mutate the content of the "in-memory file"
  file_locks: FileLockMap
}

impl FilePool {
  /// At creation the [FilePool] generates the exhaustive flat list of files that
  /// directives will work on.
  pub fn new(
    directives: Vec<Directive>, export_db: ExportDatabase, game_root: &PathBuf, out: &PathBuf
  ) -> CResult<Self> {
    let mut locks = HashMap::new();
    let mods = paths::mod_folders(game_root, out)?;

    // fill the locks so each file has a corresponding lock
    for directive in &directives {
      let suffixes = directive.file_suffixes();
      for suffix in suffixes {
        let search_result = Self::find_file(&locks, game_root, &out, &suffix, &mods);

        match search_result {
          FileSearchResult::AlreadyInCache(_) => {}
          FileSearchResult::File((cahirp_path, contents)) => {
            locks.insert(cahirp_path, Arc::new(Mutex::new(Cell::new(contents))));
          }
          FileSearchResult::NotFound => {
            println!("Could not find with name [{:?}]", suffix);
          }
        }
      }
    }

    Ok(Self {
      file_locks: locks,
      directives,
      export_db
    })
  }

  /// Generate code and mutate the inner "in-memory" file locks with the results
  ///
  /// If persistence to disk is needed then refer to the [`persist()`] method
  pub fn emit(self, out: &PathBuf, mod_names: &Vec<String>) -> std::io::Result<Self> {
    // the initial variables are the names of all the mods that are installed,
    // with a special prefix to clearly indicate these are the installed mods.
    let initial_variables: Vec<String> =
      mod_names.iter().map(|s| format!("installed.{s}")).collect();

    let mut variables = HashSet::from_iter(initial_variables.iter().map(std::ops::Deref::deref));
    let mut orchestrator = ExecutionOrchestrator::new(&self.directives, &variables);

    loop {
      if orchestrator.finished {
        if crate::VERBOSE {
          verbose_debug("directive processing queue empty".to_owned());
        }

        break;
      }

      orchestrator.to_run.par_iter().for_each(|directive| {
        for suffix in directive.file_suffixes() {
          let arc = self.file_lock(out, &suffix);
          let cell = arc.lock().expect("mutex poisoning error");
          let contents = cell.take();
          let new_contents = match directive
            .insert
            .emit(contents, &directive.code, &self.export_db)
          {
            Ok(s) => s,
            Err(s) => {
              crate::cli::prints::build_no_location_found(out, directive.insert.parameters());

              s
            }
          };

          cell.set(new_contents);
        }
      });

      for &dir in &orchestrator.to_run {
        for define in dir.parameters().defines() {
          if crate::VERBOSE {
            verbose_debug(format!("define({define})"));
          }

          variables.insert(define);
        }
      }

      orchestrator.next(&variables);
    }

    Ok(self)
  }

  /// Persist the content of the in-memory files to disk
  pub fn persist(self) -> std::io::Result<()> {
    let results: Vec<std::io::Result<()>> = self
      .file_locks
      .into_par_iter()
      .map(|(path, contents)| {
        if let Some(parent) = path.parent() {
          if let Err(_) = std::fs::create_dir_all(parent) {}
        }

        let contents = contents.lock().expect("mutex poisoning error").take();

        std::fs::write(path, contents)
      })
      .collect();

    for result in results {
      if let Err(e) = result {
        println!("error while writing output to disk: {e}");
      }
    }

    Ok(())
  }

  fn find_file(
    locks: &FileLockMap, game_root: &PathBuf, out: &PathBuf, file_suffix: &PathBuf,
    mod_folders: &Vec<PathBuf>
  ) -> FileSearchResult {
    fn find_merge_file(game_root: &PathBuf, file_suffix: &PathBuf) -> Option<String> {
      read_file(&paths::merge_scripts(game_root).join(file_suffix)).ok()
    }

    /// Find a file inside mod folders, this can happen when a file is edited
    /// by a single mod which doesn't need any merging.
    fn find_mod_file(file_suffix: &PathBuf, mod_folders: &Vec<PathBuf>) -> Option<String> {
      for module in mod_folders {
        let p = module.join(file_suffix);

        if let Ok(content) = read_file(&p) {
          return Some(content);
        }
      }

      None
    }

    fn find_content_file(game_root: &PathBuf, file_suffix: &PathBuf) -> Option<String> {
      read_file(&paths::content_scripts(game_root).join(file_suffix)).ok()
    }

    let cahirp_file = out.join(file_suffix);

    if locks.contains_key(&cahirp_file) {
      FileSearchResult::AlreadyInCache(cahirp_file)
    } else {
      match read_file(&cahirp_file)
        .ok()
        .or_else(|| find_merge_file(game_root, file_suffix))
        .or_else(|| find_mod_file(file_suffix, mod_folders))
        .or_else(|| find_content_file(game_root, file_suffix))
      {
        Some(s) => FileSearchResult::File((cahirp_file, s)),
        None => FileSearchResult::NotFound
      }
    }
  }

  /// Get the file mutex for the given file suffix
  pub fn file_lock(&self, out: &PathBuf, file_suffix: &PathBuf) -> Arc<Mutex<Cell<String>>> {
    let path = out.join(file_suffix);

    Arc::clone(
      self
        .file_locks
        .get(&path)
        .expect("filelock on unknown file")
    )
  }
}

enum FileSearchResult {
  AlreadyInCache(PathBuf),
  File((PathBuf, String)),
  NotFound
}
