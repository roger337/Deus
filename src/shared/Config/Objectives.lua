--!strict
-- Objective definitions for the campaign.

export type ObjectiveDef = {
    id: string,
    title: string,
    description: string,
    primary: boolean,
    target: number,             -- count required (e.g., 5 ambrosia vials)
    rewardSkillPoints: number,
}

local Objectives: { [string]: ObjectiveDef } = {
    RecoverAmbrosia = {
        id = "RecoverAmbrosia",
        title = "Recover Stolen Ambrosia",
        description = "The NSF stole five vials of Ambrosia from the docks. Recover them.",
        primary = true,
        target = 5,
        rewardSkillPoints = 1500,
    },
    EliminateCommander = {
        id = "EliminateCommander",
        title = "Neutralize the NSF Commander",
        description = "The NSF commander is fortified at the top of the statue. Neutralize him — lethal or non-lethal.",
        primary = true,
        target = 1,
        rewardSkillPoints = 1000,
    },
    HackTerminal = {
        id = "HackTerminal",
        title = "Access NSF Comms",
        description = "Hack the comm terminal in the operations room to download enemy plans.",
        primary = false,
        target = 1,
        rewardSkillPoints = 500,
    },
    SpareTheGrunts = {
        id = "SpareTheGrunts",
        title = "Pacifist Run",
        description = "Complete the mission without lethally killing any NSF grunts.",
        primary = false,
        target = 1,
        rewardSkillPoints = 750,
    },
}

return Objectives
