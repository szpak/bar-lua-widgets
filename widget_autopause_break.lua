function widget:GetInfo()
    return {
        name    = "Auto Pause Break Reminder",
        desc    = "Pauses the game after 30 minutes and resumes after 2 minutes",
        author  = "szpak (AI assisted)",
        date    = "2025-12-28",
        license = "GPLv2+",
        layer   = 0,
        enabled = true
    }
end

local PAUSE_AFTER = 30 * 60   -- 30 minutes
local PAUSE_DURATION = 2 * 60 -- 2 minutes

local gameStartTime
local pauseTime
local hasPaused = false
local isPausedByWidget = false

function widget:Initialize()
    gameStartTime = Spring.GetGameSeconds()
end

function widget:Update(dt)
    local now = Spring.GetGameSeconds()
    if not now then return end

    -- Trigger pause
    if not hasPaused and now - gameStartTime >= PAUSE_AFTER then
        Spring.Echo("🧘 Time to stretch! Game paused for 2 minutes.")
        Spring.SendCommands("pause 1")
        pauseTime = now
        hasPaused = true
        isPausedByWidget = true
    end

    -- Resume game
    if isPausedByWidget and pauseTime and now - pauseTime >= PAUSE_DURATION then
        Spring.Echo("🎮 Break over! Resuming game.")
        Spring.SendCommands("pause 0")
        isPausedByWidget = false
    end
end

