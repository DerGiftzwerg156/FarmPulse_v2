--[[
    test_vehicle_collector.lua - Unit-Tests fuer scripts/VehicleCollector.lua
]]

local testkit = require("tests.testkit")

dofile("scripts/VehicleCollector.lua")

return function()
    testkit.run("buildFleetValue: summiert eine Liste von Preisen", function()
        testkit.assertEquals(150000, VehicleCollector.buildFleetValue({ 50000, 75000, 25000 }))
    end)

    testkit.run("buildFleetValue: rundet das Ergebnis", function()
        testkit.assertEquals(100, VehicleCollector.buildFleetValue({ 49.6, 50.1 }))
    end)

    testkit.run("buildFleetValue: ignoriert nicht-numerische Eintraege", function()
        testkit.assertEquals(100, VehicleCollector.buildFleetValue({ 100, "kaputt", nil, true }))
    end)

    testkit.run("buildFleetValue: ignoriert negative/Null-Eintraege", function()
        testkit.assertEquals(100, VehicleCollector.buildFleetValue({ 100, -50, 0 }))
    end)

    testkit.run("buildFleetValue: leere Liste liefert 0", function()
        testkit.assertEquals(0, VehicleCollector.buildFleetValue({}))
    end)

    testkit.run("buildFleetValue: Nicht-Tabellen-Eingabe liefert 0", function()
        testkit.assertEquals(0, VehicleCollector.buildFleetValue(nil))
        testkit.assertEquals(0, VehicleCollector.buildFleetValue("keine Tabelle"))
    end)
end
