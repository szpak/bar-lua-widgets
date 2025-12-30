function widget:GetInfo()
    return {
        name    = "Auto Pause Break Reminder",
        desc    = "Pauses the game periodically for stretch breaks with optional sound alerts",
        author  = "szpak (AI assisted)",
        date    = "2025-12-28",
        license = "GPLv2+",
        layer   = 0,
        enabled = true
    }
end

------------------------------------------------------------
-- DEFAULT CONFIG (user configurable)
------------------------------------------------------------

local config = {
    breakIntervalMinutes = 30, -- minutes
    breakDurationMinutes = 2,  -- minutes
    soundEnabled         = true,
}

------------------------------------------------------------
-- INTERNAL CONSTANTS
------------------------------------------------------------

local UPDATE_INTERVAL = 1 -- seconds
local ALERT_SOUND = "LuaUI/Sounds/beep4.wav"

local COUNTDOWN_SECONDS = {
    [10] = true,
    [5]  = true,
    [3]  = true,
    [2]  = true,
    [1]  = true,
}

------------------------------------------------------------
-- STATE
------------------------------------------------------------

local nextBreakTime
local pauseStartTime
local pausedByWidget = false
local lastUpdate = 0
local countdownPlayed = {}

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

local function IsPauseAllowed()
    return Spring.GetGameRulesParam("pauseAllowed") == 1
end

local function PlayAlert()
    if config.soundEnabled then
        Spring.PlaySoundFile(ALERT_SOUND, 1.0)
    end
end

local function BreakIntervalSeconds()
    return math.max(1, config.breakIntervalMinutes) * 60
end

local function BreakDurationSeconds()
    return math.max(1, config.breakDurationMinutes) * 60
end

------------------------------------------------------------
-- CONFIG PERSISTENCE
------------------------------------------------------------

function widget:GetConfigData()
    return config
end

function widget:SetConfigData(data)
    if type(data) ~= "table" then return end

    if type(data.breakIntervalMinutes) == "number" then
        config.breakIntervalMinutes = data.breakIntervalMinutes
    end

    if type(data.breakDurationMinutes) == "number" then
        config.breakDurationMinutes = data.breakDurationMinutes
    end

    if type(data.soundEnabled) == "boolean" then
        config.soundEnabled = data.soundEnabled
    end
end

------------------------------------------------------------
-- WIDGET LIFECYCLE
------------------------------------------------------------

function widget:Initialize()
    local now = Spring.GetGameSeconds()
    nextBreakTime = now + BreakIntervalSeconds()
end

function widget:Update(dt)
    lastUpdate = lastUpdate + dt
    if lastUpdate < UPDATE_INTERVAL then
        return
    end
    lastUpdate = 0

    local now = Spring.GetGameSeconds()
    if not now then return end

    --------------------------------------------------------
    -- Trigger break
    --------------------------------------------------------
    if now >= nextBreakTime and not pauseStartTime then
        Spring.Echo("🧘 Time to stretch! Recommended " ..
            config.breakDurationMinutes .. "-minute break.")
        PlayAlert()

        if IsPauseAllowed() then
            if not Spring.IsPaused() then
                Spring.SendCommands("pause 1")
                pausedByWidget = true
                pauseStartTime = now
                Spring.Echo("⏸ Game paused for your break.")
            else
                pauseStartTime = now
                pausedByWidget = false
            end
        else
            Spring.Echo("⚠ Pause not allowed in this game. Please consider taking a short break anyway!")
            pauseStartTime = now
            pausedByWidget = false
        end

        countdownPlayed = {}
    end

    --------------------------------------------------------
    -- Countdown warnings
    --------------------------------------------------------
    if pauseStartTime then
        local remaining =
            math.ceil(BreakDurationSeconds() - (now - pauseStartTime))

        if COUNTDOWN_SECONDS[remaining] and not countdownPlayed[remaining] then
            Spring.Echo("⏳ Resuming game in " .. remaining .. " seconds...")
            PlayAlert()
            countdownPlayed[remaining] = true
        end
    end

    --------------------------------------------------------
    -- Resume
    --------------------------------------------------------
    if pauseStartTime and (now - pauseStartTime >= BreakDurationSeconds()) then
        if pausedByWidget and Spring.IsPaused() then
            Spring.SendCommands("pause 0")
            Spring.Echo("🎮 Break over! Game resumed.")
        end

        pauseStartTime = nil
        pausedByWidget = false
        countdownPlayed = {}
        nextBreakTime = now + BreakIntervalSeconds()
    end
end

