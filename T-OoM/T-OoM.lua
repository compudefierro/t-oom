--[[
T-OoM - is a simple Out of Mana announcer addon for Turtle WoW.
T-OoM - это простой аддон для объявления об окончании маны для сервера Turtle WoW.

Addon GitHub link: https://github.com/whtmst/t-oom

Author: Mikhail Palagin (Wht Mst)
Website: https://band.link/whtmst
--]]

-- 20250428: Added a list of messages that are chosen randomly
-- 20250429: Added different channels SAY, PARTY and YELL between % of mana

-- MESSAGES
local lowManaMsg = {
    "--- POCO MANA --- 30%",
    "Mana bajando! 30%",
    "Demasiada Sangre!!!: Mana al 30%",
    "Modo Ahorro de Mana Activado! 30%",
	"Ese Compa ya esta muerto... 30%"
}

local criticalLowManaMsg = {
    "--- MUY POCO MANA --- 15%",
    "Mana bajo: niveles de fe incrementado! 15%",
    "Mana bajando: mejor un ibuprofeno y a la cama! 15%",
    "Vamos a palmar!! ahhhhhh mana muy bajo!  Mana 15%",
	"Corre perra correeeeeee!!! Mana 15%"
}

local outOfManaMessage = {
    "Solo Dios revivio de entre los muertos... Mana: 5%",
    "Ese compa ya esta muerto...! Mana 5%",
    "Sin mana... me hubiera creado un Warrior... 5%!",
    "Y dónde esta tu Dios ahora?! Mana 5%",
    "Todos vamos a morir!!! Mana: 5%"
}

-- SETTINGS (НАСТРОЙКИ)
local chatChannel = "YELL"  -- You can change the channel, for example, to "PARTY" or "RAID" (channel for sending messages) (Вы можете изменить чат, например, на "PARTY" или "RAID" (чат для отправки сообщений))
local lowManaThreshold1 = 0.30 -- Threshold 30% of mana (Порог 30% маны)
local lowManaThreshold2 = 0.15 -- Threshold 15% of mana (Порог 15% маны)
local lowManaThreshold3 = 0.05 -- Threshold 5% of mana (Порог 5% маны)
local messageDuration = 3  -- Message display duration in seconds (Время отображения сообщения в секундах)
local fontSize = 96  -- Font size for the custom message (Размер шрифта для собственного сообщения)
local frameColor = {0, 0, 0, 0}  -- Frame color with transparency (Цвет фрейма с прозрачностью)
local fontColor = {1, 1, 1, 1}  -- Font color with transparency (Цвет шрифта с прозрачностью)
local fontPath = "Interface\\AddOns\\T-OoM\\Fonts\\ARIALN.ttf"  -- File path to the custom font (Путь к файлу собственного шрифта)

-- Set to true to enable the respective instance type (Установите true, чтобы включить соответствующий тип инстанса)
local instanceTypeOptions = { 
    none = false, -- When outside an instance (В открытом мире)
    party = true, -- In 5-man instances (В подземельях на 5-человек)
    raid = false, -- In raid instances (В рейдах)
    arena = false, -- In arenas (На арене)
    pvp = false, -- In battlegrounds (На полях боя)
    scenario = false -- In scenarios (В сценариях)
}

-- MAIN CODE (ОСНОВНОЙ КОД)
local T_OoM = CreateFrame("Frame")

-- Initialize variables (Инициализация переменных)
local customFrame
local currentMessage = ""
local lastUpdateTime = 0
local lastManaPercentage = 0
local inInstance = false
local instanceType = ""

-- Get random message
local function GetRandomMessage(messageList)
    if type(messageList) ~= "table" then return "" end

    local count = 0
    for _, _ in ipairs(messageList) do
        count = count + 1
    end

    if count == 0 then return "" end

    local randomIndex = math.random(1, count)
    return messageList[randomIndex]
end

-- Create a custom frame (Создание собственного фрейма)
local function CreateCustomFrame()
    customFrame = CreateFrame("Frame", "CustomMessageFrame", UIParent)
    customFrame:SetWidth(400)
    customFrame:SetHeight(100)
    customFrame:SetPoint("CENTER", 0, 200)

    -- Create a background with transparency (Создание фона с прозрачностью)
    local background = customFrame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(customFrame)
    background:SetTexture(unpack(frameColor))

    -- Create a font string for text (Создание текстовой области для текста)
    local text = customFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetFont(fontPath, fontSize, "OUTLINE")
    text:SetTextColor(unpack(fontColor))
    text:SetAllPoints(customFrame)
    customFrame.text = text

    customFrame:Hide()
end

-- Show a custom message (Показать собственное сообщение)
local function ShowCustomMessage(message)
    if not customFrame then
        CreateCustomFrame()
    end

    if customFrame.text then
        customFrame.text:SetText(message)
        currentMessage = message
        customFrame:Show()
        lastUpdateTime = GetTime()
    end
end

-- Hide the custom message frame (Скрыть фрейм с сообщением)
local function HideCustomMessage()
    if customFrame and currentMessage ~= "" then
        customFrame:Hide()
        currentMessage = ""
    end
end

-- On player login (При входе игрока)
local function OnPlayerLogin()
    local title = GetAddOnMetadata("T-OoM", "Title")
    local notes = GetAddOnMetadata("T-OoM", "Notes")
    local loaded = title .. " - |cFF00FF00Successfully loaded!|r"
    local message = notes

    DEFAULT_CHAT_FRAME:AddMessage(loaded)
    DEFAULT_CHAT_FRAME:AddMessage(message)
end

-- World/Instance/Graveyard entering or leaves function (Функция входа/выхода игрока в мир, инстанс или на кладбище)
local function OnEnteringWorld()
	inInstance, instanceType = IsInInstance()

	--[[ DEBUG MESSAGE
	if inInstance then
		print("--- YOU ARE IN AN INSTANCE NOW ---")
		print("--- INSTANCE TYPE: " .. instanceType .. " ---")
	else
		print("--- YOU ARE IN AN OUTDOOR NOW ---")
	end
	--]]
end

-- Update function (Функция обновления)
T_OoM:SetScript("OnUpdate", function()
    local unit = "player"
    local powerType = UnitPowerType(unit)
    local powerToken = (powerType == 0) and "MANA" or "UNKNOWN"
    local currentMana = UnitMana(unit)
    local maxMana = UnitManaMax(unit)
    local manaPercentage = currentMana / maxMana

    if instanceTypeOptions[instanceType] then
        if powerToken == "MANA" then
            if manaPercentage <= lowManaThreshold3 and lastManaPercentage > lowManaThreshold3 then
				msg = GetRandomMessage(outOfManaMessage)
				local chatChannel = "YELL"
				SendChatMessage(msg, chatChannel)
				ShowCustomMessage(msg)
            elseif manaPercentage <= lowManaThreshold2 and manaPercentage > lowManaThreshold3 and lastManaPercentage > lowManaThreshold2 then
                msg = GetRandomMessage(criticalLowManaMsg)
				local chatChannel = "PARTY"
				SendChatMessage(msg, chatChannel)
				ShowCustomMessage(msg)
            elseif manaPercentage <= lowManaThreshold1 and manaPercentage > lowManaThreshold2 and lastManaPercentage > lowManaThreshold1 then
                msg = GetRandomMessage(lowManaMsg)
				local chatChannel = "SAY"
				SendChatMessage(msg, chatChannel)
				ShowCustomMessage(msg)
            end
        else
            HideCustomMessage()
        end
    else
        if powerToken == "MANA" then
            if manaPercentage <= lowManaThreshold3 and lastManaPercentage > lowManaThreshold3 then
                ShowCustomMessage(GetRandomMessage(outOfManaMessage))
            elseif manaPercentage <= lowManaThreshold2 and manaPercentage > lowManaThreshold3 and lastManaPercentage > lowManaThreshold2 then
                ShowCustomMessage(GetRandomMessage(criticalLowManaMsg))
            elseif manaPercentage <= lowManaThreshold1 and manaPercentage > lowManaThreshold2 and lastManaPercentage > lowManaThreshold1 then
                ShowCustomMessage(GetRandomMessage(lowManaMsg))
            end
        else
            HideCustomMessage()
        end
    end

    if currentMessage ~= "" and GetTime() - lastUpdateTime >= messageDuration then
        HideCustomMessage()
    end

    lastManaPercentage = manaPercentage
end)

-- Register events (Регистрация событий)
T_OoM:RegisterEvent("PLAYER_LOGIN")
T_OoM:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Set event handlers (Установка обработчиков событий)
T_OoM:SetScript("OnEvent", function()
    if event == "PLAYER_LOGIN" then
        OnPlayerLogin()
		-- print("Event 'PLAYER_LOGIN' handled")
    elseif event == "PLAYER_ENTERING_WORLD" then
        OnEnteringWorld()
		-- print("Event 'PLAYER_ENTERING_WORLD' handled")
    end
end)
