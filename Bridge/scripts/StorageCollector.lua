--[[
    StorageCollector.lua

    Reine Verarbeitungslogik fuer Lager-/Silobestaende: nimmt eine rohe Liste
    von {fillType, amount, capacity}-Datensaetzen entgegen (siehe
    FarmPulseBridge.readStorages() fuer den eigentlichen Lesezugriff) und
    normalisiert sie zu einer stabilen, nach Fill-Typ aggregierten und
    alphabetisch sortierten Liste fuer die world.json-Nutzlast.

    Mehrere Lagerstaetten desselben Fill-Typs (z.B. zwei Weizensilos) werden
    bewusst zu einem Eintrag aufsummiert - Core interessiert sich fuer "wie
    viel Weizen habe ich insgesamt", nicht fuer einzelne Gebaeude.

    Bewusst ohne jede GIANTS-Abhaengigkeit -> per `lua`-Interpreter unit-testbar
    (siehe tests/test_storage_collector.lua).
]]

StorageCollector = {}

local function toNonNegativeInt(value)
    local n = math.floor((value or 0) + 0.5)
    if n < 0 then
        n = 0
    end
    return n
end

--- Normalisiert einen einzelnen rohen Lager-Datensatz.
-- @param raw Tabelle mit den rohen Feldern fillType, amount, capacity
--        (jeweils optional/nil, falls die Engine sie nicht liefern konnte)
-- @return normalisierte Tabelle mit fillType, amount, capacity
function StorageCollector.normalizeEntry(raw)
    raw = raw or {}
    local fillType = raw.fillType
    if type(fillType) ~= "string" or fillType == "" then
        fillType = "UNKNOWN"
    end
    return {
        fillType = fillType,
        amount = toNonNegativeInt(raw.amount),
        capacity = toNonNegativeInt(raw.capacity),
    }
end

--- Normalisiert eine rohe Liste von Lager-Datensaetzen, aggregiert sie nach
-- fillType und sortiert sie alphabetisch, damit die Reihenfolge in world.json
-- stabil und deterministisch ist (wichtig fuer Core-seitiges Diffing und fuer
-- deterministische Tests) - unabhaengig davon, ueber wie viele einzelne
-- Gebaeude/Produktionspunkte ein Fill-Typ verteilt ist.
-- @param rawList Liste roher {fillType, amount, capacity}-Tabellen
-- @return normalisierte, nach fillType aufsteigend sortierte, aggregierte
--         Liste (leer, falls rawList keine Tabelle ist)
function StorageCollector.buildStorages(rawList)
    if type(rawList) ~= "table" then
        return {}
    end

    local byFillType = {}
    local order = {}
    for i = 1, #rawList do
        local entry = StorageCollector.normalizeEntry(rawList[i])
        local existing = byFillType[entry.fillType]
        if existing == nil then
            byFillType[entry.fillType] = entry
            table.insert(order, entry.fillType)
        else
            existing.amount = existing.amount + entry.amount
            existing.capacity = existing.capacity + entry.capacity
        end
    end

    table.sort(order)

    local storages = {}
    for i, fillType in ipairs(order) do
        storages[i] = byFillType[fillType]
    end
    return storages
end

return StorageCollector
