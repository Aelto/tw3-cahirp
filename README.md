# Cahir Pre-processor
> [Using It](#using-it) | [Advantages](#advantages-of-generating-merges-using-recipes)


Enables merges as code for The Witcher 3. Provides version agnostic generation of
merged files from recipes written in a DSL.

```c
@insert(
  note("add our own event listener for when an item is added to the inventory")
  file("game/components/inventoryComponent.ws")
  at(class CInventoryComponent)
  at(event OnItemAdded)
  below(ent = (CGameplayEntity)GetEntity())
)
// modItemEquipEvent - BEGIN
MOD_onItemAdded(this, data);
// modItemEquipEvent - END


@insert(
  note("makes that repair kits repair 100% of the item's durability")
  file(game/player/r4Player.ws)
  at(class CR4Player)
  at(function RepairItemUsingConsumable)
  select(repairValue = max * itemValue /100;)
)
// modFullRepair - BEGIN
repairValue = max;
// modFullRepair - BEGIN
```


- A mod can be composed of as many recipes as needed. In practice a recipe is a text
file written in [`modExample/cahirp`](/fake-game/mods/modExample/) (where `modExample`
is the arbitrary name given to the example mod).
- Each recipe contains one or more directives that will be executed by the pre-processor in order to emit code in a `mod00000_Cahirp`
mod.
- A directive is a series of pattern to look in file(s), and code to emit once all patterns
were found. The pre-processor goes from top to bottom, from pattern to pattern until
all the list is exhausted where it finally writes the code.

The cahirp mod is like the MergedFiles mod, a combination of multiple mods the
game will load before any other mod (MergedFiles included). While building the
cahirp mod and while generating code, the pre-processor can use the code from either:
- the existing file in `mod00000_Cahirp`
- the existing file in `mod0000_MergedFiles`
- the existing file in `content0/scripts`
in this order of importance. If a recipe requires a file that is not found in `MergedFiles`
then it will use the current `content0` scripts as the base. But then for any other recipe
needing this file they will instead use the previously extracted one in order to
accumulate the generated code.

The pre-processor and code generation is idempotent as the first action is the deletion
of any existing `mod00000_Cahirp` folder to ensure that successive runs,
if given similar inputs (content0 & MergedFiles & recipes), yields the exact same
`mod00000_Cahirp` folder.

# Advantages of generating merges using recipes
## Version agnostic
As stated in the headline, the directives use a series of patterns (similar to anchors)
to progressively move a virtual cursor around the code until the desired position
is found. This has the advantage of abstracting away any change to the code as long
as the desired patterns or anchors remain intact.

Whether the input code uses the game's version 1.32 or 4.04, the following directive
stays valid and can be used to emit the code in the correct place every time:
```c
@insert(
  note("add our own event listener for when an item is added to the inventory")
  file("game/components/inventoryComponent.ws")
  at(class CInventoryComponent)
  at(event OnItemAdded)
  below(ent = (CGameplayEntity)GetEntity())
)
// modItemEquipEvent - BEGIN
MOD_onItemAdded(this, data);
// modItemEquipEvent - END
```

## Conflict free
Unlike a regular script-merger that uses an automatic algorithm generally aimed
at software developers, the pre-processor puts the duty of defining patterns & anchors
that will be used to properly write the code in the correct place to the person
writing the mod. It gives control to the mod author over what pattern is needed
and what is not so the emitted code can function as intended, removing conflicts
almost entirely.

Note that removing conflicts may help in most cases, but it can also create other
problems with poorly written directives that can emit code like the following.
```c
if (some_bool) {
```
_This is where the `select` parameter can be used to replace code and change the
value of variable as needed._

## Compile-time code generation
The pre-processor working at compile time (and it being mostly conflict free)
creates possibilities that would otherwise cause conflicts or require extra
manipulation from the end users.

For example it is possible for multiple recipes from multiple mods to add a
function call in `R4Player::OnSpawn()` to bootstrap their mods without fearing
a conflict or without requiring any fake quest mod to call the function automatically
after a loading screen.

The pre-processor is also able to work on local files that use custom syntax that
your recipes will change at compile time. The first example that comes to mind
is the ability to turn on/off parts of an overhaul by using directives to turn
boolean flag to `true` or `false`.

## Isolated merges per domain
A single mod can be composed of multiple recipes, each recipe can in turn hold
multiple directives. A recipe is thus a unit that holds merges spanning over
different files and that can be used to organize the merges for specific domains.

Let's take a gameplay overhaul as an example, let's imagine it adds the following features:
- combat stamina changes:
  - actions cost stamina (r4player.ws in the performAction event)
  - actions require stamina (playerInput.ws)
  - passive stamina regeneration increased by 100% (effect.ws)
- loot changes:
  - common monsters no longer drop gear on death (CNewNPC.ws)
  - ...

This overhaul could be composed of a `cahirp/combat-stamina.ws` recipe and a
`cahirp/loot.ws` recipe to organize each series of merges by their domain.

# Using it
## Before shipping, by the author (mod maker)
see:
- [Isolated merges per domain](#isolated-merges-per-domain)
- [Version agnostic](#version-agnostic)

The tool can be used while crafting mods, to organize, re-use, and share merge recipes.
Once the mod is ready to be shipped and shared to the world the pre-processor can be
used to generate the merges using the currently installed version of the game.

### Command examples
- building all mods currently installed into a mod in the current working directory named `release/myMod`
  - `--game` is used to target a game install from elsewhere
  - `--out` is used to tell cahirp to emit the merges in the provided folder
  - `--clean` instructs cahirp to clean the `--out` folder before emitting merges
  - ```sh
    tw3-cahirp build --game /games/the-witcher-3 --out ./release/myMod/content/scripts --clean
    ```

- watching for changes in the dev recipes and updating a ready to release mod
  - `--game` is used to target a game install from elsewhere
  - `--out` is used to tell cahirp to emit the merges in the provided folder
  - `--watch` tells cahirp to continuously watch for changes on the recipes and rebuild when needed
  - `--recipes` is used to use a specific folder for the recipes rather than the mods installed in `--game`
  - `--clean` instructs cahirp to clean the `--out` folder before emitting merges
  - ```sh
    tw3-cahirp build --game /games/the-witcher-3 --out ./release/myMod/content/scripts --recipes src/myMod/cahirp --watch --clean
    ```

### Mods using cahirp for development
- [TW3 CROW](https://github.com/Aelto/tw3-crow)
- [TW3 Combat Skills](https://github.com/Aelto/tw3-combat-skills)

## After shipping, by the end user (mod user)
see:
- [Conflict free](#conflict-free)
- [Version agnostic](#version-agnostic)
- [Compile time code generation](#compile-time-code-generation)

It is possible to share mods with the merge recipes in them so the end-user runs
the pre-processor after merging the other mods in order to safely and easily emit
code.

The pre-processor default parameters are configured for this situation, so running
the tool without any special argument will parse all recipes that can be found in
the mods installed in the game install directory in order to emit a `mods/mod00000_Cahirp` mod folder.

# Writing recipes
```c
@context(
  file(game/player/r4Player.ws)
  at(class CR4Player)
)

@insert(
  note("makes that repair kits repair 100% of the item's durability")
  define("modFullRepair.installed")
  at(function RepairItemUsingConsumable)
  select(repairValue = max * itemValue /100;)
)
// modFullRepair - BEGIN
repairValue = max;
// modFullRepair - BEGIN
```

Let's start by examining an existing recipe:
- `@insert()` is a **directive**,
- in its parenthesis you can find parameters like `note()`, or `file`, or `at`
- below the directive there is the code emitted by the directive. The code can span over
multiple lines and it continues until the next directive or the end of the file.

## Directives
- `@insert` informs the pre-processor to emit code in one or many files at a given position
  - parameters:
    - `note` (optional, multiple notes is possible): like a comments, adds context to the directive
      and can be used by the pre-processor to generate descriptions of the directives
    - `file` (required, multiple files is possible): informs the pre-processor to
    run the directive over the provided files. The path that is supplied should start
    from the `The Witcher 3/content/content0/scripts` folder
    - `ifdef(string)` (optional, multiple ifdefs is possible): provide a variable that must be defined for the directive to emit its code
    - `define(string)` (optional, multiple defines is possible): provide a variable to define after the directive has emitted its code. If the directive is blocked by `ifdef` requirements then it will wait until all of them are valid before defining its `define` instructions
    - `at(pattern)` places the cursor at the start of the pattern,
    - `above(pattern)` places it on line above right before the `\n`,
    - `below(pattern)` places it on the line below right after the `\n`
    - `select(pattern)` places the cursor at the start of the pattern and removes
    anything that is outside the pattern. Successive `select(pattern)` can be used
    to progressively go deeper in the patterns. It can be used to declare "dependencies"
    where the first select must exist before going deeper into the second the select
    - `select[[multiline pattern]]` is like the normal select but on multiple lines,
    the indentation of the lines is ignored to make it easier/cleaner
    - `export(pattern)`, marks the current insert directive as available to use in other directives through the `use(pattern)` parameter. Any exported directive is ignored during the code generation process, and its code is ignored. If multiple `export` parameters are found in a single directive, only the first one is used to identify it.
    - `use(pattern)` tells to copy the parameters from the exported directive at the exact position of the parameter inside the current directive. If the imported directives themselves has `use` parameters as well then it will continue to append parameters until there is no more import found.
- `@context` can be used to avoid repetitions in the `@insert` parameters by adding
its own parameters to all the lower insert directives in the file. The context can
grow by adding more context directives, the parameters of the second context are
added after the ones of the first context. However context parameters are added
in front of the `@insert` parameters 