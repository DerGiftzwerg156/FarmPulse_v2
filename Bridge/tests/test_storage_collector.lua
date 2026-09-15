--[[
    test_storage_collector.lua - Unit-Tests fuer scripts/StorageCollector.lua
]]

local testkit = require("tests.testkit")

dofile("scripts/StorageCollector.lua")

return function()
    testkit.run("normalizeEntry: uebernimmt und rundet alle Felder", function()
        local entry = StorageCollector.normalizeEntry({ fillType = "WHEAT", amount = 4999.6, capacity = 20000.4 })
        testkit.assertEquals("WHEAT", entry.fillType)
        testkit.assertEquals(5000, entry.amount)
        testkit.assertEquals(20000, entry.capacity)
    end)

    testkit.run("normalizeEntry: fehlende Werte werden zu 0 bzw. 'UNKNOWN'", function()
        local entry = StorageCollector.normalizeEntry({})
        testkit.assertEquals("UNKNOWN", entry.fillType)
        testkit.assertEquals(0, entry.amount)
        testkit.assertEquals(0, entry.capacity)
    end)

    testkit.run("normalizeEntry: fehlender raw-Datensatz wird wie leere Tabelle behandelt", function()
        local entry = StorageCollector.normalizeEntry(nil)
        testkit.assertEquals("UNKNOWN", entry.fillType)
    end)

    testkit.run("normalizeEntry: negative Rohwerte werden auf 0 abgefangen", function()
        local entry = StorageCollector.normalizeEntry({ fillType = "WHEAT", amount = -5, capacity = -10 })
        testkit.assertEquals(0, entry.amount)
        testkit.assertEquals(0, entry.capacity)
    end)

    testkit.run("buildStorages: nicht-Tabellen-Eingabe liefert eine leere Liste", function()
        testkit.assertEquals(0, #StorageCollector.buildStorages(nil))
        testkit.assertEquals(0, #StorageCollector.buildStorages("keine Tabelle"))
    end)

    testkit.run("buildStorages: aggregiert mehrere Eintraege desselben Fill-Typs", function()
        local storages = StorageCollector.buildStorages({
            { fillType = "WHEAT", amount = 3000, capacity = 10000 },
            { fillType = "WHEAT", amount = 2000, capacity = 10000 },
        })
        testkit.assertEquals(1, #storages)
        testkit.assertEquals("WHEAT", storages[1].fillType)
        testkit.assertEquals(5000, storages[1].amount)
        testkit.assertEquals(20000, storages[1].capacity)
    end)

    testkit.run("buildStorages: sortiert das Ergebnis alphabetisch nach fillType", function()
        local storages = StorageCollector.buildStorages({
            { fillType = "WHEAT", amount = 1, capacity = 1 },
            { fillType = "BARLEY", amount = 1, capacity = 1 },
            { fillType = "MAIZE", amount = 1, capacity = 1 },
        })
        testkit.assertEquals("BARLEY", storages[1].fillType)
        testkit.assertEquals("MAIZE", storages[2].fillType)
        testkit.assertEquals("WHEAT", storages[3].fillType)
    end)
end
