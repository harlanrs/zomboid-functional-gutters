# Functional Gutters
Functional Gutters is a mod for the video game Project Zomboid [B42] that increases the rate of water collection for the game's rain collector entities when they are built or placed on a tile containing a gutter drain pipe sprite.

This is a simple representation of rain flowing from a building's roof through its gutters and drain pipes into a collector below. Unlike real life, you won't ever need to clean them!

## Context
Build 42 introduced a great variety of of new sprites that decorate buildings including drain pipes, however these are all purely aesthetic and don't impact any functionality of the game world. 

This mod allows these new drainage pipe sprites to serve a purpose by increasing the rain factor of select entities built on the same grid square.

This increased rain factor is a variable `GutterRainFactor` created by this mod. This value defaults to `0.8` (2x the base value of crates and >3x the base value of barrels) and can be customized in the mod's options panel to a value between `0.5` and `3.0`.

Fun fact: 
* In the base game, the square rain collector crates have a greater base rain factor (`0.4`) than the circular rain collector barrels (`0.25`) meaning they will collect rain much faster. This makes some sense as the square covers a greater surface area but these details aren't ever surfaced to the player.

## TODO

### TBD

* Support for feeding troughs?
* Support for world inventory objects like pots?
* Support for variable gutter rain factor that scales with roof size?
* Support stacked/multi tier rain collectors with connected pipe?


## Local Dev Notes

### Windows SymLink
To avoid developing directly in the PZ mods directory, it is helpful to create a symlink in the PZ mods folder (path) pointing to the external path of the mod managed elsewhere on your system.

NOTE: you will want to point to the interior mod folder not the root.

#### Path (PZ Mods Directory)
C:\\<zomboid_mod_directory_path>\FunctionalGutters

#### Target (Mod Source Directory)
C:\\<local_development_mod_path>\Contents\mods\FunctionalGutters

#### Cmd (Windows)
mklink /d \<path> \<target>