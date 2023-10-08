use std::{
  cell::Cell,
  collections::HashMap,
  error::Error,
  path::PathBuf,
  sync::{Arc, Mutex}
};

use rayon::prelude::*;

use crate::{encoding::read_file, parser::Directive};

use super::CodeEmitter;

pub struct FilePool {
  directives: Vec<Directive>,

  file_locks: HashMap<PathBuf, Arc<Mutex<Cell<String>>>>
}

impl FilePool {
  pub fn new(directives: Vec<Directive>, game_root: &PathBuf) -> Result<Self, Box<dyn Error>> {
    let mut locks = HashMap::new();

    // fill the locks so each file has a corresponding lock
    for directive in &directives {
      let files = directive.affected_files(game_root);

      for (file, file_suffix) in files {
        let content_path = Self::cahirp_path(game_root, &file_suffix);

        if !locks.contains_key(&content_path) {
          // let parent = content_path
          //   .parent()
          //   .expect("invalid file path, no parent available");
          // std::fs::create_dir_all(parent)?;

          // std::fs::copy(&file, &content_path)?;

          let contents = read_file(&file)?;
          locks.insert(content_path, Arc::new(Mutex::new(Cell::new(contents))));
        }
      }
    }

    Ok(Self {
      directives,
      file_locks: locks
    })
  }

  pub fn emit(self, game_root: &PathBuf) -> std::io::Result<Self> {
    self.directives.par_iter().for_each(|directive| {
      for (_, file_suffix) in directive.affected_files(game_root) {
        let arc = self.file_lock(game_root, &file_suffix);
        let cell = arc.lock().expect("mutex poisoning error");
        let contents = cell.take();
        let new_contents = directive.insert.emit(contents, &directive.code);

        cell.set(new_contents);
      }
    });

    Ok(self)
  }

  pub fn perist(self) -> std::io::Result<()> {
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

  /// Make a path to the file in the cahirp output merged files folder using
  /// the provided file_suffix
  pub fn cahirp_path(game_root: &PathBuf, file_suffix: &PathBuf) -> PathBuf {
    Directive::cahirp_merge_path(game_root).join(file_suffix)
  }

  /// Get the file mutex for the given file suffix
  pub fn file_lock(&self, game_root: &PathBuf, file_suffix: &PathBuf) -> Arc<Mutex<Cell<String>>> {
    let path = Self::cahirp_path(game_root, file_suffix);

    Arc::clone(
      self
        .file_locks
        .get(&path)
        .expect("filelock on unknown file")
    )
  }
}
