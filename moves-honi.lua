if not _G.charSelectExists then return end

local function convert_s16(num)
    local min = -32768
    local max = 32767
    while (num < min) do
        num = max + (num - min)
    end
    while (num > max) do
        num = min + (num - max)
    end
    return num
end

--Extra player variables, similar to gMarioStates
gExtrasStates = {}
function reset_honi_states(index)
    if index == nil then index = 0 end
    gExtrasStates[index] = {
        index = network_global_index_from_local(0),
        actionTick = 0,
        prevFrameAction = 0,
        chargedFling = 0,
        canTwirl = true,
        twirlFromDive = true,
        airDash = true,
        canDoubleJump = true,
        diveTimer = 0,
        slideTimer = 0,

        gfxAngleX = 0,
        gfxAngleY = 0,
        gfxAngleZ = 0,
    }
end

-- Iterates through all players
for i = 0, (MAX_PLAYERS - 1) do
    reset_honi_states(i)
end

ACT_HONI_TWIRL     = allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR) --DONE
ACT_HONI_FLING     = allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_GROUP_STATIONARY)

--- @param m MarioState
local function honi_twirl(m)
    local e = gExtrasStates[m.playerIndex]
    --local mag = (m.controller.stickMag) / 64

    if m.actionTimer == 0 then
        m.vel.y = 20
        m.faceAngle.y = m.intendedYaw
        --m.forwardVel = 10
        play_character_sound(m, CHAR_SOUND_HOOHOO)
        m.particleFlags = m.particleFlags | PARTICLE_MIST_CIRCLE
    end
    
    common_air_action_step(m, ACT_FREEFALL_LAND, CHAR_ANIM_TWIRL, AIR_STEP_NONE)

    m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x2800, 0x2800);
    --m.vel.x = m.forwardVel * sins(m.faceAngle.y)
    --m.vel.z = m.forwardVel * coss(m.faceAngle.y)

    if m.input & INPUT_B_PRESSED ~= 0 then
        m.vel.y = 20
        --m.forwardVel = 30
        m.faceAngle.y = m.intendedYaw
        set_mario_action(m, ACT_DIVE, 0)
    end

    if m.input & INPUT_Z_PRESSED ~= 0 then
        m.faceAngle.y = m.intendedYaw
        set_mario_action(m, ACT_GROUND_POUND, 0)
    end

    e.canTwirl = false -- if already twirling, cant twirl again :3

    -- Saves rotation to Extra States
    e.gfxAngleY = e.gfxAngleY + 0x2800
    -- Applies rotation
    m.marioObj.header.gfx.angle.y = e.gfxAngleY

    m.actionTimer = m.actionTimer + 1
end
hook_mario_action(ACT_HONI_TWIRL,{every_frame = honi_twirl})

local function honi_on_set_action(m)
    --i also dont know how this works, placeholder fot the moment
    -- Hook runs when mario's action is changed, so you can run things on the first frame of a base action
    local e = gExtrasStates[m.playerIndex]
end

local canTwirlFromAct = {
    [ACT_DIVE] = true,
    [ACT_JUMP] = true,
    [ACT_DOUBLE_JUMP] = true,
    [ACT_TRIPLE_JUMP] = true,
    [ACT_HOLD_JUMP] = true,
    [ACT_SIDE_FLIP] = true,
    [ACT_BACKFLIP] = true,
    [ACT_LONG_JUMP] = true,
    [ACT_WALL_KICK_AIR] = true,
}

local function update_honi(m)
    local e = gExtrasStates[m.playerIndex]
    local mag = (m.controller.stickMag) / 64

    m.peakHeight = m.pos.y

    -- Global Action Timer 
    e.actionTick = e.actionTick + 1
    if e.prevFrameAction ~= m.action then
        e.prevFrameAction = m.action
        e.actionTick = 0
    end

    if m.action & ACT_FLAG_AIR == 0 then
        e.canTwirl = true -- if in air, cant twirl from other actions
        e.canDoubleJump = true
        e.airDash = true
    end

    if m.action == ACT_DIVE and (m.prevAction == ACT_HONI_TWIRL or m.prevAction == ACT_GROUND_POUND_LAND or (m.prevAction == ACT_GROUND_POUND and not e.airDash) or (m.prevAction == ACT_DOUBLE_JUMP and not e.canDoubleJump)) then
        e.gfxAngleZ = e.gfxAngleZ + 0x1800
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x500, 0x500)
        set_mario_animation(m, CHAR_ANIM_GROUND_POUND)
        smlua_anim_util_set_animation(m.marioObj, HONI_ANIM_DIVE_ROTATE)
        m.marioObj.header.gfx.angle.z = e.gfxAngleZ -- make u spinn when divingg
        m.marioObj.header.gfx.angle.x = 0
        --m.vel.y = m.vel.y + 2
        e.diveTimer = e.diveTimer + 1
        m.particleFlags = m.particleFlags | PARTICLE_SPARKLES

        if e.diveTimer < 30 then
            m.vel.y = 0
        else
            set_mario_action(m, ACT_DIVE, 0)
        end
        if m.input & INPUT_Z_PRESSED ~= 0 then
            set_mario_action(m, ACT_GROUND_POUND, 0)
            m.marioObj.header.gfx.angle.z = 0
        end
    else
        e.diveTimer = 0
    end
    
    if m.action == ACT_DIVE and m.input & INPUT_Z_PRESSED ~= 0 and m.prevAction == ACT_DIVE then 
        set_mario_action(m, ACT_GROUND_POUND, 0)
    end

    if m.action == ACT_DOUBLE_JUMP and m.prevAction == ACT_GROUND_POUND then
        e.gfxAngleY = e.gfxAngleY + 0x2800
        m.marioObj.header.gfx.angle.y = e.gfxAngleY
        m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
    end

    if m.action == ACT_WALL_KICK_AIR then e.canTwirl = true end -- can twirl after a wallkick, either having twirled already or not.
    --djui_chat_message_create(tostring(e.canTwirl))
    --djui_chat_message_create(tostring(e.actionTick))
    if m.input & INPUT_A_PRESSED ~= 0 and e.canTwirl and canTwirlFromAct[m.action] and e.actionTick > 3 then
        set_mario_action(m, ACT_HONI_TWIRL, 0)
    end

    if m.action == ACT_LONG_JUMP then
        if m.input & INPUT_B_PRESSED ~= 0 then
            m.faceAngle.y = m.intendedYaw
            set_mario_action(m, ACT_DIVE, 0)
            m.vel.y = 20
            --m.forwardVel = 30
        end
    end

    if m.action == ACT_FORWARD_ROLLOUT or m.action == ACT_BACKWARD_ROLLOUT then
        if m.input & INPUT_B_PRESSED ~= 0 then
            m.vel.y = 20
            --m.forwardVel = 30
            m.faceAngle.y = m.intendedYaw
            set_mario_action(m, ACT_DIVE, 0) -- can dive from rollouts
            
        elseif m.input & INPUT_A_PRESSED ~= 0 then
            set_mario_action(m, ACT_HONI_TWIRL, 0)
        end
    end

    if m.action == ACT_DIVE_SLIDE then
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x800, 0x800);
        e.slideTimer = e.slideTimer + 1
        m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
        if mag > 0 and e.slideTimer < 40 then
            mario_set_forward_vel(m, 60) 
        else return set_mario_action(m, ACT_HONI_TWIRL, 0)
        end

        if m.input & INPUT_Z_PRESSED ~= 0 then
            m.vel.y = 20
            m.forwardVel = 40
            m.faceAngle.y = m.intendedYaw
            set_mario_action(m, ACT_LONG_JUMP, 0) -- can long jump from dive slidesssss
        end
    else e.slideTimer = 0
    end
    if m.action == ACT_GROUND_POUND then
        if m.input & INPUT_A_PRESSED ~= 0 and e.canDoubleJump then
            if mag > 0 then
                m.forwardVel = 30 + (mag * 10)
                m.vel.y = 10
            end

            e.canDoubleJump = false
            m.vel.y = 30
            m.faceAngle.y = m.intendedYaw      
            set_mario_action(m, ACT_DOUBLE_JUMP, 0)
        end

        if m.input & INPUT_B_PRESSED ~= 0 and e.airDash then
            m.faceAngle.y = m.intendedYaw
            set_mario_action(m, ACT_DIVE, 0)
            m.forwardVel = 60
            m.vel.y = 40
            e.airDash = false
        end
    end

    if m.action == ACT_GROUND_POUND_LAND then
        if m.input & INPUT_B_PRESSED ~= 0 then
            m.faceAngle.y = m.intendedYaw
            set_mario_action(m, ACT_DIVE, 0)
            m.forwardVel = 60
            m.vel.y = 40
        end
        if m.input & INPUT_A_PRESSED ~= 0 then
            m.faceAngle.y = m.intendedYaw
            if mag > 0 then
                m.forwardVel = 60 + (mag * 10)
            end
            m.vel.y = 50
            set_mario_action(m, ACT_TRIPLE_JUMP, 0)
        end
    end
end

local function honi_interact(m, interact)
    local e = gExtrasStates[m.playerIndex]
    --djui_chat_message_create("Interact: " .. tostring(interact))
    if m.action == ACT_HONI_TWIRL and interact == INTERACT_BOUNCE_TOP then
        e.canTwirl = true
        m.vel.y = 100
    end
end

_G.charSelect.character_hook_moveset(CHAR_HONI, HOOK_MARIO_UPDATE, update_honi)
_G.charSelect.character_hook_moveset(CHAR_HONI, HOOK_ON_LEVEL_INIT, reset_honi_states)
_G.charSelect.character_hook_moveset(CHAR_HONI, HOOK_ON_SET_MARIO_ACTION, honi_on_set_action)
_G.charSelect.character_hook_moveset(CHAR_HONI, HOOK_ON_INTERACT, honi_interact)
