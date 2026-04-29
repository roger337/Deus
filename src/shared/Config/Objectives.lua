--!strict
-- Mission objective definitions.

export type ObjectiveDef = {
    id: string,
    title: string,
    description: string,
    primary: boolean,
    target: number,
    rewardSkillPoints: number,
}

local Objectives: { [string]: ObjectiveDef } = {
    RecoverHelixVials = {
        id = "RecoverHelixVials",
        title = "Recover Helix Vials",
        description = "The Awakened took five sealed Helix sample cases. Recover them before either side weaponizes the contents.",
        primary = true,
        target = 5,
        rewardSkillPoints = 1500,
    },
    NeutralizeOrganizer = {
        id = "NeutralizeOrganizer",
        title = "Neutralize the Awakened Organizer",
        description = "The cell leader is dug in on the upper deck of the pier. Neutralize them — lethal or non-lethal.",
        primary = true,
        target = 1,
        rewardSkillPoints = 1000,
    },
    HackTerminal = {
        id = "HackTerminal",
        title = "Pull the Comms Cache",
        description = "Hack the comms terminal in the operations bunker to download intercepted Helix traffic.",
        primary = false,
        target = 1,
        rewardSkillPoints = 500,
    },
    NoCasualties = {
        id = "NoCasualties",
        title = "Pacifist Run",
        description = "Complete the contract without killing anyone — Awakened, AEGIS, or civilian.",
        primary = false,
        target = 1,
        rewardSkillPoints = 750,
    },
    HardlineStealth = {
        id = "HardlineStealth",
        title = "Hardline District: Quiet Infiltration",
        description = "Cael's intel must stay clean. Reach the warehouse without raising an alarm.",
        primary = true,
        target = 1,
        rewardSkillPoints = 1500,
    },
    HardlineAssault = {
        id = "HardlineAssault",
        title = "Hardline District: Hard Entry",
        description = "Subtlety is no longer an option. Force entry into the warehouse and pull the data chip.",
        primary = true,
        target = 1,
        rewardSkillPoints = 1000,
    },
    AnchorStealth = {
        id = "AnchorStealth",
        title = "Pacific Anchor: Quiet Infiltration",
        description = "Reach Helix Tower without raising an alarm.",
        primary = true,
        target = 1,
        rewardSkillPoints = 1500,
    },
    AnchorAssault = {
        id = "AnchorAssault",
        title = "Pacific Anchor: Hard Entry",
        description = "Force entry into Helix Tower and recover the data chip.",
        primary = true,
        target = 1,
        rewardSkillPoints = 1000,
    },
}

return Objectives
