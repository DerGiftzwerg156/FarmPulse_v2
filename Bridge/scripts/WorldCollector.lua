--[[
    WorldCollector.lua

    Reine Verarbeitungslogik: baut aus bereits normalisierten Teil-Ergebnissen
    (FieldCollector.buildFields(), VehicleCollector.buildFleetValue(),
    StorageCollector.buildStorages()) die world.json-Nutzlast:

        {
          "fleetValue": 125000,
          "fields": [ { "fieldId": 1, "ownerFarmId": 0, "sizeHa": 4.53, "price": 32000 } ],
          "storages": [ { "fillType": "WHEAT", "amount": 5000, "capacity": 20000 } ]
        }

    world.json fasst bewusst alles zusammen, was "Besitz/Vermoegen" jenseits
    des Kontostands ist (siehe telemetry.json fuer "money") und wird seltener
    exportiert als telemetry.json, da sich Feldbesitz, Fuhrpark und
    Lagerbestaende deutlich langsamer aendern als Uhrzeit/Kontostand (siehe
    FarmPulseBridge.WORLD_POLL_INTERVAL_MS).

    Benoetigt JsonEncoder fuer die eigentliche Serialisierung; "fields" und
    "storages" werden dabei als bereits normalisierte Listen erwartet.
]]

WorldCollector = {}

--- Baut aus rohen Eingabewerten eine validierte, normalisierte world.json-Nutzlast.
-- @param rawState Tabelle mit den Feldern fields, fleetValue, storages
-- @return normalisierte Tabelle mit denselben Feldern, bereit fuer toJson()
function WorldCollector.buildPayload(rawState)
    rawState = rawState or {}

    local fields = rawState.fields
    if type(fields) ~= "table" then
        fields = {}
    end

    local storages = rawState.storages
    if type(storages) ~= "table" then
        storages = {}
    end

    local fleetValue = math.floor((rawState.fleetValue or 0) + 0.5)
    if fleetValue < 0 then
        fleetValue = 0
    end

    return {
        fleetValue = fleetValue,
        fields = fields,
        storages = storages,
    }
end

--- Serialisiert eine (bereits mit buildPayload erzeugte) Nutzlast als JSON-Text
-- mit stabiler Feldreihenfolge.
function WorldCollector.toJson(payload)
    local fieldEntries = {}
    for i, field in ipairs(payload.fields) do
        fieldEntries[i] = JsonEncoder.encodeObject({
            { key = "fieldId", value = field.fieldId },
            { key = "ownerFarmId", value = field.ownerFarmId },
            { key = "sizeHa", value = field.sizeHa },
            { key = "price", value = field.price },
            { key = "fruitType", value = field.fruitType },
            { key = "growthState", value = field.growthState },
            { key = "estimatedYieldLiters", value = field.estimatedYieldLiters },
        })
    end

    local storageEntries = {}
    for i, storage in ipairs(payload.storages) do
        storageEntries[i] = JsonEncoder.encodeObject({
            { key = "fillType", value = storage.fillType },
            { key = "amount", value = storage.amount },
            { key = "capacity", value = storage.capacity },
        })
    end

    return JsonEncoder.encodeObject({
        { key = "fleetValue", value = payload.fleetValue },
        { key = "fields", raw = JsonEncoder.encodeRawArray(fieldEntries) },
        { key = "storages", raw = JsonEncoder.encodeRawArray(storageEntries) },
    })
end

return WorldCollector
