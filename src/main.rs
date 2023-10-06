use std::error::Error;
use std::path::{Path, PathBuf};

use parser::Directive;

pub mod codegen;
pub mod parser;

fn main() -> Result<(), Box<dyn Error>> {
    let path = Path::new("./fake-game");
    scan_mods(path.into())?;

    Ok(())
}

fn scan_mods(game_root: PathBuf) -> Result<(), Box<dyn Error>> {
    let cahirp_merge = Directive::cahirp_merge_path(&game_root);
    if cahirp_merge.exists() {
        println!("clearing existing cahirp merged files");
        std::fs::remove_dir_all(cahirp_merge)?;
    }

    let mods_folder = game_root.join("mods");
    let mods = std::fs::read_dir(mods_folder)?;

    for module in mods {
        let module = module?;

        let directives = scan_mod(&module.path())?;

        for directive in directives {
            directive.emit_code(&game_root)?;
        }
    }

    Ok(())
}

fn scan_mod(module: &PathBuf) -> Result<Vec<Directive>, Box<dyn Error>> {
    let mut output = Vec::new();

    let files = read_mod_directive_files(module)?;
    for content in files {
        let mut directives = parse_directive_file(content)?;

        output.append(&mut directives);
    }

    Ok(output)
}

fn read_mod_directive_files(module: &PathBuf) -> Result<Vec<String>, Box<dyn Error>> {
    let folder = module.join("cahirp");

    match std::fs::read_dir(folder) {
        Err(_) => Ok(Vec::new()),
        Ok(dir) => {
            let mut output = Vec::new();

            for entry in dir {
                let entry = entry?;
                let content = std::fs::read_to_string(entry.path())?;

                output.push(content)
            }

            Ok(output)
        }
    }
}

fn parse_directive_file(input: String) -> Result<Vec<parser::Directive>, Box<dyn Error>> {
    let mut output = Vec::new();

    // since we do not parse the code that a directive emits (to speed things up)
    // we must use some clever thinking to find exactly when the current directive
    // ends:
    // - if it's the last one in the file then it starts from the @ up until EOF
    // - if it's not the last one then it starts from the @ up until the next @
    let mut slice = &input[..];

    loop {
        slice = slice.trim();
        let start = slice.find('@');

        if start.is_none() {
            break;
        }

        let _start = start.unwrap_or(0);
        let end = match slice[1..].find('@') {
            Some(other) => other - 1,
            None => slice.len() - 1,
        };
        let directive_slice = slice[..=end].trim();

        match parser::Directive::parse(directive_slice) {
            Ok((_, directive)) => {
                output.push(directive);
            }
            Err(e) => {
                println!("parse error: {e}");
            }
        }

        slice = &slice[end..];
    }

    Ok(output)
}
