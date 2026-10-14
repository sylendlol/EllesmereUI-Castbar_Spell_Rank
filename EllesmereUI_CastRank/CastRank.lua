if EUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (EllesmereUI_ClientGate.lua)
-------------------------------------------------------------------------------
--  EllesmereUI_CastRank \ CastRank.lua   (standalone add-on)
--
--  Lives in its own folder: no EllesmereUI file is changed. It attaches at run
--  time to the EllesmereUI Resource Bars module through the module registry
--  (EllesmereUI._ModuleNS["EllesmereUIResourceBars"]).
--
--  Appends the rank of the spell being cast to the spell name on the player
--  cast bar:  "Fireball - Rank 3"  or  "Fireball (Rank 3)".
--
--  How: a hooksecurefunc on the cast bar's name FontString (ERB_CastBarFrame
--  ._nameText). When the cast bar writes exactly the current spell name
--  (castBarFrame._spellName) the hook writes it again with the rank suffix.
--  Anything else ("", other texts) is left alone. Spells without a numeric
--  rank (racials, passives, rankless spells) get no suffix.
--
--  Settings (ERB.db.profile.castBar):
--    rankSuffixEnabled  bool    master switch (default off)
--    rankSuffixFormat   string  "dash" (Spell - Rank 3) | "paren" (Spell (Rank 3))
--    rankSuffixCustom   bool    paint the rank in its own color
--    rankSuffixR/G/B    number  that color (default 0.85 grey)
-------------------------------------------------------------------------------
local EllesmereUI = _G.EllesmereUI
local ns = EllesmereUI and EllesmereUI._ModuleNS and EllesmereUI._ModuleNS["EllesmereUIResourceBars"]
if not (ns and type(ns.ERB) == "table") then return end

local type, pcall, tonumber, format, floor = type, pcall, tonumber, string.format, math.floor
local issecret = _G.issecretvalue or function() return false end
local GetSubtext = (C_Spell and C_Spell.GetSpellSubtext) or _G.GetSpellSubtext

local CR = {}
ns.CastRank = CR

CR.DEFAULTS = {
    rankSuffixEnabled = false,
    rankSuffixFormat  = "dash",
    rankSuffixCustom  = false,
    rankSuffixR = 0.85, rankSuffixG = 0.85, rankSuffixB = 0.85,
}

local function CB()
    local db = ns.ERB.db
    return db and db.profile and db.profile.castBar
end

function CR.Get(key)
    local cb = CB()
    local v = cb and cb[key]
    if v == nil then return CR.DEFAULTS[key] end
    return v
end

-- "Rank 3" (localized subtext as the client gives it) or nil.
local function RankText(spellID)
    if not GetSubtext or spellID == nil or issecret(spellID) then return nil end
    local ok, sub = pcall(GetSubtext, spellID)
    if not ok or sub == nil or issecret(sub) or type(sub) ~= "string" or sub == "" then return nil end
    local n = sub:match("(%d+)")
    if not n then return nil end
    return sub
end
CR.RankText = RankText

function CR.Suffix(rank)
    if not rank then return "" end
    if CR.Get("rankSuffixCustom") then
        local r, g, b = CR.Get("rankSuffixR"), CR.Get("rankSuffixG"), CR.Get("rankSuffixB")
        rank = format("|cff%02x%02x%02x%s|r",
            floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5), rank)
    end
    if CR.Get("rankSuffixFormat") == "paren" then
        return " (" .. rank .. ")"
    end
    return " - " .. rank
end

-------------------------------------------------------------------------------
--  Hook on the cast bar name text
-------------------------------------------------------------------------------
local hooked, busy = false, false

local function OnNameSet(fs, text)
    if busy or not CR.Get("rankSuffixEnabled") then return end
    local f = _G.ERB_CastBarFrame
    if not f or text == nil or issecret(text) or type(text) ~= "string" or text == "" then return end
    local name = f._spellName
    if name == nil or issecret(name) or text ~= name then return end
    local rank = RankText(f._spellID)
    if not rank then return end
    busy = true
    pcall(fs.SetText, fs, text .. CR.Suffix(rank))
    busy = false
end

local function TryHook()
    if hooked then return true end
    local f = _G.ERB_CastBarFrame
    local fs = f and f._nameText
    if not (fs and fs.SetText) then return false end
    hooksecurefunc(fs, "SetText", OnNameSet)
    hooked = true
    return true
end

-- Re-writes the live cast's name so a settings change shows at once
-- (the hook adds or leaves out the suffix).
function CR.Refresh()
    if not TryHook() then return end
    local f = _G.ERB_CastBarFrame
    if not (f._casting or f._channeling or f._empowering) then return end
    local name = f._spellName
    if name == nil or issecret(name) or name == "" then return end
    f._nameText:SetText(name)
end

-- The cast bar frame is built by the Resource Bars module after login; hook
-- it as soon as it exists (first cast at the latest, then re-apply).
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
ev:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
pcall(ev.RegisterUnitEvent, ev, "UNIT_SPELLCAST_EMPOWER_START", "player")
ev:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0, function()
            if TryHook() then self:UnregisterAllEvents() end
        end)
        return
    end
    if not hooked and TryHook() then
        self:UnregisterAllEvents()
        CR.Refresh()
    end
end)
TryHook()
