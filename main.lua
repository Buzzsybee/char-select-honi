-- name: [CS] Honi
-- description: Did uknoe idunnohow to code? ye i don't :3c

local TEXT_MOD_NAME = "[CS] Honi"

if not _G.charSelectExists then
    djui_popup_create("\\#ffffdc\\\n"..TEXT_MOD_NAME.."\nRequires the Character Select Mod\nto use as a Library!\n\nPlease turn on the Character Select Mod\nand Restart the Room!", 6)
    return 0
end

local E_MODEL_HONI = smlua_model_util_get_id("honi_geo")   -- Located in "actors"
local TEX_ICON_HONI = get_texture_info("honi-icon")

local PALETTE_HONI = {
    [PANTS]  = "5656FF",
    [SHIRT]  = "4F8B4A",
    [GLOVES] = "360099",
    [SHOES]  = "995B53",
    [HAIR]   = "8F1F31",
    [SKIN]   = "FFA787",
    [CAP]    = "5153FF",
	[EMBLEM] = "000672"
}

    _G.charSelect.character_add_palette_preset(E_MODEL_HONI, PALETTE_HONI)


CHAR_HONI = _G.charSelect.character_add(
    "Honi", -- Character Name
    "Just a floaty gal, would u believe ittt?!?!?!?!?!?!", -- Description
    "Honi", -- Credits
    "03fc7b",           -- Menu Color
    E_MODEL_HONI,       -- Character Model
    CT_MARIO,           -- Override Character
    TEX_ICON_HONI, -- Life Icon
    1,                  -- Camera Scale
    0                   -- Vertical Offset
)

function open_doors_check(m)
  
    local dist = 150
    local doorwarp = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvDoorWarp)
    local door = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvDoor)
    local stardoor = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvStarDoor)
    local shell = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvKoopaShell)
    
    if m.action == ACT_WALKING or m.action == ACT_HOLD_WALKING then
        if
        ((doorwarp ~= nil and dist_between_objects(m.marioObj, doorwarp) > dist) or
        (door ~= nil and dist_between_objects(m.marioObj, door) > dist) or
        (stardoor ~= nil and dist_between_objects(m.marioObj, stardoor) > dist) or (dist_between_objects(m.marioObj, shell) > dist and shell ~= nil) and m.heldObj == nil)
        then
            return set_mario_action(m, ACT_HONI_WALK, 0)
        elseif doorwarp == nil and door == nil and stardoor == nil and shell == nil then
            return set_mario_action(m, ACT_HONI_WALK, 0)
        end
    end
    
    if m.action == ACT_HONI_WALK then
        if
        (dist_between_objects(m.marioObj, doorwarp) < dist and doorwarp ~= nil) or
        (dist_between_objects(m.marioObj, door) < dist and door ~= nil) or
        (dist_between_objects(m.marioObj, stardoor) < dist and stardoor ~= nil) or (dist_between_objects(m.marioObj, shell) < dist and shell ~= nil)
        then
          if m.heldObj == nil then
            return set_mario_action(m, ACT_WALKING, 0)
            else
              return set_mario_action(m, ACT_HOLD_WALKING, 0)
          end
        
        end
    end
end