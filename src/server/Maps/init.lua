--!strict
-- Registry of all map modules.

local Maps = {
    Lobby         = require(script.Lobby),
    Demo          = require(script.Demo),
    Bayfront      = require(script.Bayfront),
    AegisTower    = require(script.AegisTower),
    Hardline      = require(script.HardlineDistrict),
    PacificAnchor = require(script.PacificAnchor),
    Vault7        = require(script.Vault7),
}

return Maps
