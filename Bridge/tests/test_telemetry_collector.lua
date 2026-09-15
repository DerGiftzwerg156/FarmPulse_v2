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
            season = "summer",
            weather = "sun",
        })
        testkit.assertEquals(8, payload.hour)
        testkit.assertEquals(30, payload.minute)
        testkit.assertEquals(4, payload.day)
        testkit.assertEquals(6, payload.month)
        testkit.assertEquals(2, payload.year)
        testkit.assertEquals(3, payload.daysPerMonth)
        testkit.assertEquals(84250, payload.money)
        testkit.assertEquals(1, payload.farmId)
        testkit.assertEquals("summer", payload.season)
        testkit.assertEquals("sun", payload.weather)
    end)

    testkit.run("buildPayload: erlaubt negativen Kontostand", function()
        local payload = TelemetryCollector.buildPayload({ money = -500 })
        testkit.assertEquals(-500, payload.money)
    end)

    testkit.run("buildPayload: fehlende/ungueltige season/weather werden zu 'unknown'", function()
        local payload = TelemetryCollector.buildPayload({ season = nil, weather = 42 })
        testkit.assertEquals("unknown", payload.season)
        testkit.assertEquals("unknown", payload.weather)
    end)

    testkit.run("buildPayload: leerer season/weather-String wird zu 'unknown'", function()
        local payload = TelemetryCollector.buildPayload({ season = "", weather = "" })
        testkit.assertEquals("unknown", payload.season)
        testkit.assertEquals("unknown", payload.weather)
    end)

    testkit.run("buildPayload: fehlender rawState wird wie leere Tabelle behandelt", function()
        local payload = TelemetryCollector.buildPayload(nil)
        testkit.assertEquals(0, payload.hour)
        testkit.assertEquals(0, payload.money)
        testkit.assertEquals("unknown", payload.season)
        testkit.assertEquals("unknown", payload.weather)
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
            season = "summer",
            weather = "sun",
        })
        testkit.assertEquals(
            '{"hour":8,"minute":30,"day":4,"month":6,"year":2,"daysPerMonth":3,"money":84250,"farmId":1,'
                .. '"season":"summer","weather":"sun"}',
            TelemetryCollector.toJson(payload)
        )
    end)

    testkit.run("toJson: 'unknown' wird wie jeder andere String kodiert", function()
        local payload = TelemetryCollector.buildPayload({ money = 100, farmId = 1 })
        testkit.assertEquals(
            '{"hour":0,"minute":0,"day":0,"month":0,"year":0,"daysPerMonth":0,"money":100,"farmId":1,'
                .. '"season":"unknown","weather":"unknown"}',
            TelemetryCollector.toJson(payload)
        )
    end)
end
