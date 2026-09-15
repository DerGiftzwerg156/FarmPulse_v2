--[[
    test_field_collector.lua - Unit-Tests fuer scripts/FieldCollector.lua
]]

local testkit = require("tests.testkit")

dofile("scripts/FieldCollector.lua")

return function()
    testkit.run("normalizeField: uebernimmt und rundet alle Felder", function()
        local field = FieldCollector.normalizeField({ id = 3, farmId = 1, areaInHa = 4.526, price = 31999.6 })
        testkit.assertEquals(3, field.fieldId)
        testkit.assertEquals(1, field.ownerFarmId)
        testkit.assertNear(4.53, field.sizeHa, 1e-9)
        testkit.assertEquals(32000, field.price)
    end)

    testkit.run("normalizeField: fehlende Werte werden zu 0", function()
        local field = FieldCollector.normalizeField({ id = 1 })
        testkit.assertEquals(0, field.ownerFarmId)
        testkit.assertNear(0, field.sizeHa, 1e-9)
        testkit.assertEquals(0, field.price)
    end)

    testkit.run("normalizeField: fehlender raw-Datensatz wird wie leere Tabelle behandelt", function()
        local field = FieldCollector.normalizeField(nil)
        testkit.assertEquals(0, field.fieldId)
        testkit.assertEquals(0, field.ownerFarmId)
    end)

    testkit.run("normalizeField: negative Rohwerte werden auf 0 abgefangen", function()
        local field = FieldCollector.normalizeField({ id = -1, farmId = -2, price = -100 })
        testkit.assertEquals(0, field.fieldId)
        testkit.assertEquals(0, field.ownerFarmId)
        testkit.assertEquals(0, field.price)
    end)

    testkit.run("buildFields: nicht-Tabellen-Eingabe liefert eine leere Liste", function()
        testkit.assertEquals(0, #FieldCollector.buildFields(nil))
        testkit.assertEquals(0, #FieldCollector.buildFields("keine Tabelle"))
    end)

    testkit.run("buildFields: leere Liste bleibt leer", function()
        testkit.assertEquals(0, #FieldCollector.buildFields({}))
    end)

    testkit.run("buildFields: normalisiert jeden Eintrag", function()
        local fields = FieldCollector.buildFields({
            { id = 1, farmId = 0, areaInHa = 2.5, price = 10000 },
            { id = 2, farmId = 1, areaInHa = 6.12, price = 45000 },
        })
        testkit.assertEquals(2, #fields)
        testkit.assertEquals(1, fields[1].fieldId)
        testkit.assertEquals(0, fields[1].ownerFarmId)
        testkit.assertEquals(2, fields[2].fieldId)
        testkit.assertEquals(1, fields[2].ownerFarmId)
    end)

    testkit.run("buildFields: sortiert das Ergebnis stabil nach fieldId, unabhaengig von der Eingabereihenfolge", function()
        local fields = FieldCollector.buildFields({
            { id = 5, areaInHa = 1 },
            { id = 2, areaInHa = 1 },
            { id = 9, areaInHa = 1 },
        })
        testkit.assertEquals(2, fields[1].fieldId)
        testkit.assertEquals(5, fields[2].fieldId)
        testkit.assertEquals(9, fields[3].fieldId)
    end)
end
