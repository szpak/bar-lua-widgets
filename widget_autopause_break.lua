function widget:GetInfo()
    return {
        name    = "Auto Pause Break Reminder",
        desc    = "Pauses the game every 30 minutes for a 2-minute stretch break",
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
local UPDATE_INTERVAL = 1        -- seconds (throttling)

------------------------------------------------------------
-- STATE
------------------------------------------------------------

local nextBreakTime
local pauseStartTime
local pausedByWidget = false
local lastUpdate = 0

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

local function IsPauseAllowed()
    local allowed = Spring.GetGameRulesParam("pauseAllowed")
    return allowed == 1
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
    -- Time to take a break
    --------------------------------------------------------
    if now >= nextBreakTime and not pauseStartTime then
        Spring.Echo("🧘 Time to stretch! Recommended 2-minute break.")

        if IsPauseAllowed() then
            if not Spring.IsPaused() then
                Spring.SendCommands("pause 1")
                pausedByWidget = true
                pauseStartTime = now
                Spring.Echo("⏸ Game paused for your break.")
            else
                -- Game already paused manually
                pauseStartTime = now
                pausedByWidget = false
            end
        else
            Spring.Echo("⚠ Pause not allowed in this game. Please consider taking a short break anyway!")
            -- Still track timing so the reminder cycle continues
            pauseStartTime = now
            pausedByWidget = false
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
        nextBreakTime = now + BREAK_INTERVAL
    end
end

