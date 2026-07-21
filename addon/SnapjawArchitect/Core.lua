SnapjawArchitect = {}
SnapjawArchitect.version = "1.0.0"
SnapjawArchitect.activeTab = "NPC"
SnapjawArchitect.searchText = ""
SnapjawArchitect.page = 1
SnapjawArchitect.pageSize = 12
SnapjawArchitect.filtered = {}
SnapjawArchitect.selectedEntry = nil
SnapjawArchitect.selectedGameObjectGuid = nil
SnapjawArchitect.frame = nil

local function SJA_Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cffd9a441Snapjaw Architect:|r " .. tostring(message)
        )
    end
end

SnapjawArchitect.Print = SJA_Print



local function SJA_Normalize(value)
    if value == nil then
        return ""
    end

    return string.lower(tostring(value))
end

local function SJA_QueryTokens(value)
    local tokens = {}
    local text
    local token

    if value == nil then
        return tokens
    end

    text = string.lower(tostring(value))

    -- Spaces and punctuation separate search words.
    for token in string.gfind(text, "[%w]+") do
        table.insert(tokens, token)
    end

    return tokens
end

local function SJA_IndexContains(searchIndex, queryToken)
    if not searchIndex or not queryToken or queryToken == "" then
        return false
    end

    -- The generated index keeps words separated by spaces.
    --
    -- Plain substring matching therefore finds:
    --   tent -> Tent
    --   tent -> Tents
    --   tent -> OrcTent
    --
    -- But it cannot cross the space between:
    --   Forgotten Trunk
    --
    -- This is both broader and considerably faster than iterating through
    -- every indexed word in Lua.
    return string.find(
        searchIndex,
        queryToken,
        1,
        true
    ) ~= nil
end

local function SJA_MatchesTokens(searchIndex, tokens)
    local index
    local queryToken

    for index = 1, table.getn(tokens) do
        queryToken = tokens[index]

        if not SJA_IndexContains(searchIndex, queryToken) then
            return false
        end
    end

    return true
end

function SnapjawArchitect.GetCatalogue()
    if SnapjawArchitect.activeTab == "OBJECT" then
        return SnapjawArchitectGameObjects or {}
    end
    return SnapjawArchitectNPCs or {}
end



function SnapjawArchitect.FilterCatalogue()
    local catalogue = SnapjawArchitect.GetCatalogue()
    local tokens = SJA_QueryTokens(SnapjawArchitect.searchText)
    local tokenCount = table.getn(tokens)
    local filtered = {}
    local item
    local index

    if tokenCount == 0 then
        SnapjawArchitect.filtered = catalogue
    elseif tokenCount == 1 and string.len(tokens[1]) < 2 then
        -- Avoid expensive and usually unhelpful one-character searches.
        SnapjawArchitect.filtered = catalogue
    else
        for index = 1, table.getn(catalogue) do
            item = catalogue[index]

            if SJA_MatchesTokens(item.searchIndex, tokens) then
                table.insert(filtered, item)
            end
        end

        SnapjawArchitect.filtered = filtered
    end

    local pageCount = math.ceil(
        table.getn(SnapjawArchitect.filtered)
        / SnapjawArchitect.pageSize
    )

    if pageCount < 1 then
        pageCount = 1
    end

    if SnapjawArchitect.page > pageCount then
        SnapjawArchitect.page = pageCount
    end

    if SnapjawArchitect.page < 1 then
        SnapjawArchitect.page = 1
    end
end

function SnapjawArchitect.SetTab(tab)
    SnapjawArchitect.activeTab = tab
    SnapjawArchitect.page = 1
    SnapjawArchitect.selectedEntry = nil
    SnapjawArchitect.FilterCatalogue()

    if SnapjawArchitect.RefreshUI then
        SnapjawArchitect.RefreshUI()
    end
end


function SnapjawArchitect.SetSearch(text)
    SnapjawArchitect.searchText = text or ""
    SnapjawArchitect.page = 1
    SnapjawArchitect.selectedEntry = nil
    SnapjawArchitect.FilterCatalogue()

    if SnapjawArchitect.RefreshUI then
        SnapjawArchitect.RefreshUI()
    end
end

local searchDelayFrame = CreateFrame("Frame")
searchDelayFrame.elapsed = 0
searchDelayFrame:Hide()

searchDelayFrame:SetScript("OnUpdate", function()
    this.elapsed = this.elapsed + arg1

    if this.elapsed >= 0.20 then
        this:Hide()
        this.elapsed = 0

        SnapjawArchitect.SetSearch(
            SnapjawArchitect.pendingSearchText or ""
        )
    end
end)

function SnapjawArchitect.QueueSearch(text)
    SnapjawArchitect.pendingSearchText = text or ""
    searchDelayFrame.elapsed = 0
    searchDelayFrame:Show()
end

function SnapjawArchitect.SelectEntry(item)
    SnapjawArchitect.selectedEntry = item

    if SnapjawArchitect.RefreshUI then
        SnapjawArchitect.RefreshUI()
    end
end

function SnapjawArchitect.SendCommand(command)
    if command == nil or command == "" then
        return
    end

    SJA_Print("Sending " .. command)

    -- VMaNGOS processes dot-prefixed messages as GM commands.
    SendChatMessage(command, "SAY")
end

function SnapjawArchitect.SpawnSelected()
    local item = SnapjawArchitect.selectedEntry

    if not item then
        SJA_Print("Select an entry first.")
        return
    end

    if SnapjawArchitect.activeTab == "OBJECT" then
        SnapjawArchitect.SendCommand(".gobject add " .. item.entry)
    else
        SnapjawArchitect.SendCommand(".npc add " .. item.entry)
    end
end

function SnapjawArchitect.NPCInfo()
    SnapjawArchitect.SendCommand(".npc info")
end

function SnapjawArchitect.NPCDelete()
    SnapjawArchitect.SendCommand(".npc delete")
end

function SnapjawArchitect.NPCSetModel(displayId)
    local value = tonumber(displayId)

    if not value or value < 1 then
        SJA_Print("Enter a valid display ID.")
        return
    end

    SnapjawArchitect.SendCommand(".npc setmodel " .. value)
end

function SnapjawArchitect.GameObjectSelectNearest()
    SnapjawArchitect.SendCommand(".gobject select")
end

function SnapjawArchitect.GameObjectInfo()
    SnapjawArchitect.SendCommand(".gobject info")
end

function SnapjawArchitect.GameObjectDelete()
    if not SnapjawArchitect.selectedGameObjectGuid then
        SJA_Print("Select the nearest GameObject first.")
        return
    end

    SnapjawArchitect.SendCommand(
        ".gobject delete " .. SnapjawArchitect.selectedGameObjectGuid
    )
end

function SnapjawArchitect.GameObjectMoveToMe()
    if not SnapjawArchitect.selectedGameObjectGuid then
        SJA_Print("Select the nearest GameObject first.")
        return
    end

    SnapjawArchitect.SendCommand(
        ".gobject move " .. SnapjawArchitect.selectedGameObjectGuid
    )
end

function SnapjawArchitect.GameObjectTurnToMe()
    if not SnapjawArchitect.selectedGameObjectGuid then
        SJA_Print("Select the nearest GameObject first.")
        return
    end

    SnapjawArchitect.SendCommand(
        ".gobject turn " .. SnapjawArchitect.selectedGameObjectGuid
    )
end

local function SJA_CaptureGameObjectGuid(message)
    local guid

    if not message then
        return
    end

    local startPosition
    local endPosition
    startPosition, endPosition, guid = string.find(
        message,
        "|Hgameobject:(%d+)|h"
    )

    if guid then
        SnapjawArchitect.selectedGameObjectGuid = tonumber(guid)
        SJA_Print("Selected GameObject GUID " .. guid)

        if SnapjawArchitect.RefreshUI then
            SnapjawArchitect.RefreshUI()
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")

eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "SnapjawArchitect" then
        if not SnapjawArchitectDB then
            SnapjawArchitectDB = {}
        end

        SnapjawArchitect.FilterCatalogue()
        SJA_Print(
            "v" .. SnapjawArchitect.version ..
            " loaded. Type /sja to open."
        )
    elseif event == "CHAT_MSG_SYSTEM" then
        SJA_CaptureGameObjectGuid(arg1)
    end
end)

SLASH_SNAPJAWARCHITECT1 = "/sja"
SLASH_SNAPJAWARCHITECT2 = "/architect"

SlashCmdList["SNAPJAWARCHITECT"] = function(message)
    local command = SJA_Normalize(message)

    if command == "npc" then
        SnapjawArchitect.SetTab("NPC")
    elseif command == "object" or command == "objects" or command == "go" then
        SnapjawArchitect.SetTab("OBJECT")
    end

    if SnapjawArchitect.frame then
        if SnapjawArchitect.frame:IsVisible() then
            SnapjawArchitect.frame:Hide()
        else
            SnapjawArchitect.frame:Show()
            SnapjawArchitect.RefreshUI()
        end
    end
end
