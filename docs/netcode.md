# Netcode

## Client -> Server
```
<request id> used to throw away already processed requests
<highest consecutive response id> used to stop peer broadcasting messages already seen. 
<action id> what action to perform
<arguments...> arguments for action
<signature> message signature to prevent spoofing (probably don't need the entire hash just first x bits to prevent real-time attacks?)
```

## Server -> Client
```
<request id> used to throw away already processed requests
<highest consecutive response id> used to stop peer broadcasting messages already seen. 
<response id> the id of the request its responding to
<return values...> return values from the action
<signature> message signature to prevent spoofing (probably don't need the entire hash just first x bits to prevent real-time attacks?)
```

## Error responses
...


## Schema File
User defined. Read by the client and server, validated handlers are given.

```lua
netcode = require("rune.netcode")
connection = netcode.Client("/path/to/schema.yaml")
```

```yaml
insert_tick:
    description: Client submission for their inputs for simulation tick.
    implemented_by: server
    arguments:
        -  # needs to allow *variadic arguments for simultaneous key presses in single tick
    returns:
        -
```
