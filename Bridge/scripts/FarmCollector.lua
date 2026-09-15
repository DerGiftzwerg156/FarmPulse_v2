--[[
    FarmCollector.lua

    Reine Verarbeitungslogik fuer die Betriebs-/Spieleridentitaet: nimmt rohe
    Namensfelder entgegen (siehe FarmPulseBridge.readFarmName()/readPlayerName()
    fuer den eigentlichen Lesezugriff) und baut daraus die farm.json-Nutzlast.

    farm.json aendert sich praktisch nie waehrend eines Spielstands (Hofname/
    Spielername werden bei Erstellung des Spielstands festgelegt) - die Bridge
    schreibt sie deshalb nur einmal bei der Aktivierung, siehe
    FarmPulseBridge.tryActivate().

    Bewusst ohne jede GIANTS-Abhaengigkeit -> per `lua`-Interpreter unit-testbar
    (siehe tests/test_farm_collector.lua).
]]

FarmCollector = {}

local FALLBACK_NAME = "Unbekannt"

local function normalizeName(value)
    if type(value) == "string" then
        local trimmed = value:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            return trimmed
        end
    end
    return FALLBACK_NAME
end

--- Baut aus rohen Eingabewerten eine validierte farm.json-Nutzlast.
-- @param rawState Tabelle mit den Feldern farmName, playerName (jeweils
--        optional/nil, falls die Engine sie nicht liefern konnte)
-- @return normalisierte Tabelle mit farmName, playerName, bereit fuer toJson()
function FarmCollector.buildPayload(rawState)
    rawState = rawState or {}
    return {
        farmName = normalizeName(rawState.farmName),
        playerName = normalizeName(rawState.playerName),
    }
end

--- Serialisiert eine (bereits mit buildPayload erzeugte) Nutzlast als JSON-Text
-- mit stabiler Feldreihenfolge.
function FarmCollector.toJson(payload)
    return JsonEncoder.encodeObject({
        { key = "farmName", value = payload.farmName },
        { key = "playerName", value = payload.playerName },
    })
end

return FarmCollector
