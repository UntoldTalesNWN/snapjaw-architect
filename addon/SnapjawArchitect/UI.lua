local SJA_ROWS = 12
local SJA_ROW_HEIGHT = 24

local function SJA_CreateButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetText(text)
    return button
end

local function SJA_CreateEditBox(parent, width, height)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetWidth(width)
    edit:SetHeight(height)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    return edit
end

local function SJA_ResetScroll()
    if SnapjawArchitect.scrollFrame then
        FauxScrollFrame_SetOffset(SnapjawArchitect.scrollFrame, 0)
        SnapjawArchitect.scrollFrame:SetVerticalScroll(0)
    end
end

local frame = CreateFrame("Frame", "SnapjawArchitectFrame", UIParent)
SnapjawArchitect.frame = frame

frame:SetWidth(760)
frame:SetHeight(620)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetFrameStrata("DIALOG")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function()
    this:StartMoving()
end)
frame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
end)
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
frame:SetBackdropColor(0, 0, 0, 1)
frame:Hide()

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", frame, "TOP", 0, -17)
title:SetText("Snapjaw Architect")

local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

local npcTab = SJA_CreateButton(frame, "NPCs", 105, 24)
npcTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -48)
npcTab:SetScript("OnClick", function()
    SJA_ResetScroll()
    SnapjawArchitect.SetTab("NPC")
end)

local objectTab = SJA_CreateButton(frame, "Objects", 105, 24)
objectTab:SetPoint("LEFT", npcTab, "RIGHT", 8, 0)
objectTab:SetScript("OnClick", function()
    SJA_ResetScroll()
    SnapjawArchitect.SetTab("OBJECT")
end)

local buildInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
buildInfo:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -53)
buildInfo:SetJustifyH("RIGHT")

local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
searchLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -87)
searchLabel:SetText("Search")

local searchBox = SJA_CreateEditBox(frame, 530, 24)
searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 12, 0)
searchBox:SetScript("OnTextChanged", function()
    SJA_ResetScroll()
    SnapjawArchitect.QueueSearch(this:GetText())
end)
searchBox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
end)
searchBox:SetScript("OnEnterPressed", function()
    this:ClearFocus()
end)

local clearButton = SJA_CreateButton(frame, "Clear", 72, 22)
clearButton:SetPoint("LEFT", searchBox, "RIGHT", 8, 0)
clearButton:SetScript("OnClick", function()
    searchBox:SetText("")
    searchBox:ClearFocus()
end)

local listBorder = CreateFrame("Frame", nil, frame)
listBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -119)
listBorder:SetWidth(716)
listBorder:SetHeight(324)
listBorder:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
listBorder:SetBackdropColor(0.04, 0.04, 0.04, 0.95)

local scrollFrame = CreateFrame(
    "ScrollFrame",
    "SnapjawArchitectScrollFrame",
    listBorder,
    "FauxScrollFrameTemplate"
)
SnapjawArchitect.scrollFrame = scrollFrame
scrollFrame:SetPoint("TOPLEFT", listBorder, "TOPLEFT", 4, -7)
scrollFrame:SetPoint("BOTTOMRIGHT", listBorder, "BOTTOMRIGHT", -27, 7)
scrollFrame:SetScript("OnVerticalScroll", function()
    FauxScrollFrame_OnVerticalScroll(
        SJA_ROW_HEIGHT,
        SnapjawArchitect.RefreshUI
    )
end)

local rows = {}
local rowIndex

for rowIndex = 1, SJA_ROWS do
    local row = CreateFrame("Button", nil, listBorder)
    row:SetWidth(665)
    row:SetHeight(SJA_ROW_HEIGHT)

    if rowIndex == 1 then
        row:SetPoint("TOPLEFT", listBorder, "TOPLEFT", 10, -10)
    else
        row:SetPoint("TOPLEFT", rows[rowIndex - 1], "BOTTOMLEFT", 0, 0)
    end

    row:SetHighlightTexture(
        "Interface\\QuestFrame\\UI-QuestTitleHighlight",
        "ADD"
    )

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.text:SetWidth(650)
    row.text:SetJustifyH("LEFT")

    row:SetScript("OnClick", function()
        if this.item then
            SnapjawArchitect.SelectEntry(this.item)
        end
    end)

    row:SetScript("OnDoubleClick", function()
        if this.item then
            SnapjawArchitect.SelectEntry(this.item)
            SnapjawArchitect.SpawnSelected()
        end
    end)

    rows[rowIndex] = row
end

local resultText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
resultText:SetPoint("TOPLEFT", listBorder, "BOTTOMLEFT", 2, -10)
resultText:SetWidth(712)
resultText:SetJustifyH("CENTER")

local selectedText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
selectedText:SetPoint("TOPLEFT", resultText, "BOTTOMLEFT", 0, -13)
selectedText:SetWidth(712)
selectedText:SetJustifyH("LEFT")
selectedText:SetText("Nothing selected")

local spawnButton = SJA_CreateButton(frame, "Spawn", 90, 24)
spawnButton:SetPoint("TOPLEFT", selectedText, "BOTTOMLEFT", -2, -12)
spawnButton:SetScript("OnClick", function()
    SnapjawArchitect.SpawnSelected()
end)

local action1 = SJA_CreateButton(frame, "Info", 100, 24)
action1:SetPoint("LEFT", spawnButton, "RIGHT", 7, 0)

local action2 = SJA_CreateButton(frame, "Delete", 105, 24)
action2:SetPoint("LEFT", action1, "RIGHT", 7, 0)

local action3 = SJA_CreateButton(frame, "Select nearest", 110, 24)
action3:SetPoint("LEFT", action2, "RIGHT", 7, 0)

local action4 = SJA_CreateButton(frame, "Move to me", 105, 24)
action4:SetPoint("LEFT", action3, "RIGHT", 7, 0)

local action5 = SJA_CreateButton(frame, "Turn to me", 105, 24)
action5:SetPoint("LEFT", action4, "RIGHT", 7, 0)

local modelLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
modelLabel:SetPoint("TOPLEFT", spawnButton, "BOTTOMLEFT", 2, -13)
modelLabel:SetText("Display ID")

local modelBox = SJA_CreateEditBox(frame, 90, 24)
modelBox:SetPoint("LEFT", modelLabel, "RIGHT", 10, 0)
modelBox:SetText("")

local modelButton = SJA_CreateButton(frame, "Set NPC model", 125, 24)
modelButton:SetPoint("LEFT", modelBox, "RIGHT", 8, 0)
modelButton:SetScript("OnClick", function()
    SnapjawArchitect.NPCSetModel(modelBox:GetText())
end)

local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
statusText:SetPoint("LEFT", modelButton, "RIGHT", 18, 0)
statusText:SetWidth(355)
statusText:SetJustifyH("LEFT")

local hintText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
hintText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 24, 18)
hintText:SetWidth(710)
hintText:SetJustifyH("LEFT")
hintText:SetText(
    "Use the scrollbar to browse. Double-click an entry to spawn it. " ..
    "Type /sja to show or hide this window."
)

function SnapjawArchitect.RefreshUI()
    SnapjawArchitect.FilterCatalogue()

    local total = table.getn(SnapjawArchitect.filtered)
    local offset
    local firstVisible
    local lastVisible
    local item
    local label
    local index

    FauxScrollFrame_Update(
        scrollFrame,
        total,
        SJA_ROWS,
        SJA_ROW_HEIGHT
    )

    offset = FauxScrollFrame_GetOffset(scrollFrame)
    firstVisible = offset + 1
    lastVisible = offset + SJA_ROWS

    if lastVisible > total then
        lastVisible = total
    end

    if total == 0 then
        resultText:SetText("No matching entries")
    else
        resultText:SetText(
            "Showing " .. firstVisible .. "-" .. lastVisible ..
            " of " .. total .. " results"
        )
    end

    if SnapjawArchitectBuildInfo then
        buildInfo:SetText(
            tostring(SnapjawArchitectBuildInfo.npcCount or 0) ..
            " NPCs / " ..
            tostring(SnapjawArchitectBuildInfo.gameObjectCount or 0) ..
            " objects"
        )
    end

    if SnapjawArchitect.activeTab == "OBJECT" then
        npcTab:UnlockHighlight()
        objectTab:LockHighlight()
    else
        objectTab:UnlockHighlight()
        npcTab:LockHighlight()
    end

    for index = 1, SJA_ROWS do
        item = SnapjawArchitect.filtered[offset + index]
        rows[index].item = item

        -- Keep the currently selected catalogue entry highlighted.
        if item
            and SnapjawArchitect.selectedEntry
            and item.entry == SnapjawArchitect.selectedEntry.entry
        then
            rows[index]:LockHighlight()
        else
            rows[index]:UnlockHighlight()
        end

        if item then
            if SnapjawArchitect.activeTab == "OBJECT" then
                label =
                    item.entry .. "  " ..
                    (item.name or "") ..
                    "  |cff888888[type " ..
                    tostring(item.type or 0) ..
                    ", display " ..
                    tostring(item.displayId or 0) ..
                    "]|r"
            else
                label = item.entry .. "  " .. (item.name or "")

                if item.subname and item.subname ~= "" then
                    label =
                        label ..
                        "  |cff888888<" ..
                        item.subname ..
                        ">|r"
                end
            end

            rows[index].text:SetText(label)
            rows[index]:Show()
        else
            rows[index].text:SetText("")
            rows[index]:Hide()
        end
    end

    item = SnapjawArchitect.selectedEntry

    if item then
        if SnapjawArchitect.activeTab == "OBJECT" then
            selectedText:SetText(
                "Selected object: " ..
                item.entry .. " — " .. (item.name or "") ..
                " | Type " .. tostring(item.type or 0) ..
                " | Display " .. tostring(item.displayId or 0)
            )
        else
            selectedText:SetText(
                "Selected NPC: " ..
                item.entry .. " — " .. (item.name or "") ..
                " | Model " .. tostring(item.displayId or 0)
            )

            if item.displayId and item.displayId > 0 then
                modelBox:SetText(tostring(item.displayId))
            end
        end
    else
        selectedText:SetText("Nothing selected")
    end

    if SnapjawArchitect.activeTab == "OBJECT" then
        action1:SetText("Object info")
        action1:SetScript("OnClick", function()
            SnapjawArchitect.GameObjectInfo()
        end)

        action2:SetText("Delete object")
        action2:SetScript("OnClick", function()
            SnapjawArchitect.GameObjectDelete()
        end)

        action3:SetText("Select nearest")
        action3:SetScript("OnClick", function()
            SnapjawArchitect.GameObjectSelectNearest()
        end)

        action4:SetText("Move to me")
        action4:SetScript("OnClick", function()
            SnapjawArchitect.GameObjectMoveToMe()
        end)

        action5:SetText("Turn to me")
        action5:SetScript("OnClick", function()
            SnapjawArchitect.GameObjectTurnToMe()
        end)

        action3:Show()
        action4:Show()
        action5:Show()
        modelLabel:Hide()
        modelBox:Hide()
        modelButton:Hide()

        statusText:ClearAllPoints()
        statusText:SetPoint("TOPLEFT", spawnButton, "BOTTOMLEFT", 2, -15)
        statusText:SetWidth(700)

        if SnapjawArchitect.selectedGameObjectGuid then
            statusText:SetText(
                "Selected GameObject GUID: " ..
                SnapjawArchitect.selectedGameObjectGuid
            )
        else
            statusText:SetText(
                "No GameObject selected. Use Select nearest first."
            )
        end
    else
        action1:SetText("NPC info")
        action1:SetScript("OnClick", function()
            SnapjawArchitect.NPCInfo()
        end)

        action2:SetText("Delete NPC")
        action2:SetScript("OnClick", function()
            SnapjawArchitect.NPCDelete()
        end)

        action3:Hide()
        action4:Hide()
        action5:Hide()
        modelLabel:Show()
        modelBox:Show()
        modelButton:Show()

        statusText:ClearAllPoints()
        statusText:SetPoint("LEFT", modelButton, "RIGHT", 18, 0)
        statusText:SetWidth(355)
        statusText:SetText(
            "Target an NPC before Info, Delete, or Set model."
        )
    end
end

frame:SetScript("OnShow", function()
    SnapjawArchitect.RefreshUI()
end)
