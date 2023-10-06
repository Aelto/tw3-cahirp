use std::{error::Error, path::PathBuf};

pub fn read_file(path: &PathBuf) -> Result<String, Box<dyn Error>> {
  let contents = std::fs::read_to_string(path)?;

  Ok(contents.replace("\r", ""))
}
