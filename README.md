# godot-addon-cables

A Godot plugin to serve as an alternative to [Autoload Event Buses](https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/)
for a more visual / editor gameplay design approach.

The implementation of this addon is very much inspired by [Ryan Hipple's 2017 Talk](https://www.youtube.com/watch?v=raQ3iHhE_Kk)
on using Unity `ScriptableObject`s as an alternative to singletons.

## Installation

From your Godot project's root (the folder with `project.godot`), on Linux or macOS:

```sh
curl -fsSL https://raw.githubusercontent.com/BartInTheField/godot-addon-cables/main/install.sh | sh
```

This puts the latest release in `addons/cables`, replacing any older version there. Run it again to update.

Or install it by hand (also works on Windows):

1. Download `godot-addon-cables.zip` from the [latest release](https://github.com/BartInTheField/godot-addon-cables/releases/latest)
2. Extract it into your project's root, so you get `res://addons/cables/plugin.cfg`
3. Enable **Cables** in `Project` > `Project Settings` > `Plugins`

The addon targets Godot 4.4+.

### Releases

Every hour, if `main` has new commits, the addon scripts are checked with Godot, the tests are run, and a release is published. Versions are
[CalVer](https://calver.org) `YYYY.MM.DD.N`, where `N` counts the releases of that (UTC) day: `2026.09.26.1`,
`2026.09.26.2`, ... The version is written into the released `plugin.cfg`; a checkout of the repository reports `dev`.

## Usage

The general flow for usage is:

1. Right-click on any folder in the `FileSystem` tab > `Create New` > `Resource...`
2. Search for `Cable` > click `Create`
3. Name your Cable something useful like `player_death_event.tres` or `player_health_value.tres`
4. Produce values on the cable - this can be done by either producing a value on a `Cable` directly via `notify()` (e.g. for primitive values like `float`,`string`,`int`,`bool` etc), or using a `CableValueProducer` node to emit events / data on the cable. (NOTE: the producer should generally be a child of the node that is producing the value)
5. Consume values from the cable - this can be done by adding the `CableValueConsumer` node as a child of the node that wishes to consume value updates

### Typed Cables with an initial value

For values a game designer should be able to tune, create one of the typed Cables instead of a plain `Cable`:
`BoolCable`, `IntCable`, `FloatCable`, `StringCable`, `Vector2Cable`, `Vector3Cable` or `ColorCable`.
They work like a `Cable`, plus an **Initial Value** field in the Inspector (e.g. a `FloatCable` named
`player_health_value.tres` with an initial value of `100`):

- Until something is emitted, `current_value` returns the initial value, and with **Replay on Link** on,
  consumers receive it as soon as they link, so a HUD shows the starting value right away.
- `reset()` emits the initial value again, e.g. when a level restarts.
- Values emitted while the game runs are never saved to the `.tres`; each run starts from the initial value.

Available Producer Types:

1. `CableNodeValueProducer` - sends `Node` references across the `Cable`, and automatically clears the reference when the producer gets destroyed
2. `CableButtonEventProduer` - translates a button click into a `Cable` event; useful for quickly wiring up UI across scenes
3. `CableInputEventProducer` - translates input actions into `Cable` events; this is more niche, but can help cover some edge cases for prototyping

See the `examples` folder for more granular implementation details

## Best Practices

It is best to use `Cable` resources for _global_ state, such has passing data to UI components (e.g. player health ratio to a healthbar widget) or sharing atomic data like enemy count, number of coins, or even a shared node reference to a manager script that holds these.

You should _not_ use `Cable` resources when transferring **local** state, such as watching a single monster's `CollisionShape2D.area_entered` event to apply damage to the monster (e.g., multiple instances of the monster scene will all broadcast on the same assigned `Cable` resource).
