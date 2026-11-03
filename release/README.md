# Unlimited Universal Boxes

Spawn universal boxes past the normal **150-box limit** using the **Universal Box Dispenser** in *Roadside Research*.

## Features

- Removes the universal-box spawn limit.
- Keeps other object spawn limits, dispenser cooldowns, and occupied-socket checks intact.
- Always active when installed; no hotkeys or configuration required.

## Installation

### Mod manager

Install with Thunderstore Mod Manager or r2modman. The BepInEx IL2CPP dependency is installed automatically. Start Roadside Research using the manager's modded launch button.

### Manual

1. Install **BepInEx 6 IL2CPP x64** for Roadside Research and launch once to generate its interop assemblies.
2. Close the game.
3. Copy this package's `BepInEx` folder into the game folder beside `Roadside Research.exe`.
4. Launch with BepInEx enabled.

The DLL belongs at `BepInEx/plugins/KeyErrorFinn-UnlimitedBoxes/KeyErrorFinn.UnlimitedBoxes.dll`. When updating, replace the existing DLL and keep only one installed copy. BepInEx 5 and Mono builds are incompatible.

## Compatibility and limitations

- Targets Roadside Research **0.2.13, build 12678**.
- Version 1.0.1 targets the dispenser's `GenericBox` spawn limit. Version 1.0.0 incorrectly targeted the separate store-ordering limit.
- In-game spawning beyond 150 and multiplayer have not yet been verified. For co-op testing, install on the host and participating clients.
- Large numbers of physical boxes can reduce performance.
- The mod changes runtime checks and does not directly edit save files. Back up your save before testing. Loading an over-limit save after uninstalling has not been verified.

## Uninstall

Remove `KeyErrorFinn.UnlimitedBoxes.dll` and restart. The normal spawn limit returns.

## Credits

Mod by **KeyErrorFinn**. Package icon created using OpenAI image generation.
