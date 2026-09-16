--[[
    PriceCollector.lua

    Reine Verarbeitungslogik fuer Marktpreise pro Fill-Typ: nimmt den rohen
    aktuellen Preis (Euro je Liter) sowie die rohe 12-Perioden-Preishistorie
    eines Fill-Typs entgegen (siehe FarmPulseBridge.readFillTypePrice() fuer
    den eigentlichen Lesezugriff auf g_currentMission.economyManager und
    fillType.economy.history) und berechnet daraus den besten (hoechsten)
    historischen Preis samt Periode fuer die world.json-Nutzlast:

        { fillType = "WHEAT", amount = 9500, capacity = 10000,
          currentPricePer1000L = 218.4, bestPricePer1000L = 254.1,
          bestPricePeriod = 3, bestPricePeriodLabel = "März" }

    FS25 fuehrt intern KEINE Kalendermonate, sondern 12 "Perioden" (1..12) -
    Periode 1 ist je nach Kartenbreitengrad nicht zwingend Januar (siehe
    Bridge/README.md, Abschnitt "Marktpreise"). Die Aufloesung einer
    Periodennummer zu einem menschenlesbaren Monatsnamen ist deshalb ein
    separater Engine-Call (g_i18n:formatPeriod(), siehe
    FarmPulseBridge.formatPricePeriod()) und wird von aussen als bereits
    aufgeloester String hereingereicht, statt hier nachgebildet zu werden -
    diese Datei bleibt damit ohne jede GIANTS-Abhaengigkeit testbar.

    Alle Preise werden von "Euro je Liter" (Rohwert der Engine) in "Euro je
    1000 Liter" umgerechnet, da das Spiel Preise so anzeigt (siehe
    Bridge/README.md).

    Bewusst ohne jede GIANTS-Abhaengigkeit -> per `lua`-Interpreter unit-testbar
    (siehe tests/test_price_collector.lua).
]]

PriceCollector = {}

local PRICE_UNIT_MULTIPLIER = 1000

local function round2(value)
    if value == nil then
        return nil
    end
    return math.floor(value * 100 + 0.5) / 100
end

local function toPricePer1000L(rawPricePerLiter)
    if type(rawPricePerLiter) ~= "number" then
        return nil
    end
    return round2(rawPricePerLiter * PRICE_UNIT_MULTIPLIER)
end

--- Ermittelt den hoechsten Preis samt Periode aus einer rohen 12-Perioden-
-- Preishistorie (Rohwerte in Euro je Liter, siehe fillType.economy.history).
-- @param rawHistory Liste/Tabelle mit (bis zu) 12 Eintraegen, Index 1..12,
--        Werte in Euro je Liter oder nil, falls fuer diese Periode unbekannt
-- @return bestPricePer1000L (Zahl oder nil), bestPricePeriod (1..12 oder nil)
function PriceCollector.findBestPrice(rawHistory)
    if type(rawHistory) ~= "table" then
        return nil, nil
    end

    local bestRawPrice, bestPeriod
    for period = 1, 12 do
        local value = rawHistory[period]
        if type(value) == "number" and (bestRawPrice == nil or value > bestRawPrice) then
            bestRawPrice = value
            bestPeriod = period
        end
    end

    if bestRawPrice == nil then
        return nil, nil
    end
    return toPricePer1000L(bestRawPrice), bestPeriod
end

--- Reichert einen bereits von StorageCollector normalisierten Lager-
-- Datensatz um Marktpreisfelder an.
-- @param storage normalisierte Tabelle mit fillType/amount/capacity
-- @param rawCurrentPricePerLiter roher aktueller Preis in Euro je Liter (oder nil)
-- @param rawHistory rohe 12-Perioden-Preishistorie in Euro je Liter (oder nil)
-- @param bestPricePeriodLabel bereits aufgeloester Periodenname (oder nil),
--        siehe FarmPulseBridge.formatPricePeriod()
-- @return neue Tabelle mit allen Storage-Feldern plus currentPricePer1000L,
--         bestPricePer1000L, bestPricePeriod, bestPricePeriodLabel
function PriceCollector.withPrice(storage, rawCurrentPricePerLiter, rawHistory, bestPricePeriodLabel)
    storage = storage or {}
    local bestPricePer1000L, bestPricePeriod = PriceCollector.findBestPrice(rawHistory)

    return {
        fillType = storage.fillType,
        amount = storage.amount,
        capacity = storage.capacity,
        currentPricePer1000L = toPricePer1000L(rawCurrentPricePerLiter),
        bestPricePer1000L = bestPricePer1000L,
        bestPricePeriod = bestPricePeriod,
        bestPricePeriodLabel = bestPricePeriod ~= nil and bestPricePeriodLabel or nil,
    }
end

return PriceCollector
