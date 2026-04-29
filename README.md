# AEGIS: Veil — A cyberpunk-conspiracy game on Roblox

A condensed, playable single-narrative-arc game built for Roblox Studio with [Rojo](https://rojo.space/) for source-controllable Luau development. **All code, fiction, characters, factions, locations, and visual design are original to this project.**

## Premise

Helix appears to be a galactic custodial bureau that has quietly "managed" Earth for centuries. Its primary tool is a global perception filter that shapes what humans see — and what humans *want* to see. AEGIS is Earth's covert defense agency; most of its operatives believe they're fighting an alien threat, not realizing the agency itself has been infiltrated. The Awakened are humans who've pierced the veil and are working to expose Helix.

You play an AEGIS contract operative with reverse-engineered biomod implants. The biomods enhance you, but they also *reveal* — they're the only known human-deployable tech that can punch through the filter. Run Refraction Veil and you become something the filter can't render. Run Smart-Sights and you notice which humans around you aren't quite human anymore.

**Late-game twist (spoilers):** the Awakened cell leader Cael delivers a revelation in Vault-7. Helix isn't from another star — they're older and smaller. They were deformed, exiled by the Creator, and fell to the prison they now run. Earth isn't a planet; it's the floor of the pit. The "perception filter" is the demons' jealousy made into law: if they cannot leave, neither can you. Humans were the only inmates ever offered a way out — ascension. The biomods are demonic tech turned against its makers. Five endings reflect five answers to what to do with that knowledge.

## Pillars

- **1-4 player co-op** — server cap of 4. Shared world, shared objective progress; per-player skills, biomods, inventory, weapon mods, kill counts. Friendly fire off.
- **Vote-majority for narrative beats** — defection (Cael), Helix recruitment (Director Cole), and the four endgame choices all open a team vote.
- **Skills + biomods + inventory** — three orthogonal progression systems.
- **Multiple solutions** — every level has lethal and non-lethal paths, locked doors that open via lockpick OR hack OR key, hostile patrols you can avoid with stealth/cloak.
- **Five maps** — Bayfront District (intro), AEGIS Tower (hub), Hardline District, Pacific Anchor (free-port), Vault-7 (Sierras endgame).
- **Three enemy kinds** — human grunts, Security Bots (wheeled lasers, EMP-vulnerable), Spider Bots (skitter, melee zap).
- **11 weapons + 9 weapon mods** — stealth pistol, marksman rifle, plasma rifle, sticky charges, throwing blades, etc. Mods (accuracy, range, recoil, reload, clip, scope, laser, silencer, damage) attach per-weapon.
- **Five endings** — Lattice Symbiosis (mass ascension), Quorum Restoration (continued captivity), Network Reset (defiant captivity), Helix Ascension (damnation), Ascension by Faith (refuse all four consoles, walk out). Lattice locks at 3+ civilian deaths; Helix Ascension requires accepting Director Cole's offer; Faith is unavailable to those who joined Helix.
- **Faction-specific vendors** — AEGIS Quartermaster, Awakened Armorer, Helix Quartermaster. Each gates on faction/flags.
- **Three save slots per user** — pick on join. Replay routes without erasing prior runs.
- **Lobby gate** — every player joins into a Lobby map first. Info kiosks (Story / Mechanics / Factions), a vendor preview, a Demo Range door, and a Request-Access terminal. The main game door is gated; the owner approves teams from the Owner Console. Pre-approved team names auto-grant.
- **Demo Range** — a self-contained training map (firing range, practice lockpick, practice hack, basic loadout). Open to everyone, no access needed. Run it to learn the verbs before requesting access to the campaign.
- **Tie-breaker duels** — when a co-op vote ends in a tie, the tied voters are teleported to a sealed dueling arena, friendly fire flips on for them only, last side standing wins the vote for the team. Knock-down at 5 HP (clamped at 1 to avoid death + auto-respawn); HP and walk speed restored on duel end; everyone teleported back to where they were.
- **Branching dialog** — `WorldState` tracks faction, reputation, flags ("defected", "killedVega", "joinedHelix"), counters ("kills", "civiliansKilled"). Dialog gates on a small predicate DSL.
- **Aug-reactive NPCs** — Dr. Halberg comments on whatever biomods you're running; Vega and Cael notice high-level Targeting and Cloak.

## Setup

Requires the [Rojo VS Code extension](https://marketplace.visualstudio.com/items?itemName=evaera.vscode-rojo) (or the Rojo CLI) and the Rojo Studio plugin.

```bash
cargo install rojo
rojo serve              # sync into Studio
# or
rojo build -o Game.rbxlx
```

In Roblox Studio: open a new place → connect the Rojo plugin → press play (F5).

**Before publishing**, edit `src/shared/Config/AccessConfig.lua`:

```lua
AccessConfig.AdminUserIds   = { 123456789 }   -- your Roblox userId(s)
AccessConfig.PreApprovedTeams = { "alpha" }   -- (optional) auto-approved team names
```

Players who join without access land in the lobby. They fill in a team name at the Request Access terminal; you (the admin) approve from the Owner Console in the lobby.

## Lobby flow

1. Player joins → drops into the Lobby map with their slot picker on top.
2. They read the kiosks, browse the vendor preview, run the Demo Range if they want.
3. They walk up to the Request Access terminal, press E, type a team name, submit.
4. The owner (anyone whose UserId is in `AccessConfig.AdminUserIds`) sees the request in the Owner Console and clicks GRANT.
5. The player gets a notification; they walk through the "Enter Game" pad and the whole session loads AEGIS Tower.
6. Once granted, access is persisted per-userId in DataStore — they can come and go in subsequent sessions without re-requesting.

## Controls

| Key | Action |
| --- | --- |
| `WASD` / `Space` | Move / jump |
| `LMB` | Fire equipped weapon |
| `RMB` | Aim down sights |
| `R` | Reload |
| `E` | Interact (NPC, pickup, door, terminal, vendor, transition) |
| `F` | Toggle first-person camera |
| `Tab` | Inventory |
| `K` | Skills |
| `U` | Biomods |
| `1`-`5` | Quick-equip Pistol / Rifle / Heavy / Melee / Demolition |
| `SPACE` | Confirm pick during lockpick minigame |
| `0-9 A-F` | Type displayed code during hack minigame |

## Co-op model

| Aspect | Behavior |
| --- | --- |
| Server cap | 4 (`Players.MaxPlayers = 4` in `default.project.json`) |
| Map state | One shared world; map reload on transition affects everyone |
| Objective progress | Shared — any player advancing the counter advances it for the team |
| Skills, biomods, inventory, mods, ammo, credits | Per-player |
| Defection at Cael | Team vote — majority decides for everyone |
| Helix recruitment at Director Cole | Team vote |
| Endings at Vault-7 | Team vote per terminal |
| Friendly fire | Off (except inside a tie-breaker duel) |
| Tie-breaker | Tied voters duel in a sealed arena; last side standing wins |
| Lobby gate | Owner approves teams; pre-approved team names auto-grant |

## Branching reference

Predicate DSL (used in `Dialog.lua`'s `requires` and per-tree `selectStart`):

| Form | Meaning |
| --- | --- |
| `flag:foo` / `!flag:foo` | `WorldState.flags.foo` is/isn't truthy |
| `faction:AEGIS` / `!faction:Helix` | current faction |
| `counter:kills>=10` (`>`, `<`, `<=`, `==`) | counter comparison |
| `rep:AEGIS<0` | reputation comparison |
| `aug:Cloak` / `!aug:Cloak` | biomod installed (any level) |
| `aug:Cloak>=3` | biomod installed at level 3+ |
| `;` | AND clauses inside one predicate |
| `\|` | OR clauses across whole predicate |

Effects (used in `DialogOption.effect` — semicolon-chained):

| Form | Meaning |
| --- | --- |
| `flag:foo` / `!flag:foo` | set/clear a named flag |
| `faction:Helix` | switch faction |
| `rep:AEGIS+10` / `rep:Helix-25` | adjust reputation |
| `vote:defect` | open a team vote (see `Votes.lua`) |
| `hostile:Vega` | call a registered code handler |

## Voice lines

`src/shared/Config/VoiceLines.lua` is the single registry — string keys mapped to `{ assetId, subtitle, duration, prefix?, pitch?, volume? }`. Default `assetId = ""` plays nothing; subtitles still display. **Add your own audio:**

1. Upload your own `.ogg`/`.mp3` to Roblox Studio (Toolbox → Inventory → My Audio).
2. Copy the resulting `rbxassetid://NUMBER`.
3. Paste into the matching key.

All audio you upload must be your own work or properly licensed. The repo ships with no audio assets.

## Repository layout

```
src/
├── shared/                       # ReplicatedStorage.Shared
│   ├── Remotes.lua
│   └── Config/
│       ├── Weapons.lua
│       ├── WeaponMods.lua
│       ├── Skills.lua
│       ├── Augmentations.lua    # biomods
│       ├── Items.lua
│       ├── Dialog.lua
│       ├── Objectives.lua
│       ├── Votes.lua
│       ├── Vendors.lua
│       ├── VoiceLines.lua
│       └── AccessConfig.lua     # set AdminUserIds + PreApprovedTeams here
├── server/                       # ServerScriptService.Server
│   ├── init.server.lua
│   ├── PlayerData.lua
│   ├── WorldState.lua            # narrative state
│   ├── EnemyAI.lua               # human / SecurityBot / SpiderBot
│   ├── LevelManager.lua
│   ├── Services/
│   │   ├── SaveSlotService.lua
│   │   ├── InventoryService.lua
│   │   ├── SkillService.lua
│   │   ├── AugService.lua
│   │   ├── CombatService.lua
│   │   ├── DialogService.lua
│   │   ├── InteractionService.lua
│   │   ├── MissionService.lua
│   │   ├── VoteService.lua
│   │   ├── VendorService.lua
│   │   ├── EndingService.lua
│   │   ├── VoiceService.lua
│   │   ├── DuelService.lua       # tie-breaker arena
│   │   └── AccessService.lua     # lobby gate
│   └── Maps/
│       ├── init.lua
│       ├── MapUtil.lua
│       ├── Lobby.lua
│       ├── Demo.lua
│       ├── Bayfront.lua
│       ├── AegisTower.lua
│       ├── HardlineDistrict.lua
│       ├── PacificAnchor.lua
│       └── Vault7.lua
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
        ├── EndingScreen.lua
        ├── VoteUI.lua
        ├── VendorUI.lua
        ├── SlotSelectUI.lua
        ├── RequestAccessUI.lua
        ├── AdminConsoleUI.lua
        └── Minigames/
            ├── Lockpick.lua
            └── Hack.lua
```

## Extending

- **Add a weapon:** entry in `Weapons.lua` + `MapUtil.pickup(folder, "MyGun", 1, pos, color)` somewhere.
- **Add a biomod:** entry in `Augmentations.lua`. If active, set `energyPerSec` and `magnitudes`; the drain loop in `AugService` handles it.
- **Add a weapon mod:** entry in `WeaponMods.lua` (compatible slots, `{field, op, amount}` effects). Add the matching `WeaponModXxx` item in `Items.lua`.
- **Add a map:** copy a map module, change `id`/`displayName`/`spawnPoint`/`build`, register in `Maps/init.lua`, add a `MapUtil.transition` from another map.
- **Add a dialog tree:** entry in `Dialog.lua`. Tag an NPC with `model:SetAttribute("DialogTree", "MyTree")`.
- **Add a vote:** entry in `Votes.lua` (prompt, options, timeout). Trigger via `effect = "vote:myVote"` from any dialog option.
- **Add an ending:** entry in `EndingService.Endings` (color, eligibility predicate, paragraphs). Add a corresponding vote in `Votes.lua` and a Vault-7 console with `EndingId = "..."`.
- **Add a vendor:** entry in `Vendors.lua`. Spawn the NPC with `MapUtil.vendor(folder, "Name", pos, "VendorId")`.
- **React to biomods in dialog:** add a `selectStart` variant `{ when = "aug:Cloak>=3", node = "intro_cloak" }` to any dialog tree.

## Originality

All code, fiction, character names, faction names, location names, biomod names, weapon names, and visual designs in this repository are original to this project. No code, audio, art, or text was copied or adapted from any commercial game. The genre conventions used (cybernetic enhancement, multiple endings, branching dialog, faction reputation, hub-and-spoke mission structure) are common-pattern game systems, not protected expression.
