--[[
    VehicleCollector.lua

    Reine Verarbeitungslogik fuer den Fuhrpark-Wert: nimmt eine rohe Liste von
    Fahrzeugpreisen entgegen (siehe FarmPulseBridge.readVehiclePrices() fuer den
    eigentlichen Lesezugriff auf g_currentMission.vehicleSystem) und aggregiert
    sie zu einem einzigen "fleetValue" fuer die world.json-Nutzlast.

    Bewusst NUR ein aggregierter Vermoegenswert, kein Einzelfahrzeug-Zustand
    (Tankfuellung, Verschleiss etc.) - diese Bridge exportiert nur, was Core
    fuer Ereignisse braucht, keine Werte, auf die der Spieler ohnehin selbst im
    laufenden Spiel achtet.

    Bewusst ohne jede GIANTS-Abhaengigkeit -> per `lua`-Interpreter unit-testbar
    (siehe tests/test_vehicle_collector.lua).
]]

VehicleCollector = {}

--- Summiert eine rohe Liste von Fahrzeugpreisen (Zahlen) zu einem
-- nicht-negativen, gerundeten Gesamtwert. Nicht-numerische/negative Eintraege
-- werden ignoriert, statt die gesamte Berechnung scheitern zu lassen.
-- @param rawPrices Liste roher Preis-Zahlen (z.B. je Fahrzeug getSellPrice())
-- @return gerundeter, nicht-negativer Gesamtwert (0, falls rawPrices keine
--         Tabelle ist oder leer bleibt)
function VehicleCollector.buildFleetValue(rawPrices)
    if type(rawPrices) ~= "table" then
        return 0
    end

    local total = 0
    for i = 1, #rawPrices do
        local price = rawPrices[i]
        if type(price) == "number" and price > 0 then
            total = total + price
        end
    end

    local rounded = math.floor(total + 0.5)
    if rounded < 0 then
        rounded = 0
    end
    return rounded
end

return VehicleCollector
