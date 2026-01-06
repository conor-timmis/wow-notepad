-- WoW Notepad Addon
-- A clean, flat UI notepad with multiple note support

-- ============================================================================
-- Namespace and Constants
-- ============================================================================

local ADDON_NAME = "wow-notepad"
local Notepad = {}

-- Initialize saved variables
NotepadDB = NotepadDB or {
    notes = {},
    selectedNote = nil,
    nextID = 1
}

-- Constants
local CONSTANTS = {
    WINDOW_WIDTH = 750,
    WINDOW_HEIGHT = 500,
    TITLE_BAR_HEIGHT = 32,
    LEFT_PANEL_WIDTH = 190,
    RIGHT_PANEL_WIDTH = 532,
    PANEL_HEIGHT = 423,
    PANEL_PADDING = 8,
    NOTE_BUTTON_WIDTH = 135,
    NOTE_BUTTON_HEIGHT = 32,
    DELETE_BUTTON_WIDTH = 28,
    NOTE_BUTTON_SPACING = 37,
    BORDER_WIDTH = 1,
    SCROLL_STEP = 20,
}

-- Color scheme
local COLORS = {
    bg = {0.05, 0.05, 0.05, 0.95},
    panel = {0.1, 0.1, 0.1, 1},
    button = {0.15, 0.15, 0.15, 1},
    buttonHover = {0.2, 0.2, 0.2, 1},
    buttonSelected = {0.25, 0.35, 0.5, 1},
    border = {0.3, 0.3, 0.3, 1},
    text = {1, 1, 1, 1},
    textDim = {0.7, 0.7, 0.7, 1},
    deleteButton = {0.6, 0.1, 0.1, 1},
    deleteButtonHover = {0.9, 0.2, 0.2, 1},
    titleBar = {0.08, 0.08, 0.08, 1},
}

-- State
local State = {
    frame = nil,
    editBox = nil,
    currentNoteID = nil,
    noteButtons = {},
    deleteButtons = {},
}

-- ============================================================================
-- Database Helper Functions
-- ============================================================================

local Database = {}

function Database.Initialize()
    NotepadDB.nextID = NotepadDB.nextID or 1
    NotepadDB.notes = NotepadDB.notes or {}
    NotepadDB.selectedNote = NotepadDB.selectedNote or nil
end

function Database.CreateNote(name, text)
    local noteID = NotepadDB.nextID
    NotepadDB.nextID = NotepadDB.nextID + 1
    
    NotepadDB.notes[noteID] = {
        name = name or ("Note " .. noteID),
        text = text or "",
        created = time(),
        lastModified = time()
    }
    
    return noteID
end

function Database.GetNote(noteID)
    return NotepadDB.notes[noteID]
end

function Database.UpdateNoteText(noteID, text)
    local note = NotepadDB.notes[noteID]
    if note then
        note.text = text
        note.lastModified = time()
    end
end

function Database.UpdateNoteName(noteID, name)
    local note = NotepadDB.notes[noteID]
    if note then
        note.name = name
    end
end

function Database.DeleteNote(noteID)
    NotepadDB.notes[noteID] = nil
end

function Database.GetSortedNotes()
    local sortedNotes = {}
    for id, note in pairs(NotepadDB.notes) do
        table.insert(sortedNotes, {id = id, note = note})
    end
    table.sort(sortedNotes, function(a, b)
        return (a.note.created or 0) < (b.note.created or 0)
    end)
    return sortedNotes
end

function Database.HasNotes()
    return next(NotepadDB.notes) ~= nil
end

function Database.CreateDefaultNote()
    return Database.CreateNote(
        "My First Note",
        "Welcome to WoW Notepad!\n\nClick here to start typing..."
    )
end

-- ============================================================================
-- UI Component Factory
-- ============================================================================

local UIFactory = {}

function UIFactory.CreateFlatButton(parent, width, height, text)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, height)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetHitRectInsets(0, 0, 0, 0)
    
    -- Background
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(unpack(COLORS.button))
    
    -- Create border
    UIFactory.AddBorderToFrame(btn)
    
    -- Text
    btn.text = btn:CreateFontString(nil, "OVERLAY")
    btn.text:SetFont("Fonts\\FRIZQT__.TTF", 12)
    btn.text:SetPoint("CENTER", 0, 0)
    btn.text:SetText(text or "")
    btn.text:SetTextColor(unpack(COLORS.text))
    btn.text:SetJustifyH("CENTER")
    btn.text:SetJustifyV("MIDDLE")
    btn.text:SetWordWrap(false)
    
    -- Method to update button text
    function btn:SetButtonText(newText)
        self.text:SetText(newText or "")
    end
    
    -- Hover effects
    UIFactory.AddHoverEffect(btn)
    
    return btn
end

function UIFactory.AddBorderToFrame(frame)
    frame.border = {}
    local borderSize = CONSTANTS.BORDER_WIDTH
    
    -- Top border
    frame.border[1] = frame:CreateTexture(nil, "ARTWORK")
    frame.border[1]:SetColorTexture(unpack(COLORS.border))
    frame.border[1]:SetPoint("TOPLEFT", frame, "TOPLEFT")
    frame.border[1]:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
    frame.border[1]:SetHeight(borderSize)
    
    -- Bottom border
    frame.border[2] = frame:CreateTexture(nil, "ARTWORK")
    frame.border[2]:SetColorTexture(unpack(COLORS.border))
    frame.border[2]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
    frame.border[2]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
    frame.border[2]:SetHeight(borderSize)
    
    -- Left border
    frame.border[3] = frame:CreateTexture(nil, "ARTWORK")
    frame.border[3]:SetColorTexture(unpack(COLORS.border))
    frame.border[3]:SetPoint("TOPLEFT", frame, "TOPLEFT")
    frame.border[3]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
    frame.border[3]:SetWidth(borderSize)
    
    -- Right border
    frame.border[4] = frame:CreateTexture(nil, "ARTWORK")
    frame.border[4]:SetColorTexture(unpack(COLORS.border))
    frame.border[4]:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
    frame.border[4]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
    frame.border[4]:SetWidth(borderSize)
end

function UIFactory.AddHoverEffect(button)
    button:SetScript("OnEnter", function(self)
        if not self.selected then
            self.bg:SetColorTexture(unpack(COLORS.buttonHover))
        end
    end)
    
    button:SetScript("OnLeave", function(self)
        if not self.selected then
            self.bg:SetColorTexture(unpack(COLORS.button))
        end
    end)
end

-- ============================================================================
-- Note Management
-- ============================================================================

local NoteManager = {}

function NoteManager.SaveCurrent()
    if State.currentNoteID and State.editBox then
        local text = State.editBox:GetText()
        Database.UpdateNoteText(State.currentNoteID, text)
    end
end

function NoteManager.Load(noteID)
    NoteManager.SaveCurrent()
    
    local note = Database.GetNote(noteID)
    if not note then return end
    
    State.currentNoteID = noteID
    NotepadDB.selectedNote = noteID
    
    -- Update editor
    if State.editBox then
        State.editBox:SetText(note.text or "")
        State.editBox:SetCursorPosition(0)
        -- Auto-focus for better UX
        C_Timer.After(0.1, function()
            if State.editBox then
                State.editBox:SetFocus()
            end
        end)
    end
    
    -- Update button visuals
    NoteManager.UpdateButtonSelection(noteID)
end

function NoteManager.UpdateButtonSelection(selectedNoteID)
    for id, btn in pairs(State.noteButtons) do
        if id == selectedNoteID then
            btn.bg:SetColorTexture(unpack(COLORS.buttonSelected))
            btn.selected = true
        else
            btn.bg:SetColorTexture(unpack(COLORS.button))
            btn.selected = false
        end
    end
end

function NoteManager.Delete(noteID)
    Database.DeleteNote(noteID)
    
    if State.currentNoteID == noteID then
        State.currentNoteID = nil
        if State.editBox then
            State.editBox:SetText("")
        end
    end
    
    NoteManager.RefreshList(State.frame.noteListContainer)
end

function NoteManager.Rename(noteID, newName)
    if newName and newName ~= "" then
        Database.UpdateNoteName(noteID, newName)
        NoteManager.RefreshList(State.frame.noteListContainer)
    end
end

function NoteManager.Create()
    local noteID = Database.CreateNote()
    NoteManager.RefreshList(State.frame.noteListContainer)
    NoteManager.Load(noteID)
end

-- ============================================================================
-- UI List Management
-- ============================================================================

local ListUI = {}

function ListUI.ClearButtons()
    for _, btn in pairs(State.noteButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    State.noteButtons = {}
    
    for _, btn in pairs(State.deleteButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    State.deleteButtons = {}
end

function ListUI.CreateNoteButton(container, noteID, note, yOffset)
    local btn = UIFactory.CreateFlatButton(
        container,
        CONSTANTS.NOTE_BUTTON_WIDTH,
        CONSTANTS.NOTE_BUTTON_HEIGHT,
        note.name or "Untitled"
    )
    btn:SetPoint("TOPLEFT", container, "TOPLEFT", 5, yOffset)
    btn:Show()
    
    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            NoteManager.Load(noteID)
        elseif button == "RightButton" then
            StaticPopup_Show("NOTEPAD_RENAME", note.name, nil, noteID)
        end
    end)
    
    return btn
end

function ListUI.CreateDeleteButton(container, noteID, noteButton)
    local deleteBtn = CreateFrame("Button", nil, container)
    deleteBtn:SetSize(CONSTANTS.DELETE_BUTTON_WIDTH, CONSTANTS.NOTE_BUTTON_HEIGHT)
    deleteBtn:SetPoint("LEFT", noteButton, "RIGHT", 2, 0)
    deleteBtn:EnableMouse(true)
    deleteBtn:RegisterForClicks("LeftButtonUp")
    deleteBtn:Show()
    
    -- Background
    deleteBtn.bg = deleteBtn:CreateTexture(nil, "BACKGROUND")
    deleteBtn.bg:SetAllPoints()
    deleteBtn.bg:SetColorTexture(unpack(COLORS.deleteButton))
    
    -- X text
    deleteBtn.text = deleteBtn:CreateFontString(nil, "OVERLAY")
    deleteBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    deleteBtn.text:SetPoint("CENTER")
    deleteBtn.text:SetText("×")
    deleteBtn.text:SetTextColor(unpack(COLORS.text))
    
    -- Hover effect
    deleteBtn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(unpack(COLORS.deleteButtonHover))
    end)
    
    deleteBtn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(unpack(COLORS.deleteButton))
    end)
    
    deleteBtn:SetScript("OnClick", function(self)
        StaticPopup_Show("NOTEPAD_DELETE_CONFIRM", nil, nil, noteID)
    end)
    
    return deleteBtn
end

function NoteManager.RefreshList(container)
    ListUI.ClearButtons()
    
    local sortedNotes = Database.GetSortedNotes()
    local yOffset = 0
    
    for _, data in ipairs(sortedNotes) do
        local noteID = data.id
        local note = data.note
        
        local noteBtn = ListUI.CreateNoteButton(container, noteID, note, yOffset)
        local deleteBtn = ListUI.CreateDeleteButton(container, noteID, noteBtn)
        
        State.noteButtons[noteID] = noteBtn
        State.deleteButtons[noteID] = deleteBtn
        
        yOffset = yOffset - CONSTANTS.NOTE_BUTTON_SPACING
    end
    
    -- Auto-select first note if none selected
    if State.currentNoteID == nil and #sortedNotes > 0 then
        NoteManager.Load(sortedNotes[1].id)
    elseif State.currentNoteID then
        NoteManager.Load(State.currentNoteID)
    end
end

-- ============================================================================
-- Dialog Definitions
-- ============================================================================

local function InitializeDialogs()
    StaticPopupDialogs["NOTEPAD_RENAME"] = {
        text = "Rename note '%s':",
        button1 = "Rename",
        button2 = "Delete",
        button3 = "Cancel",
        hasEditBox = true,
        OnShow = function(self, data)
            local note = Database.GetNote(data)
            if note then
                self.editBox:SetText(note.name)
                self.editBox:HighlightText()
            end
        end,
        OnButton1 = function(self, data)
            local newName = self.editBox:GetText()
            NoteManager.Rename(data, newName)
        end,
        OnButton2 = function(self, data)
            StaticPopup_Show("NOTEPAD_DELETE_CONFIRM", nil, nil, data)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs["NOTEPAD_DELETE_CONFIRM"] = {
        text = "Are you sure you want to delete this note?",
        button1 = "Delete",
        button2 = "Cancel",
        OnAccept = function(self, data)
            NoteManager.Delete(data)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

-- ============================================================================
-- Main Frame Construction
-- ============================================================================

local FrameBuilder = {}

function FrameBuilder.CreateMainWindow()
    local frame = CreateFrame("Frame", "NotepadMainFrame", UIParent)
    frame:SetSize(CONSTANTS.WINDOW_WIDTH, CONSTANTS.WINDOW_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    
    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(unpack(COLORS.bg))
    
    return frame
end

function FrameBuilder.CreateTitleBar(parent)
    local titleBar = CreateFrame("Frame", nil, parent)
    titleBar:SetSize(CONSTANTS.WINDOW_WIDTH, CONSTANTS.TITLE_BAR_HEIGHT)
    titleBar:SetPoint("TOP", parent, "TOP", 0, 0)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() parent:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() parent:StopMovingOrSizing() end)
    
    -- Background
    titleBar.bg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBar.bg:SetAllPoints()
    titleBar.bg:SetColorTexture(unpack(COLORS.titleBar))
    
    -- Title text
    local title = parent:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    title:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    title:SetText("WoW Notepad")
    title:SetTextColor(unpack(COLORS.text))
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -4, 0)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeBtn:SetScript("OnClick", function()
        NoteManager.SaveCurrent()
        parent:Hide()
    end)
    
    return titleBar
end

function FrameBuilder.CreateLeftPanel(parent)
    local leftPanel = CreateFrame("Frame", nil, parent)
    leftPanel:SetSize(CONSTANTS.LEFT_PANEL_WIDTH, CONSTANTS.PANEL_HEIGHT)
    leftPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", CONSTANTS.PANEL_PADDING, -40)
    
    leftPanel.bg = leftPanel:CreateTexture(nil, "BACKGROUND")
    leftPanel.bg:SetAllPoints()
    leftPanel.bg:SetColorTexture(unpack(COLORS.panel))
    
    -- Container for note list
    local noteListContainer = CreateFrame("Frame", nil, leftPanel)
    noteListContainer:SetSize(170, 375)
    noteListContainer:SetPoint("TOP", leftPanel, "TOP", 0, -48)
    noteListContainer:Show()
    
    -- New note button
    local newNoteBtn = UIFactory.CreateFlatButton(leftPanel, 170, 28, "+ New Note")
    newNoteBtn:SetPoint("TOP", leftPanel, "TOP", 0, -10)
    newNoteBtn:SetFrameLevel(leftPanel:GetFrameLevel() + 10)
    
    -- Custom hover effect for new note button
    newNoteBtn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.3, 0.3, 0.3, 1)
    end)
    
    newNoteBtn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(unpack(COLORS.button))
    end)
    
    newNoteBtn:SetScript("OnClick", function()
        NoteManager.Create()
    end)
    
    return leftPanel, noteListContainer
end

function FrameBuilder.CreateEditor(parent)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -25, 45)
    
    -- Create EditBox
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(490)
    editBox:SetHeight(1000)  -- Large height for scrolling
    editBox:SetMaxLetters(0)
    editBox:SetTextColor(unpack(COLORS.text))
    editBox:EnableMouse(true)
    
    editBox:SetScript("OnEscapePressed", function(self) 
        self:ClearFocus() 
    end)
    
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput and State.currentNoteID then
            NoteManager.SaveCurrent()
        end
    end)
    
    editBox:SetScript("OnMouseDown", function(self)
        self:SetFocus()
    end)
    
    scrollFrame:SetScrollChild(editBox)
    scrollFrame:EnableMouse(true)
    
    return scrollFrame, editBox
end

function FrameBuilder.CreateScrollbar(scrollFrame)
    local scrollBar = CreateFrame("Slider", nil, scrollFrame)
    scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 15, -5)
    scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 15, 5)
    scrollBar:SetWidth(12)
    scrollBar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetMinMaxValues(0, 100)
    scrollBar:SetValue(0)
    scrollBar:EnableMouseWheel(true)
    
    scrollBar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)
    
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollBar:GetValue()
        local min, max = scrollBar:GetMinMaxValues()
        if delta < 0 and current < max then
            scrollBar:SetValue(math.min(max, current + CONSTANTS.SCROLL_STEP))
        elseif delta > 0 and current > min then
            scrollBar:SetValue(math.max(min, current - CONSTANTS.SCROLL_STEP))
        end
    end)
    
    scrollFrame:SetScript("OnScrollRangeChanged", function(self, xRange, yRange)
        scrollBar:SetMinMaxValues(0, yRange)
    end)
    
    return scrollBar
end

function FrameBuilder.CreateRightPanel(parent)
    local rightPanel = CreateFrame("Frame", nil, parent)
    rightPanel:SetSize(CONSTANTS.RIGHT_PANEL_WIDTH, CONSTANTS.PANEL_HEIGHT)
    rightPanel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -CONSTANTS.PANEL_PADDING, -40)
    
    rightPanel.bg = rightPanel:CreateTexture(nil, "BACKGROUND")
    rightPanel.bg:SetAllPoints()
    rightPanel.bg:SetColorTexture(unpack(COLORS.panel))
    
    -- Editor with scrolling
    local scrollFrame, editBox = FrameBuilder.CreateEditor(rightPanel)
    FrameBuilder.CreateScrollbar(scrollFrame)
    
    -- Bottom buttons
    local clearBtn = UIFactory.CreateFlatButton(rightPanel, 80, 28, "Clear")
    clearBtn:SetPoint("BOTTOMLEFT", rightPanel, "BOTTOMLEFT", 10, 10)
    clearBtn:SetScript("OnClick", function()
        if State.currentNoteID then
            editBox:SetText("")
            NoteManager.SaveCurrent()
        end
    end)
    
    local saveBtn = UIFactory.CreateFlatButton(rightPanel, 80, 28, "Save")
    saveBtn:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -10, 10)
    saveBtn:SetScript("OnClick", function()
        NoteManager.SaveCurrent()
    end)
    
    -- Info text
    local infoText = rightPanel:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Fonts\\FRIZQT__.TTF", 10)
    infoText:SetPoint("BOTTOM", rightPanel, "BOTTOM", 0, 15)
    infoText:SetText("Left-click notes to edit | Right-click to rename | Click × to delete")
    infoText:SetTextColor(unpack(COLORS.textDim))
    
    return rightPanel, editBox
end

function FrameBuilder.Build()
    if State.frame then return State.frame end
    
    local frame = FrameBuilder.CreateMainWindow()
    frame.titleBar = FrameBuilder.CreateTitleBar(frame)
    frame.leftPanel, frame.noteListContainer = FrameBuilder.CreateLeftPanel(frame)
    frame.rightPanel, State.editBox = FrameBuilder.CreateRightPanel(frame)
    
    -- Create default note if none exist
    if not Database.HasNotes() then
        Database.CreateDefaultNote()
    end
    
    NoteManager.RefreshList(frame.noteListContainer)
    
    frame:Hide()
    return frame
end

-- ============================================================================
-- Public Interface
-- ============================================================================

function Notepad.Toggle()
    if not State.frame then
        State.frame = FrameBuilder.Build()
    end
    
    if State.frame:IsShown() then
        NoteManager.SaveCurrent()
        State.frame:Hide()
    else
        State.frame:Show()
    end
end

function Notepad.Initialize()
    Database.Initialize()
    InitializeDialogs()
end

function Notepad.OnLogout()
    NoteManager.SaveCurrent()
end

-- ============================================================================
-- Slash Commands
-- ============================================================================

SLASH_NOTEPAD1 = "/notepad"
SLASH_NOTEPAD2 = "/np"
SlashCmdList["NOTEPAD"] = function(msg)
    Notepad.Toggle()
end

-- ============================================================================
-- Event Handling
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON_NAME then
        Notepad.Initialize()
    elseif event == "PLAYER_LOGOUT" then
        Notepad.OnLogout()
    end
end)
