use std::{
    error::Error,
    path::{Path, PathBuf},
};

use crate::codegen::CodeEmitter;
pub use crate::parser::prelude::*;

use self::directives::DirectiveType;

#[derive(Debug)]
pub struct Directive {
    pub variant: DirectiveType,
    pub code: String,
}

impl Directive {
    pub fn parse(i: &str) -> IResult<&str, Self> {
        let (i, _) = tag("@")(i)?;
        let (i, variant) = DirectiveType::parse(i)?;
        let code = i.trim().to_owned();

        Ok(("", Self { variant, code }))
    }

    pub fn emit_code(&self, game_root: &PathBuf) -> Result<(), Box<dyn Error>> {
        for note in self.variant.parameters().notes() {
            println!("- {note}");
        }

        for (file, relative_path) in self.affected_files(&game_root) {
            println!("  - on: {relative_path:?}");

            let content = std::fs::read_to_string(file)?;
            let output = match &self.variant {
                DirectiveType::Insert(i) => i.emit(content, &self.code)?,
                DirectiveType::Replace(r) => r.emit(content, &self.code)?,
            };

            let cahirp_merge = Self::cahirp_merge_path(game_root);
            let output_path = cahirp_merge.join(relative_path);

            if let Some(parent) = output_path.parent() {
                std::fs::create_dir_all(parent)?;
                std::fs::write(output_path, output)?;
            }
        }

        Ok(())
    }

    pub fn cahirp_merge_path(game_root: &PathBuf) -> PathBuf {
        game_root
            .join("mods")
            .join("mod00000_Cahirp")
            .join("content")
            .join("scripts")
    }

    fn affected_files<'a>(
        &'a self,
        game_root: &PathBuf,
    ) -> impl Iterator<Item = (PathBuf, PathBuf)> + 'a {
        let params = self.variant.parameters();

        let cahirp_merge = Self::cahirp_merge_path(game_root);
        let normal_merge = game_root
            .join("mods")
            .join("mod0000_MergedFiles")
            .join("content")
            .join("scripts");
        let content0 = game_root.join("content").join("content0").join("scripts");

        params.files()
            .filter_map(move |file| {
                let filep = Path::new(file);
                let p = cahirp_merge.join(filep);
                if p.exists() {
                    return Some((p, filep.into()));
                }

                let p = normal_merge.join(filep);
                if p.exists() {
                    return Some((p, filep.into()));
                }

                let p = content0.join(filep);
                if p.exists() {
                    return Some((p, filep.into()));
                }

                println!("Could not find {file} in neither Cahirp's merged files, Normal merged files nor content0... Skipping.");
                None
            })
    }
}
