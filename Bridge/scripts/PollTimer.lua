--[[
    PollTimer.lua

    Reine Timer-/Edge-Logik fuer den Update-Loop der Bridge: exportiert nicht bei
    jedem Engine-Frame, sondern nur alle POLL_INTERVAL_MS Millisekunden.

    `update(dt)` wird bei jedem Engine-Frame mit der seit dem letzten Frame
    vergangenen Zeit in Millisekunden aufgerufen (FS25 uebergibt `dt` in ms an
    update-Hooks). Sobald das konfigurierte Intervall ueberschritten ist, liefert
    `update` `true` zurueck (ein "Tick"), ansonsten `false`. Der Ueberschuss wird
    nicht verworfen, sondern in die naechste Periode uebernommen, damit sich kleine
    Frame-Schwankungen ueber die Zeit nicht aufaddieren (Drift-Vermeidung).

    Bewusst ohne jede GIANTS-Abhaengigkeit -> per `lua`-Interpreter unit-testbar.
]]

PollTimer = {}
PollTimer.__index = PollTimer

local DEFAULT_INTERVAL_MS = 5000

--- Erstellt einen neuen PollTimer.
-- @param intervalMs Intervall in Millisekunden zwischen zwei Ticks (Default: 5000)
function PollTimer.new(intervalMs)
    local self = setmetatable({}, PollTimer)
    self.intervalMs = intervalMs or DEFAULT_INTERVAL_MS
    if self.intervalMs <= 0 then
        error("PollTimer: intervalMs muss > 0 sein")
    end
    self.accumulatedMs = 0
    return self
end

--- Verarbeitet die vergangene Zeit seit dem letzten Aufruf.
-- @param dtMs vergangene Zeit in Millisekunden (>= 0)
-- @return true, wenn (mindestens) ein Intervall abgelaufen ist, sonst false
function PollTimer:update(dtMs)
    if dtMs == nil or dtMs < 0 then
        dtMs = 0
    end
    self.accumulatedMs = self.accumulatedMs + dtMs
    if self.accumulatedMs >= self.intervalMs then
        self.accumulatedMs = self.accumulatedMs % self.intervalMs
        return true
    end
    return false
end

--- Setzt den Timer zurueck, z.B. wenn nach dem Laden eines Spielstands sofort
-- ein Export erzwungen werden soll statt auf das naechste Intervall zu warten.
function PollTimer:reset()
    self.accumulatedMs = 0
end
