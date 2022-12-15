local netcode = require("rune.netcode")

local KEYS = {"W_DOWN", "W_UP", "A_DOWN", "A_UP", "S_DOWN", "S_UP", "D_DOWN", "D_UP"}
local PLAYERS = {1, 2, 3, 4, 5, 6, 7, 8}


local ROOM_ID = {
    name="room_id",
    type="uint8",
}
local SEED = {
    name="seed",
    type="uint8",
}
local TIME = {
    name="time",
    type="uint32",
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
