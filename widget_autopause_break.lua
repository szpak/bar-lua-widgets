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
-- CONFIG
------------------------------------------------------------

local config = {
    breakIntervalMinutes = 30,
    breakDurationMinutes = 2,
    soundEnabled = true,
}

------------------------------------------------------------
-- CONSTANTS
------------------------------------------------------------

local UPDATE_INTERVAL = 1

-- BAR / Recoil compatible sound
local ALERT_SOUND = "LuaUI/Sounds/pop.wav"

local COUNTDOWN_SECONDS = {
    [10] = true,
    [5]  = true,
    [3]  = true,
    [2]  = true,
    [1]  = true,
}

-- Countdown seconds announced to all players
local MULTI_CHAT_COUNTDOWN = {
    [10] = true,
    [1]  = true,
}

local CHAT_PREFIX = "[AutoBreak] "

------------------------------------------------------------
-- STATE
------------------------------------------------------------

local nextBreakGameTime
local pauseStartTimer
local manualPauseTimer
local pausedByWidget = false
local wasPausedLastUpdate = false
local lastUpdate = 0
local countdownPlayed = {}
local gameStartAnnounced = false

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

    Spring.Echo(
        "🧘 AutoBreak enabled: every "
        .. config.breakIntervalMinutes .. " min, "
        .. config.breakDurationMinutes .. " min breaks"
        .. (config.soundEnabled and " (sound on)" or " (sound off)")
    )
end

function widget:Update(dt)
    lastUpdate = lastUpdate + dt
    if lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = 0

    local gameNow = Spring.GetGameSeconds()
    if not gameNow then return end

    local pausedNow = IsPaused()

    --------------------------------------------------------
    -- Announce widget once game actually starts
    --------------------------------------------------------

    if not gameStartAnnounced and gameNow > 0 then
        Spring.SendCommands(
            "say " .. CHAT_PREFIX ..
            "Active: breaks every "
            .. config.breakIntervalMinutes .. " min, duration "
            .. config.breakDurationMinutes .. " min"
        )
        gameStartAnnounced = true
    end

    --------------------------------------------------------
    -- Manual pause detection
    --------------------------------------------------------

    if pausedNow and not wasPausedLastUpdate and not pausedByWidget then
        manualPauseTimer = Spring.GetTimer()
    end

    if not pausedNow and wasPausedLastUpdate and manualPauseTimer then
        local manualPauseDuration =
            Spring.DiffTimers(Spring.GetTimer(), manualPauseTimer)

        if manualPauseDuration >= BreakDurationSeconds() then
            nextBreakGameTime = gameNow + BreakIntervalSeconds()
            Spring.Echo("🧘 Manual pause counted as a break. Next reminder reset.")
        end

        manualPauseTimer = nil
    end

    --------------------------------------------------------
    -- Trigger break
    --------------------------------------------------------

    if gameNow >= nextBreakGameTime and not pauseStartTimer then
        Spring.Echo("🧘 Time to stretch! Recommended "
            .. config.breakDurationMinutes .. "-minute break.")
        PlayAlert()

        if not pausedNow then
            Spring.SendCommands("pause 1")

            -- Pause/unpause commands are applied asynchronously by the engine.
            -- Exit this Update() to avoid acting on stale pause state.
            pausedByWidget = true
            pauseStartTimer = Spring.GetTimer()
            countdownPlayed = {}

            Spring.SendCommands(
                "say " .. CHAT_PREFIX ..
                "Stretch break started ("
                .. config.breakDurationMinutes .. " min)"
            )
            return
        else
            pausedByWidget = false
            pauseStartTimer = Spring.GetTimer()
            countdownPlayed = {}
        end
    end

    --------------------------------------------------------
    -- Widget pause cancelled manually
    --------------------------------------------------------

    if pauseStartTimer and pausedByWidget and not pausedNow then
        Spring.Echo("▶ Break cancelled manually. Next reminder reset.")
        pauseStartTimer = nil
        pausedByWidget = false
        countdownPlayed = {}
        nextBreakGameTime = gameNow + BreakIntervalSeconds()
    end

    --------------------------------------------------------
    -- Countdown
    --------------------------------------------------------

    if pauseStartTimer then
        local elapsed =
            Spring.DiffTimers(Spring.GetTimer(), pauseStartTimer)
        local remaining =
            math.ceil(BreakDurationSeconds() - elapsed)

        if COUNTDOWN_SECONDS[remaining] and not countdownPlayed[remaining] then
            Spring.Echo("⏳ Resuming game in " .. remaining .. " seconds...")
            PlayAlert()

            if MULTI_CHAT_COUNTDOWN[remaining] then
                Spring.SendCommands(
                    "say " .. CHAT_PREFIX ..
                    "Game resumes in " .. remaining .. " seconds"
                )
            end

            countdownPlayed[remaining] = true
        end

        ----------------------------------------------------
        -- Resume
        ----------------------------------------------------

        if elapsed >= BreakDurationSeconds() then
            if pausedByWidget and pausedNow then
                Spring.SendCommands("pause 0")

                -- Pause/unpause commands are applied asynchronously by the engine.
                -- Exit this Update() to avoid acting on stale pause state.
                Spring.Echo("🎮 Break over! Game resuming.")
                pauseStartTimer = nil
                pausedByWidget = false
                countdownPlayed = {}
                nextBreakGameTime = gameNow + BreakIntervalSeconds()
                return
            end

            pauseStartTimer = nil
            pausedByWidget = false
            countdownPlayed = {}
            nextBreakGameTime = gameNow + BreakIntervalSeconds()
        end
    end

    wasPausedLastUpdate = pausedNow
end

