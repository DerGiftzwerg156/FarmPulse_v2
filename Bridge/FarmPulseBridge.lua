--[[
    FarmPulseBridge.lua

    Hauptskript des FarmPulse-Bridge-Mods fuer Farming Simulator 25.

    Diese Bridge exportiert periodisch drei getrennte Austauschdateien, sortiert
    nach Aenderungsfrequenz, statt eines einzigen monolithischen Schnappschusses:

        - telemetry.json (alle POLL_INTERVAL_MS, schnelle "Puls"-Werte):
          Uhrzeit, Spieltag/Monat/Jahr/Tage je Monat, Kontostand, FarmID,
          aktueller Wettertyp + Temperatur
        - world.json (alle WORLD_POLL_INTERVAL_MS, seltener - "was mir gehoert"):
          Feld-/Farmland-Informationen fuer ALLE Farmlands der Karte (inkl.
          optionaler Anbaudaten: Fruchtart, Wachstumsfortschritt,
          Ertragsschaetzung), aggregierter Fuhrpark-Wert samt Liste einzelner
          Fahrzeuge (Name, PS, Betriebsstunden, Zustand, Verkaufspreis),
          Lager-/Silobestaende (inkl. aktuellem Marktpreis sowie bestem Preis +
          Periode der letzten 12 FS25-Perioden je Fill-Typ)
        - farm.json (einmalig bei Aktivierung, aendert sich praktisch nie):
          Hofname, Spielername

    Architektur-Leitprinzip: Die Bridge bleibt bewusst "dumm" - sie liest nur
    Rohwerte aus der GIANTS-Engine und schreibt sie unveraendert (nach
    Normalisierung) heraus. Jegliche komplexere Logik (Auswahl, Aggregation,
    Bewertung) lebt auf Core-Seite. Dieses Skript ist deshalb bewusst kurz
    gehalten; die eigentliche Verarbeitungs-/Serialisierungslogik steckt in den
    testbaren, GIANTS-unabhaengigen Modulen unter scripts/ (JsonEncoder,
    PollTimer, FieldCollector, VehicleCollector, StorageCollector,
    PriceCollector, FarmCollector, WorldCollector, TelemetryCollector).

    Bewusst NICHT exportiert (siehe README.md fuer die Begruendung je Kategorie):
    Kraftstofffuellstand je Fahrzeug (beobachtet der Spieler selbst im Spiel),
    Tiere, Vertraege/Missionen, Kredite/Schulden (uebernimmt Core komplett),
    Verlauf/Historie (uebernimmt das Spiel selbst). Anbaudaten je Feld
    (Fruchtart/Wachstum/Ertragsschaetzung) waren urspruenglich ebenfalls
    bewusst ausgeschlossen ("bei fields geht es nur um Besitz, nicht um
    Bewirtschaftung") - diese Entscheidung wurde fuer die Ertragsprognose im
    Frontend revidiert, siehe readFieldCrops().

    ACHTUNG - unbestaetigtes Kategorie-C-Wissen: Die konkreten FS25-Engine-Aufrufe
    unten (welches Objekt haelt den Kontostand, in welcher Einheit liegt die
    Tageszeit vor, wie heissen Tag/Monat/Jahr/Feldliste auf Environment- bzw.
    FarmlandManager-Ebene, wie werden Fahrzeuge/Lagerbestaende gelesen)
    sind ein fundierter, aber NICHT im laufenden Spiel bestaetigter Entwurf,
    abgeleitet aus oeffentlich dokumentierten GIANTS-Engine-Mustern
    (Community-LUADOC, vergleichbare Open-Source-Telemetrie-/Finanz-Mods).
    Jeder Lesezugriff ist deshalb ueber pcall() mit teils mehreren
    Fallback-Strategien abgesichert, damit ein einzelner falscher API-Name
    nicht die gesamte Bridge zum Absturz bringt, sondern nur einen
    Platzhalterwert (0, "unknown" bzw. eine leere Liste) liefert und eine
    Warnung in log.txt hinterlaesst.
    Bitte nach dem ersten Testlauf im Spiel log.txt pruefen (siehe README.md,
    Abschnitt "Test-Feedback-Loop").

    Aktivierung: registriert sich ueber Mission00.update (Utils.appendedFunction),
    dasselbe bereits empirisch bestaetigte Hook-Muster wie im urspruenglichen
    Bridge-Prototyp - g_currentMission besitzt in diesem FS25-Build keine
    addModEventListener-Methode, daher KEINE Registrierung darueber.
]]

FarmPulseBridge = {}

FarmPulseBridge.EXCHANGE_SUBFOLDER = "FarmPulseBridge"
FarmPulseBridge.TELEMETRY_FILENAME = "telemetry.json"
FarmPulseBridge.WORLD_FILENAME = "world.json"
FarmPulseBridge.FARM_FILENAME = "farm.json"
FarmPulseBridge.POLL_INTERVAL_MS = 5000
FarmPulseBridge.WORLD_POLL_INTERVAL_MS = 30000
FarmPulseBridge.LOG_PREFIX = "[FarmPulseBridge] "

local modDirectory = g_currentModDirectory

-- Reine, GIANTS-unabhaengige Logikmodule einbinden (siehe deren Dateikommentare).
source(modDirectory .. "scripts/JsonEncoder.lua")
source(modDirectory .. "scripts/PollTimer.lua")
source(modDirectory .. "scripts/FieldCollector.lua")
source(modDirectory .. "scripts/VehicleCollector.lua")
source(modDirectory .. "scripts/StorageCollector.lua")
source(modDirectory .. "scripts/PriceCollector.lua")
source(modDirectory .. "scripts/FarmCollector.lua")
source(modDirectory .. "scripts/WorldCollector.lua")
source(modDirectory .. "scripts/TelemetryCollector.lua")

--- Zentrale Logfunktion. print() schreibt in FS25s log.txt
-- (Documents/My Games/FarmingSimulator2025/log.txt).
function FarmPulseBridge.log(message)
    print(FarmPulseBridge.LOG_PREFIX .. tostring(message))
end

--- Ermittelt den Austauschordner unterhalb des Spielprofils
-- (.../modSettings/FarmPulseBridge/) und legt ihn an, falls er noch nicht
-- existiert.
function FarmPulseBridge.resolveExchangeDirectory()
    local ok, basePath = pcall(getUserProfileAppPath)
    if not ok or basePath == nil then
        FarmPulseBridge.log("FEHLER: getUserProfileAppPath() nicht verfuegbar - Telemetrie-Export deaktiviert.")
        return nil
    end

    local directory = basePath .. "modSettings/" .. FarmPulseBridge.EXCHANGE_SUBFOLDER .. "/"
    local createOk = pcall(createFolder, directory)
    if not createOk then
        FarmPulseBridge.log("WARNUNG: createFolder() fuer '" .. directory .. "' fehlgeschlagen (existiert er evtl. schon?).")
    end
    return directory
end

--- Liefert das aktuell bekannte Missionsobjekt: bevorzugt das direkt bei der
-- Aktivierung eingefangene Objekt (FarmPulseBridge.mission, siehe tryActivate),
-- Fallback auf die globale Variable g_currentMission.
local function getMission()
    return FarmPulseBridge.mission or g_currentMission
end

--- Liest die FarmID des aktuellen Spielers.
-- Strategie 1 ist gegen die offizielle GDN-Dokumentation bestaetigt (siehe
-- README.md): Der GIANTS-eigene Quellcode von AbstractMission:update() liest
-- dort direkt `g_localPlayer.farmId`, um zu pruefen, ob eine Mission zum
-- lokalen Spieler gehoert - ein bestaetigtes, offizielles Feld.
-- @return farmId (number), source (string, zu Debug-/Logzwecken)
function FarmPulseBridge.readFarmId()
    -- Strategie 1 (bestaetigt, siehe Funktionskommentar): g_localPlayer.farmId.
    local ok, result = pcall(function()
        return g_localPlayer.farmId
    end)
    if ok and type(result) == "number" then
        return result, "g_localPlayer.farmId"
    end

    -- Strategie 2 (Fallback, unbestaetigt): aeltere, in vielen Community-Mods
    -- verwendete getFarmId()-Methode auf der Mission, falls g_localPlayer aus
    -- irgendeinem Grund nicht verfuegbar ist (z.B. vor vollstaendigem Login).
    local mission = getMission()
    ok, result = pcall(function()
        return mission:getFarmId()
    end)
    if ok and type(result) == "number" then
        return result, "currentMission.getFarmId()"
    end

    FarmPulseBridge.log("WARNUNG: Konnte FarmID ueber keine bekannte API lesen - exportiere 0.")
    return 0, "fallback-zero"
end

--- Liest den aktuellen Kontostand des Spieler-Betriebs.
-- Strategie 1 ist gegen die offizielle GDN-Dokumentation bestaetigt (siehe
-- README.md): Farm.lua definiert dort tatsaechlich eine Methode
-- Farm:getBalance() ("Get the current account balance of the farm") - ein
-- rohes .money-Feld auf dem Farm-Objekt ist NICHT dokumentiert und wird
-- deshalb bewusst nicht mehr verwendet. Nutzt dieselbe FarmID-Ermittlung wie
-- readFarmId() (g_localPlayer.farmId zuerst).
-- @return money (number), source (string, zu Debug-/Logzwecken)
function FarmPulseBridge.readMoney()
    local mission = getMission()

    -- Strategie 1 (bestaetigt, siehe Funktionskommentar): Farm:getBalance().
    local ok, result = pcall(function()
        local farmId = FarmPulseBridge.readFarmId()
        local farm = g_farmManager:getFarmById(farmId)
        return farm:getBalance()
    end)
    if ok and type(result) == "number" then
        return result, "farmManager.getFarmById(farmId):getBalance()"
    end

    -- Strategie 2 (Fallback, unbestaetigt): aelterer/vereinfachter Money-Getter
    -- direkt auf der Mission, falls Strategie 1 aus irgendeinem Grund fehlschlaegt.
    ok, result = pcall(function()
        return mission:getMoney()
    end)
    if ok and type(result) == "number" then
        return result, "currentMission.getMoney()"
    end

    FarmPulseBridge.log("WARNUNG: Konnte Kontostand ueber keine bekannte API lesen - exportiere 0.")
    return 0, "fallback-zero"
end

--- Liest Uhrzeit (Stunde/Minute), Spieltag/Monat/Jahr innerhalb des Kalenders
-- sowie die konfigurierte Monatslaenge aus dem Environment-Objekt der laufenden
-- Mission.
--
-- Gegen mehrere Quellen bestaetigt (siehe README.md):
--   - Offizielle GDN-Dokumentation (Klasse AbstractMission): environment.dayTime
--     ist in Millisekunden seit Mitternacht (Verrechnung mit `24*60*60*1000` in
--     AbstractMission:getMinutesLeft()), environment.daysPerPeriod ist ein
--     echtes Feld (AbstractMission:setDefaultEndDate()), und der Tag-im-Monat
--     wird NICHT ueber ein rohes Feld, sondern ueber die Methode
--     environment:getDayInPeriodFromDay(currentMonotonicDay) berechnet (ebenfalls
--     setDefaultEndDate()) - environment.currentMonotonicDay ist dabei der
--     fortlaufende Tageszaehler seit Spielbeginn, kein Tag-im-Monat.
--   - environment.currentYear ist ein echtes, direktes Feld (mehrfach bestaetigt,
--     siehe README.md).
--
-- KORREKTUR (siehe README.md): environment.currentMonth existiert NICHT -
-- eine fruehere Fassung dieser Bridge nahm das faelschlich an (basierend auf
-- einer fehlerhaften Quellenzuordnung, siehe README.md fuer Details) und
-- exportierte dadurch immer 0 als Monat. Bestaetigt (dekompilierter FS25-
-- Basisspiel-Quellcode, mehrfach unabhaengig durch echten Basisspiel- und
-- Mod-Code bestaetigt): der Monat wird stattdessen aus
-- environment.currentPeriod (1..12, FS-interne "Periode" - Periode 1 ist
-- "frueher Fruehling", auf einer Nordhalbkugel-Karte also Maerz, nicht
-- Januar) unter Anwendung derselben Hemisphaeren-Verschiebung berechnet, die
-- die Engine selbst in I18N:formatPeriod() fuer die Monatsanzeige verwendet
-- (TelemetryCollector.calendarMonthFromPeriod(), siehe dort).
-- @return hour, minute, day, month, year, daysPerMonth (jeweils number, Rohwerte
--         vor Normalisierung durch TelemetryCollector)
function FarmPulseBridge.readCalendar()
    local hour, minute, day, month, year, daysPerMonth = 0, 0, 0, 0, 0, 0
    local mission = getMission()

    local ok = pcall(function()
        local environment = mission.environment

        -- Bestaetigt: dayTime in Millisekunden seit Mitternacht (siehe
        -- Funktionskommentar).
        local rawDayTime = environment.dayTime or 0
        hour = math.floor(rawDayTime / (1000 * 60 * 60))
        minute = math.floor((rawDayTime % (1000 * 60 * 60)) / (1000 * 60))

        -- Bestaetigt: daysPerPeriod ist ein echtes Feld.
        daysPerMonth = environment.daysPerPeriod or 0

        -- Bestaetigt: Tag-im-Monat ueber getDayInPeriodFromDay(), nicht ueber
        -- ein rohes Feld (siehe Funktionskommentar).
        local currentMonotonicDay = environment.currentMonotonicDay or 0
        day = environment:getDayInPeriodFromDay(currentMonotonicDay) or 0

        -- Bestaetigt (siehe Funktionskommentar, Korrektur): Monat aus
        -- currentPeriod + Hemisphaeren-Verschiebung berechnen, NICHT ueber
        -- das nicht existierende currentMonth.
        local period = environment.currentPeriod or 1
        local isSouthern = environment.daylight ~= nil
            and type(environment.daylight.latitude) == "number"
            and environment.daylight.latitude < 0
        month = TelemetryCollector.calendarMonthFromPeriod(period, isSouthern)
        year = environment.currentYear or 0
    end)

    if not ok then
        FarmPulseBridge.log("WARNUNG: Kalenderwerte (Uhrzeit/Tag/Monat/Jahr/Tage je Monat) konnten nicht vollstaendig gelesen werden.")
    end

    return hour, minute, day, month, year, daysPerMonth
end

--- Liest den aktuellen Wettertyp und die Umgebungstemperatur.
--
-- Temperatur ist BESTAETIGT (siehe README.md): drei echte, veroeffentlichte
-- Mods (u.a. FS25_RealisticWeather) lesen an dieser Stelle
-- environment.weather:getCurrentTemperature() fuer denselben Zweck (u.a. die
-- Aussentemperatur-Anzeige im Fahrzeug-Cockpit).
--
-- Wettertyp Strategie 1 ist HERGELEITET, nicht bestaetigt (siehe README.md):
-- GIANTS haelt Weather.lua/Environment.lua sowohl aus dem SDK-Dump als auch
-- aus der offiziellen LUADOC zurueck. Die Aufrufkette (forecast:dataForTime,
-- getWeatherObjectByIndex, WeatherType.getName) taucht zwar in echtem,
-- veroeffentlichtem Mod-Code auf (der die Basisspiel-Wetteranzeige
-- nachbaut), die Klassendefinition selbst liegt aber nicht offen.
-- Strategie 2 (Fallback) nutzt ausschliesslich BESTAETIGTE Methoden
-- (getIsRaining/getIsSnowing/getIsHailing, ebenfalls in echtem Basisspiel-Code
-- referenziert), liefert dafuer nur eine grobe Naeherung ohne "bewoelkt".
-- @return weatherType (string, roh - Normalisierung siehe TelemetryCollector),
--         temperature (number)
function FarmPulseBridge.readWeather()
    local mission = getMission()
    local temperature = 0
    local weatherType = nil

    local tempOk, tempResult = pcall(function()
        return mission.environment.weather:getCurrentTemperature()
    end)
    if tempOk and type(tempResult) == "number" then
        temperature = tempResult
    else
        FarmPulseBridge.log("WARNUNG: Konnte Temperatur nicht lesen - exportiere 0.")
    end

    -- Strategie 1 (hergeleitet, siehe Funktionskommentar).
    local typeOk, typeResult = pcall(function()
        local weather = mission.environment.weather
        local _, currentWeather = weather.forecast:dataForTime(mission.environment.currentMonotonicDay,
            mission.environment.dayTime)
        local weatherObject = weather:getWeatherObjectByIndex(currentWeather.season, currentWeather.objectIndex)
        return WeatherType.getName(weatherObject.weatherType)
    end)
    if typeOk and type(typeResult) == "string" then
        weatherType = typeResult
    else
        -- Strategie 2 (Fallback, bestaetigte Einzelmethoden - siehe Funktionskommentar).
        local fallbackOk, fallbackResult = pcall(function()
            local weather = mission.environment.weather
            if weather:getIsHailing() then
                return "HAIL"
            end
            if weather:getIsSnowing() then
                return "SNOW"
            end
            if weather:getIsRaining() then
                return "RAIN"
            end
            return "SUN"
        end)
        if fallbackOk and type(fallbackResult) == "string" then
            weatherType = fallbackResult
        else
            FarmPulseBridge.log("WARNUNG: Konnte Wettertyp ueber keine bekannte API lesen - exportiere UNKNOWN.")
        end
    end

    return weatherType, temperature
end

--- Liest die rohe Liste aller Farmlands ("Felder" im Sinne dieser Bridge) ueber
-- g_farmlandManager. Ob ein Farmland dem aktuellen Spieler gehoert, wird hier
-- bewusst NICHT entschieden (siehe FieldCollector.lua) - es wird lediglich die
-- rohe ownerFarmId mit exportiert.
--
-- BESTAETIGT (siehe README.md, Abschnitt "Wichtiger Hinweis zur
-- Vertrauenswuerdigkeit"): Gegen die FS25-Community-LUADOC geprueft, die fuer
-- FarmlandManager/Farmland den tatsaechlichen Engine-Quellcode zeigt.
-- g_farmlandManager:getFarmlands() liefert `self.farmlands` (eine mit der
-- Farmland-ID indizierte Tabelle, daher pairs() statt einer 1-indizierten
-- Sequenz), und Farmland:load() weist genau die vier hier gelesenen Felder zu:
-- id, areaInHa, price, farmId (Default FarmlandManager.NO_OWNER_FARM_ID, in der
-- Doku als 0 bestaetigt).
-- @return Liste roher {id, farmId, areaInHa, price}-Tabellen (leer, falls
--         g_farmlandManager nicht verfuegbar ist oder der Zugriff fehlschlaegt)
function FarmPulseBridge.readFarmlands()
    local raw = {}

    local ok = pcall(function()
        local farmlands = g_farmlandManager:getFarmlands()
        for _, farmland in pairs(farmlands) do
            table.insert(raw, {
                id = farmland.id,
                farmId = farmland.farmId or 0,
                areaInHa = farmland.areaInHa or 0,
                price = farmland.price or 0,
            })
        end
    end)

    if not ok then
        FarmPulseBridge.log("WARNUNG: Konnte Farmland-/Feldliste nicht ueber g_farmlandManager lesen - exportiere leere fields-Liste.")
        return {}
    end

    return raw
end

--- Liest je Feld (g_fieldManager, NICHT dasselbe wie die Farmlands aus
-- readFarmlands()) rohe Anbau-/Ertragswerte, indiziert nach Farmland-ID, damit
-- FieldCollector.buildFields() sie den world.json-Feldern zuordnen kann.
--
-- HERGELEITET, nicht vollstaendig bestaetigt (siehe README.md, Tabelle):
-- g_fieldManager.fields, field:getFieldState(), FieldState.fruitTypeIndex/
-- .growthState/.isValid sowie g_fruitTypeManager:getFruitTypeByIndex() mit
-- .literPerSqm/.minHarvestingGrowthState/:getIsHarvestable() sind gegen die
-- offizielle GDN-Dokumentation UND echte FS25-Basisspiel-Skripte bestaetigt.
-- NICHT bestaetigt ist, wie sich zum rohen fruitTypeIndex ein lesbarer Name
-- auflösen laesst - diese Bridge probiert dafuer zwei unbestaetigte
-- Strategien (FruitType.getName(), analog zum bestaetigten
-- WeatherType.getName()-Muster; sonst g_fillTypeManager:getFillTypeNameByIndex()
-- mit demselben Index, da Frucht- und Fuelltyp fuer die Basis-Feldfrucht in
-- FS ueblicherweise denselben Namen tragen) und laesst fruitType sonst leer
-- (kein Anbau exportiert), statt einen falschen Namen zu raten.
--
-- Gehaertet gegen Kollisionen zwischen der bestaetigten `field.farmland`-
-- Zuordnung und dem unbestaetigten `fieldState.farmlandId`-Fallback (siehe
-- FieldCollector.shouldReplaceCropEntry()): eine bestaetigte Zuordnung wird
-- nie durch einen Fallback-Eintrag ueberschrieben, unabhaengig von der
-- (nicht garantierten) Iterationsreihenfolge von g_fieldManager.fields.
-- @return Tabelle, die Farmland-IDs auf rohe {fruitTypeName, growthState,
--         minHarvestingGrowthState, literPerSqm, isHarvestable, areaHa}
--         abbildet (leer, falls g_fieldManager nicht verfuegbar ist)
function FarmPulseBridge.readFieldCrops()
    local raw = {}
    local isAuthoritativeByFarmlandId = {}

    local ok = pcall(function()
        for _, field in pairs(g_fieldManager.fields) do
            -- Einzelne fehlgeschlagene/unbestellte Felder ueberspringen, statt
            -- die gesamte Liste zu verwerfen.
            pcall(function()
                local fieldState = field:getFieldState()
                if fieldState == nil or not fieldState.isValid then
                    return
                end
                if fieldState.fruitTypeIndex == nil or fieldState.fruitTypeIndex == FruitType.UNKNOWN then
                    return
                end

                local farmlandId = 0
                local isAuthoritative = false
                if field.farmland ~= nil then
                    farmlandId = field.farmland.id or 0
                    isAuthoritative = true
                elseif fieldState.farmlandId ~= nil then
                    farmlandId = fieldState.farmlandId
                end
                if farmlandId == 0 then
                    return
                end

                if not FieldCollector.shouldReplaceCropEntry(isAuthoritativeByFarmlandId[farmlandId], isAuthoritative) then
                    return
                end

                local fruitTypeName = nil
                pcall(function() fruitTypeName = FruitType.getName(fieldState.fruitTypeIndex) end)
                if fruitTypeName == nil then
                    pcall(function()
                        fruitTypeName = g_fillTypeManager:getFillTypeNameByIndex(fieldState.fruitTypeIndex)
                    end)
                end

                local desc = g_fruitTypeManager:getFruitTypeByIndex(fieldState.fruitTypeIndex)
                local literPerSqm = 0
                local minHarvestingGrowthState = 0
                local isHarvestable = false
                if desc ~= nil then
                    literPerSqm = desc.literPerSqm or 0
                    minHarvestingGrowthState = desc.minHarvestingGrowthState or 0
                    local harvestOk, harvestResult = pcall(function()
                        return desc:getIsHarvestable(fieldState.growthState)
                    end)
                    if harvestOk then
                        isHarvestable = harvestResult
                    end
                end

                local areaHa = 0
                local areaOk, areaResult = pcall(function() return field:getAreaHa() end)
                if areaOk and type(areaResult) == "number" then
                    areaHa = areaResult
                end

                raw[farmlandId] = {
                    fruitTypeName = fruitTypeName,
                    growthState = fieldState.growthState or 0,
                    minHarvestingGrowthState = minHarvestingGrowthState,
                    literPerSqm = literPerSqm,
                    isHarvestable = isHarvestable,
                    areaHa = areaHa,
                }
                isAuthoritativeByFarmlandId[farmlandId] = isAuthoritative
            end)
        end
    end)

    if not ok then
        FarmPulseBridge.log("WARNUNG: Konnte Feld-Anbaudaten nicht ueber g_fieldManager lesen - exportiere keine Anbaudaten.")
        return {}
    end

    return raw
end

--- Liest den Hofnamen der aktuellen Farm.
-- Strategie 1 ist gegen einen echten, veroeffentlichten Mod bestaetigt (siehe
-- README.md): FS25_InfoDisplayExtension liest `owningFarm.name` auf demselben
-- Farm-Objekt, das bereits readMoney() ueber g_farmManager:getFarmById()
-- verwendet.
-- @param farmId FarmID, siehe readFarmId()
-- @return roher Hofname (String) oder nil, falls kein Zugriff moeglich war
function FarmPulseBridge.readFarmName(farmId)
    local ok, result = pcall(function()
        return g_farmManager:getFarmById(farmId).name
    end)
    if ok and type(result) == "string" then
        return result, "farmManager.getFarmById(farmId).name"
    end

    FarmPulseBridge.log("WARNUNG: Konnte Hofnamen ueber keine bekannte API lesen.")
    return nil, "fallback-nil"
end

--- Liest den Spielernamen (Nickname).
-- Strategie 1 ist gegen einen echten, veroeffentlichten Mod bestaetigt (siehe
-- README.md): FS25_Tardis referenziert `g_currentMission.playerNickname`
-- direkt als Feld.
-- @return roher Spielername (String) oder nil, falls kein Zugriff moeglich war
function FarmPulseBridge.readPlayerName()
    local mission = getMission()
    local ok, result = pcall(function()
        return mission.playerNickname
    end)
    if ok and type(result) == "string" and result ~= "" then
        return result, "currentMission.playerNickname"
    end

    FarmPulseBridge.log("WARNUNG: Konnte Spielernamen ueber keine bekannte API lesen.")
    return nil, "fallback-nil"
end

--- Liest je Fahrzeug der aktuellen Farm einen rohen Detail-Datensatz (Name,
-- Kategorie, PS, Betriebsstunden, Zustand, Eigentumsstatus, Verkaufspreis)
-- fuer die "vehicles"-Liste sowie den aggregierten Fuhrpark-Wert "fleetValue"
-- (siehe VehicleCollector). Einzelne Fahrzeug-Verbrauchsdaten
-- (Kraftstofffuellstand) werden weiterhin bewusst NICHT gelesen, siehe
-- Dateikommentar/README.md - die beobachtet der Spieler ohnehin selbst im
-- laufenden Spiel.
--
-- Jedes Detail-Feld ist einzeln ueber pcall() abgesichert: schlaegt z.B. nur
-- die PS-Ermittlung fehl (z.B. bei einem nicht-motorisierten Anhaenger ohne
-- Motor-Konfiguration), liefert der Eintrag trotzdem Name/Betriebsstunden/
-- Zustand/Verkaufspreis, statt das gesamte Fahrzeug zu verwerfen.
--
-- BESTAETIGT (siehe README.md, Abschnitt "Fuhrpark-Details"): gegen den
-- dekompilierten FS25-Basisspiel-Quellcode geprueft (Quelle 9,
-- vehicles/Vehicle.lua): Vehicle:getFullName() (Name inkl. Marke),
-- Vehicle:getOperatingTime() (Betriebszeit in Millisekunden, self.operatingTime),
-- Vehicle:getSellPrice() (bereits bestehend, siehe unten), Vehicle:getPropertyState()
-- (Eigentumsstatus, vgl. VehiclePropertyState.OWNED/.LEASED/.MISSION/.SHOP_CONFIG,
-- alle vier als echte Konstanten in Vehicle.lua/Wearable.lua referenziert) sowie
-- Vehicle:getDamageAmount() (vehicles/specializations/Wearable.lua, 0..1) sind
-- allesamt echte, im Basisspiel-Quellcode vorhandene Methoden. Ebenfalls
-- BESTAETIGT: die Fahrzeugkategorie ueber denselben g_storeManager:getItemByXMLFilename()-
-- Zugriff wie beim PS-Wert - storeItem.categoryName wird in Vehicle.lua
-- (saveStatsToXMLFile) fuer denselben Zweck gelesen, und g_storeManager:getCategoryByName(...).title
-- (shop/StoreManager.lua, StoreManager:addCategory()) liefert daraus den
-- lokalisierten Anzeigenamen (z.B. "Traktoren") statt des rohen internen
-- Kategorie-Schluessels. Der PS-Wert (storeItem.specs.power) ist HERGELEITET:
-- Vehicle.calculateSellPrice() liest exakt dieses Feld ueber denselben
-- g_storeManager:getItemByXMLFilename() + StoreItemUtil.loadSpecsFromXML()-Zugriff,
-- die Einheit (PS vs. kW) selbst konnte nicht gegen die l10n-Textdateien
-- verifiziert werden - siehe README.md fuer die Einschraenkung.
-- @param farmId FarmID, siehe readFarmId()
-- @return Liste roher {name, category, horsepowerHp, operatingHours,
--         conditionPercent, ownershipStatus, sellPrice}-Tabellen (leer, falls
--         g_currentMission.vehicleSystem nicht verfuegbar ist oder der
--         Zugriff fehlschlaegt)
function FarmPulseBridge.readVehicles(farmId)
    local vehicles = {}

    local ok = pcall(function()
        local allVehicles = g_currentMission.vehicleSystem.vehicles
        for _, vehicle in pairs(allVehicles) do
            local ownerOk, ownerFarmId = pcall(function() return vehicle:getOwnerFarmId() end)
            if ownerOk and ownerFarmId == farmId then
                table.insert(vehicles, FarmPulseBridge.readVehicleDetails(vehicle))
            end
        end
    end)

    if not ok then
        FarmPulseBridge.log("WARNUNG: Konnte Fahrzeugliste nicht ueber g_currentMission.vehicleSystem lesen - exportiere leere vehicles-Liste/fleetValue 0.")
        return {}
    end

    return vehicles
end

--- Liest die rohen Detailwerte eines einzelnen Fahrzeugs, siehe readVehicles().
-- @param vehicle Fahrzeugobjekt aus g_currentMission.vehicleSystem.vehicles
-- @return rohe {name, category, horsepowerHp, operatingHours, conditionPercent,
--         ownershipStatus, sellPrice}-Tabelle (einzelne Felder nil, falls der
--         jeweilige Lesezugriff fehlschlaegt)
function FarmPulseBridge.readVehicleDetails(vehicle)
    local nameOk, name = pcall(function() return vehicle:getFullName() end)
    if not nameOk then
        name = nil
        FarmPulseBridge.log("WARNUNG: Konnte Fahrzeugnamen ueber getFullName() nicht lesen.")
    end

    local horsepowerHp = nil
    local category = nil
    local specsOk = pcall(function()
        local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
        if storeItem ~= nil then
            StoreItemUtil.loadSpecsFromXML(storeItem)
            horsepowerHp = storeItem.specs.power

            local storeCategory = g_storeManager:getCategoryByName(storeItem.categoryName)
            if storeCategory ~= nil then
                category = storeCategory.title
            else
                category = storeItem.categoryName
            end
        end
    end)
    if not specsOk then
        FarmPulseBridge.log("WARNUNG: Konnte PS-Wert/Kategorie eines Fahrzeugs nicht ueber g_storeManager lesen.")
    end

    local ownershipStatus = nil
    local propertyStateOk, propertyState = pcall(function() return vehicle:getPropertyState() end)
    if propertyStateOk then
        if propertyState == VehiclePropertyState.OWNED then
            ownershipStatus = "OWNED"
        elseif propertyState == VehiclePropertyState.LEASED then
            ownershipStatus = "LEASED"
        elseif propertyState == VehiclePropertyState.MISSION then
            ownershipStatus = "MISSION"
        elseif propertyState == VehiclePropertyState.SHOP_CONFIG then
            ownershipStatus = "SHOP_CONFIG"
        end
    else
        FarmPulseBridge.log("WARNUNG: Konnte Eigentumsstatus eines Fahrzeugs nicht ueber getPropertyState() lesen.")
    end

    local operatingHours = nil
    local operatingOk, operatingTimeMs = pcall(function() return vehicle:getOperatingTime() end)
    if operatingOk and type(operatingTimeMs) == "number" then
        operatingHours = operatingTimeMs / (1000 * 60 * 60)
    else
        FarmPulseBridge.log("WARNUNG: Konnte Betriebsstunden eines Fahrzeugs nicht ueber getOperatingTime() lesen.")
    end

    local conditionPercent = nil
    local damageOk, damageAmount = pcall(function() return vehicle:getDamageAmount() end)
    if damageOk and type(damageAmount) == "number" then
        conditionPercent = (1 - damageAmount) * 100
    else
        FarmPulseBridge.log("WARNUNG: Konnte Fahrzeugzustand eines Fahrzeugs nicht ueber getDamageAmount() lesen.")
    end

    local sellPriceOk, sellPrice = pcall(function() return vehicle:getSellPrice() end)
    if not sellPriceOk or type(sellPrice) ~= "number" then
        sellPrice = 0
        FarmPulseBridge.log("WARNUNG: Konnte Verkaufspreis eines Fahrzeugs ueber getSellPrice() nicht lesen - exportiere 0.")
    end

    return {
        name = name,
        category = category,
        horsepowerHp = horsepowerHp,
        operatingHours = operatingHours,
        conditionPercent = conditionPercent,
        ownershipStatus = ownershipStatus,
        sellPrice = sellPrice,
    }
end

--- Liest die rohen Lager-/Silobestaende der aktuellen Farm ueber die
-- Produktionspunkte UND die frei platzierten Hof-Silos der Karte (fuer die
-- "storages"-Liste, siehe StorageCollector).
--
-- TEILWEISE BESTAETIGT (siehe README.md): Produktionspunkt-Teil gegen einen
-- echten, veroeffentlichten Mod geprueft (FS25_UpgradableFactories fuer
-- g_currentMission.productionChainManager.productionPoints und
-- prodpoint.storage.fillLevels/.capacities als Struktur). Hof-Silo-Teil
-- (spec_silo) gegen einen zweiten echten, veroeffentlichten Mod geprueft
-- (FS25_AdjustStorageCapacity fuer placeable.spec_silo.storages als Liste
-- von Storage-Objekten mit .fillLevels/.capacities/.capacity). Ohne den
-- Hof-Silo-Teil blieb "amount" fuer alle Fill-Typen dauerhaft 0, sobald die
-- Ernte ausschliesslich in frei platzierten Silos statt in
-- Produktionspunkten lagert - das ist der Regelfall fuer die meisten Hoefe.
-- @param farmId FarmID, siehe readFarmId()
-- @return Liste roher {fillType, amount, capacity}-Tabellen (leer, falls der
--         Zugriff fehlschlaegt)
function FarmPulseBridge.readStorages(farmId)
    local raw = {}

    local ok = pcall(function()
        local productionPoints = g_currentMission.productionChainManager.productionPoints
        for _, point in pairs(productionPoints) do
            local pointFarmId = point.farmId or point.ownerFarmId
            if pointFarmId == farmId and point.storage ~= nil then
                for fillTypeIndex, fillLevel in pairs(point.storage.fillLevels or {}) do
                    local fillTypeName = fillTypeIndex
                    pcall(function()
                        fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
                    end)
                    local capacity = 0
                    if point.storage.capacities ~= nil then
                        capacity = point.storage.capacities[fillTypeIndex] or 0
                    end
                    table.insert(raw, {
                        fillType = tostring(fillTypeName),
                        amount = fillLevel,
                        capacity = capacity,
                    })
                end
            end
        end
    end)

    if not ok then
        FarmPulseBridge.log("WARNUNG: Konnte Lagerbestaende nicht ueber g_currentMission.productionChainManager lesen.")
    end

    local siloOk = pcall(function()
        local placeables = g_currentMission.placeableSystem.placeables
        for _, placeable in ipairs(placeables) do
            if placeable.spec_silo ~= nil and placeable.spec_silo.storages ~= nil then
                local ownerOk, ownerFarmId = pcall(function() return placeable:getOwnerFarmId() end)
                if ownerOk and ownerFarmId == farmId then
                    for _, storage in ipairs(placeable.spec_silo.storages) do
                        for fillTypeIndex, fillLevel in pairs(storage.fillLevels or {}) do
                            local fillTypeName = fillTypeIndex
                            pcall(function()
                                fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
                            end)
                            local capacity = storage.capacity or 0
                            if storage.capacities ~= nil then
                                capacity = storage.capacities[fillTypeIndex] or 0
                            end
                            table.insert(raw, {
                                fillType = tostring(fillTypeName),
                                amount = fillLevel,
                                capacity = capacity,
                            })
                        end
                    end
                end
            end
        end
    end)

    if not siloOk then
        FarmPulseBridge.log("WARNUNG: Konnte Hof-Silo-Lagerbestaende nicht ueber g_currentMission.placeableSystem lesen.")
    end

    if not ok and not siloOk then
        return {}
    end

    return raw
end

--- Liest den rohen aktuellen Marktpreis sowie die rohe 12-Perioden-
-- Preishistorie eines Fill-Typs (fuer "currentPricePer1000L"/"bestPricePer1000L"
-- eines Lagerbestands, siehe PriceCollector).
--
-- BESTAETIGT (siehe README.md, Abschnitt "Marktpreise"): gegen ein
-- dekompiliertes FS25-Basisspiel-Quellskript (EconomyManager.lua,
-- FillTypeDesc.lua) sowie gegen mehrere veroeffentlichte FS25-Mods geprueft,
-- die exakt dieselbe Signatur in Produktionscode aufrufen (u.a.
-- FS25_ForestryHelper, VDTelemetry). g_currentMission.economyManager:
-- getPricePerLiter(fillTypeIndex) liefert den aktuellen Preis in Euro je
-- Liter (globaler Marktpreis, nicht je Verkaufsstelle).
-- fillType.economy.history ist eine 12-eintraege-Tabelle (Index 1..12, eine
-- FS25-"Periode" je Eintrag, NICHT zwingend Kalendermonate - siehe
-- formatPricePeriod()) mit historischen Preisen in Euro je Liter, aus der
-- PriceCollector.findBestPrice() den hoechsten Wert samt Periode ermittelt.
-- @param fillTypeName Fill-Typ-Name wie von readStorages() geliefert (z.B. "WHEAT")
-- @return currentPricePerLiter (number oder nil), history (Tabelle mit bis zu
--         12 Eintraegen, Index 1..12, oder nil - jeweils nil, falls der
--         Zugriff fehlschlaegt)
function FarmPulseBridge.readFillTypePrice(fillTypeName)
    local currentPricePerLiter, history

    local ok = pcall(function()
        local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)
        if fillType == nil then
            return
        end

        currentPricePerLiter = g_currentMission.economyManager:getPricePerLiter(fillType.index)

        if type(fillType.economy) == "table" and type(fillType.economy.history) == "table" then
            history = {}
            for period = 1, 12 do
                history[period] = fillType.economy.history[period]
            end
        end
    end)

    if not ok then
        FarmPulseBridge.log("WARNUNG: Konnte Marktpreis fuer '" .. tostring(fillTypeName)
            .. "' nicht ueber g_currentMission.economyManager lesen.")
        return nil, nil
    end

    return currentPricePerLiter, history
end

--- Loest eine FS25-Preis-"Periode" (1..12, siehe readFillTypePrice()) zu einem
-- menschenlesbaren, spiel-lokalisierten Monatsnamen auf.
--
-- BESTAETIGT (siehe README.md, Abschnitt "Marktpreise"): g_i18n:formatPeriod()
-- ist dieselbe Funktion, die die Preis-Statistik-Ansicht des Basisspiels fuer
-- die Monatsbeschriftung nutzt. Periode 1 ist auf der Nordhalbkugel-Standard-
-- karte NICHT Januar, sondern Maerz (Verschiebung um den Kartenbreitengrad je
-- nach Hemisphaere) - die Zuordnung Periode->Monat wird deshalb bewusst NICHT
-- selbst nachgebaut, sondern ueber die Engine-Funktion aufgeloest.
-- @param period 1..12 oder nil
-- @return lokalisierter Monatsname (string) oder nil, falls period nil ist
--         oder der Zugriff fehlschlaegt
function FarmPulseBridge.formatPricePeriod(period)
    if period == nil then
        return nil
    end

    local label
    local ok = pcall(function()
        label = g_i18n:formatPeriod(period)
    end)

    if not ok or type(label) ~= "string" then
        FarmPulseBridge.log("WARNUNG: Konnte Periode " .. tostring(period) .. " nicht ueber g_i18n:formatPeriod lesen.")
        return nil
    end

    return label
end

--- Baut die aktuelle Telemetrie-Nutzlast und schreibt sie als telemetry.json in
-- den Austauschordner. Schnelle "Puls"-Werte, siehe FarmPulseBridge.POLL_INTERVAL_MS.
function FarmPulseBridge.exportTelemetry()
    if FarmPulseBridge.exchangeDirectory == nil then
        return
    end

    local hour, minute, day, month, year, daysPerMonth = FarmPulseBridge.readCalendar()
    local money = FarmPulseBridge.readMoney()
    local farmId = FarmPulseBridge.readFarmId()
    local weatherType, temperature = FarmPulseBridge.readWeather()

    local payload = TelemetryCollector.buildPayload({
        hour = hour,
        minute = minute,
        day = day,
        month = month,
        year = year,
        daysPerMonth = daysPerMonth,
        money = money,
        farmId = farmId,
        weatherType = weatherType,
        temperature = temperature,
    })

    FarmPulseBridge.writeJsonFile(FarmPulseBridge.TELEMETRY_FILENAME, TelemetryCollector.toJson(payload))
end

--- Baut die aktuelle Welt-Nutzlast (Besitz jenseits des Kontostands) und
-- schreibt sie als world.json in den Austauschordner. Seltener als
-- telemetry.json, siehe FarmPulseBridge.WORLD_POLL_INTERVAL_MS.
function FarmPulseBridge.exportWorld()
    if FarmPulseBridge.exchangeDirectory == nil then
        return
    end

    local farmId = FarmPulseBridge.readFarmId()
    local rawFarmlands = FarmPulseBridge.readFarmlands()
    local rawFieldCrops = FarmPulseBridge.readFieldCrops()
    local rawVehicles = FarmPulseBridge.readVehicles(farmId)
    local rawStorages = FarmPulseBridge.readStorages(farmId)

    local storages = StorageCollector.buildStorages(rawStorages)
    for i, storage in ipairs(storages) do
        local rawCurrentPrice, rawHistory = FarmPulseBridge.readFillTypePrice(storage.fillType)
        local _, bestPricePeriod = PriceCollector.findBestPrice(rawHistory)
        local bestPricePeriodLabel = FarmPulseBridge.formatPricePeriod(bestPricePeriod)
        storages[i] = PriceCollector.withPrice(storage, rawCurrentPrice, rawHistory, bestPricePeriodLabel)
    end

    local rawSellPrices = {}
    for i, vehicle in ipairs(rawVehicles) do
        rawSellPrices[i] = vehicle.sellPrice
    end

    local payload = WorldCollector.buildPayload({
        fields = FieldCollector.buildFields(rawFarmlands, rawFieldCrops),
        vehicles = VehicleCollector.buildVehicles(rawVehicles),
        fleetValue = VehicleCollector.buildFleetValue(rawSellPrices),
        storages = storages,
    })

    FarmPulseBridge.writeJsonFile(FarmPulseBridge.WORLD_FILENAME, WorldCollector.toJson(payload))
end

--- Baut die Betriebs-/Spieleridentitaet und schreibt sie als farm.json in den
-- Austauschordner. Wird nur einmal bei der Aktivierung geschrieben (siehe
-- tryActivate), da sich Hofname/Spielername praktisch nie waehrend eines
-- Spielstands aendern.
function FarmPulseBridge.exportFarmIdentity()
    if FarmPulseBridge.exchangeDirectory == nil then
        return
    end

    local farmId = FarmPulseBridge.readFarmId()
    local rawFarmName = FarmPulseBridge.readFarmName(farmId)
    local rawPlayerName = FarmPulseBridge.readPlayerName()

    local payload = FarmCollector.buildPayload({
        farmName = rawFarmName,
        playerName = rawPlayerName,
    })

    FarmPulseBridge.writeJsonFile(FarmPulseBridge.FARM_FILENAME, FarmCollector.toJson(payload))
end

--- Schreibt einen bereits serialisierten JSON-Text in eine Datei im
-- Austauschordner. Gemeinsame Hilfsfunktion fuer alle drei Austauschdateien.
-- @param filename Dateiname innerhalb von FarmPulseBridge.exchangeDirectory
-- @param json bereits serialisierter JSON-Text
function FarmPulseBridge.writeJsonFile(filename, json)
    local path = FarmPulseBridge.exchangeDirectory .. filename

    local file, openError = io.open(path, "w")
    if file == nil then
        FarmPulseBridge.log("FEHLER: Konnte '" .. path .. "' nicht zum Schreiben oeffnen: " .. tostring(openError))
        return
    end
    file:write(json)
    file:close()
end

--- Fasst die Aufgaben eines schnellen Poll-Ticks zusammen: der
-- telemetry.json-Export. Als eigene Funktion gehalten (statt inline in
-- onMissionUpdate), damit ein sofortiger erster Export bei der Aktivierung
-- (siehe tryActivate) denselben Code-Pfad wie jeder spaetere Timer-Tick
-- durchlaeuft.
function FarmPulseBridge.onPollTick()
    FarmPulseBridge.exportTelemetry()
end

--- Fasst die Aufgaben eines seltenen Welt-Poll-Ticks zusammen: der
-- world.json-Export, siehe onPollTick() fuer die Begruendung der eigenen
-- Funktion.
function FarmPulseBridge.onWorldPollTick()
    FarmPulseBridge.exportWorld()
end

--- Einmalige, idempotente Aktivierung: haelt das Missionsobjekt fest,
-- initialisiert beide Poll-Timer und den Austauschordner und fuehrt die
-- ersten Sofort-Exporte durch (telemetry.json, world.json und - einmalig,
-- siehe exportFarmIdentity - farm.json). Wird ausschliesslich aus dem
-- Mission00.update-Hook heraus aufgerufen (siehe Registrierung am Dateiende) -
-- dort ist "mission" garantiert eine gueltige Missionsinstanz, da die Engine
-- update() schliesslich AUF der laufenden Mission aufruft.
-- @param mission die laufende Mission (self aus Mission00.update)
function FarmPulseBridge.tryActivate(mission)
    if FarmPulseBridge.activated or type(mission) ~= "table" then
        return
    end

    FarmPulseBridge.activated = true
    FarmPulseBridge.mission = mission
    FarmPulseBridge.pollTimer = PollTimer.new(FarmPulseBridge.POLL_INTERVAL_MS)
    FarmPulseBridge.worldPollTimer = PollTimer.new(FarmPulseBridge.WORLD_POLL_INTERVAL_MS)
    FarmPulseBridge.exchangeDirectory = FarmPulseBridge.resolveExchangeDirectory()

    if FarmPulseBridge.exchangeDirectory ~= nil then
        FarmPulseBridge.log("Aktiviert (ueber Mission00.update). Austauschordner: " .. FarmPulseBridge.exchangeDirectory)
        -- Sofortiger erster Export je Datei nach der Aktivierung, statt bis zum
        -- ersten Timer-Tick zu warten - das Dashboard soll direkt nach dem
        -- Spielstart Daten zeigen. farm.json wird bewusst NUR hier geschrieben
        -- (kein eigener Timer, siehe exportFarmIdentity).
        FarmPulseBridge.onPollTick()
        FarmPulseBridge.onWorldPollTick()
        FarmPulseBridge.exportFarmIdentity()
    end
end

--- Wird bei jedem Update der laufenden Mission aufgerufen (siehe Registrierung
-- am Dateiende). Aktiviert die Bridge beim ersten Aufruf (idempotent) und treibt
-- danach beide Poll-Timer an.
-- @param missionSelf die laufende Mission (self)
-- @param dt vergangene Zeit seit dem letzten Frame in Millisekunden
function FarmPulseBridge.onMissionUpdate(missionSelf, dt)
    if not FarmPulseBridge.activated then
        FarmPulseBridge.tryActivate(missionSelf)
        if not FarmPulseBridge.activated then
            return
        end
    end

    if FarmPulseBridge.pollTimer:update(dt) then
        FarmPulseBridge.onPollTick()
    end

    if FarmPulseBridge.worldPollTimer:update(dt) then
        FarmPulseBridge.onWorldPollTick()
    end
end

--- Haengt newFunc an targetTable[fieldName] an (Utils.appendedFunction), ohne zu
-- crashen, falls targetTable selbst nil ist (z.B. weil eine Klasse in dieser
-- FS-Version anders heisst als angenommen).
local function safeAppend(targetTable, fieldName, newFunc)
    if targetTable == nil then
        return false
    end
    targetTable[fieldName] = Utils.appendedFunction(targetTable[fieldName], newFunc)
    return true
end

-- Mission00.update ueberschreiben. Erwartete Signatur: (self, dt) als
-- Instanzmethode. Falls Mission00.update in dieser FS-Version stattdessen ohne
-- self als (dt) aufgerufen wird, faengt die Typpruefung das sauber ab und faellt
-- auf g_currentMission zurueck, statt einen Zahlenwert faelschlich als
-- Missionsobjekt zu behandeln.
safeAppend(Mission00, "update", function(arg1, arg2)
    local missionSelf, dt
    if type(arg1) == "table" then
        missionSelf, dt = arg1, arg2
    else
        missionSelf, dt = g_currentMission, arg1
    end
    FarmPulseBridge.onMissionUpdate(missionSelf, dt)
end)
