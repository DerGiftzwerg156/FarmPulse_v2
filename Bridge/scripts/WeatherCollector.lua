--[[
    WeatherCollector.lua

    Reine Verarbeitungslogik fuer Jahreszeit/Wetter, die in telemetry.json
    landen (siehe TelemetryCollector.lua). Zwei grundsaetzlich verschiedene
    Faelle:

    - "season" (Jahreszeit) ist eine reine Berechnung aus dem bereits
      bestaetigten Monatsfeld (siehe README.md, Tabelle "Monat") - dafuer ist
      KEIN zusaetzlicher, unbestaetigter Engine-Zugriff noetig.
    - "weather" (aktueller Wetterzustand) kommt dagegen aus einem rohen,
      unbestaetigten Engine-Wert (siehe FarmPulseBridge.readWeather) - dieses
      Modul normalisiert ihn nur defensiv.

    Bewusst ohne jede GIANTS-Abhaengigkeit -> per `lua`-Interpreter unit-testbar
    (siehe tests/test_weather_collector.lua).
]]

WeatherCollector = {}

local SEASON_BY_MONTH = {
    [12] = "winter", [1] = "winter", [2] = "winter",
    [3] = "spring", [4] = "spring", [5] = "spring",
    [6] = "summer", [7] = "summer", [8] = "summer",
    [9] = "autumn", [10] = "autumn", [11] = "autumn",
}

--- Leitet die Jahreszeit rein rechnerisch aus dem Monat (1-12) ab.
-- @param month Monat als Zahl (1-12), z.B. aus TelemetryCollector-Rohdaten
-- @return "winter"/"spring"/"summer"/"autumn", oder "unknown" bei ungueltigem Monat
function WeatherCollector.seasonFromMonth(month)
    return SEASON_BY_MONTH[math.floor(month or 0)] or "unknown"
end

--- Normalisiert einen rohen Wetterwert defensiv: nur nicht-leere Strings
-- werden uebernommen, alles andere (nil, Zahl, leerer String, ...) wird zu
-- "unknown" - so bricht ein fehlgeschlagener/unbekannter Engine-Zugriff die
-- Nutzlast nicht.
-- @param rawWeather roher Wert aus FarmPulseBridge.readWeather()
-- @return normalisierter Wetter-String
function WeatherCollector.normalizeWeather(rawWeather)
    if type(rawWeather) ~= "string" or rawWeather == "" then
        return "unknown"
    end
    return rawWeather
end

return WeatherCollector
