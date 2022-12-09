# Netcode

## Client -> Server
```
<request id> used to throw away already processed requests
<highest consecutive response id> used to stop peer broadcasting messages already seen. 
<action id> what action to perform
<arguments...> arguments for action
<nonce> prevent replay attacks. needed if requests with ids already seen are dropped? request id might wrap though?
<signature> message signature to prevent spoofing (probably don't need the entire hash just first x bits to prevent real-time attacks?)
```

## Server -> Client
```
<request id> used to throw away already processed requests
<highest consecutive response id> used to stop peer broadcasting messages already seen. 
<response id> the id of the request its responding to
<return values...> return values from the action
<nonce> prevent replay attacks. needed if requests with ids already seen are dropped? request id might wrap though?
<signature> message signature to prevent spoofing (probably don't need the entire hash just first x bits to prevent real-time attacks?)
```

## Error responses
...


## Schema File
User defined. Read by the client and server, validated handlers are given.

```lua
netcode = require("rune.netcode")
connection = netcode.Client(schema)
```

```lua
local KEYS = {"W", "A", "S", "D"}
local PLAYERS = {1, 2, 3, 4, 5, 6, 7, 8}

schema = {
    {
        name="join",
        description="Client submission to join game.",
        implemented_by="server",
        authenticated=false,  -- no signature required on this message (default true)
        arguments={
            {
                name="public_key",
                description="Client public key to be used by the server to authenticate subsequent messages.",
                type="bit256",
            },
        },
        returns={
            {
                name="seed",
                description="Game seed to drive clients deterministic simulation.",
                type="uint16",
            },
            {
                name="player",
                description="Assign player number for client.",
                type=PLAYERS,
            },
            {
                name="public_key",
                description="Server public key to be used by the client to authenticate subsequent messages.",
                type="bit256",
            },
        }
    },
    {
        name="insert_tick",
        description="Client submission for their inputs for simulation tick.",
        implemented_by="server",
        arguments={
            {
                name="time",
                type="uint22",  -- (2^22)/60/60/60 == 19.42 hours max  (maybe should wrap a lower bit number instead?)
            },
            {
                name="moves",
                type="enum",
                options=KEYS, 
                variadic=true,
            },
        },
        returns={},
    },
    {
        name="insert_tick",
        description="Server broadcast for their inputs for simulation tick.",
        implemented_by="client",
        arguments={
            {
                name="time",
                type="uint22",  -- (2^22)/60/60/60 == 19.42 hours max  (maybe should wrap a lower bit number instead?)
            },
            {
                name="player",
                type="enum",
                options=PLAYERS,
            },
            {
                name="moves",
                type="enum",
                options=KEYS,
                variadic=true,
            },
        },
        returns={},
    }
}
```
