use std::path::PathBuf;

pub fn to_scripts(module: PathBuf) -> PathBuf {
  module.join("content").join("scripts")
}

pub fn cahirp_mod(game_root: &PathBuf) -> PathBuf {
  game_root.join("mods").join("mod00000_Cahirp")
}

pub fn cahirp_folder(game_root: &PathBuf) -> PathBuf {
  to_scripts(cahirp_mod(game_root))
}

pub fn merge_folder(game_root: &PathBuf) -> PathBuf {
  to_scripts(game_root.join("mods").join("mod0000_MergedFiles"))
}

pub fn content_folder(game_root: &PathBuf) -> PathBuf {
  game_root.join("content").join("content0").join("scripts")
}

/// Get the list of mod folders that aren't MergedFiles nor Cahirp files
pub fn mod_folders(game_root: &PathBuf) -> std::io::Result<Vec<PathBuf>> {
  let merge_folder = merge_folder(game_root);
  let cahirp_folder = cahirp_folder(game_root);

  let is_enabled = |m: &PathBuf| {
    m.file_name()
      .and_then(|m| m.to_str())
      .map(|n| !n.starts_with("~"))
      .unwrap_or(false)
  };

  let folders = std::fs::read_dir(game_root.join("mods"))?
    .into_iter()
    .filter_map(|e| e.ok())
    .map(|m| m.path())
    .filter(is_enabled)
    .map(to_scripts)
    .filter(|m| m != &cahirp_folder && m != &merge_folder)
    .collect::<Vec<PathBuf>>();

  Ok(folders)
}
