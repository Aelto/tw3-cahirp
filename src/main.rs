use std::error::Error;
use std::path::{Path, PathBuf};

pub mod parser;

fn main() -> Result<(), Box<dyn Error>> {
    scan_mods(Path::new("mods"))?;

    Ok(())
}

fn scan_mods(folder: &'static Path) -> Result<(), Box<dyn Error>> {
    let mods = std::fs::read_dir(folder)?;

    for module in mods {
        let module = module?;

        scan_mod(&module.path())?;
    }

    Ok(())
}

fn scan_mod(module: &PathBuf) -> Result<(), Box<dyn Error>> {
    println!("scanning: {module:?}");

    let files = dbg!(read_mod_directive_files(module)?);
    for content in files {
        let directives = parse_directive_file(content)?;
        println!("{directives:#?}");
    }

    Ok(())
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
