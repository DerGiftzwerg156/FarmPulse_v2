--[[
    test_telemetry_collector.lua - Unit-Tests fuer scripts/TelemetryCollector.lua
]]

local testkit = require("tests.testkit")

dofile("scripts/JsonEncoder.lua")
dofile("scripts/TelemetryCollector.lua")

return function()
    testkit.run("normalizeHour: Wert innerhalb des Tages bleibt unveraendert", function()
        testkit.assertEquals(8, TelemetryCollector.normalizeHour(8))
    end)

    testkit.run("normalizeHour: Wert >= 24 wird umgebrochen", function()
        testkit.assertEquals(2, TelemetryCollector.normalizeHour(26))
    end)

    testkit.run("normalizeHour: negativer Wert wird korrekt in den gueltigen Bereich gebracht", function()
        testkit.assertEquals(23, TelemetryCollector.normalizeHour(-1))
    end)

    testkit.run("normalizeMinute: Wert innerhalb der Stunde bleibt unveraendert", function()
        testkit.assertEquals(30, TelemetryCollector.normalizeMinute(30))
    end)

    testkit.run("normalizeMinute: Wert >= 60 wird umgebrochen", function()
        testkit.assertEquals(5, TelemetryCollector.normalizeMinute(65))
    end)

    testkit.run("normalizeMinute: negativer Wert wird korrekt in den gueltigen Bereich gebracht", function()
        testkit.assertEquals(59, TelemetryCollector.normalizeMinute(-1))
    end)

    testkit.run("buildPayload: normalisiert alle Felder", function()
        local payload = TelemetryCollector.buildPayload({
            hour = 8,
            minute = 30,
            day = 4,
            month = 6,
            year = 2,
            daysPerMonth = 3,
            money = 84250,
            farmId = 1,
            weatherType = "RAIN",
            temperature = 11.4,
        })
        testkit.assertEquals(8, payload.hour)
        testkit.assertEquals(30, payload.minute)
        testkit.assertEquals(4, payload.day)
        testkit.assertEquals(6, payload.month)
        testkit.assertEquals(2, payload.year)
        testkit.assertEquals(3, payload.daysPerMonth)
        testkit.assertEquals(84250, payload.money)
        testkit.assertEquals(1, payload.farmId)
        testkit.assertEquals("RAIN", payload.weatherType)
        testkit.assertEquals(11.4, payload.temperature)
    end)

    testkit.run("buildPayload: erlaubt negativen Kontostand", function()
        local payload = TelemetryCollector.buildPayload({ money = -500 })
        testkit.assertEquals(-500, payload.money)
    end)

    testkit.run("buildPayload: erlaubt negative Temperatur", function()
        local payload = TelemetryCollector.buildPayload({ temperature = -4.5 })
        testkit.assertEquals(-4.5, payload.temperature)
    end)

    testkit.run("buildPayload: unbekannter/fehlender Wettertyp wird zu UNKNOWN", function()
        testkit.assertEquals("UNKNOWN", TelemetryCollector.buildPayload({}).weatherType)
        testkit.assertEquals("UNKNOWN", TelemetryCollector.buildPayload({ weatherType = "TORNADO" }).weatherType)
    end)

    testkit.run("buildPayload: fehlender rawState wird wie leere Tabelle behandelt", function()
        local payload = TelemetryCollector.buildPayload(nil)
        testkit.assertEquals(0, payload.hour)
        testkit.assertEquals(0, payload.money)
        testkit.assertEquals("UNKNOWN", payload.weatherType)
        testkit.assertEquals(0, payload.temperature)
    end)

    testkit.run("toJson: liefert das erwartete Format", function()
        local payload = TelemetryCollector.buildPayload({
            hour = 8,
            minute = 30,
            day = 4,
            month = 6,
            year = 2,
            daysPerMonth = 3,
            money = 84250,
            farmId = 1,
            weatherType = "SUN",
            temperature = 11.4,
        })
        testkit.assertEquals(
            '{"hour":8,"minute":30,"day":4,"month":6,"year":2,"daysPerMonth":3,"money":84250,"farmId":1,'
                .. '"weatherType":"SUN","temperature":11.40}',
            TelemetryCollector.toJson(payload)
        )
    end)
end
