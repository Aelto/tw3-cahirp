use std::{path::PathBuf, sync::mpsc::Sender, time::Duration};

use notify_debouncer_full::DebounceEventHandler;

use crate::{error::CResult, game::paths};

use super::BuildOptions;

/// Kinds of events the Producer/Sender channel transmits & that are handled by
/// the [build_and_watch()] function
enum WatchEvent {
  /// Perform a rebuild of the recipes into the output folder
  Build,

  /// Perform a rebuild but stop the watcher once the build is finished
  BuildAndClose
}

/// An implementation of `DebounceEventHandler` from watching files that sends
/// [WatchEvent] from valid file changes.
struct WatchEmitter {
  tx: Sender<WatchEvent>,
  out: PathBuf
}

impl DebounceEventHandler for WatchEmitter {
  fn handle_event(&mut self, event: notify_debouncer_full::DebounceEventResult) {
    match event {
      Ok(events) => {
        let only_output_folder = events.iter().all(|event| {
          event
            .paths
            .iter()
            .all(|p| p.ancestors().any(|ancestor| ancestor.ends_with(&self.out)))
        });

        if !only_output_folder {
          if let Err(e) = self.tx.send(WatchEvent::Build) {
            println!("error sending build event: {e}");
          }
        }
      }
      Err(e) => e.iter().for_each(|e| println!("file watch error: {e}"))
    }
  }
}

pub fn build_and_watch(game_root: PathBuf, out: PathBuf, options: &BuildOptions) -> CResult<()> {
  use notify_debouncer_full::{new_debouncer, notify::*};

  let mods_folder = paths::mods_folder(&game_root);

  crate::cli::prints::clear();
  crate::cli::prints::watch(&mods_folder);

  let (tx, rx) = std::sync::mpsc::channel();
  let mut debouncer = new_debouncer(
    Duration::from_secs(1),
    None,
    WatchEmitter {
      tx: tx.clone(),
      out: out.clone()
    }
  )?;

  debouncer
    .watcher()
    .watch(&mods_folder, RecursiveMode::Recursive)?;

  debouncer.watcher().unwatch(&out)?;

  debouncer
    .cache()
    .add_root(&mods_folder, RecursiveMode::Recursive);

  let mut counter = 0;

  // instantly perform a build when starting the watch mode:
  handle_build(&game_root, &out, &options, &mut counter);

  ctrlc::set_handler(move || {
    if let Err(e) = tx.send(WatchEvent::BuildAndClose) {
      println!("error sending BuildAndClose event: {e}");
    }
  })
  .expect("error setting ctrl+c handler");

  // asynchronously handle watch events and trigger rebuilds when it happens
  for event in rx {
    match event {
      WatchEvent::Build => {
        // send a CLI clear here precisely so it doesn't clear in the
        // BuildAndClose event.
        crate::cli::prints::clear();

        handle_build(&game_root, &out, &options, &mut counter)
      }
      WatchEvent::BuildAndClose => {
        crate::cli::prints::clear();
        crate::cli::prints::watch_ctrlc();
        handle_build(&game_root, &out, &options, &mut counter);
        break;
      }
    }
  }

  Ok(())
}

/// Builds the recipes and safely handle any resulting error that may come from
/// it
fn handle_build(game_root: &PathBuf, out: &PathBuf, options: &BuildOptions, counter: &mut u64) {
  let before = std::time::Instant::now();

  match super::build(&game_root, &out, options) {
    Ok(()) => {
      crate::cli::prints::watch_rebuild(*counter, out, before);
      *counter += 1;
    }
    Err(e) => {
      println!("{e}");
    }
  };
}
