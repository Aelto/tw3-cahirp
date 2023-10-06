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

## After shipping, by the end user (mod user)
see:
- [Conflict free](#conflict-free)
- [Version agnostic](#version-agnostic)
- [Compile time code generation](#compile-time-code-generation)

It is possible to share mods with the merge recipes in them so the end-user runs
the pre-processor after merging the other mods in order to safely and easily emit
code.

