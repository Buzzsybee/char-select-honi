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

local function s16(x)
    x = (math.floor(x) & 0xFFFF)
    if x >= 32768 then return x - 65536 end
    return x
end

function get_current_speed(m)
    return math.sqrt((m.vel.x * m.vel.x) + (m.vel.z * m.vel.z))
end

local function reset_rotation(m, nextAct, actionArg)
    m.marioBodyState.allowPartRotation = 0
end
hook_event(HOOK_BEFORE_SET_MARIO_ACTION, reset_rotation)

local function reset_pitch(m)
    if m.action == ACT_HONI_WALK then
        m.marioObj.oMarioWalkingPitch = 0
    end
end
hook_event(HOOK_ON_SET_MARIO_ACTION, reset_pitch)

local function update_honi_walking_speed(m)
    local e = gExtrasStates[m.playerIndex]
    local maxTargetSpeed = 0.0;
    local targetSpeed = 0.0;

    if (m.floor ~= nil and m.floor.type == SURFACE_SLOW) then
        maxTargetSpeed = e.lastSpeed;
    else
        maxTargetSpeed = e.lastSpeed;
    end

    if (m.intendedMag < maxTargetSpeed) then
        targetSpeed = m.intendedMag + 20
    else
        targetSpeed = maxTargetSpeed
    end

    if (m.forwardVel <= 0.0) then
        m.forwardVel = m.forwardVel + 2.1;
    elseif (m.forwardVel <= targetSpeed) then
        m.forwardVel = m.forwardVel + 2.1;
    end

    m.faceAngle.y = m.intendedYaw - approach_s32(s16(m.intendedYaw - m.faceAngle.y), 0, 0x800, 0x800);
    apply_slope_accel(m);
end

gExtrasStates = {}
function reset_honi_states(index)
    if index == nil then index = 0 end
    gExtrasStates[index] = {
        index = network_global_index_from_local(0),
        actionTick = 0,
        prevFrameAction = 0,
        canTwirl = true,
        isSpecialDive = false,
        boostGauge = 100,
        isBoosting = false,
        twirlFromDive = true,
        airDash = true,
        airDashCount = 3,
        boomCount = 3,
        canDoubleJump = true,
        diveTimer = 0,
        slideTimer = 0,
        runTimer = 0,
        hasReleasedZ = false,

        gfxAngleX = 0,
        gfxAngleY = 0,
        gfxAngleZ = 0,

        lastSpeed = 0,
        diveSlideSpeed = 0,
        slideJumpSpeed = 0,
        tripleJumpSpeed = 0,
    }
end

-- Iterates through all players
for i = 0, (MAX_PLAYERS - 1) do
    reset_honi_states(i)
end

ACT_HONI_TWIRL = allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_AIR) --DONE
ACT_HONI_GROUND_POUND = allocate_mario_action(ACT_GROUP_AIRBORNE|ACT_FLAG_ATTACKING|ACT_FLAG_MOVING|ACT_FLAG_AIR) --DONE
ACT_HONI_WALK = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_FLAG_MOVING | ACT_FLAG_CUSTOM_ACTION)

function act_honi_walking(m)
    local startPos = m.pos;
    local startYaw = m.faceAngle.y;

    mario_drop_held_object(m);

    m.particleFlags = m.particleFlags | PARTICLE_MIST_CIRCLE;

    if (m.input & INPUT_FIRST_PERSON ~= 0) then
        return begin_braking_action(m);
    end

    if (m.input & INPUT_A_PRESSED ~= 0) then
        return set_mario_action(m, ACT_TRIPLE_JUMP, 0);
    end

    if (check_ground_dive_or_punch(m) ~= 0) then
        return 1;
    end

    if (m.input & INPUT_ZERO_MOVEMENT ~= 0) then
        return begin_braking_action(m);
    end
    
    if (analog_stick_held_back(m) ~= 0 and m.forwardVel >= 1.0) then
        return set_mario_action(m, ACT_TURNING_AROUND, 0);
    end

    m.actionState = 0;

    vec3f_copy(startPos, m.pos);
    update_honi_walking_speed(m);
    open_doors_check(m)

    local stepResult = perform_ground_step(m)
    if (stepResult == GROUND_STEP_LEFT_GROUND) then
        set_mario_action(m, ACT_FREEFALL, 0);
        set_character_animation(m, CHAR_ANIM_GENERAL_FALL);    
    elseif (stepResult == GROUND_STEP_NONE) then
        anim_and_audio_for_walk(m);
        if ((m.intendedMag - m.forwardVel) > 16.0) then
            set_mario_particle_flags(m, PARTICLE_DUST, false);
        end
    elseif (stepResult == GROUND_STEP_HIT_WALL) then
        push_or_sidle_wall(m, startPos);
        m.actionTimer = 0;
    end

    tilt_body_walking(m, startYaw);
    m.marioBodyState.allowPartRotation = 1
    return 0;
end
hook_mario_action(ACT_HONI_WALK, { every_frame = act_honi_walking, gravity = nil } )

--- @param m MarioState
local function honi_twirl(m)
    local e = gExtrasStates[m.playerIndex]
    if m.actionTimer == 0 then
        mario_set_forward_vel(m, math.max(30, e.lastSpeed))
        m.vel.y = 30
        m.faceAngle.y = m.intendedYaw
        play_character_sound(m, CHAR_SOUND_HOOHOO)
        m.particleFlags = m.particleFlags | PARTICLE_MIST_CIRCLE
    end
    
    common_air_action_step(m, ACT_FREEFALL_LAND, CHAR_ANIM_TWIRL, AIR_STEP_NONE)

    m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x2800, 0x2800)

    if m.input & INPUT_B_PRESSED ~= 0 then
        m.faceAngle.y = m.intendedYaw
        set_mario_action(m, ACT_DIVE, 0)
    end

    if m.input & INPUT_Z_PRESSED ~= 0 then
        m.faceAngle.y = m.intendedYaw
        set_mario_action(m, ACT_HONI_GROUND_POUND, 0)
    end

    e.canTwirl = false -- if already twirling, cant twirl again :3

    -- Saves rotation to Extra States
    e.gfxAngleY = e.gfxAngleY + 0x2800
    -- Applies rotation
    m.marioObj.header.gfx.angle.y = e.gfxAngleY

    m.actionTimer = m.actionTimer + 1
end
hook_mario_action(ACT_HONI_TWIRL,{every_frame = honi_twirl})

local function act_honi_ground_pound(m)
    local e = gExtrasStates[m.playerIndex]
    local mag = (m.controller.stickMag) / 64

    common_air_action_step(m, ACT_GROUND_POUND_LAND, MARIO_ANIM_BEING_GRABBED, AIR_STEP_CHECK_LEDGE_GRAB)
    m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x1000, 0x1000)
    if e.actionTick == 0 then
        m.faceAngle.y = m.intendedYaw

        m.vel.y = 30
        play_character_sound(m, CHAR_SOUND_WHOA)
        m.particleFlags = m.particleFlags | PARTICLE_MIST_CIRCLE
    end

    if mag > 0 then
        mario_set_forward_vel(m, math.max(e.lastSpeed, 32))
    else m.forwardVel = approach_f32(m.forwardVel, 0, 10, 10)
    end

    -- Saves rotation to Extra States
    e.gfxAngleX = e.gfxAngleX + 0x1500
    -- Applies rotation
    m.marioObj.header.gfx.angle.x = e.gfxAngleX

    e.gfxAngleY = e.gfxAngleY + 0x800

    m.marioObj.header.gfx.angle.y = e.gfxAngleY

    m.actionTimer = m.actionTimer + 1
    m.peakHeight = m.pos.y
end
hook_mario_action(ACT_HONI_GROUND_POUND, {every_frame = act_honi_ground_pound})

local function honi_on_set_action(m)
    local e = gExtrasStates[m.playerIndex]

    if m.action == ACT_SLIDE_KICK then
        mario_set_forward_vel(m, 200)
        m.pos.y = m.pos.y + 70
        set_mario_action(m, ACT_DIVE, 0)
    end

    if m.action == ACT_GROUND_POUND then 
        set_mario_action(m, ACT_HONI_GROUND_POUND, 0)
    end -- make sure it is the honi ground pound

    if m.action == ACT_HONI_GROUND_POUND then
        e.hasReleasedZ = false
    end

    if m.action == ACT_DIVE then
        if not e.isSpecialDive then
            mario_set_forward_vel(m, e.lastSpeed)
        end
    end
end

local function before_honi_update(m)
    e = gExtrasStates[m.playerIndex]
    e.lastSpeed = get_current_speed(m)

    if (e.lastSpeed > 70 and m.action & ACT_FLAG_AIR == 0) and (m.action ~= ACT_DIVE_SLIDE and m.action ~= ACT_GROUND_POUND_LAND) then
        set_mario_action(m, ACT_HONI_WALK, 0)
    end
end

local function allow_interact(m, obj, interactType)
    -- Only prevent interaction for the local player who spawned the explosion
    if (obj_has_behavior_id(obj, id_bhvExplosion) ~= 0 and obj.oHealth == 64) then
        if m.playerIndex == 0 then
            return false
        end
    end
end
hook_event(HOOK_ALLOW_INTERACT, allow_interact)

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
        e.canTwirl = true
        e.canDoubleJump = true
        e.airDash = true
        e.airDashCount = 3
        e.boomCount = 3
    end

    -- Special dive
    if m.action == ACT_DIVE and (m.prevAction == ACT_HONI_TWIRL or m.prevAction == ACT_GROUND_POUND_LAND or (m.prevAction == ACT_HONI_GROUND_POUND and not e.airDash) or (m.prevAction == ACT_DOUBLE_JUMP and not e.canDoubleJump) or (m.prevAction == ACT_SLIDE_KICK)) then
        e.isSpecialDive = true
        e.gfxAngleZ = e.gfxAngleZ + 0x1800
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x500, 0x500)
        set_mario_animation(m, CHAR_ANIM_GROUND_POUND)
        smlua_anim_util_set_animation(m.marioObj, HONI_ANIM_DIVE_ROTATE)
        m.marioObj.header.gfx.angle.z = e.gfxAngleZ -- make u spinn when divingg
        m.marioObj.header.gfx.angle.x = 0
        e.diveTimer = e.diveTimer + 1
        m.particleFlags = m.particleFlags | PARTICLE_SPARKLES

        if e.diveTimer < 30 then
            m.vel.y = 0
        else
            e.isSpecialDive = false
            set_mario_action(m, ACT_DIVE, 0)
        end
        if m.input & INPUT_Z_PRESSED ~= 0 then
            set_mario_action(m, ACT_HONI_GROUND_POUND, 0)
            m.marioObj.header.gfx.angle.z = 0
        end
    else
        e.diveTimer = 0
        e.isSpecialDive = false
    end

    if m.action == ACT_DIVE then
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x500, 0x500)

        if m.input & INPUT_Z_PRESSED ~= 0 then
            set_mario_action(m, ACT_HONI_GROUND_POUND, 0)
        end

        if m.input & INPUT_B_PRESSED ~= 0 and e.actionTick > 3 and e.boomCount > 0 then
            m.faceAngle.y = m.intendedYaw
            local explosionObj  = spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, m.pos.x, m.pos.y, m.pos.z, function(explosionObj)
                explosionObj.oHealth = 64
            end)
            play_character_sound(m, CHAR_SOUND_HOOHOO)
            mario_set_forward_vel(m, m.forwardVel + 30)
            e.gfxAngleX = 0x2800
            m.vel.y = 30
            e.boomCount = e.boomCount - 1
            if e.isSpecialDive then
                e.diveTimer = 0
                m.vel.y = 0
            end
        end
        if m.forwardVel > 200 then
            m.forwardVel = 200
        end

        if not e.isSpecialDive and m.forwardVel > 40 then
            m.particleFlags = m.particleFlags | PARTICLE_DUST
        end
    end

    if m.action == ACT_DOUBLE_JUMP and m.prevAction == ACT_HONI_GROUND_POUND then
        e.gfxAngleY = e.gfxAngleY + 0x2800
        m.marioObj.header.gfx.angle.y = e.gfxAngleY
        m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
    end

    if (m.action == ACT_TRIPLE_JUMP and m.prevAction == ACT_GROUND_POUND_LAND) or m.action == ACT_WALL_KICK_AIR then
        m.particleFlags = m.particleFlags | PARTICLE_DUST
    end

    if m.action == ACT_JUMP or m.action == ACT_DOUBLE_JUMP or m.action == ACT_TRIPLE_JUMP or m.action == ACT_STEEP_JUMP or m.action == ACT_WATER_JUMP then
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x2800, 0x2800)
    end

    if m.action == ACT_WALL_KICK_AIR then 
        e.canTwirl = true 
        e.airDash = true
        e.boomCount = 3
    end
    -- can twirl after a wallkick, either having twirled already or not.
    if m.input & INPUT_A_PRESSED ~= 0 and e.canTwirl and canTwirlFromAct[m.action] and e.actionTick > 3 then
        set_mario_action(m, ACT_HONI_TWIRL, 0)
    end

    if m.action == ACT_LONG_JUMP then
        if e.actionTick == 0 then
            if m.prevAction == ACT_DIVE_SLIDE then
                local explosionObj  = spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, m.pos.x, m.pos.y, m.pos.z, function(explosionObj)
                    explosionObj.oHealth = 64
                end)
                e.slideJumpSpeed = e.lastSpeed
            end
        end

        if m.prevAction == ACT_DIVE_SLIDE then
            mario_set_forward_vel(m, e.slideJumpSpeed)
        end
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x800, 0x800)

        if m.input & INPUT_B_PRESSED ~= 0 then
            m.faceAngle.y = m.intendedYaw
            set_mario_action(m, ACT_DIVE, 0)
        end

        if m.input & INPUT_Z_PRESSED ~= 0 then
            set_mario_action(m, ACT_HONI_GROUND_POUND, 0)
        end
    else e.slideJumpSpeed = 0
    
    end

    if (m.action == ACT_FORWARD_ROLLOUT or m.action == ACT_BACKWARD_ROLLOUT) then
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x800, 0x800)
        
        if e.actionTick > 5 then
            if m.input & INPUT_B_PRESSED ~= 0 then
                m.vel.y = 20
                --m.forwardVel = 30
                m.faceAngle.y = m.intendedYaw
                set_mario_action(m, ACT_DIVE, 0) -- can dive from rollouts
                
            elseif m.input & INPUT_A_PRESSED ~= 0 then
                set_mario_action(m, ACT_HONI_TWIRL, 0)
            end
        end
    end

    if m.action == ACT_DIVE_SLIDE then
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x800, 0x800);
        e.slideTimer = e.slideTimer + 1
        m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
        if e.slideTimer == 1 then
            if m.prevAction == ACT_GROUND_POUND_LAND then
                e.diveSlideSpeed = 95
            else
                e.diveSlideSpeed = e.lastSpeed
            end
        end

        mario_set_forward_vel(m, e.diveSlideSpeed)

        if mag <= 0 or e.slideTimer >= 40 then
        e.slideTimer = 0
        e.diveSlideSpeed = 0
        return set_mario_action(m, ACT_HONI_TWIRL, 0)
        end

        if m.input & INPUT_Z_PRESSED ~= 0 then
            m.vel.y = 20
            m.faceAngle.y = m.intendedYaw
            set_mario_action(m, ACT_LONG_JUMP, 0) -- can long jump from dive slidesssss
        end
    else e.slideTimer = 0
    end

    --special wallkick, easier to do(10 frames), can be done from heavy knockback and not just soft bonk, has only 3 uses
    if m.action == ACT_BACKWARD_AIR_KB then
        if e.actionTick == 0 then
            m.invincTimer = 2
            local explosionObj  = spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, m.pos.x, m.pos.y, m.pos.z, function(explosionObj)
                explosionObj.oHealth = 64
            end)
            play_character_sound(m, CHAR_SOUND_TWIRL_BOUNCE)
            play_mario_heavy_landing_sound(m, SOUND_GENERAL_EXPLOSION7) 
        end

        if e.actionTick < 10 then
            if e.airDashCount > 0 and m.input & INPUT_A_PRESSED ~= 0 then
                e.airDashCount = e.airDashCount - 1
                m.faceAngle.y = m.faceAngle.y - 0x8000
                m.particleFlags = m.particleFlags | PARTICLE_MIST_CIRCLE
                set_mario_action(m, ACT_WALL_KICK_AIR, 0)
            end
        end
        if m.vel.z > 10 then
            m.vel.z = 10
        end
    end

    if m.action == ACT_HONI_GROUND_POUND then
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
        if m.input & INPUT_Z_DOWN == 0 then
            e.hasReleasedZ = true
        end
        if e.actionTick > 1 and (m.input & INPUT_Z_DOWN ~= 0) and e.hasReleasedZ then
            play_mario_sound(m, SOUND_ACTION_TWIRL, SOUND_ACTION_TWIRL)
            if m.input & INPUT_A_PRESSED ~= 0 or m.input & INPUT_B_PRESSED ~= 0 then return end
            m.particleFlags = m.particleFlags | PARTICLE_MIST_CIRCLE
            m.vel.y = -110
            mario_set_forward_vel(m, 0)
        end
    end

    if m.action == ACT_GROUND_POUND_LAND then
        if e.actionTick == 0 then
            m.invincTimer = 2
            local explosionObj = spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, m.pos.x, m.pos.y, m.pos.z, function(explosionObj)
                explosionObj.oHealth = 64
            end)
            play_mario_sound(m, CHAR_SOUND_TWIRL_BOUNCE, CHAR_SOUND_TWIRL_BOUNCE)
            play_mario_heavy_landing_sound(m, SOUND_GENERAL_EXPLOSION7)

            e.tripleJumpSpeed = math.max(e.lastSpeed, 50)
        end
        if m.input & INPUT_B_PRESSED ~= 0 then
            m.faceAngle.y = m.intendedYaw
            set_mario_action(m, ACT_DIVE, 0)
            m.forwardVel = 60
            m.vel.y = 40
        end
        if m.input & INPUT_A_PRESSED ~= 0 then
            m.faceAngle.y = m.intendedYaw
            if mag > 0 then
                mario_set_forward_vel(m, e.tripleJumpSpeed)
            end
            m.vel.y = 50
            set_mario_action(m, ACT_TRIPLE_JUMP, 0)
        end

        if m.input & INPUT_Z_PRESSED ~= 0 then
            set_mario_action(m, ACT_DIVE_SLIDE, 0)
        end
    end

    if (m.action == ACT_FLAG_BUTT_OR_STOMACH_SLIDE) then
        e.actionTick = e.actionTick + 1
        if e.actionTick == 1 then
            m.invincTimer = 2
        end
    end

    if m.action == ACT_WATER_JUMP or m.action == ACT_FREEFALL then
        if m.input & INPUT_B_PRESSED ~= 0 then
            m.faceAngle.y = m.intendedYaw
            set_mario_action(m, ACT_DIVE, 0)
            m.vel.y = 20
            --m.forwardVel = 30
        end

        if m.input & INPUT_A_PRESSED ~= 0 and e.canTwirl and e.actionTick > 3 then
            set_mario_action(m, ACT_HONI_TWIRL, 0)
        end

        if m.input & INPUT_Z_PRESSED ~= 0 then
            set_mario_action(m, ACT_HONI_GROUND_POUND, 0)
        end
    end

    if m.action == ACT_HONI_WALK then
        if m.input & INPUT_Z_DOWN ~= 0 and e.boostGauge > 0 then
            e.isBoosting = true
            m.forwardVel = m.forwardVel + 1
            if m.forwardVel > 200 then
                m.forwardVel = 200
            end
            e.boostGauge = e.boostGauge - 1
            m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
        else
            e.isBoosting = false
        if e.boostGauge < 100 then
            e.boostGauge = e.boostGauge + 1
        end
    end

        e.runTimer = e.runTimer + 1
        if e.runTimer > 120 then
            m.forwardVel = approach_f32(m.forwardVel, 50, 2, 2)
            if m.forwardVel <= 50 then
                e.runTimer = 0
                return set_mario_action(m, ACT_WALKING, 0)
            end
        end
        else e.runTimer = 0

        if not e.isBoosting and e.boostGauge < 100 then
        e.boostGauge = e.boostGauge + 1
        end
    end

    if m.action == ACT_WALKING then
        update_honi_walking_speed(m)
    end
end

_G.charSelect.character_hook_moveset(CHAR_HONI, HOOK_MARIO_UPDATE, update_honi)
_G.charSelect.character_hook_moveset(CHAR_HONI, HOOK_ON_LEVEL_INIT, reset_honi_states)
_G.charSelect.character_hook_moveset(CHAR_HONI, HOOK_ON_SET_MARIO_ACTION, honi_on_set_action)
_G.charSelect.character_hook_moveset(CHAR_HONI, HOOK_ON_INTERACT, honi_interact)
_G.charSelect.character_hook_moveset(CHAR_HONI, HOOK_BEFORE_MARIO_UPDATE, before_honi_update)
