--[[
    JsonEncoder.lua

    Minimaler, abhaengigkeitsfreier JSON-Encoder fuer die FarmPulse Bridge.

    Warum ein eigener Encoder? Die GIANTS-Engine liefert Mods native XML-Funktionen
    (loadXMLFile/saveXMLFile), aber keinen JSON-Parser/-Encoder. telemetry.json wird
    daher als einfacher, selbst generierter JSON-Text geschrieben.

    Bewusst kein General-Purpose-JSON-Encoder: unterstuetzt nur die Wertetypen, die
    die Telemetrie tatsaechlich braucht (Zahlen, Strings, Booleans, flache Arrays,
    Objekte mit fester Feldreihenfolge). Verschachtelte Objekte (z.B. die "fields"-
    Liste) werden ueber vorab kodierte Fragmente zusammengesetzt (siehe
    encodeRawArray/encodeObject mit "raw"-Eintraegen), statt einen generischen
    rekursiven Encoder zu bauen.

    WICHTIG zum Ladeverhalten: Die GIANTS-Engine bindet Mod-Skripte ueber `source()`
    ein, nicht ueber `require`/`return` - jede sourced Datei laeuft im globalen
    Namensraum. Die Tabelle wird deshalb bewusst OHNE `local` deklariert, damit
    FarmPulseBridge.lua nach dem `source()`-Aufruf global auf `JsonEncoder`
    zugreifen kann. Die Testsuite laedt dieselbe Datei per `dofile` und nutzt
    denselben globalen Namen.
]]

JsonEncoder = {}

--- Escaped die fuer JSON reservierten Zeichen in einem String.
-- @param value beliebiger Wert, wird zu einem String konvertiert
-- @return escapeter String, ohne umschliessende Anfuehrungszeichen
function JsonEncoder.escapeString(value)
    local s = tostring(value)
    s = s:gsub("\\", "\\\\")
    s = s:gsub('"', '\\"')
    s = s:gsub("\n", "\\n")
    s = s:gsub("\r", "\\r")
    s = s:gsub("\t", "\\t")
    return s
end

--- Kodiert eine einzelne Zahl. Ganzzahlen werden ohne Nachkommastellen ausgegeben
-- (z.B. "money": 84250), alle anderen Zahlen (z.B. Feldgroessen in Hektar) mit
-- fester Genauigkeit von 2 Nachkommastellen.
function JsonEncoder.encodeNumber(value)
    if value ~= value then
        error("JsonEncoder: NaN kann nicht kodiert werden")
    end
    if value == math.huge or value == -math.huge then
        error("JsonEncoder: Unendlichkeit kann nicht kodiert werden")
    end
    if math.floor(value) == value and math.abs(value) < 1e15 then
        return string.format("%d", value)
    end
    return string.format("%.2f", value)
end

--- Kodiert einen beliebigen unterstuetzten Wert (String, Zahl, Boolean, Array, nil).
function JsonEncoder.encodeValue(value)
    local valueType = type(value)
    if valueType == "string" then
        return '"' .. JsonEncoder.escapeString(value) .. '"'
    elseif valueType == "number" then
        return JsonEncoder.encodeNumber(value)
    elseif valueType == "boolean" then
        return value and "true" or "false"
    elseif valueType == "nil" then
        return "null"
    elseif valueType == "table" then
        return JsonEncoder.encodeArray(value)
    else
        error("JsonEncoder: nicht unterstuetzter Typ '" .. valueType .. "'")
    end
end

--- Kodiert ein Lua-Array (1-indizierte Sequenz) als JSON-Array.
-- Ein leeres Array wird als [] kodiert.
function JsonEncoder.encodeArray(list)
    local parts = {}
    for i = 1, #list do
        parts[i] = JsonEncoder.encodeValue(list[i])
    end
    return "[" .. table.concat(parts, ",") .. "]"
end

--- Kodiert eine Liste bereits fertig kodierter JSON-Fragmente (z.B. verschachtelte
-- Objekte, die zuvor selbst per encodeObject erzeugt wurden) als JSON-Array, ohne
-- sie erneut zu escapen. Erlaubt so verschachtelte Objekt-Arrays (z.B. "fields"),
-- ohne dass encodeValue/encodeArray selbst rekursiv Objekte verstehen muessen.
-- Eine leere Liste wird als [] kodiert.
function JsonEncoder.encodeRawArray(rawEntries)
    return "[" .. table.concat(rawEntries, ",") .. "]"
end

--- Kodiert ein Objekt mit GARANTIERTER Feldreihenfolge.
-- Lua-Tabellen haben keine definierte Iterationsreihenfolge (pairs()) - fuer ein
-- stabiles, gut lesbares telemetry.json (und deterministische Tests) wird die
-- Reihenfolge deshalb explizit als Liste von {key, value}-Paaren uebergeben.
--
-- Ein Eintrag kann statt "value" auch "raw" setzen - dann wird der String
-- unveraendert (ohne erneutes Escapen/Kodieren) als Wert eingesetzt. Das wird von
-- TelemetryCollector genutzt, um eine bereits per encodeRawArray gebaute
-- verschachtelte "fields"-Liste einzubetten.
--
-- @param orderedEntries Liste von { key = "...", value = ... }, { key = "...", raw = "..." }
--        ODER { "key", value } (Kurzschreibweise)
-- @return JSON-Objekt-String, z.B. {"money":84250,"farmId":1}
function JsonEncoder.encodeObject(orderedEntries)
    local parts = {}
    for i, entry in ipairs(orderedEntries) do
        local key = entry.key or entry[1]
        if key == nil then
            error("JsonEncoder: Objekt-Eintrag Nr. " .. i .. " hat keinen Schluessel")
        end

        local encodedValue
        if entry.raw ~= nil then
            encodedValue = entry.raw
        else
            local value = entry.value
            if value == nil then
                value = entry[2]
            end
            encodedValue = JsonEncoder.encodeValue(value)
        end

        parts[i] = '"' .. JsonEncoder.escapeString(key) .. '":' .. encodedValue
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

return JsonEncoder
