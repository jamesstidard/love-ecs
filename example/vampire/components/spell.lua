--- Spell
-- @param cooldown between when the spell can be used and reused
function Spell(cooldown)
    return {
        name="spell",
        cooldown=cooldown,
        dt=0,  -- tracks time since last usage
    }
end
