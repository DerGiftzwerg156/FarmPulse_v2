--[[
    FieldCollector.lua

    Reine Verarbeitungslogik fuer Feld-/Farmland-Informationen: nimmt eine rohe
    Liste von Farmland-Datensaetzen entgegen (siehe FarmPulseBridge.readFarmlands()
    fuer den eigentlichen Lesezugriff auf g_farmlandManager) und normalisiert sie
    zu einer stabilen, deterministisch sortierten Liste fuer die world.json-
    Nutzlast:

        { fieldId = 1, ownerFarmId = 0, sizeHa = 4.53, price = 32000,
          fruitType = "WHEAT", growthState = 0.42, estimatedYieldLiters = 12500 }

    "ownerFarmId" ist 0, solange ein Feld/Farmland noch niemandem gehoert (FS-
    Konvention: farmId 0 = unbesessen/AI). Ob ein Feld dem aktuellen Spieler
    gehoert, laesst sich auf Core-Seite durch Vergleich mit dem separat
    exportierten Top-Level-Feld "farmId" (siehe TelemetryCollector) feststellen -
    diese Bridge trifft diese Entscheidung bewusst nicht selbst (Architektur-
    Leitprinzip: die Bridge bleibt "dumm", vgl. FarmPulseBridge.lua).

    "fruitType"/"growthState"/"estimatedYieldLiters" sind nullable: sie fehlen
    (JSON null), solange kein Feld-Objekt zu diesem Farmland gefunden wurde oder
    dort aktuell keine Frucht steht (siehe FarmPulseBridge.readFieldCrops() fuer
    den Lesezugriff auf g_fieldManager/FieldState/FruitTypeDesc - Konfidenz siehe
    README.md). Die eigentliche Wachstums-/Ertragsberechnung passiert bewusst
    hier (reine, testbare Logik), nicht in FarmPulseBridge.lua: dieses liefert
    nur rohe growthState/minHarvestingGrowthState/literPerSqm/isHarvestable/
    areaHa-Werte.

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

local function clamp01(value)
    if value < 0 then
        return 0
    end
    if value > 1 then
        return 1
    end
    return value
end

--- Berechnet aus rohen Anbau-/Ertragswerten eines Feldes (siehe
-- FarmPulseBridge.readFieldCrops()) den normalisierten Wachstumsfortschritt
-- (0..1) und eine grobe Ertragsschaetzung in Litern (FS-Ingame-Einheit,
-- konsistent zu storages/amount - siehe Bridge/README.md).
-- @param cropRaw Tabelle mit fruitTypeName (string|nil), growthState (int),
--        minHarvestingGrowthState (int), literPerSqm (number), isHarvestable
--        (boolean), areaHa (number) - oder nil, falls kein Feld-Objekt
--        gefunden wurde
-- @return Tabelle { fruitType, growthState, estimatedYieldLiters } oder nil,
--         falls cropRaw nil ist oder keine Frucht bekannt ist
function FieldCollector.computeCropInfo(cropRaw)
    if cropRaw == nil or cropRaw.fruitTypeName == nil then
        return nil
    end

    local progress
    if cropRaw.isHarvestable then
        progress = 1.0
    elseif (cropRaw.minHarvestingGrowthState or 0) > 0 then
        progress = clamp01((cropRaw.growthState or 0) / cropRaw.minHarvestingGrowthState)
    else
        progress = 0
    end

    local areaSqm = (cropRaw.areaHa or 0) * 10000
    local estimatedYieldLiters = (cropRaw.literPerSqm or 0) * areaSqm * progress

    return {
        fruitType = cropRaw.fruitTypeName,
        growthState = round2(progress),
        estimatedYieldLiters = round2(estimatedYieldLiters),
    }
end

--- Normalisiert einen einzelnen rohen Farmland-Datensatz, optional angereichert
-- um Anbaudaten desselben Feldes.
-- @param raw Tabelle mit den rohen Feldern id, farmId, areaInHa, price (jeweils
--        optional/nil, falls die Engine sie nicht liefern konnte)
-- @param cropRaw optionale rohe Anbauwerte, siehe computeCropInfo()
-- @return normalisierte Tabelle mit fieldId, ownerFarmId, sizeHa, price,
--         fruitType, growthState, estimatedYieldLiters
function FieldCollector.normalizeField(raw, cropRaw)
    raw = raw or {}
    local cropInfo = FieldCollector.computeCropInfo(cropRaw)

    return {
        fieldId = toNonNegativeInt(raw.id),
        ownerFarmId = toNonNegativeInt(raw.farmId),
        sizeHa = round2(raw.areaInHa),
        price = toNonNegativeInt(raw.price),
        fruitType = cropInfo and cropInfo.fruitType or nil,
        growthState = cropInfo and cropInfo.growthState or nil,
        estimatedYieldLiters = cropInfo and cropInfo.estimatedYieldLiters or nil,
    }
end

--- Normalisiert eine rohe Liste von Farmland-Datensaetzen und sortiert sie nach
-- fieldId, damit die Reihenfolge in telemetry.json unabhaengig von der (nicht
-- garantierten) Iterationsreihenfolge der Engine-API stabil und deterministisch
-- ist (wichtig fuer Core-seitiges Diffing und fuer deterministische Tests).
-- @param rawList Liste roher {id, farmId, areaInHa, price}-Tabellen
-- @param rawCropsByFieldId optionale Tabelle, die Farmland-/Feld-IDs auf rohe
--        Anbauwerte abbildet (siehe FarmPulseBridge.readFieldCrops()), fuer
--        Felder ohne bekannten Anbau einfach weglassen
-- @return normalisierte, nach fieldId aufsteigend sortierte Liste (leer, falls
--         rawList keine Tabelle ist)
function FieldCollector.buildFields(rawList, rawCropsByFieldId)
    if type(rawList) ~= "table" then
        return {}
    end
    rawCropsByFieldId = rawCropsByFieldId or {}

    local fields = {}
    for i = 1, #rawList do
        local raw = rawList[i]
        local cropRaw = raw ~= nil and rawCropsByFieldId[raw.id] or nil
        fields[i] = FieldCollector.normalizeField(raw, cropRaw)
    end

    table.sort(fields, function(a, b) return a.fieldId < b.fieldId end)

    return fields
end

return FieldCollector
