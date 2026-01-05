-- WoW Notepad Addon
-- A simple notepad with local storage

-- Initialize saved variables
NotepadDB = NotepadDB or { text = "" }

local frame = nil
local editBox = nil

-- Create the main notepad frame
local function CreateNotepadFrame()
    if frame then return frame end
    
    -- Main window frame
    frame = CreateFrame("Frame", "NotepadMainFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(500, 400)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    
    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("WoW Notepad")
    
    -- Create ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", "NotepadScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 45)
    
    -- Create EditBox
    editBox = CreateFrame("EditBox", "NotepadEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(450)
    editBox:SetHeight(400)
    editBox:SetMaxLetters(0)
    editBox:SetScript("OnEscapePressed", function(self) 
        self:ClearFocus() 
    end)
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            NotepadDB.text = self:GetText()
        end
    end)
    
    -- Set text color to white
    editBox:SetTextColor(1, 1, 1, 1)
    
    -- Connect scrollframe to editbox
    scrollFrame:SetScrollChild(editBox)
    
    -- Load saved text
    editBox:SetText(NotepadDB.text or "")
    editBox:SetCursorPosition(0)
    
    -- Clear button
    local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearButton:SetSize(80, 22)
    clearButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
    clearButton:SetText("Clear")
    clearButton:SetScript("OnClick", function()
        editBox:SetText("")
        NotepadDB.text = ""
        print("Notepad cleared!")
    end)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 22)
    closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    frame:Hide()
    return frame
end

-- Slash command to toggle notepad
SLASH_NOTEPAD1 = "/notepad"
SLASH_NOTEPAD2 = "/np"
SlashCmdList["NOTEPAD"] = function(msg)
    if not frame then
        frame = CreateNotepadFrame()
    end
    
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        if editBox then
            editBox:SetText(NotepadDB.text or "")
        end
    end
end

-- Initialize on load
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "wow-notepad" then
        print("WoW Notepad loaded! Type /notepad or /np to open.")
    end
end)
