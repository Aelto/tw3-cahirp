set shell := ["nu", "-c"]

release:
  cargo b --release

dev: dev-build

dev-build:
  cargo r -- build --recipes ./recipes

dev-watch:
  cargo r -- build --recipes ./recipes --watch