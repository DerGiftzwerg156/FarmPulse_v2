--[[
    run_tests.lua - Einstiegspunkt fuer die reinen Lua-Unit-Tests der FarmPulse
    Bridge.

    Ausfuehren aus dem Verzeichnis Bridge/:

        lua tests/run_tests.lua

    Getestet werden ausschliesslich die GIANTS-unabhaengigen Logikmodule
    (JsonEncoder, PollTimer, FieldCollector, VehicleCollector, StorageCollector,
    FarmCollector, WorldCollector, TelemetryCollector) -
    FarmPulseBridge.lua selbst (die GIANTS-Engine-Glue) ist NICHT auf diese
    Weise testbar, siehe README.md, Abschnitt "Tests ausfuehren".
]]

package.path = package.path .. ";./?.lua"

local testkit = require("tests.testkit")

local suites = {
    { name = "JsonEncoder", loader = "tests.test_json_encoder" },
    { name = "PollTimer", loader = "tests.test_poll_timer" },
    { name = "FieldCollector", loader = "tests.test_field_collector" },
    { name = "VehicleCollector", loader = "tests.test_vehicle_collector" },
    { name = "StorageCollector", loader = "tests.test_storage_collector" },
    { name = "FarmCollector", loader = "tests.test_farm_collector" },
    { name = "WorldCollector", loader = "tests.test_world_collector" },
    { name = "TelemetryCollector", loader = "tests.test_telemetry_collector" },
}

for _, suite in ipairs(suites) do
    io.write("== " .. suite.name .. " ==\n")
    local suiteFn = require(suite.loader)
    suiteFn()
    io.write("\n")
end

os.exit(testkit.summaryExitCode())
