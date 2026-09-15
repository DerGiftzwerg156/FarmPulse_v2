--[[
    test_json_encoder.lua - Unit-Tests fuer scripts/JsonEncoder.lua
]]

local testkit = require("tests.testkit")

-- JsonEncoder.lua deklariert die Tabelle bewusst global (siehe Dateikommentar
-- dort) - dofile fuehrt die Datei im aktuellen globalen Namensraum aus, danach
-- ist `JsonEncoder` verfuegbar.
dofile("scripts/JsonEncoder.lua")

return function()
    testkit.run("encodeValue: String wird escaped und in Anfuehrungszeichen gesetzt", function()
        testkit.assertEquals('"hallo"', JsonEncoder.encodeValue("hallo"))
    end)

    testkit.run("encodeValue: Sonderzeichen werden korrekt escaped", function()
        testkit.assertEquals('"a\\"b\\\\c\\nd"', JsonEncoder.encodeValue('a"b\\c\nd'))
    end)

    testkit.run("encodeValue: Ganzzahlen ohne Nachkommastellen", function()
        testkit.assertEquals("84250", JsonEncoder.encodeValue(84250))
    end)

    testkit.run("encodeValue: negative Ganzzahlen (z.B. Kontostand im Minus)", function()
        testkit.assertEquals("-500", JsonEncoder.encodeValue(-500))
    end)

    testkit.run("encodeValue: Fliesskommazahlen mit fester Genauigkeit (2 Nachkommastellen)", function()
        testkit.assertEquals("4.53", JsonEncoder.encodeValue(4.53))
        testkit.assertEquals("6.10", JsonEncoder.encodeValue(6.1))
    end)

    testkit.run("encodeValue: Boolean true/false", function()
        testkit.assertEquals("true", JsonEncoder.encodeValue(true))
        testkit.assertEquals("false", JsonEncoder.encodeValue(false))
    end)

    testkit.run("encodeValue: nil wird zu null", function()
        testkit.assertEquals("null", JsonEncoder.encodeValue(nil))
    end)

    testkit.run("encodeValue: NaN wirft einen Fehler", function()
        local nan = 0 / 0
        testkit.assertRaises(function() JsonEncoder.encodeValue(nan) end)
    end)

    testkit.run("encodeArray: leeres Array wird zu []", function()
        testkit.assertEquals("[]", JsonEncoder.encodeArray({}))
    end)

    testkit.run("encodeArray: Array von Strings", function()
        testkit.assertEquals('["A","B"]', JsonEncoder.encodeArray({ "A", "B" }))
    end)

    testkit.run("encodeRawArray: leere Liste wird zu []", function()
        testkit.assertEquals("[]", JsonEncoder.encodeRawArray({}))
    end)

    testkit.run("encodeRawArray: fuegt vorab kodierte Fragmente ohne erneutes Escapen zusammen", function()
        local json = JsonEncoder.encodeRawArray({ '{"a":1}', '{"a":2}' })
        testkit.assertEquals('[{"a":1},{"a":2}]', json)
    end)

    testkit.run("encodeObject: feste Feldreihenfolge", function()
        local json = JsonEncoder.encodeObject({
            { key = "money", value = 84250 },
            { key = "farmId", value = 1 },
        })
        testkit.assertEquals('{"money":84250,"farmId":1}', json)
    end)

    testkit.run("encodeObject: unterstuetzt auch {key, value}-Kurzschreibweise", function()
        local json = JsonEncoder.encodeObject({
            { "money", 100 },
        })
        testkit.assertEquals('{"money":100}', json)
    end)

    testkit.run("encodeObject: 'raw'-Eintrag wird unveraendert eingesetzt (fuer verschachtelte Arrays)", function()
        local json = JsonEncoder.encodeObject({
            { key = "money", value = 100 },
            { key = "fields", raw = JsonEncoder.encodeRawArray({ '{"fieldId":1}' }) },
        })
        testkit.assertEquals('{"money":100,"fields":[{"fieldId":1}]}', json)
    end)

    testkit.run("encodeObject: fehlender Schluessel wirft einen Fehler", function()
        testkit.assertRaises(function()
            JsonEncoder.encodeObject({ { value = 1 } })
        end)
    end)
end
