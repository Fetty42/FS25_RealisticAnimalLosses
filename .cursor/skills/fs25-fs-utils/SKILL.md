---
name: fs25-fs-utils
description: Use when working with fs-utils CLI tools — decompiling Luau/LuaJIT bytecode, extracting GAR/DLC archives, unlocking shapes files, or formatting XML.
---

# fs-utils

## Overview

Collection of CLI tools for working with Farming Simulator game files. Source: [github.com/scfmod/fs-utils](https://github.com/scfmod/fs-utils)

## When to Use

- Decompiling `.l64` scripts (Luau or LuaJIT)
- Extracting `.gar` or `.dlc` archives
- Unlocking `.i3d.shapes` files
- Formatting XML files from game data

## Build

Clone the repo and build with Cargo:

```bash
git clone https://github.com/scfmod/fs-utils.git
cd fs-utils
cargo build
```

Run tools with `cargo run -p <crate> --`:

## Tools

### fs-luau-decompile

Decompile FS25 Luau `.l64` bytecode. Uses medal by default, optionally lantern.

```bash
# Single file
cargo run -p fs-luau-decompile -- script.l64

# Recursive
cargo run -p fs-luau-decompile -- -r scripts/ ./output/

# Read directly from GAR archive
cargo run -p fs-luau-decompile -- dataS.gar/scripts/main.l64
cargo run -p fs-luau-decompile -- -r dataS.gar/scripts/ ./output/

# Decode only (no decompile)
cargo run -p fs-luau-decompile -- -d script.l64
```

### fs-luajit-decompile

Decompile FS19/FS22 LuaJIT `.l64` bytecode.

```bash
cargo run -p fs-luajit-decompile -- script.l64
cargo run -p fs-luajit-decompile -- -r scripts/ ./output/
```

### fs-unpack

Extract `.gar` / `.dlc` archives.

```bash
cargo run -p fs-unpack -- archive.gar ./output/
cargo run -p fs-unpack -- archive.dlc ./output/
```

### fs-shapes-unlock

Unlock `.i3d.shapes` files.

```bash
cargo run -p fs-shapes-unlock -- model.i3d.shapes
cargo run -p fs-shapes-unlock -- -r models/ ./output/
```

### fs-xml-format

Format XML files with consistent indentation.

```bash
cargo run -p fs-xml-format -- file.xml
cargo run -p fs-xml-format -- -r xmlfiles/ ./output/
cargo run -p fs-xml-format -- -c tab file.xml
cargo run -p fs-xml-format -- -c space -i 4 file.xml
```

### fs-patch / fs-patch-process

Binary patching tools (Windows only for process patching).

## Quick Reference

| Task | Command |
|---|---|
| Decompile FS25 script | `cargo run -p fs-luau-decompile -- script.l64` |
| Decompile FS19/22 script | `cargo run -p fs-luajit-decompile -- script.l64` |
| Extract GAR archive | `cargo run -p fs-unpack -- archive.gar ./out/` |
| Unlock shapes | `cargo run -p fs-shapes-unlock -- model.i3d.shapes` |
| Format XML | `cargo run -p fs-xml-format -- file.xml` |
| Batch any tool | Add `-r` flag for recursive directory processing |
