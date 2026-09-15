--[[
    test_telemetry_collector.lua - Unit-Tests fuer scripts/TelemetryCollector.lua
]]

local testkit = require("tests.testkit")

dofile("scripts/JsonEncoder.lua")
dofile("scripts/FieldCollector.lua")
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

    testkit.run("buildPayload: normalisiert alle Felder und ergaenzt fehlende fields als leere Liste", function()
        local payload = TelemetryCollector.buildPayload({
            hour = 8,
            minute = 30,
            day = 4,
            month = 6,
            year = 2,
            daysPerMonth = 3,
            money = 84250,
            farmId = 1,
        })
        testkit.assertEquals(8, payload.hour)
        testkit.assertEquals(30, payload.minute)
        testkit.assertEquals(4, payload.day)
        testkit.assertEquals(6, payload.month)
        testkit.assertEquals(2, payload.year)
        testkit.assertEquals(3, payload.daysPerMonth)
        testkit.assertEquals(84250, payload.money)
        testkit.assertEquals(1, payload.farmId)
        testkit.assertEquals(0, #payload.fields)
    end)

    testkit.run("buildPayload: erlaubt negativen Kontostand", function()
        local payload = TelemetryCollector.buildPayload({ money = -500 })
        testkit.assertEquals(-500, payload.money)
    end)

    testkit.run("buildPayload: uebernimmt eine uebergebene fields-Liste", function()
        local fields = FieldCollector.buildFields({ { id = 1, farmId = 0, areaInHa = 4.5, price = 32000 } })
        local payload = TelemetryCollector.buildPayload({ fields = fields })
        testkit.assertEquals(1, #payload.fields)
        testkit.assertEquals(1, payload.fields[1].fieldId)
    end)

    testkit.run("buildPayload: fehlender rawState wird wie leere Tabelle behandelt", function()
        local payload = TelemetryCollector.buildPayload(nil)
        testkit.assertEquals(0, payload.hour)
        testkit.assertEquals(0, payload.money)
        testkit.assertEquals(0, #payload.fields)
    end)

    testkit.run("toJson: liefert das erwartete Format ohne Felder", function()
        local payload = TelemetryCollector.buildPayload({
            hour = 8,
            minute = 30,
            day = 4,
            month = 6,
            year = 2,
            daysPerMonth = 3,
            money = 84250,
            farmId = 1,
        })
        testkit.assertEquals(
            '{"hour":8,"minute":30,"day":4,"month":6,"year":2,"daysPerMonth":3,"money":84250,"farmId":1,"fields":[]}',
            TelemetryCollector.toJson(payload)
        )
    end)

    testkit.run("toJson: serialisiert die fields-Liste als verschachteltes Array", function()
        local fields = FieldCollector.buildFields({
            { id = 1, farmId = 0, areaInHa = 4.53, price = 32000 },
            { id = 2, farmId = 1, areaInHa = 6.1, price = 45000 },
        })
        local payload = TelemetryCollector.buildPayload({ money = 100, farmId = 1, fields = fields })
        testkit.assertEquals(
            '{"hour":0,"minute":0,"day":0,"month":0,"year":0,"daysPerMonth":0,"money":100,"farmId":1,'
                .. '"fields":[{"fieldId":1,"ownerFarmId":0,"sizeHa":4.53,"price":32000},'
                .. '{"fieldId":2,"ownerFarmId":1,"sizeHa":6.10,"price":45000}]}',
            TelemetryCollector.toJson(payload)
        )
    end)
end
