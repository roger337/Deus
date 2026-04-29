--!strict
-- Faction-specific weapon vendors. Each vendor has a stock list (item +
-- price) and a `gate` predicate that must pass for the player to even open
-- the shop. Different factions sell different things — the Awakened won't
-- sell to an AEGIS loyalist; Helix won't sell to anyone but their own.

export type StockEntry = {
    id: string,
    price: number,
    quantity: number?,
}

export type VendorDef = {
    id: string,
    name: string,
    faction: string,
    gate: string?,
    rejectMessage: string?,
    greeting: string,
    stock: { StockEntry },
}

local Vendors: { [string]: VendorDef } = {

    -- =====================================================================
    -- AEGIS Quartermaster: standard issue. Refuses defectors.
    -- =====================================================================
    AEGIS_QM = {
        id = "AEGIS_QM",
        name = "AEGIS Quartermaster",
        faction = "AEGIS",
        gate = "!flag:defected|faction:AEGIS",
        rejectMessage = "You're flagged as a defector. We don't sell to traitors.",
        greeting = "Standard issue, operative. Credit chits accepted.",
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
    -- Awakened Armorer (Cael's clinic). Stealth and unconventional gear.
    -- Refuses AEGIS loyalists.
    -- =====================================================================
    Awakened_QM = {
        id = "Awakened_QM",
        name = "Awakened Armorer",
        faction = "IronPromise",
        gate = "faction:IronPromise|flag:defected",
        rejectMessage = "You're an AEGIS badge. Get out of my shop.",
        greeting = "Whatever Cael sent you for, I've probably got it. Cash on the table.",
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
    -- Helix Quartermaster (Vault-7). Custodial-grade gear; only Helix.
    -- =====================================================================
    Helix_QM = {
        id = "Helix_QM",
        name = "Helix Quartermaster",
        faction = "Helix",
        gate = "faction:Helix|flag:joinedHelix",
        rejectMessage = "Restricted access. Authorization not on file.",
        greeting = "Director Cole authorized full inventory access. Choose carefully, Custodian.",
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
