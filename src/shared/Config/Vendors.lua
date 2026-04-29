--!strict
-- Faction-specific weapon vendors. Each vendor has a stock list (weapon/item +
-- price), and a `gate` predicate that must pass for the player to even open
-- the shop. Different factions sell different things — the NSF won't sell to
-- a UNATCO loyalist; MJ12 won't sell to anyone but their own.

export type StockEntry = {
    id: string,         -- weapon or item id
    price: number,      -- credits
    quantity: number?,  -- given per purchase (default 1; ammo bundles 30)
}

export type VendorDef = {
    id: string,
    name: string,
    faction: string,
    gate: string?,                  -- predicate; see WorldState.evaluate
    rejectMessage: string?,
    greeting: string,
    stock: { StockEntry },
}

local Vendors: { [string]: VendorDef } = {

    -- =====================================================================
    -- UNATCO Quartermaster: standard issue. Available to UNATCO faction or
    -- before the player has defected.
    -- =====================================================================
    UNATCO_QM = {
        id = "UNATCO_QM",
        name = "UNATCO Quartermaster",
        faction = "UNATCO",
        gate = "!flag:defected|faction:UNATCO",
        rejectMessage = "You're flagged as a defector. We don't sell to traitors.",
        greeting = "Standard issue, Agent. Credit chits accepted.",
        stock = {
            { id = "Pistol10mm", price = 200 },
            { id = "AssaultRifle", price = 600 },
            { id = "SniperRifle", price = 900 },
            { id = "Combat10mm", price = 100 },
            { id = "Ammo10mm", price = 30, quantity = 30 },
            { id = "Ammo762", price = 50, quantity = 30 },
            { id = "Medkit", price = 80 },
            { id = "Lockpick", price = 60 },
            { id = "Multitool", price = 60 },
            { id = "WeaponModAccuracy", price = 350 },
            { id = "WeaponModRange", price = 350 },
            { id = "WeaponModReload", price = 250 },
        },
    },

    -- =====================================================================
    -- NSF Quartermaster (Tracer Tong's clinic). Stealth and unconventional
    -- gear. Refuses UNATCO loyalists.
    -- =====================================================================
    NSF_QM = {
        id = "NSF_QM",
        name = "NSF Armorer",
        faction = "NSF",
        gate = "faction:NSF|flag:defected",
        rejectMessage = "You're a UNATCO badge. Get out of my shop.",
        greeting = "Whatever Tong sent you for, I've probably got it. Cash on the table.",
        stock = {
            { id = "StealthPistol", price = 500 },
            { id = "MiniCrossbow", price = 350 },
            { id = "ThrowingKnife", price = 200 },
            { id = "AmmoTranq", price = 60, quantity = 15 },
            { id = "AmmoKnife", price = 40, quantity = 6 },
            { id = "Lockpick", price = 40 },
            { id = "Multitool", price = 40 },
            { id = "Biocell", price = 100 },
            { id = "WeaponModSilencer", price = 600 },
            { id = "WeaponModLaser", price = 400 },
            { id = "WeaponModClip", price = 350 },
        },
    },

    -- =====================================================================
    -- MJ12 Quartermaster (Area 51, Sector 4). High-end / exotic gear.
    -- Only sells if the player has joined MJ12.
    -- =====================================================================
    MJ12_QM = {
        id = "MJ12_QM",
        name = "MJ12 Quartermaster",
        faction = "MJ12",
        gate = "faction:MJ12|flag:joinedMJ12",
        rejectMessage = "Restricted access. Authorization not on file.",
        greeting = "Director Simons authorized full inventory access. Choose carefully, Enforcer.",
        stock = {
            { id = "PlasmaRifle", price = 1500 },
            { id = "GepGun", price = 2200 },
            { id = "AmmoPlasma", price = 80, quantity = 30 },
            { id = "AmmoRocket", price = 200, quantity = 2 },
            { id = "AmmoLAM", price = 250, quantity = 2 },
            { id = "LAM", price = 500 },
            { id = "AugCanister", price = 1200 },
            { id = "AugUpgradeCanister", price = 800 },
            { id = "WeaponModDamage", price = 800 },
            { id = "WeaponModScope", price = 700 },
            { id = "WeaponModRecoil", price = 500 },
        },
    },
}

return Vendors
