if EUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (EllesmereUI_ClientGate.lua)
-------------------------------------------------------------------------------
--  EllesmereUI_CastRank \ CastRank_Options.lua   (standalone add-on)
--  "Spell Rank" rows in an EXTRAS section at the bottom of Resource Bars >
--  Cast Bar. Runtime: CastRank.lua.
--
--  EXTRAS on the Cast Bar page is a shared host (ns._EUICastExtras) so later
--  cast bar extras add-ons can join it: one wrap of ns.ERB_BuildCastBarPage,
--  one EXTRAS header, each add-on's rows appended by order. A new add-on
--  copies the same block and registers; it never wraps the builder itself.
-------------------------------------------------------------------------------
local EllesmereUI = _G.EllesmereUI
local ns = EllesmereUI and EllesmereUI._ModuleNS and EllesmereUI._ModuleNS["EllesmereUIResourceBars"]
if not (ns and ns.CastRank) then return end

-------------------------------------------------------------------------------
--  Shared Cast Bar EXTRAS host (same block in every cast bar extras add-on;
--  the first one loaded creates it, the others reuse it).
-------------------------------------------------------------------------------
local X = ns._EUICastExtras
if not X then
    X = { builders = {} }
    ns._EUICastExtras = X
end
if not X.Install then
    function X.Register(id, order, fn)
        X.builders[id] = { order = order, fn = fn }
    end
    function X.Header(parent, y, W)
        if X.headerDone then return y end
        X.headerDone = true
        local _, h = W:SectionHeader(parent, "EXTRAS", y)
        return y - h
    end
    function X.Install()
        if X.hooked then return true end
        local orig = ns.ERB_BuildCastBarPage
        if type(orig) ~= "function" then return false end
        X.hooked = true
        ns.ERB_BuildCastBarPage = function(pageName, parent, yOffset, ...)
            local total = orig(pageName, parent, yOffset, ...)
            -- The page returns its height (math.abs of its running y).
            if type(total) ~= "number" then return total end
            local y = -total
            X.headerDone = false
            local list = {}
            for _, b in pairs(X.builders) do list[#list + 1] = b end
            table.sort(list, function(a, b) return a.order < b.order end)
            for _, b in ipairs(list) do
                local ok, newY = pcall(b.fn, parent, y)
                if ok and type(newY) == "number" then
                    y = newY
                elseif not ok then
                    geterrorhandler()(newY)
                end
            end
            return math.abs(y)
        end
        return true
    end
end

-------------------------------------------------------------------------------
--  Spell Rank rows
-------------------------------------------------------------------------------
local FORMAT_LABELS = { dash = "Spell Name - Rank 3", paren = "Spell Name (Rank 3)" }
local FORMAT_ORDER  = { "dash", "paren" }

local function BuildCastRank(parent, y)
    local CR = ns.CastRank
    local env = ns._ERB_OptEnv
    local W = EllesmereUI.Widgets
    if not (CR and env and env.DB and W) then return y end
    local DB = env.DB
    local _, h

    local function CB() local p = DB(); return p and p.castBar end
    local function Get(k) return CR.Get(k) end
    local function Set(k, v)
        local cb = CB(); if not cb then return end
        cb[k] = v
        CR.Refresh()
        EllesmereUI:RefreshPage()
    end
    local function castOff() local cb = CB(); return not (cb and cb.enabled) end
    local function rankOff() return castOff() or not Get("rankSuffixEnabled") end

    y = X.Header(parent, y, W)

    -- Show Spell Rank | Rank Format
    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Show Spell Rank",
          tooltip = "Writes the rank of the spell after its name on the cast bar, e.g. Fireball - Rank 3. Spells without a rank get nothing.",
          disabled = castOff, disabledTooltip = "Player Cast Bar",
          getValue = function() return Get("rankSuffixEnabled") and true or false end,
          setValue = function(v) Set("rankSuffixEnabled", v and true or false) end },
        { type = "dropdown", text = "Rank Format",
          values = FORMAT_LABELS, order = FORMAT_ORDER,
          disabled = rankOff, disabledTooltip = "Show Spell Rank",
          getValue = function() return Get("rankSuffixFormat") end,
          setValue = function(v) Set("rankSuffixFormat", v) end }
    );  y = y - h

    -- Custom Rank Color | Rank Color
    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Custom Rank Color",
          tooltip = "Off: the rank uses the Spell Text color. On: the rank gets its own color.",
          disabled = rankOff, disabledTooltip = "Show Spell Rank",
          getValue = function() return Get("rankSuffixCustom") and true or false end,
          setValue = function(v) Set("rankSuffixCustom", v and true or false) end },
        { type = "colorpicker", text = "Rank Color", hasAlpha = false,
          disabled = function() return rankOff() or not Get("rankSuffixCustom") end,
          disabledTooltip = "Custom Rank Color",
          getValue = function()
              return Get("rankSuffixR"), Get("rankSuffixG"), Get("rankSuffixB"), 1
          end,
          setValue = function(r, g, b)
              local cb = CB(); if not cb then return end
              cb.rankSuffixR, cb.rankSuffixG, cb.rankSuffixB = r, g, b
              CR.Refresh()
          end }
    );  y = y - h

    _, h = W:Spacer(parent, y, 20);  y = y - h
    return y
end

X.Register("CastRank", 10, BuildCastRank)

local IsLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
if not (IsLoaded and IsLoaded("EllesmereUIOptions") and X.Install()) then
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, _, name)
        if name == "EllesmereUIOptions" then
            X.Install()
            self:UnregisterAllEvents()
        end
    end)
end
