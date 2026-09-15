--[[
    FieldCollector.lua

    Reine Verarbeitungslogik fuer Feld-/Farmland-Informationen: nimmt eine rohe
    Liste von Farmland-Datensaetzen entgegen (siehe FarmPulseBridge.readFarmlands()
    fuer den eigentlichen Lesezugriff auf g_farmlandManager) und normalisiert sie
    zu einer stabilen, deterministisch sortierten Liste fuer die telemetry.json-
    Nutzlast:

        { fieldId = 1, ownerFarmId = 0, sizeHa = 4.53, price = 32000 }

    "ownerFarmId" ist 0, solange ein Feld/Farmland noch niemandem gehoert (FS-
    Konvention: farmId 0 = unbesessen/AI). Ob ein Feld dem aktuellen Spieler
    gehoert, laesst sich auf Core-Seite durch Vergleich mit dem separat
    exportierten Top-Level-Feld "farmId" (siehe TelemetryCollector) feststellen -
    diese Bridge trifft diese Entscheidung bewusst nicht selbst (Architektur-
    Leitprinzip: die Bridge bleibt "dumm", vgl. FarmPulseBridge.lua).

    Bewusst ohne jede GIANTS-Abhaengigkeit -> per `lua`-Interpreter unit-testbar
    (siehe tests/test_field_collector.lua).
]]

FieldCollector = {}

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

--- Normalisiert einen einzelnen rohen Farmland-Datensatz.
-- @param raw Tabelle mit den rohen Feldern id, farmId, areaInHa, price (jeweils
--        optional/nil, falls die Engine sie nicht liefern konnte)
-- @return normalisierte Tabelle mit fieldId, ownerFarmId, sizeHa, price
function FieldCollector.normalizeField(raw)
    raw = raw or {}
    return {
        fieldId = toNonNegativeInt(raw.id),
        ownerFarmId = toNonNegativeInt(raw.farmId),
        sizeHa = round2(raw.areaInHa),
        price = toNonNegativeInt(raw.price),
    }
end

--- Normalisiert eine rohe Liste von Farmland-Datensaetzen und sortiert sie nach
-- fieldId, damit die Reihenfolge in telemetry.json unabhaengig von der (nicht
-- garantierten) Iterationsreihenfolge der Engine-API stabil und deterministisch
-- ist (wichtig fuer Core-seitiges Diffing und fuer deterministische Tests).
-- @param rawList Liste roher {id, farmId, areaInHa, price}-Tabellen
-- @return normalisierte, nach fieldId aufsteigend sortierte Liste (leer, falls
--         rawList keine Tabelle ist)
function FieldCollector.buildFields(rawList)
    if type(rawList) ~= "table" then
        return {}
    end

    local fields = {}
    for i = 1, #rawList do
        fields[i] = FieldCollector.normalizeField(rawList[i])
    end

    table.sort(fields, function(a, b) return a.fieldId < b.fieldId end)

    return fields
end

return FieldCollector
