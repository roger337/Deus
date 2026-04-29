--!strict
-- Weapon mods. Each mod is one-shot consumable; install consumes it from
-- inventory and attaches it to a specific weapon stack. A given mod can only
-- be installed once per weapon (DX canon).
--
-- Effects are applied as a list of field operations. Order is irrelevant for
-- "set" ops; for "mul" ops the order doesn't matter either since multiplication
-- commutes. The applyMods helper at the bottom of this module merges them.

export type ModEffect = {
    field: string,                -- e.g. "spread", "range", "magazine", "silenced"
    op: "mul" | "add" | "set",
    amount: any,
}

export type WeaponMod = {
    id: string,
    name: string,
    description: string,
    color: Color3,                -- pickup tint
    compatibleSlots: { string },  -- weapon slots this fits ("Pistol", "Rifle", ...)
    effects: { ModEffect },
}

local Mods: { [string]: WeaponMod } = {
    Accuracy = {
        id = "Accuracy",
        name = "Accuracy Mod",
        description = "Reduces base spread by 40%.",
        color = Color3.fromRGB(80, 200, 80),
        compatibleSlots = { "Pistol", "Rifle", "Heavy" },
        effects = { { field = "spread", op = "mul", amount = 0.6 } },
    },
    Range = {
        id = "Range",
        name = "Range Mod",
        description = "Extends maximum effective range by 50%.",
        color = Color3.fromRGB(80, 160, 220),
        compatibleSlots = { "Pistol", "Rifle", "Heavy" },
        effects = { { field = "range", op = "mul", amount = 1.5 } },
    },
    Recoil = {
        id = "Recoil",
        name = "Recoil Mod",
        description = "Reduces spread on automatic fire by 30%.",
        color = Color3.fromRGB(140, 100, 80),
        compatibleSlots = { "Rifle", "Heavy" },
        effects = { { field = "spread", op = "mul", amount = 0.7 } },
    },
    Reload = {
        id = "Reload",
        name = "Reload Mod",
        description = "Cuts reload time by 40%.",
        color = Color3.fromRGB(220, 180, 60),
        compatibleSlots = { "Pistol", "Rifle", "Heavy" },
        effects = { { field = "reloadTime", op = "mul", amount = 0.6 } },
    },
    Clip = {
        id = "Clip",
        name = "Clip Mod",
        description = "Doubles magazine capacity.",
        color = Color3.fromRGB(160, 160, 160),
        compatibleSlots = { "Pistol", "Rifle" },
        effects = { { field = "magazine", op = "mul", amount = 2.0 } },
    },
    Scope = {
        id = "Scope",
        name = "Scope Mod",
        description = "Adds 2x ADS zoom and reduces spread when aiming.",
        color = Color3.fromRGB(50, 50, 60),
        compatibleSlots = { "Rifle" },
        effects = {
            { field = "adsZoom", op = "set", amount = 2.0 },
            { field = "spread", op = "mul", amount = 0.85 },
        },
    },
    Laser = {
        id = "Laser",
        name = "Laser Sight",
        description = "Visible laser; reduces spread by 20%.",
        color = Color3.fromRGB(255, 50, 50),
        compatibleSlots = { "Pistol", "Rifle" },
        effects = {
            { field = "spread", op = "mul", amount = 0.8 },
            { field = "laser", op = "set", amount = true },
        },
    },
    Silencer = {
        id = "Silencer",
        name = "Silencer",
        description = "Suppresses muzzle report; halves enemy hearing range.",
        color = Color3.fromRGB(40, 40, 50),
        compatibleSlots = { "Pistol", "Rifle" },
        effects = { { field = "silenced", op = "set", amount = true } },
    },
    Damage = {
        id = "Damage",
        name = "Damage Mod",
        description = "Increases base damage by 25%.",
        color = Color3.fromRGB(220, 60, 60),
        compatibleSlots = { "Pistol", "Rifle", "Heavy", "Demolition" },
        effects = { { field = "damage", op = "mul", amount = 1.25 } },
    },
}

local module = {}
module.Mods = Mods

-- Apply a list of mod IDs onto a weapon definition. Returns a NEW table
-- (does not mutate the original). Unknown field ops are ignored.
function module.applyMods(weaponDef: { [string]: any }, modIds: { string }?): { [string]: any }
    local effective: { [string]: any } = {}
    for k, v in pairs(weaponDef) do
        effective[k] = v
    end
    if not modIds then return effective end
    for _, modId in ipairs(modIds) do
        local mod = Mods[modId]
        if not mod then continue end
        for _, eff in ipairs(mod.effects) do
            if eff.op == "mul" then
                local cur = effective[eff.field]
                if typeof(cur) == "number" then
                    effective[eff.field] = cur * eff.amount
                end
            elseif eff.op == "add" then
                local cur = effective[eff.field]
                if typeof(cur) == "number" then
                    effective[eff.field] = cur + eff.amount
                end
            elseif eff.op == "set" then
                effective[eff.field] = eff.amount
            end
        end
    end
    return effective
end

-- Returns true if `mod` can be installed onto a weapon of `slot`.
function module.compatible(modId: string, slot: string): boolean
    local mod = Mods[modId]
    if not mod then return false end
    for _, s in ipairs(mod.compatibleSlots) do
        if s == slot then return true end
    end
    return false
end

return module
