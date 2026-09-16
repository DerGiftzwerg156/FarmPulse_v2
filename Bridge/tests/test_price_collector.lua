--[[
    test_price_collector.lua - Unit-Tests fuer scripts/PriceCollector.lua
]]

local testkit = require("tests.testkit")

dofile("scripts/PriceCollector.lua")

return function()
    testkit.run("findBestPrice: nicht-Tabellen-Eingabe liefert nil, nil", function()
        local price, period = PriceCollector.findBestPrice(nil)
        testkit.assertEquals(nil, price)
        testkit.assertEquals(nil, period)

        price, period = PriceCollector.findBestPrice("keine Tabelle")
        testkit.assertEquals(nil, price)
        testkit.assertEquals(nil, period)
    end)

    testkit.run("findBestPrice: leere Historie liefert nil, nil", function()
        local price, period = PriceCollector.findBestPrice({})
        testkit.assertEquals(nil, price)
        testkit.assertEquals(nil, period)
    end)

    testkit.run("findBestPrice: findet den Hoechstwert und dessen Periode", function()
        local price, period = PriceCollector.findBestPrice({
            [1] = 0.2, [2] = 0.18, [3] = 0.254, [4] = 0.21,
        })
        testkit.assertNear(254.0, price, 0.001)
        testkit.assertEquals(3, period)
    end)

    testkit.run("findBestPrice: rechnet von Euro/Liter in Euro/1000L um und rundet auf 2 Nachkommastellen", function()
        local price = PriceCollector.findBestPrice({ [1] = 0.123456 })
        testkit.assertNear(123.46, price, 0.001)
    end)

    testkit.run("findBestPrice: ueberspringt Perioden ohne numerischen Wert", function()
        local price, period = PriceCollector.findBestPrice({ [1] = 0.1, [2] = "unbekannt", [5] = 0.3 })
        testkit.assertNear(300.0, price, 0.001)
        testkit.assertEquals(5, period)
    end)

    testkit.run("withPrice: uebernimmt Storage-Felder und ergaenzt Preisfelder", function()
        local storage = { fillType = "WHEAT", amount = 9500, capacity = 10000 }
        local priced = PriceCollector.withPrice(storage, 0.2184, { [3] = 0.2541 }, "März")

        testkit.assertEquals("WHEAT", priced.fillType)
        testkit.assertEquals(9500, priced.amount)
        testkit.assertEquals(10000, priced.capacity)
        testkit.assertNear(218.4, priced.currentPricePer1000L, 0.001)
        testkit.assertNear(254.1, priced.bestPricePer1000L, 0.001)
        testkit.assertEquals(3, priced.bestPricePeriod)
        testkit.assertEquals("März", priced.bestPricePeriodLabel)
    end)

    testkit.run("withPrice: fehlender aktueller Preis/Historie wird zu nil, kein Label ohne Periode", function()
        local priced = PriceCollector.withPrice({ fillType = "WHEAT", amount = 1, capacity = 1 }, nil, nil, "sollte ignoriert werden")

        testkit.assertEquals(nil, priced.currentPricePer1000L)
        testkit.assertEquals(nil, priced.bestPricePer1000L)
        testkit.assertEquals(nil, priced.bestPricePeriod)
        testkit.assertEquals(nil, priced.bestPricePeriodLabel)
    end)

    testkit.run("withPrice: fehlender Storage-Datensatz wird wie leere Tabelle behandelt", function()
        local priced = PriceCollector.withPrice(nil, nil, nil, nil)
        testkit.assertEquals(nil, priced.fillType)
    end)
end
