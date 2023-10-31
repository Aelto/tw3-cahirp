use std::path::PathBuf;

use owo_colors::colors::*;
use owo_colors::OwoColorize;

mod badges {

  use super::*;

  pub fn build() -> String {
    let badge = " BUILD ";

    badge.fg::<White>().bg::<Cyan>().to_string()
  }

  pub fn watch() -> String {
    let badge = " WATCH ";

    badge.fg::<Black>().bg::<Yellow>().to_string()
  }

  pub fn counter(n: u64) -> String {
    let badge = format!(" #{n} ");

    badge.fg::<Black>().bg::<Yellow>().to_string()
  }
}

pub fn build(path: &PathBuf) {
  println!("{} {}", badges::build(), path.display().green());
}

pub fn clean_files() {
  let spaces = " ".repeat(5);

  println!("{spaces}└─ cleaning output directory");
}

pub fn watch(folder: &PathBuf) {
  let badge = badges::watch();

  println!("{badge} {}", folder.display().green());
}

pub fn watch_rebuild(counter: u64, path: &PathBuf, instant: std::time::Instant) {
  let badge = badges::build();
  let counter = badges::counter(counter);

  linebreak();
  println!("{badge}{counter} rebuilt {}", path.display().green());

  let spaces = " ".repeat(9);
  println!(
    "{spaces}└─ finished in {}s",
    instant.elapsed().as_secs_f32()
  );
}

pub fn watch_ctrlc() {
  let badge = badges::watch();

  println!("{badge} building one last time and closing...");
}

pub fn linebreak() {
  println!("");
}

pub fn clear() {
  print!("\x1B[2J\x1B[1;1H");
}
