-- name: [CS] Honi
-- description: Did uknoe idunnohow to code? ye i don't :3c

local TEXT_MOD_NAME = "[CS] Honi"

if not _G.charSelectExists then
    djui_popup_create("\\#ffffdc\\\n"..TEXT_MOD_NAME.."\nRequires the Character Select Mod\nto use as a Library!\n\nPlease turn on the Character Select Mod\nand Restart the Room!", 6)
    return 0
end

local E_MODEL_HONI = smlua_model_util_get_id("honi_geo")   -- Located in "actors"
local TEX_ICON_HONI = get_texture_info("honi-icon")
local HONI_GRAFFITI = get_texture_info("honi_graffiti")

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

anims = {
    [charSelect.CS_ANIM_MENU] = 'HONI_MENU_ANIM',
}


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

if anims then charSelect.character_add_animations(E_MODEL_HONI, anims) end
charSelect.character_add_graffiti(CHAR_HONI, HONI_GRAFFITI)