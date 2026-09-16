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

    testkit.run("normalizeField: ohne cropRaw sind Anbaufelder nil", function()
        local field = FieldCollector.normalizeField({ id = 1, areaInHa = 1 })
        testkit.assertEquals(nil, field.fruitType)
        testkit.assertEquals(nil, field.growthState)
        testkit.assertEquals(nil, field.estimatedYieldLiters)
    end)

    testkit.run("computeCropInfo: nil-cropRaw liefert nil", function()
        testkit.assertEquals(nil, FieldCollector.computeCropInfo(nil))
    end)

    testkit.run("computeCropInfo: cropRaw ohne fruitTypeName liefert nil (kein Anbau)", function()
        testkit.assertEquals(nil, FieldCollector.computeCropInfo({ growthState = 3 }))
    end)

    testkit.run("computeCropInfo: waehrend des Wachstums liegt growthState zwischen 0 und 1", function()
        local info = FieldCollector.computeCropInfo({
            fruitTypeName = "WHEAT",
            growthState = 3,
            minHarvestingGrowthState = 6,
            literPerSqm = 0.7,
            isHarvestable = false,
            areaHa = 1,
        })
        testkit.assertEquals("WHEAT", info.fruitType)
        testkit.assertNear(0.5, info.growthState, 1e-9)
        -- areaSqm=10000, literPerSqm=0.7 -> 7000 bei voller Reife, hier zur Haelfte
        testkit.assertNear(3500, info.estimatedYieldLiters, 1e-6)
    end)

    testkit.run("computeCropInfo: erntereif liefert growthState 1 unabhaengig vom rohen Wert", function()
        local info = FieldCollector.computeCropInfo({
            fruitTypeName = "BARLEY",
            growthState = 4,
            minHarvestingGrowthState = 6,
            literPerSqm = 0.6,
            isHarvestable = true,
            areaHa = 2,
        })
        testkit.assertEquals(1, info.growthState)
        testkit.assertNear(12000, info.estimatedYieldLiters, 1e-6)
    end)

    testkit.run("computeCropInfo: growthState wird auf [0,1] begrenzt (kein minHarvestingGrowthState-Ueberlauf)", function()
        local info = FieldCollector.computeCropInfo({
            fruitTypeName = "WHEAT",
            growthState = 20,
            minHarvestingGrowthState = 6,
            literPerSqm = 1,
            isHarvestable = false,
            areaHa = 1,
        })
        testkit.assertEquals(1, info.growthState)
    end)

    testkit.run("computeCropInfo: fehlendes minHarvestingGrowthState liefert growthState 0", function()
        local info = FieldCollector.computeCropInfo({
            fruitTypeName = "WHEAT",
            growthState = 3,
            literPerSqm = 1,
            isHarvestable = false,
            areaHa = 1,
        })
        testkit.assertEquals(0, info.growthState)
        testkit.assertEquals(0, info.estimatedYieldLiters)
    end)

    testkit.run("buildFields: reichert Felder ueber rawCropsByFieldId mit Anbaudaten an", function()
        local fields = FieldCollector.buildFields(
            {
                { id = 1, farmId = 1, areaInHa = 1, price = 1000 },
                { id = 2, farmId = 1, areaInHa = 1, price = 1000 },
            },
            {
                [1] = {
                    fruitTypeName = "WHEAT",
                    growthState = 6,
                    minHarvestingGrowthState = 6,
                    literPerSqm = 0.7,
                    isHarvestable = true,
                    areaHa = 1,
                },
            }
        )
        testkit.assertEquals("WHEAT", fields[1].fruitType)
        testkit.assertEquals(1, fields[1].growthState)
        testkit.assertEquals(nil, fields[2].fruitType)
    end)
end
