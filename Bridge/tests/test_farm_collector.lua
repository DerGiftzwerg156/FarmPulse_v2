--[[
    test_farm_collector.lua - Unit-Tests fuer scripts/FarmCollector.lua
]]

local testkit = require("tests.testkit")

dofile("scripts/JsonEncoder.lua")
dofile("scripts/FarmCollector.lua")

return function()
    testkit.run("buildPayload: uebernimmt gueltige Namen", function()
        local payload = FarmCollector.buildPayload({ farmName = "Sonnenhof", playerName = "Keno" })
        testkit.assertEquals("Sonnenhof", payload.farmName)
        testkit.assertEquals("Keno", payload.playerName)
    end)

    testkit.run("buildPayload: trimmt umgebende Leerzeichen", function()
        local payload = FarmCollector.buildPayload({ farmName = "  Sonnenhof  " })
        testkit.assertEquals("Sonnenhof", payload.farmName)
    end)

    testkit.run("buildPayload: nil/leere/nur-Leerzeichen-Namen werden zum Fallback", function()
        local payload = FarmCollector.buildPayload({ farmName = nil, playerName = "   " })
        testkit.assertEquals("Unbekannt", payload.farmName)
        testkit.assertEquals("Unbekannt", payload.playerName)
    end)

    testkit.run("buildPayload: Nicht-String-Werte werden zum Fallback", function()
        local payload = FarmCollector.buildPayload({ farmName = 42 })
        testkit.assertEquals("Unbekannt", payload.farmName)
    end)

    testkit.run("buildPayload: fehlender rawState wird wie leere Tabelle behandelt", function()
        local payload = FarmCollector.buildPayload(nil)
        testkit.assertEquals("Unbekannt", payload.farmName)
        testkit.assertEquals("Unbekannt", payload.playerName)
    end)

    testkit.run("toJson: liefert das erwartete Format", function()
        local payload = FarmCollector.buildPayload({ farmName = "Sonnenhof", playerName = "Keno" })
        testkit.assertEquals(
            '{"farmName":"Sonnenhof","playerName":"Keno"}',
            FarmCollector.toJson(payload)
        )
    end)
end
