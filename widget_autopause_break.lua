function widget:GetInfo()
    return {
        name    = "Auto Pause Break Reminder",
        desc    = "Periodic stretch breaks with pause, countdown, and optional sound",
        author  = "szpak (AI assisted)",
        date    = "2025-12-28",
        license = "GPLv2+",
        layer   = 0,
        enabled = false, -- must be enabled once via F11
    }
end

------------------------------------------------------------
-- CONFIG (persisted by Spring)
------------------------------------------------------------

local config = {
    breakIntervalMinutes = 30,
    breakDurationMinutes = 2,
    soundEnabled = true,
}

------------------------------------------------------------
-- CONSTANTS
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

local nextBreakGameTime
local pauseStartTimer -- real timer
local pausedByWidget = false
local lastUpdate = 0
local countdownPlayed = {}

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

local function IsPaused()
    local _, _, paused = Spring.GetGameSpeed()
    return paused
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
-- LIFECYCLE
------------------------------------------------------------

function widget:Initialize()
    local now = Spring.GetGameSeconds()
    nextBreakGameTime = now + BreakIntervalSeconds()
end

function widget:Update(dt)
    lastUpdate = lastUpdate + dt
    if lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = 0

    local gameNow = Spring.GetGameSeconds()
    if not gameNow then return end

    --------------------------------------------------------
    -- Trigger break (game time)
    --------------------------------------------------------
    if gameNow >= nextBreakGameTime and not pauseStartTimer then
        Spring.Echo("🧘 Time to stretch! Recommended "
            .. config.breakDurationMinutes .. "-minute break.")
        PlayAlert()

        if not IsPaused() then
            Spring.SendCommands("pause 1")
            pausedByWidget = true
        else
            pausedByWidget = false
        end

        pauseStartTimer = Spring.GetTimer()
        countdownPlayed = {}
    end

    --------------------------------------------------------
    -- Countdown (real time)
    --------------------------------------------------------
    if pauseStartTimer then
        local elapsed = Spring.DiffTimers(Spring.GetTimer(), pauseStartTimer)
        local remaining = math.ceil(BreakDurationSeconds() - elapsed)

        if COUNTDOWN_SECONDS[remaining] and not countdownPlayed[remaining] then
            Spring.Echo("⏳ Resuming game in " .. remaining .. " seconds...")
            PlayAlert()
            countdownPlayed[remaining] = true
        end

        ----------------------------------------------------
        -- Resume
        ----------------------------------------------------
        if elapsed >= BreakDurationSeconds() then
            if pausedByWidget and IsPaused() then
                Spring.SendCommands("pause 0")
                Spring.Echo("🎮 Break over! Game resumed.")
            end

            pauseStartTimer = nil
            pausedByWidget = false
            countdownPlayed = {}
            nextBreakGameTime = gameNow + BreakIntervalSeconds()
        end
    end
end

