# Functional Gutters
Functional Gutters is a mod for the video game `Project Zomboid [B42]` that increases the rate of water collection for the game's rain collector entities when they are built or placed on a tile containing a gutter drain pipe sprite.

This is a simple representation of rain flowing from a building's roof through its gutters and drain pipes into a collector below. Unlike real life, you won't ever need to clean them!


![Functional Gutters Poster Image](poster.png)


## Context
Build 42 introduced a great variety of of new sprites that decorate buildings, however most are purely aesthetic and don't impact any systems in the game. Gutter pipes are an example of the newly added flavor sprites and they inspired the creation of this mod.

### How It Works
This mod allows these new gutter sprites to serve a functional purpose by increasing the amount of rain water collected for any rain collectors placed on the same grid square.

The increased rain factor is controlled by the mod option `GutterRainFactor` and can be changed through the mod options menu. This value defaults to `0.8` (2x the base value of crates and nearly 3x the base value of barrels) and can be customized in the mod's options panel to a value between `0.5` and `3.0`.

When a supported collector entity is built or placed on a square, the mod compares all object sprites in the square against a mod-managed list of gutter sprites. 
- If the newly-placed collector shares a square with one of the "approved" sprites, its rain factor is set the to `GutterRainFactor`. 
- If it doesn't share a square, a quick equality check is made against the entity's base rain factor and a reset occurs if there is any difference between these values.


#### Fun Fact
> In the base game, the square rain collector crates have a much greater base rain factor (`0.4`) compared with the circular rain collector barrels (`0.25`) meaning they will collect rain much faster. This makes some sense as the crate's square opening covers a larger surface area than the barrel's circular opening but these details aren't ever surfaced to the player.


Even though crates and barrels have a different base rain factor, this mod sets both types to the same rate `GutterRainFactor` when they are on an active drain pipe tile. Realistically, the diameter of the drainpipes would limit the maximum fill rate of any attached vessel to effectively the same amount. For the sake of realism (and simplicity), the current version of the mod treats all containers the same. That said, I am open to potentially exploring more involved options - such as including the size of the building's roof as a variable in the equation - at a later date.

### Supported Collector Entities
* [x] Rain collector crate
* [x] Rain collector crate (tarp)
* [x] Rain collector barrel
* [x] Rain collector barrel (tarp)
* [ ] Closed `FluidContainers` (amphora)
* [ ] Single-tile feeding troughs
* [ ] Multi-tile feeding troughs
* [ ] Placeable world inventory items (pots)
* [ ] Generic multi-tile entities with FluidContainers
* [ ] Non-FluidContainer entities that fit thematically (bathtub, toilet)
* [ ] Generic movable entities with FluidContainers (tanker trailer)


### Drainage Sprites
```
{
    "industry_02_260",
    "industry_02_261",
    "industry_02_263",
    -- TODO find all
}
```

### TODO / TBD
* Add any missing drain pipe sprite identifiers!
* Support for variable gutter rain factor that scales with roof size?
* Support stacked/multi tier rain collectors with connected pipe?
* Support manually adding custom sprites to the core gutter list?


### Local Dev Notes

#### Windows SymLink
To avoid developing directly in the PZ mods directory, it is helpful to create a symlink in the PZ mods folder (path) pointing to the external path of the mod managed elsewhere on your system.

NOTE: you will want to point to the interior mod folder not the root.

##### Path (PZ Mods Directory)
`C:\\<zomboid_mod_directory_path>\FunctionalGutters`

##### Target (Mod Source Directory)
`<local_development_mod_path>\Contents\mods\FunctionalGutters`

##### Cmd (Windows)
```
mklink /d <path> <target>
```
<br/>

#
<br/>

![Functional Gutters Poster Image](Contents/mods/FunctionalGutters/42/hey.png)
![Functional Gutters Poster Image](Contents/mods/FunctionalGutters/42/yes.png)
![Functional Gutters Poster Image](Contents/mods/FunctionalGutters/42/no.png)