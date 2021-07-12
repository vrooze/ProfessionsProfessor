ProfessionProfessor = LibStub("AceAddon-3.0"):NewAddon("ProfessionProfessor", "AceEvent-3.0", "AceConsole-3.0", "AceSerializer-3.0")

prof = ProfessionProfessor

local aceGUI = LibStub("AceGUI-3.0")

local allowedTradeskills = {
    "Alchemy",
    "Blacksmithing",
    "Enchanting",
    "Engineering",
    "Leatherworking",
    "Tailoring",
    "Jewelcrafting",
    "Cooking"
}

-- AceAddon :OnInitialize()
function prof:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ProfessionProfessorDB")

    -- Console commands
    prof:RegisterChatCommand("pro", "consoleCommands");

    -- Event registration
    -- Enchanting
    prof:RegisterEvent("CRAFT_UPDATE", "craftUpdate")
    -- Everything else
    prof:RegisterEvent("TRADE_SKILL_UPDATE", "tradeSkillUpdate")
end

local function hasValue(value)
    for i,v in ipairs(allowedTradeskills) do
        if v == value then
            return true
        end
    end
    return false
end

function prof:tradeSkillUpdate()
    local localisedName = GetTradeSkillLine()
    local numSkills = GetNumTradeSkills()
    updateProfessionDB(localisedName, numSkills)
end

function prof:craftUpdate()
    local localisedName = GetCraftDisplaySkillLine()
    local numSkills = GetNumCrafts()
    updateProfessionDB(localisedName, numSkills)
end

function updateProfessionDB(localisedName, numSkills)

    if localisedName == nil or localisedName == "UNKNOWN" then return end
    if hasValue(localisedName) == false then return end

    if type(prof.db.char.professions) == "table" then
        if prof.db.char.professions[localisedName] and prof.db.char.professions[localisedName]["numSkills"] >= numSkills then
            return
        end
    else
        prof.db.char.professions = {}
    end

    prof:Print("Updating database for " .. localisedName)

    local learnedIds = {}
    local amount = 0


    for i=1,numSkills do
        local _,skillType = getSkillInfo(localisedName, i) -- Need localization
        -- Skip the headers, only check real skills
        if skillType ~= "header" then
            local itemLink, id = getTradeSkillItemId(localisedName, i)
            prof:Print("Adding "  .. itemLink .. ' [' .. id .. ']')
            table.insert(learnedIds, id)
            amount = amount + 1
        end
    end
    if #learnedIds > 0 then
        prof.db.char.professions[localisedName] = {
            ["numSkills"] =  numSkills,
            ["realNumSkills"] = amount,
            ["learnedIds"] = learnedIds
        }
    end
end

function getSkillInfo(localisedName, i)
    if localisedName == "Enchanting" then
        return GetCraftInfo(i)
    else
        return GetTradeSkillInfo(i)
    end
end    

function getTradeSkillItemId(localisedName, i)
    local itemLink
    local returnid

    if localisedName == "Enchanting" then
        itemLink = GetCraftRecipeLink(i)
    else
        itemLink = GetTradeSkillRecipeLink(i)
    end
    returnid = itemLink:match("enchant:(%d+)")
    if returnid == nil then
        returnid = itemLink:match("item:(%d+)")
    end

    return itemLink, returnid
end

function prof:consoleCommands(input)
    if not input or input:trim() == "" then
        if self.db.char.professions and next(self.db.char.professions) ~= nil then
            showJson()
        else
            self:Print("Please open your professions windows to update the database, so there is something to export")
        end
    elseif input == "reset" then
        self.db.char.professions = {}
        self:Print("Data has been reset")
    elseif input == "print" then
        if self.db.char.professions then
            local output = "You have " .. countTable(self.db.char.professions) .. " saved"
            for k,v in pairs(self.db.char.professions) do
                output = output .. ", " .. k .. "(" .. self.db.char.professions[k]['realNumSkills'] .. ") "
            end
            self:Print(output)
        end
    end    
end

function showJson()
    -- Create a container frame
    local f = aceGUI:Create("Frame")
    f:SetCallback("OnClose",function(widget) aceGUI:Release(widget) end)
    f:SetTitle("Profession Professor Skill Checker - Export")
    f:SetLayout("Flow")

    local editBox = aceGUI:Create("MultiLineEditBox")
	editBox:SetWidth(800)
    editBox:SetHeight(500)
    editBox:SetText(convertTableToString())
    editBox:SetLabel("Copy text and paste into your discord channel with the Profession Professor bot with an !pp-upload in front of the text")
    editBox:SetNumLines(20)
    editBox:DisableButton(true)

    f:AddChild(editBox)
end

function countTable(tableName)
    local count = 0
    for _ in pairs(tableName) do
        count = count + 1
    end
    return count
end

function convertTableToString()
    local name,_ = UnitName("player")
    local faction,_ = UnitFactionGroup("player")

    local text = name .. ";" .. faction .. ";" .. GetRealmName() .. ";"

    for k,v in pairs(prof.db.char.professions) do
        text = text .. k .. ";"
        text = text .. getSkillString(k)
    end
    return text
end

function getSkillString(key)
    local profession = prof.db.char.professions[key]
    local realNumSkills = profession['realNumSkills']
    local list = profession['learnedIds']

    local text = ""

    for i = 1,realNumSkills do
        if list[i] ~= nil then
            text = text .. list[i] .. ";"
        end
    end

    return text
end