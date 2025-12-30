function widget:GetInfo()
    return {
        name    = "Auto Pause Break Reminder",
        desc    = "Pauses the game every 30 minutes with sound reminders and countdown resume warnings",
        author  = "szpak (AI assisted)",
        date    = "2025-12-28",
        license = "GPLv2+",
        layer   = 0,
        enabled = true
    }
end

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------

local BREAK_INTERVAL  = 30 * 60  -- 30 minutes
local BREAK_DURATION  = 2 * 60   -- 2 minutes
local UPDATE_INTERVAL = 1        -- seconds (throttled update)

local ALERT_SOUND = "LuaUI/Sounds/beep4.wav"

-- Countdown seconds before resume
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
    Spring.PlaySoundFile(ALERT_SOUND, 1.0)
end

------------------------------------------------------------
-- WIDGET LIFECYCLE
------------------------------------------------------------

function widget:Initialize()
    local now = Spring.GetGameSeconds()
    nextBreakTime = now + BREAK_INTERVAL
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
        Spring.Echo("🧘 Time to stretch! Recommended 2-minute break.")
        PlayAlert()

        if IsPauseAllowed() then
            if not Spring.IsPaused() then
                Spring.SendCommands("pause 1")
                pausedByWidget = true
                pauseStartTime = now
                Spring.Echo("⏸ Game paused for your break.")
            else
                -- Already paused manually
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
    -- Countdown warnings before resume
    --------------------------------------------------------
    if pauseStartTime then
        local remaining = math.ceil(BREAK_DURATION - (now - pauseStartTime))

        if COUNTDOWN_SECONDS[remaining] and not countdownPlayed[remaining] then
            Spring.Echo("⏳ Resuming game in " .. remaining .. " seconds...")
            PlayAlert()
            countdownPlayed[remaining] = true
        end
    end

    --------------------------------------------------------
    -- Resume after break duration
    --------------------------------------------------------
    if pauseStartTime and (now - pauseStartTime >= BREAK_DURATION) then
        if pausedByWidget and Spring.IsPaused() then
            Spring.SendCommands("pause 0")
            Spring.Echo("🎮 Break over! Game resumed.")
        end

        -- Schedule next break
        pauseStartTime = nil
        pausedByWidget = false
        countdownPlayed = {}
        nextBreakTime = now + BREAK_INTERVAL
    end
end

