use std::{collections::HashMap, error::Error, path::PathBuf, sync::Mutex};

use rayon::prelude::*;

use crate::parser::Directive;

pub struct FilePool {
  directives: Vec<Directive>,

  file_locks: HashMap<PathBuf, Mutex<()>>
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
          let parent = content_path
            .parent()
            .expect("invalid file path, no parent available");
          std::fs::create_dir_all(parent)?;

          std::fs::copy(&file, &content_path)?;
          locks.insert(content_path, Mutex::new(()));
        }
      }
    }

    Ok(Self {
      directives,
      file_locks: locks
    })
  }

  pub fn emit(self, game_root: &PathBuf) -> std::io::Result<()> {
    self
      .directives
      .par_iter()
      .flat_map(|directive| {
        directive
          .affected_files(game_root)
          .par_bridge()
          .map(|(_, file_suffix)| {
            let mutex = self.file_lock(game_root, &file_suffix);
            let _lock = mutex.lock().expect("mutex poisoning error");

            let cahirp_file = Self::cahirp_path(game_root, &file_suffix);
            if let Err(e) = directive.emit_file_code(&cahirp_file) {
              return Err(e);
            }

            Ok(())
          })
      })
      .collect()
  }

  /// Make a path to the file in the cahirp output merged files folder using
  /// the provided file_suffix
  pub fn cahirp_path(game_root: &PathBuf, file_suffix: &PathBuf) -> PathBuf {
    Directive::cahirp_merge_path(game_root).join(file_suffix)
  }

  /// Get the file mutex for the given file suffix
  pub fn file_lock(&self, game_root: &PathBuf, file_suffix: &PathBuf) -> &Mutex<()> {
    let path = Self::cahirp_path(game_root, file_suffix);

    self
      .file_locks
      .get(&path)
      .expect("filelock on unknown file")
  }
}
