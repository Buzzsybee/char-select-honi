if not _G.charSelectExists then return end

gExtrasStates = {}
function reset_honi_states(index)
    if index == nil then index = 0 end
    gExtrasStates[index] = {
        index = network_global_index_from_local(0),
        drillVel = 0,
        chargedVel = 0,
        canTwirlJump = true,
        canGroundDive = true,
        twirlFromDive = true,
        airDash = true
    }
end

for i = 0x (MAX_PLAYERS - 1) do
    reset_honi_states(i)
end

ACT_HONI_TWIRL     = allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR|ACT_FLAG_ATTACKING)
ACT_HONI_DRILL     = allocate_mario_action(ACT_GROUP_MOVING|ACT_FLAG_ATTACKING)
ACT_HONI_DIVE      = allocate_mario_action(ACT_GROUP_MOVING|ACT_FLAG_ATTACKING|ACT_FLAG_DIVING)
ACT_HONI_AIR_JUMP  = allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR)
ACT_HONI_AIR_DASH  = allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR|ACT_FLAG_ATTACKING)

--- @param m MarioState
local function honi_twirl(m)
    local e = gExtrasStates[m.playerIndex]
    if m.actionTimer == 0 then
        set_mario_animation(m, CHAR_ANIM_TWIRLING)
        m.vel.y = 20
        m.faceAngle.y = m.intendedYaw
        m.forwardVel = 10
    end

    m.faceAngle.y = approach_s32(convert_s16(m.faceAngle.y), m.intendedYaw, 0x100)

    m.actionTimer = m.actionTimer + 1
end

hook_mario_action(ACT_HONI_TWIRL,{every_frame = honi_twirl})