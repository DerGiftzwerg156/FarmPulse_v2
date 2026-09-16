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
          "weatherType": "SUN",
          "temperature": 11.4
        }

    Die Trennung von "rohe Engine-Werte lesen" (unsicher, siehe FarmPulseBridge.lua)
    und "Werte zu einer validen Nutzlast zusammenbauen" (reine Logik, vollstaendig
    testbar) ist bewusst: Dieses Modul kann unabhaengig von FS25 mit einem
    einfachen `lua`-Interpreter getestet werden (siehe
    tests/test_telemetry_collector.lua).

    Benoetigt JsonEncoder fuer die eigentliche Serialisierung.
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

--- Berechnet den Kalendermonat (1=Januar..12=Dezember) aus der FS25-internen
-- "Periode" (environment.currentPeriod, 1..12, saisonbezogen - NICHT direkt
-- der Kalendermonat: Periode 1 ist "frueher Fruehling", auf einer
-- Nordhalbkugel-Karte also Maerz statt Januar). Bildet exakt dieselbe
-- Hemisphaeren-Verschiebung nach, die die Engine selbst in I18N:formatPeriod()
-- fuer die Monatsanzeige verwendet (siehe Bridge/README.md, Abschnitt
-- "Kalender"). Es gibt KEIN eigenstaendiges "currentMonth"-Feld in FS25 - eine
-- fruehere Fassung dieser Bridge nahm das faelschlich an (siehe README.md,
-- Korrektur-Hinweis).
-- @param period rohe FS25-Periode (1..12); faellt auf 1 zurueck falls nil
-- @param isSouthern true, falls die Karte auf der Suedhalbkugel liegt
--        (environment.daylight.latitude < 0)
-- @return Kalendermonat 1..12
function TelemetryCollector.calendarMonthFromPeriod(period, isSouthern)
    period = period or 1
    local offset = period + 2 + (isSouthern and 6 or 0)
    return ((offset - 1) % 12) + 1
end

--- Normalisiert einen rohen Wettertyp-String auf einen bekannten Wert.
-- Unbekannte/fehlende Werte werden zu "UNKNOWN" - siehe FarmPulseBridge.readWeather()
-- fuer die (teils hergeleiteten) Engine-Zugriffe, die diesen Rohwert liefern.
local KNOWN_WEATHER_TYPES = {
    SUN = true,
    PARTIALLY_CLOUDY = true,
    CLOUDY = true,
    RAIN = true,
    SNOW = true,
    HAIL = true,
    THUNDER = true,
    TWISTER = true,
}

function TelemetryCollector.normalizeWeatherType(rawWeatherType)
    if type(rawWeatherType) == "string" and KNOWN_WEATHER_TYPES[rawWeatherType] then
        return rawWeatherType
    end
    return "UNKNOWN"
end

-- Wie FieldCollector.round2, aber (anders als dort, wo sizeHa immer positiv
-- ist) mit korrekter Behandlung negativer Werte - Temperatur kann im Winter
-- unter 0 liegen (vgl. TelemetryCollector.toInt fuer denselben Negativ-Fall
-- beim Kontostand).
local function round2(value)
    value = value or 0
    if value >= 0 then
        return math.floor(value * 100 + 0.5) / 100
    end
    return -math.floor(-value * 100 + 0.5) / 100
end

--- Baut aus rohen Eingabewerten eine validierte, normalisierte Telemetrie-Nutzlast.
-- @param rawState Tabelle mit den Feldern hour, minute, day, month, year,
--        daysPerMonth, money, farmId, weatherType, temperature
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
        weatherType = TelemetryCollector.normalizeWeatherType(rawState.weatherType),
        temperature = round2(rawState.temperature),
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
        { key = "weatherType", value = payload.weatherType },
        { key = "temperature", value = payload.temperature },
    })
end

return TelemetryCollector
