--[[
    testkit.lua

    Winzige Assertion-/Test-Runner-Hilfsbibliothek fuer die reinen Lua-Module der
    FarmPulse Bridge (JsonEncoder, PollTimer, FieldCollector, TelemetryCollector).
    Kein externes Test-Framework noetig - die Module sind bewusst so klein und
    abhaengigkeitsfrei gehalten, dass ein paar assert()-Helfer und ein einfacher
    Runner ausreichen.

    Aufruf: lua tests/run_tests.lua  (siehe dort)
]]

local testkit = {}

testkit.results = {
    passed = 0,
    failed = 0,
    failures = {},
}

function testkit.reset()
    testkit.results.passed = 0
    testkit.results.failed = 0
    testkit.results.failures = {}
end

local function recordFailure(testName, message)
    testkit.results.failed = testkit.results.failed + 1
    table.insert(testkit.results.failures, { name = testName, message = message })
    io.write("  [FAIL] " .. testName .. ": " .. message .. "\n")
end

local function recordSuccess(testName)
    testkit.results.passed = testkit.results.passed + 1
    io.write("  [ OK ] " .. testName .. "\n")
end

--- Fuehrt eine benannte Testfunktion aus und faengt Fehler ab, damit ein
-- fehlschlagender Test nicht die gesamte Suite abbricht.
function testkit.run(testName, testFunction)
    local ok, err = pcall(testFunction)
    if ok then
        recordSuccess(testName)
    else
        recordFailure(testName, tostring(err))
    end
end

function testkit.assertEquals(expected, actual, context)
    if expected ~= actual then
        error(string.format("%serwartet '%s', erhalten '%s'", context and (context .. ": ") or "", tostring(expected), tostring(actual)), 2)
    end
end

function testkit.assertTrue(value, context)
    if value ~= true then
        error((context or "Wert") .. " sollte true sein, war " .. tostring(value), 2)
    end
end

function testkit.assertNear(expected, actual, tolerance, context)
    tolerance = tolerance or 1e-9
    if math.abs(expected - actual) > tolerance then
        error(string.format("%serwartet ~%s, erhalten %s", context and (context .. ": ") or "", tostring(expected), tostring(actual)), 2)
    end
end

function testkit.assertRaises(fn, context)
    local ok = pcall(fn)
    if ok then
        error((context or "Aufruf") .. " haette einen Fehler werfen sollen", 2)
    end
end

--- Gibt eine Zusammenfassung aus und liefert einen fuer os.exit() geeigneten
-- Exit-Code zurueck (0 = alles gruen, 1 = mind. ein Fehlschlag).
function testkit.summaryExitCode()
    io.write("\n" .. testkit.results.passed .. " bestanden, " .. testkit.results.failed .. " fehlgeschlagen\n")
    if testkit.results.failed > 0 then
        return 1
    end
    return 0
end

return testkit
