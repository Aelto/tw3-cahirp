use std::{error::Error, path::PathBuf};

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
        for (file, relative_path) in self.affected_files(&game_root) {
            let content = std::fs::read_to_string(file)?;
            let output = match &self.variant {
                DirectiveType::Insert(i) => i.emit(content, &self.code)?,
                DirectiveType::Replace(r) => r.emit(content, &self.code)?,
            };

            let cahirp_merge = self.cahirp_merge_path(game_root);
            let output_path = cahirp_merge.join(relative_path);

            std::fs::write(output_path, output)?;
        }

        Ok(())
    }

    fn cahirp_merge_path(&self, game_root: &PathBuf) -> PathBuf {
        game_root
            .join("mod00000_Cahirp")
            .join("content")
            .join("scripts")
    }

    fn affected_files<'a>(
        &'a self,
        game_root: &PathBuf,
    ) -> impl Iterator<Item = (PathBuf, &'a str)> + 'a {
        let params = self.variant.parameters();

        let cahirp_merge = self.cahirp_merge_path(game_root);
        let normal_merge = game_root
            .join("mod0000_MergedFiles")
            .join("content")
            .join("scripts");
        let content0 = game_root.join("content").join("content0").join("scripts");

        params.files()
            .filter_map(move |file| {
                let p = cahirp_merge.join(file);
                if cahirp_merge.join(file).exists() {
                    return Some((p, file));
                }

                let p = normal_merge.join(file);
                if p.exists() {
                    return Some((p, file));
                }

                let p = content0.join(file);
                if p.exists() {
                    return Some((p,file));
                }

                println!("Could not find {file} in neither Cahirp's merged files, Normal merged files nor content0... Skipping.");
                None
            })
    }
}
