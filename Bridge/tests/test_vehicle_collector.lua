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

    testkit.run("normalizeVehicle: uebernimmt und rundet alle Felder", function()
        local vehicle = VehicleCollector.normalizeVehicle({
            name = "John Deere 8R 410",
            horsepowerHp = 410.4,
            operatingHours = 128.456,
            conditionPercent = 91.999,
            sellPrice = 245000.4,
        })
        testkit.assertEquals("John Deere 8R 410", vehicle.name)
        testkit.assertEquals(410, vehicle.horsepowerHp)
        testkit.assertEquals(128.46, vehicle.operatingHours)
        testkit.assertEquals(92.0, vehicle.conditionPercent)
        testkit.assertEquals(245000, vehicle.sellPrice)
    end)

    testkit.run("normalizeVehicle: fehlender/leerer Name wird zum Fallback", function()
        testkit.assertEquals("Unbekanntes Fahrzeug", VehicleCollector.normalizeVehicle({}).name)
        testkit.assertEquals("Unbekanntes Fahrzeug", VehicleCollector.normalizeVehicle({ name = "   " }).name)
        testkit.assertEquals("Unbekanntes Fahrzeug", VehicleCollector.normalizeVehicle({ name = nil }).name)
    end)

    testkit.run("normalizeVehicle: nicht lesbare Detailwerte werden zu nil statt 0", function()
        local vehicle = VehicleCollector.normalizeVehicle({ name = "Anhaenger" })
        testkit.assertEquals(nil, vehicle.horsepowerHp)
        testkit.assertEquals(nil, vehicle.operatingHours)
        testkit.assertEquals(nil, vehicle.conditionPercent)
        testkit.assertEquals(0, vehicle.sellPrice)
    end)

    testkit.run("normalizeVehicle: negativer/nicht-numerischer PS-Wert wird zu nil", function()
        testkit.assertEquals(nil, VehicleCollector.normalizeVehicle({ horsepowerHp = -50 }).horsepowerHp)
        testkit.assertEquals(nil, VehicleCollector.normalizeVehicle({ horsepowerHp = "viel" }).horsepowerHp)
    end)

    testkit.run("normalizeVehicle: conditionPercent wird auf 0..100 begrenzt", function()
        testkit.assertEquals(100, VehicleCollector.normalizeVehicle({ conditionPercent = 140 }).conditionPercent)
        testkit.assertEquals(0, VehicleCollector.normalizeVehicle({ conditionPercent = -10 }).conditionPercent)
    end)

    testkit.run("normalizeVehicle: negativer Verkaufspreis wird auf 0 abgefangen", function()
        testkit.assertEquals(0, VehicleCollector.normalizeVehicle({ sellPrice = -100 }).sellPrice)
    end)

    testkit.run("buildVehicles: nicht-Tabellen-Eingabe liefert eine leere Liste", function()
        testkit.assertEquals(0, #VehicleCollector.buildVehicles(nil))
        testkit.assertEquals(0, #VehicleCollector.buildVehicles("keine Tabelle"))
    end)

    testkit.run("buildVehicles: normalisiert und sortiert alphabetisch nach Name", function()
        local vehicles = VehicleCollector.buildVehicles({
            { name = "Trecker B", sellPrice = 1000 },
            { name = "Trecker A", sellPrice = 2000 },
        })
        testkit.assertEquals(2, #vehicles)
        testkit.assertEquals("Trecker A", vehicles[1].name)
        testkit.assertEquals("Trecker B", vehicles[2].name)
    end)

    testkit.run("buildVehicles: bei gleichem Namen wird nach Verkaufspreis absteigend sortiert", function()
        local vehicles = VehicleCollector.buildVehicles({
            { name = "Trecker", sellPrice = 1000 },
            { name = "Trecker", sellPrice = 5000 },
        })
        testkit.assertEquals(5000, vehicles[1].sellPrice)
        testkit.assertEquals(1000, vehicles[2].sellPrice)
    end)
end
