--[[
    test_poll_timer.lua - Unit-Tests fuer scripts/PollTimer.lua
]]

local testkit = require("tests.testkit")

dofile("scripts/PollTimer.lua")

return function()
    testkit.run("new(): verwendet 5000ms als Standardintervall", function()
        local timer = PollTimer.new()
        testkit.assertEquals(5000, timer.intervalMs)
    end)

    testkit.run("new(): wirft Fehler bei intervalMs <= 0", function()
        testkit.assertRaises(function() PollTimer.new(0) end)
        testkit.assertRaises(function() PollTimer.new(-100) end)
    end)

    testkit.run("update(): liefert false, solange das Intervall nicht erreicht ist", function()
        local timer = PollTimer.new(5000)
        testkit.assertEquals(false, timer:update(1000))
        testkit.assertEquals(false, timer:update(3999))
    end)

    testkit.run("update(): liefert true, sobald das Intervall genau erreicht wird", function()
        local timer = PollTimer.new(5000)
        timer:update(4000)
        testkit.assertEquals(true, timer:update(1000))
    end)

    testkit.run("update(): liefert true, wenn ein einzelner dt-Schritt das Intervall ueberspringt", function()
        -- Simuliert z.B. einen kurzen Framerate-Einbruch oder eine grosse
        -- Zeitspanne zwischen zwei Frames.
        local timer = PollTimer.new(5000)
        testkit.assertEquals(true, timer:update(12000))
    end)

    testkit.run("update(): Ueberschuss wird in die naechste Periode uebernommen (kein Drift)", function()
        local timer = PollTimer.new(5000)
        timer:update(7000) -- 2000ms Ueberschuss
        testkit.assertEquals(2000, timer.accumulatedMs)
        testkit.assertEquals(false, timer:update(2999))
        testkit.assertEquals(true, timer:update(1))
    end)

    testkit.run("update(): mehrere uebersprungene Intervalle in einem Schritt werden korrekt verrechnet", function()
        local timer = PollTimer.new(5000)
        testkit.assertEquals(true, timer:update(23000)) -- 4x 5000 + 3000 Rest
        testkit.assertEquals(3000, timer.accumulatedMs)
    end)

    testkit.run("update(): negative oder fehlende dt-Werte werden wie 0 behandelt", function()
        local timer = PollTimer.new(5000)
        testkit.assertEquals(false, timer:update(-100))
        testkit.assertEquals(false, timer:update(nil))
        testkit.assertEquals(0, timer.accumulatedMs)
    end)

    testkit.run("reset(): setzt den akkumulierten Wert zurueck", function()
        local timer = PollTimer.new(5000)
        timer:update(3000)
        timer:reset()
        testkit.assertEquals(0, timer.accumulatedMs)
    end)
end
