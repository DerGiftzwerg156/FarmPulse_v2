--[[
    test_world_collector.lua - Unit-Tests fuer scripts/WorldCollector.lua
]]

local testkit = require("tests.testkit")

dofile("scripts/JsonEncoder.lua")
dofile("scripts/FieldCollector.lua")
dofile("scripts/StorageCollector.lua")
dofile("scripts/WorldCollector.lua")

return function()
    testkit.run("buildPayload: normalisiert alle Felder und ergaenzt fehlende Listen als leer", function()
        local payload = WorldCollector.buildPayload({ fleetValue = 1000.4 })
        testkit.assertEquals(1000, payload.fleetValue)
        testkit.assertEquals(0, #payload.fields)
        testkit.assertEquals(0, #payload.storages)
    end)

    testkit.run("buildPayload: negativer fleetValue wird auf 0 abgefangen", function()
        local payload = WorldCollector.buildPayload({ fleetValue = -100 })
        testkit.assertEquals(0, payload.fleetValue)
    end)

    testkit.run("buildPayload: fehlender rawState wird wie leere Tabelle behandelt", function()
        local payload = WorldCollector.buildPayload(nil)
        testkit.assertEquals(0, payload.fleetValue)
        testkit.assertEquals(0, #payload.fields)
        testkit.assertEquals(0, #payload.storages)
    end)

    testkit.run("buildPayload: uebernimmt uebergebene fields-/storages-Listen", function()
        local fields = FieldCollector.buildFields({ { id = 1, farmId = 0, areaInHa = 4.5, price = 32000 } })
        local storages = StorageCollector.buildStorages({ { fillType = "WHEAT", amount = 100, capacity = 1000 } })
        local payload = WorldCollector.buildPayload({ fields = fields, storages = storages, fleetValue = 500 })
        testkit.assertEquals(1, #payload.fields)
        testkit.assertEquals(1, payload.fields[1].fieldId)
        testkit.assertEquals(1, #payload.storages)
        testkit.assertEquals("WHEAT", payload.storages[1].fillType)
    end)

    testkit.run("toJson: liefert das erwartete Format ohne Felder/Lager", function()
        local payload = WorldCollector.buildPayload({ fleetValue = 125000 })
        testkit.assertEquals(
            '{"fleetValue":125000,"fields":[],"storages":[]}',
            WorldCollector.toJson(payload)
        )
    end)

    testkit.run("toJson: serialisiert fields und storages als verschachtelte Arrays", function()
        local fields = FieldCollector.buildFields({
            { id = 1, farmId = 0, areaInHa = 4.53, price = 32000 },
        })
        local storages = StorageCollector.buildStorages({
            { fillType = "WHEAT", amount = 5000, capacity = 20000 },
        })
        local payload = WorldCollector.buildPayload({ fields = fields, storages = storages, fleetValue = 100 })
        testkit.assertEquals(
            '{"fleetValue":100,'
                .. '"fields":[{"fieldId":1,"ownerFarmId":0,"sizeHa":4.53,"price":32000,'
                .. '"fruitType":null,"growthState":null,"estimatedYieldLiters":null}],'
                .. '"storages":[{"fillType":"WHEAT","amount":5000,"capacity":20000}]}',
            WorldCollector.toJson(payload)
        )
    end)
end
