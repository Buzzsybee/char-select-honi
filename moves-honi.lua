if not _G.charSelectExists then return end

gExtrasStates = {}
function reset_honi_states(index)
    if index == nil then index = 0 end
    gExtrasStates[index] = {
        index = network_global_index_from_local(0),
        chargedFling = 0,
        canTwirlAct = true,
        canTwirl = true,
        twirlFromDive = true,
        airDash = true
    }
end

for i = 0x (MAX_PLAYERS - 1) do
    reset_honi_states(i)
end

local canTwirlFromAct = {
    [ACT_DIVE] = true,
    [ACT_JUMPING] = true,
    [ACT_DOUBLE_JUMP] = true,
    [ACT_TRIPLE_JUMP] = true,
    [ACT_HOLD_JUMP] = true
}

local function honi_on_set_action(m)
    --i also dont know how this works, placeholder fot the moment
    local e = gExtrasStates[m.playerIndex]
end

local function update_honi(m)
    --idunno what update functions do yett... fully
    local e = gExtrasStates[m.playerIndex]
    if m.action == ACT_HONI_TWIRL then
        e.canTwirl = false -- if already twirling, cant twirl again :3
    end
    if m.pos.y == m.floorHeight then
        e.canTwirl = true -- if touching land, u can twirl again midair.
        e.airDash = true -- if touching land, u can air dash again.
    end
    if m.action == ACT_DIVE then 
        e.airDash = false
    end

    if m.input & INPUT_A_PRESSED ~= 0 and m.pos.y > m.floorHeight and e.canTwirl and canTwirlFromAct[m.action] then
        set_mario_action(m, ACT_HONI_TWIRL, 0)
    end
end

ACT_HONI_TWIRL     = allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR|ACT_FLAG_ATTACKING)
ACT_HONI_DRILL     = allocate_mario_action(ACT_GROUP_MOVING|ACT_FLAG_ATTACKING)
ACT_HONI_DIVE      = allocate_mario_action(ACT_GROUP_MOVING|ACT_FLAG_ATTACKING|ACT_FLAG_DIVING)
ACT_HONI_AIR_DASH  = allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR|ACT_FLAG_ATTACKING)
ACT_HONI_SKATE     = allocate_mario_action(ACT_GROUP_MOVING|ACT_FLAG_ATTACKING)
ACT_HONI_FLING     = allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_GROUP_STATIONARY)

--- @param m MarioState
local function honi_twirl(m)
    local e = gExtrasStates[m.playerIndex]
    local mag = (m.controller.stickMag) / 64

    set_mario_animation(m, CHAR_ANIM_TWIRLING)
    if m.actionTimer == 0 then
        m.vel.y = 20
        m.faceAngle.y = m.intendedYaw
        m.forwardVel = 10
    end
    
    m.marioObj.header.gfx.angle.y = m.marioObj.header.gfx.angle.y + 0x9000 -- this is supposed to make u spin, idunno if it workss

    local air = perform_air_step(m)
    if air == AIR_STEP_LANDED then 
        if m.forwardVel > 0 then
            if mag > 0 then
                set_mario_action(m, ACT_WALKING, 0)
            end
        else set_mario_action(m, ACT_IDLE, 0) end
    end

    m.faceAngle.y = approach_s32(convert_s16(m.faceAngle.y), m.intendedYaw, 0x100)
    m.vel.x = m.forwardVel * sins(m.faceAngle.y)
    m.vel.z = m.forwardVel * coss(m.faceAngle.y)

    if m.input & INPUT_A_PRESSED ~= 0 and e.airDash then
        m.vel.y = 10
        m.forwardVel = 30
        set_mario_action(m, ACT_DIVE, 0)
    end

    m.actionTimer = m.actionTimer + 1
end

local function honi_drill(m)
    local e = gExtrasStates[m.playerIndex] 
    local mag = (m.controller.stickMag) / 64

    set_mario_animation(m, CHAR_ANIM_TWIRLING)

    if m.actionTimer == 0 then
        m.faceAngle.y = m.intendedYaw
    end

    if mag > 0 then -- this is supposed to check if ur holding the stick, but i dont knoo
        if m.forwardVel < 30 then m.forwardVel = 30 end
        m.forwardVel = m.forwardVel + (mag * 5)
        if m.forwardVel > 50 the m.forwardVel = 50 end
    elseif mag == 0 then -- and this is if ur not holding stickk
        m.forwardVel = m.forwardVel - 2
    end

    m.marioObj.header.gfx.angle.y = m.marioObj.header.gfx.angle.y + 0x9999

    m.faceAngle.y = approach_s32(convert_s16(m.faceAngle.y), m.intendedYaw, 0x400)
    m.vel.x = m.forwardVel * sins(m.faceAngle.y)
    m.vel.z = m.forwardVel * coss(m.faceAngle.y)

    local ground = perform_ground_step(m)

    if ground == GROUND_STEP_LEFT_GROUND then
        set_mario_action(m, ACT_FREE_FALL, 0)
    end

    m.actionTimer = m.actioTimer + 1
end

hook_mario_action(ACT_HONI_TWIRL,{every_frame = honi_twirl})
hook_mario_action(ACT_HONI_DRILL,{every_frame = honi_drill})


_G.charSelect.character_hook_moveset(CHAR_HONI, HOOK_MARIO_UPDATE, update_honi)
_G.charSelect.character_hook_moveset(CHAR_HONI, HOOK_ON_LEVEL_INIT, reset_honi_states)
_G.charSelect.character_hook_moveset(CHAR_HONI, HOOK_ON_SET_MARIO_ACTION, honi_on_set_action)