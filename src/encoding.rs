use std::path::PathBuf;

pub fn read_file(path: &PathBuf) -> std::io::Result<String> {
  let contents = std::fs::read_to_string(path)?;

  Ok(contents.replace("\r", ""))
}
