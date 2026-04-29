# Deus Ex (Roblox) — A simplified remake

A condensed, playable homage to the 2000 Ion Storm classic, built for Roblox Studio with [Rojo](https://rojo.space/) for source-controllable Luau development.

## Pillars

- **Skills + augmentations + inventory** — three orthogonal progression systems, just like the original.
- **Multiple solutions** — every level has lethal and non-lethal paths, locked doors that open with a lockpick OR a hack OR a key, hostile patrols you can avoid with stealth/cloak.
- **Five iconic maps** — Liberty Island (intro), UNATCO HQ (hub), Hell's Kitchen, Hong Kong, Area 51 (endgame).
- **Branching dialog** — talk to Paul Denton, Anna Navarre, Dr. Reyes, Tracer Tong.
- **Ending choice** — three terminals in Area 51 echo the three classic endings (Helios merge / Illuminati / Dark Age).

## Setup

Requires the [Rojo VS Code extension](https://marketplace.visualstudio.com/items?itemName=evaera.vscode-rojo) (or the Rojo CLI) and the Rojo Studio plugin.

```bash
# install rojo if you haven't
cargo install rojo
# or: foreman install / aftman install per your toolchain

# from the repo root, sync into Studio
rojo serve
```

In Roblox Studio: open a new place → connect the Rojo plugin → press play (F5).

To export a `.rbxlx` directly without syncing live:

```bash
rojo build -o DeusEx.rbxlx
```

## Controls

| Key                | Action                                                  |
| ------------------ | ------------------------------------------------------- |
| `WASD` / `Space`   | Move / jump                                             |
| `LMB`              | Fire equipped weapon                                    |
| `RMB`              | Aim down sights (tighter spread)                        |
| `R`                | Reload                                                  |
| `E`                | Interact (NPC, pickup, door, terminal, transition)      |
| `F`                | Toggle first-person camera                              |
| `Tab`              | Inventory                                               |
| `K`                | Skills                                                  |
| `U`                | Augmentations                                           |
| `1` `2` `3` `4` `5`| Quick-equip Pistol / Rifle / Heavy / Melee / Demolition |
| `SPACE`            | Confirm pick during lockpick minigame                   |
| Type `0-9 A-F`     | Hack minigame: enter the displayed code                 |

## Design notes

- **Server is authoritative.** Every weapon hit is re-cast on the server before damage is applied, and ammo is decremented server-side. Augs and skills mutate state only via `RemoteEvent` calls handled in `src/server/Services/`.
- **Configuration as data.** `src/shared/Config/` modules are pure data tables (`Weapons`, `Skills`, `Augmentations`, `Items`, `Dialog`, `Objectives`). Tuning a weapon, adding an aug, or rewriting an NPC means editing a single table, not changing logic.
- **One file per system.** Services in `src/server/Services/` are self-contained; UI panels in `src/client/UI/` likewise. Adding a new system means adding a sibling file and one line in `init.server.lua` / `init.client.lua`.
- **Maps as build scripts.** Each map module returns a `build(folder)` function and a `spawnPoint`. `LevelManager` clears the world and calls `build()` on transitions, so you can edit a map and reload by re-running.
- **DataStore is best-effort.** Saves succeed in published places; soft-fails in Studio without API services.

## Repository layout

```
src/
├── shared/                       # ReplicatedStorage.Shared
│   ├── Remotes.lua               # central RemoteEvent/Function registry
│   └── Config/
│       ├── Weapons.lua
│       ├── Skills.lua
│       ├── Augmentations.lua
│       ├── Items.lua
│       ├── Dialog.lua
│       └── Objectives.lua
├── server/                       # ServerScriptService.Server
│   ├── init.server.lua           # boot
│   ├── PlayerData.lua
│   ├── EnemyAI.lua
│   ├── LevelManager.lua
│   ├── Services/
│   │   ├── DataStoreService.lua
│   │   ├── InventoryService.lua
│   │   ├── SkillService.lua
│   │   ├── AugService.lua
│   │   ├── CombatService.lua
│   │   ├── DialogService.lua
│   │   ├── InteractionService.lua
│   │   └── MissionService.lua
│   └── Maps/
│       ├── init.lua              # map registry
│       ├── MapUtil.lua
│       ├── LibertyIsland.lua
│       ├── UnatcoHQ.lua
│       ├── HellsKitchen.lua
│       ├── HongKong.lua
│       └── Area51.lua
└── client/                       # StarterPlayer.StarterPlayerScripts.Client
    ├── init.client.lua
    ├── Controllers/
    │   ├── WeaponController.lua
    │   └── InteractionController.lua
    └── UI/
        ├── Theme.lua
        ├── HUD.lua
        ├── InventoryUI.lua
        ├── SkillsUI.lua
        ├── AugUI.lua
        ├── DialogUI.lua
        └── Minigames/
            ├── Lockpick.lua
            └── Hack.lua
```

## Extending

- **Add a weapon:** drop a new entry in `src/shared/Config/Weapons.lua`. Spawn it in a map via `MapUtil.pickup(folder, "MyGun", 1, pos, color)`.
- **Add an aug:** entry in `Augmentations.lua`. If active, set `energyPerSec` and `magnitudes`; the drain loop in `AugService` handles it. For new behaviors (e.g., aim aug), read `AugService.magnitude(player, "MyAug")` from the relevant service.
- **Add a map:** copy `Maps/HellsKitchen.lua`, change `id`/`displayName`/`spawnPoint`/`build`, register in `Maps/init.lua`, and add a `MapUtil.transition` to it from another map.
- **Add a dialog tree:** new entry in `Dialog.lua`. Tag an NPC with `model:SetAttribute("DialogTree", "MyTree")`.
- **Add an objective:** entry in `Objectives.lua`; call `MissionService.start(player, id)` and `MissionService.advance(player, id)` from wherever the trigger lives.
