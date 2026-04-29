--!strict
-- Inventory items, ammo, consumables, key items.
-- Roughly mirrors the Deus Ex inventory grid; size is in cells (w*h).

export type ItemDef = {
    id: string,
    name: string,
    category: string,           -- "Weapon", "Ammo", "Consumable", "Tool", "Key", "Aug"
    width: number,
    height: number,
    stackable: boolean,
    stackMax: number,
    description: string,
    useEffect: string?,         -- handled by InventoryService
    valueAmount: number?,       -- for consumables (HP, energy, etc.)
}

local Items: { [string]: ItemDef } = {
    Medkit = {
        id = "Medkit",
        name = "Medkit",
        category = "Consumable",
        width = 1, height = 2,
        stackable = true, stackMax = 10,
        description = "Restores health. Amount scales with Medicine skill.",
        useEffect = "Heal", valueAmount = 30,
    },
    Biocell = {
        id = "Biocell",
        name = "Bio-Electric Cell",
        category = "Consumable",
        width = 1, height = 1,
        stackable = true, stackMax = 20,
        description = "Restores 100 bio-energy.",
        useEffect = "RestoreEnergy", valueAmount = 100,
    },
    Lockpick = {
        id = "Lockpick",
        name = "Lockpick",
        category = "Tool",
        width = 1, height = 1,
        stackable = true, stackMax = 30,
        description = "Used to open locked doors and containers.",
    },
    Multitool = {
        id = "Multitool",
        name = "Multitool",
        category = "Tool",
        width = 1, height = 1,
        stackable = true, stackMax = 30,
        description = "Used to disable security systems and hack panels.",
    },
    AugCanister = {
        id = "AugCanister",
        name = "Augmentation Canister",
        category = "Aug",
        width = 1, height = 1,
        stackable = true, stackMax = 10,
        description = "Install one nano-augmentation at a Medical Bot.",
    },
    AugUpgradeCanister = {
        id = "AugUpgradeCanister",
        name = "Augmentation Upgrade",
        category = "Aug",
        width = 1, height = 1,
        stackable = true, stackMax = 10,
        description = "Upgrades an existing nano-augmentation by one level.",
    },
    Ammo10mm = {
        id = "Ammo10mm",
        name = "10mm Rounds",
        category = "Ammo",
        width = 1, height = 1,
        stackable = true, stackMax = 99,
        description = "10mm caliber pistol ammunition.",
    },
    Ammo762 = {
        id = "Ammo762",
        name = "7.62mm Rounds",
        category = "Ammo",
        width = 1, height = 1,
        stackable = true, stackMax = 99,
        description = "Rifle ammunition.",
    },
    AmmoTranq = {
        id = "AmmoTranq",
        name = "Tranquilizer Darts",
        category = "Ammo",
        width = 1, height = 1,
        stackable = true, stackMax = 30,
        description = "Non-lethal sedative crossbow darts.",
    },
    AmmoRocket = {
        id = "AmmoRocket",
        name = "Rocket",
        category = "Ammo",
        width = 1, height = 2,
        stackable = true, stackMax = 4,
        description = "GEP-gun guided rocket.",
    },
    KeyAmbrosia = {
        id = "KeyAmbrosia",
        name = "Ambrosia Vial",
        category = "Key",
        width = 1, height = 1,
        stackable = false, stackMax = 1,
        description = "Vial of Ambrosia stolen by the NSF. Recover all five.",
    },
    DataCube = {
        id = "DataCube",
        name = "Data Cube",
        category = "Key",
        width = 1, height = 1,
        stackable = false, stackMax = 1,
        description = "An infolinked data cube containing intel.",
    },
}

return Items
