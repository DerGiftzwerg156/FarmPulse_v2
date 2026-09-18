--[[
    VehicleCollector.lua

    Reine Verarbeitungslogik fuer den Fuhrpark: nimmt eine rohe Liste von
    Einzelfahrzeug-Datensaetzen entgegen (siehe FarmPulseBridge.readVehicles()
    fuer den eigentlichen Lesezugriff auf g_currentMission.vehicleSystem) und
    baut daraus sowohl die "vehicles"-Liste (Name, PS, Betriebsstunden,
    Zustand, Verkaufspreis je Fahrzeug) als auch den aggregierten "fleetValue"
    fuer die world.json-Nutzlast.

    Bewusst weiterhin NICHT exportiert: Kraftstofffuellstand - der beobachtet
    der Spieler ohnehin selbst im laufenden Spiel (siehe Bridge/README.md).
    Zustand (Verschleiss/Schaden) wird dagegen jetzt exportiert, da explizit
    fuer eine Fuhrpark-Uebersicht im Frontend gewuenscht.

    Bewusst ohne jede GIANTS-Abhaengigkeit -> per `lua`-Interpreter unit-testbar
    (siehe tests/test_vehicle_collector.lua).
]]

VehicleCollector = {}

local FALLBACK_NAME = "Unbekanntes Fahrzeug"

local function round2(value)
    value = value or 0
    return math.floor(value * 100 + 0.5) / 100
end

local function toNonNegativeInt(value)
    local n = math.floor((value or 0) + 0.5)
    if n < 0 then
        n = 0
    end
    return n
end

local function clamp(value, min, max)
    if value < min then
        return min
    end
    if value > max then
        return max
    end
    return value
end

local function normalizeName(value)
    if type(value) == "string" then
        local trimmed = value:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            return trimmed
        end
    end
    return FALLBACK_NAME
end

--- Summiert eine rohe Liste von Fahrzeugpreisen (Zahlen) zu einem
-- nicht-negativen, gerundeten Gesamtwert. Nicht-numerische/negative Eintraege
-- werden ignoriert, statt die gesamte Berechnung scheitern zu lassen.
-- @param rawPrices Liste roher Preis-Zahlen (z.B. je Fahrzeug getSellPrice())
-- @return gerundeter, nicht-negativer Gesamtwert (0, falls rawPrices keine
--         Tabelle ist oder leer bleibt)
function VehicleCollector.buildFleetValue(rawPrices)
    if type(rawPrices) ~= "table" then
        return 0
    end

    local total = 0
    for i = 1, #rawPrices do
        local price = rawPrices[i]
        if type(price) == "number" and price > 0 then
            total = total + price
        end
    end

    local rounded = math.floor(total + 0.5)
    if rounded < 0 then
        rounded = 0
    end
    return rounded
end

--- Normalisiert einen einzelnen rohen Fahrzeug-Datensatz.
-- @param raw Tabelle mit den rohen Feldern name, horsepowerHp, operatingHours,
--        conditionPercent, sellPrice (jeweils optional/nil, falls die Engine
--        sie nicht liefern konnte - siehe FarmPulseBridge.readVehicles())
-- @return normalisierte Tabelle mit name, horsepowerHp, operatingHours,
--         conditionPercent, sellPrice
function VehicleCollector.normalizeVehicle(raw)
    raw = raw or {}

    local horsepowerHp = nil
    if type(raw.horsepowerHp) == "number" and raw.horsepowerHp > 0 then
        horsepowerHp = toNonNegativeInt(raw.horsepowerHp)
    end

    local operatingHours = nil
    if type(raw.operatingHours) == "number" and raw.operatingHours >= 0 then
        operatingHours = round2(raw.operatingHours)
    end

    local conditionPercent = nil
    if type(raw.conditionPercent) == "number" then
        conditionPercent = round2(clamp(raw.conditionPercent, 0, 100))
    end

    return {
        name = normalizeName(raw.name),
        horsepowerHp = horsepowerHp,
        operatingHours = operatingHours,
        conditionPercent = conditionPercent,
        sellPrice = toNonNegativeInt(raw.sellPrice),
    }
end

--- Normalisiert eine rohe Liste von Fahrzeug-Datensaetzen und sortiert sie
-- nach Name (bei Gleichstand nach Verkaufspreis absteigend), damit die
-- Reihenfolge in world.json unabhaengig von der (nicht garantierten)
-- Iterationsreihenfolge von g_currentMission.vehicleSystem.vehicles stabil
-- und deterministisch ist.
-- @param rawList Liste roher Fahrzeug-Tabellen, siehe normalizeVehicle()
-- @return normalisierte, sortierte Liste (leer, falls rawList keine Tabelle
--         ist)
function VehicleCollector.buildVehicles(rawList)
    if type(rawList) ~= "table" then
        return {}
    end

    local vehicles = {}
    for i = 1, #rawList do
        vehicles[i] = VehicleCollector.normalizeVehicle(rawList[i])
    end

    table.sort(vehicles, function(a, b)
        if a.name ~= b.name then
            return a.name < b.name
        end
        return a.sellPrice > b.sellPrice
    end)

    return vehicles
end

return VehicleCollector
