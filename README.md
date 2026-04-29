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

## Voice lines

The game has a full voice pipeline wired up: dialog lines, enemy combat barks ("Hostile! Take him down!"), JC's hurt grunts, and mission cues all fire `PlayVoice` events from the server. Until you upload audio, **the system gracefully no-ops** — barks still display as subtitles and dialog UI still shows the line. Adding audio is a one-file change.

### Adding your own audio

1. Open `src/shared/Config/VoiceLines.lua`. Each entry is a string key mapped to `{ assetId = "", duration = N, ... }`.
2. Upload your audio in Roblox Studio (`View → Toolbox → Inventory → My Audio`) and copy the resulting `rbxassetid://<NUMBER>` URL.
3. Paste it into the `assetId` field for the matching key. Reload the place; that line is now voiced.

### Voice key naming

| Key pattern                       | When it plays                                                          |
| --------------------------------- | ---------------------------------------------------------------------- |
| `Dialog:<tree>:<node>`            | Each time `DialogService` shows that node. Subtitle is the dialog text |
| `NSF:spotted` / `lostTarget` etc. | Enemy AI bark (positional, 3D audio)                                   |
| `JC:hurt` / `JC:lowHealth`        | Player took damage / dropped below 25 HP                               |
| `Mission:objectiveAdded` / etc.   | Global mission cue (no positional audio)                               |

### How the pipeline works

- `VoiceService.playFor(player, key)` — server fires a cue to one player.
- `VoiceService.playFromInstance(npc, key, range?)` — positional, 3D-audible within range.
- `VoiceService.bark(npc, key)` — same as above but throttled to once per 4 s per source so AI loops can call it freely.
- Server only sends the **key + source position** — never the asset URL — keeping the wire small. The client looks up the asset locally from `VoiceLines.lua`.
- Bark-type subtitles appear in a bottom-center caption GUI; dialog-type voice lines reuse the existing `DialogUI` text (no double display).

### Generating voice lines (suggestion)

If you want to populate dozens of lines fast, you can:
- Record yourself / a friend in any DAW, export to `.ogg` or `.mp3`, upload to Roblox.
- Use a TTS tool (ElevenLabs, Coqui, etc.) per node, then upload. Keep one voice per character (Paul Denton, Anna Navarre, etc.) for consistency.
- Roblox enforces a moderation pass on uploaded audio and a 7-second-or-30-second tier — make sure each clip fits within your `duration` budget.

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
│       ├── Objectives.lua
│       └── VoiceLines.lua       # paste in audio asset IDs here
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
│   │   ├── MissionService.lua
│   │   └── VoiceService.lua
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
    │   ├── InteractionController.lua
    │   └── VoiceController.lua
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
