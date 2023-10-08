use std::{
  fs::File,
  io::{BufReader, ErrorKind},
  path::PathBuf
};

use encoding_rs_io::DecodeReaderBytesBuilder;

pub fn read_file(path: &PathBuf) -> std::io::Result<String> {
  let contents = read_utf16_file(path)?;
  // let contents = std::fs::read_to_string(path).or_else(|_| read_utf16_file(path))?;

  Ok(contents.replace("\r", ""))
}

fn read_utf16_file(path: &PathBuf) -> std::io::Result<String> {
  use std::io::Read;

  let file = File::open(path)?;
  let source = BufReader::new(file);

  let mut decoder = DecodeReaderBytesBuilder::new().build(source);
  let mut dest = String::new();
  // decoder implements the io::Read trait, so it can easily be plugged
  // into any consumer expecting an arbitrary reader.
  decoder.read_to_string(&mut dest)?;

  Ok(dest)
}
