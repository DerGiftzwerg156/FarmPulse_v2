--[[
    TelemetryCollector.lua

    Reine Verarbeitungslogik: nimmt rohe, bereits aus der GIANTS-Engine gelesene
    Werte entgegen (siehe FarmPulseBridge.lua fuer die eigentlichen Engine-
    Zugriffe) und baut daraus die telemetry.json-Nutzlast - die "schnellen",
    sich haeufig aendernden Werte (Uhrzeit, Kontostand, Wetter). Besitz/
    Vermoegen (Felder, Fuhrpark, Lager) wandert seit der Aufteilung in mehrere
    Austauschdateien in world.json (siehe WorldCollector.lua), Betriebs-/
    Spieleridentitaet in farm.json (siehe FarmCollector.lua):

        {
          "hour": 8,
          "minute": 30,
          "day": 4,
          "month": 6,
          "year": 2,
          "daysPerMonth": 3,
          "money": 84250,
          "farmId": 1,
          "season": "summer",
          "weather": "sun"
        }

    Die Trennung von "rohe Engine-Werte lesen" (unsicher, siehe FarmPulseBridge.lua)
    und "Werte zu einer validen Nutzlast zusammenbauen" (reine Logik, vollstaendig
    testbar) ist bewusst: Dieses Modul kann unabhaengig von FS25 mit einem
    einfachen `lua`-Interpreter getestet werden (siehe
    tests/test_telemetry_collector.lua).

    Benoetigt JsonEncoder fuer die eigentliche Serialisierung; "season"/"weather"
    werden dabei als bereits ueber WeatherCollector normalisierte Strings erwartet.
]]

TelemetryCollector = {}

local function toNonNegativeInt(value)
    local n = math.floor((value or 0) + 0.5)
    if n < 0 then
        n = 0
    end
    return n
end

--- Rundet einen Wert auf eine Ganzzahl, erlaubt aber negative Werte (z.B.
-- Kontostand im Minus bei einer Liquiditaetskrise).
local function toInt(value)
    local n = value or 0
    if n >= 0 then
        return math.floor(n + 0.5)
    end
    return -math.floor(-n + 0.5)
end

--- Normalisiert eine rohe Stunde auf den gueltigen Bereich [0, 23].
function TelemetryCollector.normalizeHour(rawHour)
    local hour = math.floor((rawHour or 0) + 0.5) % 24
    if hour < 0 then
        hour = hour + 24
    end
    return hour
end

--- Normalisiert eine rohe Minute auf den gueltigen Bereich [0, 59].
function TelemetryCollector.normalizeMinute(rawMinute)
    local minute = math.floor((rawMinute or 0) + 0.5) % 60
    if minute < 0 then
        minute = minute + 60
    end
    return minute
end

local function normalizeStringOrUnknown(value)
    if type(value) ~= "string" or value == "" then
        return "unknown"
    end
    return value
end

--- Baut aus rohen Eingabewerten eine validierte, normalisierte Telemetrie-Nutzlast.
-- @param rawState Tabelle mit den Feldern hour, minute, day, month, year,
--        daysPerMonth, money, farmId, season, weather (season/weather werden
--        als bereits ueber WeatherCollector normalisierte Strings erwartet -
--        die Typpruefung hier ist nur ein zusaetzliches Sicherheitsnetz)
-- @return normalisierte Tabelle mit denselben Feldern, bereit fuer toJson()
function TelemetryCollector.buildPayload(rawState)
    rawState = rawState or {}

    return {
        hour = TelemetryCollector.normalizeHour(rawState.hour),
        minute = TelemetryCollector.normalizeMinute(rawState.minute),
        day = toNonNegativeInt(rawState.day),
        month = toNonNegativeInt(rawState.month),
        year = toNonNegativeInt(rawState.year),
        daysPerMonth = toNonNegativeInt(rawState.daysPerMonth),
        money = toInt(rawState.money),
        farmId = toNonNegativeInt(rawState.farmId),
        season = normalizeStringOrUnknown(rawState.season),
        weather = normalizeStringOrUnknown(rawState.weather),
    }
end

--- Serialisiert eine (bereits mit buildPayload erzeugte) Nutzlast als JSON-Text
-- mit stabiler Feldreihenfolge.
function TelemetryCollector.toJson(payload)
    return JsonEncoder.encodeObject({
        { key = "hour", value = payload.hour },
        { key = "minute", value = payload.minute },
        { key = "day", value = payload.day },
        { key = "month", value = payload.month },
        { key = "year", value = payload.year },
        { key = "daysPerMonth", value = payload.daysPerMonth },
        { key = "money", value = payload.money },
        { key = "farmId", value = payload.farmId },
        { key = "season", value = payload.season },
        { key = "weather", value = payload.weather },
    })
end

return TelemetryCollector
