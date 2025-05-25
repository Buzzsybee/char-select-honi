if not _G.charSelectExists then return end

gExtrasStates = {}
function reset_honi_states(index)
    if index == nil then index = 0 end
    gExtrasStates[index] = {
        index = network_global_index_from_local(0),
        drillVel = 0,
        chargedVelFlick = 0,
        canTwirlAct = true,
        twirlFromDive = true,
        airDash = true
    }
end

for i = 0x (MAX_PLAYERS - 1) do
    reset_honi_states(i)
end

local twirlActs = {
    [ACT_JUMPING] = true,
    [ACT_DOUBLE_JUMP] = true,
    [ACT_TRIPLE_JUMP] = true,
    [ACT_HOLD_JUMP] = true,
    [ACT_GROUND_POUND] = true,
}

local function honi_on_set_action(m)
    --i also dont know how this works, placeholder fot the moment
    local e = gExtrasStates[m.playerIndex]
    if m.action == ACT_TWIRLING then
        set_mario_action(m, ACT_HONI_TWIRL, 0)
    end
end

local function update_honi(m)
    --idunno what update functions do yett... placeholder for when i do tho
    local e = gExtrasStates[m.playerIndex]
    if m.action == ACT_HONI_TWIRL then
        e.canTwirlAct = false
    end
    if m.pos.y == m.floorHeight then
        e.canTwirlAct = true
    end

    if m.input & INPUT_A_PRESSED ~= 0 and m.pos.y > m.floorHeight and e.canTwirlAct then
        set_mario_action(m, ACT_HONI_TWIRL, 0)
    end
end

ACT_HONI_TWIRL     = allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR|ACT_FLAG_ATTACKING)
ACT_HONI_DRILL     = allocate_mario_action(ACT_GROUP_MOVING|ACT_FLAG_ATTACKING)
ACT_HONI_DIVE      = allocate_mario_action(ACT_GROUP_MOVING|ACT_FLAG_ATTACKING|ACT_FLAG_DIVING)
ACT_HONI_AIR_DASH  = allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR|ACT_FLAG_ATTACKING)
ACT_HONI_SKATE     = allocate_mario_action(ACT_GROUP_MOVING|ACT_FLAG_ATTACKING)
ACT_HONI_FLICK     = allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_GROUP_STATIONARY)

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

    m.actionTimer = m.actionTimer + 1
end

hook_mario_action(ACT_HONI_TWIRL,{every_frame = honi_twirl})

_G.charSelect.character_hook_moveset(CHAR_HONI, HOOK_MARIO_UPDATE, update_honi)
_G.charSelect.character_hook_moveset(CHAR_HONI, HOOK_ON_LEVEL_INIT, reset_honi_states)
_G.charSelect.character_hook_moveset(CHAR_HONI, HOOK_ON_SET_MARIO_ACTION, honi_on_set_action)

