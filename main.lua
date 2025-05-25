-- name:[CS]Honi
-- description:Did uknoe idunnohow to code? ye i don't :3c


local TEXT_MOD_NAME = "[CS] Honi"

if not _G.charSelectExists then
    djui_popup_create("\\#ffffdc\\\n"..TEXT_MOD_NAME.."\nRequires the Character Select Mod\nto use as a Library!\n\nPlease turn on the Character Select Mod\nand Restart the Room!", 6)
    return 0
end

CHAR_HONI = _G.charSelect.character_add(
    "Honi", -- Character Name
    "Just a floaty gal, would u believe ittt?!?!?!?!?!?!", -- Description
    "Honi", -- Credits
    "03fc7b",           -- Menu Color
    E_MODEL_MARIO,       -- Character Model
    CT_MARIO,           -- Override Character
    TEX_CHAR_LIFE_ICON, -- Life Icon
    1,                  -- Camera Scale
    0                   -- Vertical Offset
)
