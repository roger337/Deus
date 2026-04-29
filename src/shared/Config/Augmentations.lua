--!strict
-- Biomods (formerly "augmentations"). Each occupies one slot, has 4 levels,
-- and may be active or passive. Activating a biomod drains bio-energy per
-- second; level 1 is cheap, level 4 is expensive.
--
-- LORE: Biomods are reverse-engineered Helix tech. Their "side effect" is
-- the ability to pierce the global perception filter Helix maintains over
-- Earth — Cloak hides you from the filter, Targeting / "True Sight" tags
-- humans whose sensorium has been adjusted, Cellular Reweave repairs the
-- nervous-tissue damage caused by overriding the filter under stress.

export type AugDef = {
    id: string,
    name: string,
    slot: string,
    active: boolean,
    energyPerSec: number,
    description: string,
    levels: { string },
    magnitudes: { number },
}

local Augs: { [string]: AugDef } = {
    CombatStrength = {
        id = "CombatStrength",
        name = "Myomer Boost",
        slot = "Arms",
        active = true,
        energyPerSec = 60,
        description = "Synthetic muscle weave. Increases melee damage.",
        levels = {
            "Melee damage +50%",
            "Melee damage +100%",
            "Melee damage +200%",
            "Melee damage +400%",
        },
        magnitudes = { 1.5, 2.0, 3.0, 5.0 },
    },
    MicrofibralMuscle = {
        id = "MicrofibralMuscle",
        name = "Lift Frame",
        slot = "Arms",
        active = false,
        energyPerSec = 0,
        description = "Allows lifting and throwing of heavy objects.",
        levels = {
            "Lift up to 100 kg",
            "Lift up to 200 kg",
            "Lift up to 400 kg",
            "Lift up to 800 kg",
        },
        magnitudes = { 100, 200, 400, 800 },
    },
    SpeedEnhancement = {
        id = "SpeedEnhancement",
        name = "Reflex Tuner",
        slot = "Legs",
        active = true,
        energyPerSec = 80,
        description = "Faster running and higher jumps.",
        levels = {
            "+25% speed, +25% jump",
            "+50% speed, +50% jump",
            "+100% speed, +100% jump",
            "+150% speed, +150% jump",
        },
        magnitudes = { 1.25, 1.5, 2.0, 2.5 },
    },
    SilentRun = {
        id = "SilentRun",
        name = "Acoustic Damping",
        slot = "Legs",
        active = true,
        energyPerSec = 40,
        description = "Reduces noise made by your movement.",
        levels = { "Quieter", "Quieter still", "Near-silent", "Silent" },
        magnitudes = { 0.6, 0.4, 0.2, 0.0 },
    },
    Cloak = {
        id = "Cloak",
        name = "Refraction Veil",
        slot = "Subdermal",
        active = true,
        energyPerSec = 200,
        description = "Bends the perception filter; humans (including Helix-conditioned humans) cannot register your presence.",
        levels = {
            "Veil quality: low",
            "Veil quality: medium",
            "Veil quality: high",
            "Veil quality: perfect",
        },
        magnitudes = { 0.5, 0.3, 0.15, 0.0 },
    },
    Regeneration = {
        id = "Regeneration",
        name = "Cellular Reweave",
        slot = "Torso",
        active = true,
        energyPerSec = 120,
        description = "Repairs nervous-tissue damage caused by perception override; restores health over time.",
        levels = {
            "+1 HP/s",
            "+2 HP/s",
            "+4 HP/s",
            "+8 HP/s",
        },
        magnitudes = { 1, 2, 4, 8 },
    },
    BallisticProtection = {
        id = "BallisticProtection",
        name = "Kevlar Weave",
        slot = "Subdermal",
        active = false,
        energyPerSec = 0,
        description = "Subdermal mesh. Reduces incoming bullet damage.",
        levels = { "-15% bullet dmg", "-30%", "-45%", "-60%" },
        magnitudes = { 0.85, 0.70, 0.55, 0.40 },
    },
    Targeting = {
        id = "Targeting",
        name = "Smart-Sights / True Sight",
        slot = "Eye",
        active = true,
        energyPerSec = 30,
        description = "Tags humans whose sensorium has been Helix-adjusted; tightens weapon spread on tagged targets.",
        levels = {
            "Tag conditioned humans",
            "+ damage telemetry",
            "+ structural weak points",
            "+ predictive aim",
        },
        magnitudes = { 0.9, 0.75, 0.6, 0.4 },
    },
    AggressiveDefense = {
        id = "AggressiveDefense",
        name = "ICE Shield",
        slot = "Cranial",
        active = true,
        energyPerSec = 100,
        description = "Detonates incoming explosives in mid-air.",
        levels = { "30% chance", "50%", "75%", "100%" },
        magnitudes = { 0.3, 0.5, 0.75, 1.0 },
    },
    EMPShield = {
        id = "EMPShield",
        name = "Faraday Mesh",
        slot = "Subdermal",
        active = false,
        energyPerSec = 0,
        description = "Reduces damage from electrical and EMP sources.",
        levels = { "-25%", "-50%", "-75%", "-100%" },
        magnitudes = { 0.75, 0.5, 0.25, 0.0 },
    },
    VeilBreaker = {
        id = "VeilBreaker",
        name = "Veil Breaker",
        slot = "Cranial",
        active = true,
        energyPerSec = 160,
        description = "Burns off the perception filter in a radius around you. Reveals which humans are Helix-conditioned and which are genuine. High energy cost.",
        levels = {
            "Reveal radius 12 studs",
            "Reveal radius 24 studs",
            "Reveal radius 48 studs",
            "Reveal entire current map",
        },
        magnitudes = { 12, 24, 48, 9999 },
    },
}

local Slots = { "Cranial", "Eye", "Arms", "Legs", "Torso", "Subdermal" }

local module = {}
module.Augs = Augs
module.Slots = Slots

function module.augsForSlot(slot: string): { string }
    local out = {}
    for id, def in pairs(Augs) do
        if def.slot == slot then
            table.insert(out, id)
        end
    end
    table.sort(out)
    return out
end

return module
