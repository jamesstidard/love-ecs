local netcode = require("rune.netcode")

local UINT8_MIN = 0
local UINT8_MAX = 2^8 - 1
local UINT32_MIN = 0
local UNIT32_MAX = 2^32 - 1
local KEYS = {"W_DOWN", "W_UP", "A_DOWN", "A_UP", "S_DOWN", "S_UP", "D_DOWN", "D_UP"}
local PLAYERS = {1, 2, 3, 4, 5, 6, 7, 8}


local ROOM_ID = {
    name="room_id",
    type="number",
    min=UINT8_MIN,
    max=UINT8_MAX,
}
local SEED = {
    name="seed",
    type="number",
    min=UINT8_MIN,
    max=UINT8_MAX,
}
local TIME = {
    name="time",
    type="number",
    min=UINT32_MIN,
    max=UNIT32_MAX,
}
local PLAYER = {
    name="player",
    type="enum",
    options=PLAYERS,
}
local MOVES = {
    name="moves",
    type="enum",
    options=KEYS,
    variadic=true,
}


local API = {
    {
        -- Client submission to create game.
        name="create",
        implemented_by="server",
        arguments={},
        returns={ROOM_ID, SEED, TIME, PLAYER},
    },
    {
        -- Client submission to join game.
        name="join",
        implemented_by="server",
        arguments={ROOM_ID},
        returns={SEED, TIME, PLAYER},
    },
    {
        -- Client/Server submission/assertions for inputs for simulation tick.
        name="tick",
        implemented_by={"server", "client"},
        arguments={TIME, PLAYER, MOVES},
        returns={},
    },
}

local server = netcode.Server("*", 53474, API)
local client = netcode.Client("127.0.0.1", 53474, API)


print(client)
