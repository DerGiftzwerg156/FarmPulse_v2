--[[
    test_weather_collector.lua - Unit-Tests fuer scripts/WeatherCollector.lua
]]

local testkit = require("tests.testkit")

dofile("scripts/WeatherCollector.lua")

return function()
    testkit.run("seasonFromMonth: Winter-Monate (12, 1, 2)", function()
        testkit.assertEquals("winter", WeatherCollector.seasonFromMonth(12))
        testkit.assertEquals("winter", WeatherCollector.seasonFromMonth(1))
        testkit.assertEquals("winter", WeatherCollector.seasonFromMonth(2))
    end)

    testkit.run("seasonFromMonth: Fruehlings-Monate (3-5)", function()
        testkit.assertEquals("spring", WeatherCollector.seasonFromMonth(3))
        testkit.assertEquals("spring", WeatherCollector.seasonFromMonth(4))
        testkit.assertEquals("spring", WeatherCollector.seasonFromMonth(5))
    end)

    testkit.run("seasonFromMonth: Sommer-Monate (6-8)", function()
        testkit.assertEquals("summer", WeatherCollector.seasonFromMonth(6))
        testkit.assertEquals("summer", WeatherCollector.seasonFromMonth(7))
        testkit.assertEquals("summer", WeatherCollector.seasonFromMonth(8))
    end)

    testkit.run("seasonFromMonth: Herbst-Monate (9-11)", function()
        testkit.assertEquals("autumn", WeatherCollector.seasonFromMonth(9))
        testkit.assertEquals("autumn", WeatherCollector.seasonFromMonth(10))
        testkit.assertEquals("autumn", WeatherCollector.seasonFromMonth(11))
    end)

    testkit.run("seasonFromMonth: ungueltiger Monat liefert 'unknown'", function()
        testkit.assertEquals("unknown", WeatherCollector.seasonFromMonth(0))
        testkit.assertEquals("unknown", WeatherCollector.seasonFromMonth(13))
        testkit.assertEquals("unknown", WeatherCollector.seasonFromMonth(nil))
    end)

    testkit.run("seasonFromMonth: Nachkommastellen werden abgeschnitten", function()
        testkit.assertEquals("spring", WeatherCollector.seasonFromMonth(3.9))
    end)

    testkit.run("normalizeWeather: gueltiger String bleibt unveraendert", function()
        testkit.assertEquals("rain", WeatherCollector.normalizeWeather("rain"))
    end)

    testkit.run("normalizeWeather: nil/leerer String/Nicht-String werden zu 'unknown'", function()
        testkit.assertEquals("unknown", WeatherCollector.normalizeWeather(nil))
        testkit.assertEquals("unknown", WeatherCollector.normalizeWeather(""))
        testkit.assertEquals("unknown", WeatherCollector.normalizeWeather(42))
    end)
end
