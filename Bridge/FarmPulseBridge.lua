--[[
    FarmPulseBridge.lua

    Hauptskript des FarmPulse-Bridge-Mods fuer Farming Simulator 25.

    Diese Bridge exportiert periodisch (alle POLL_INTERVAL_MS Millisekunden) einen
    deutlich umfangreicheren Telemetrie-Schnappschuss als der urspruengliche
    Testprototyp als telemetry.json in den gemeinsamen Austauschordner:

        - Uhrzeit (Stunde/Minute)
        - Spieltag, Monat, Jahr, Tage je Monat
        - Kontostand des Spieler-Betriebs
        - FarmID des aktuellen Spielers
        - Feld-/Farmland-Informationen (Besitz anhand der FarmID, Groesse in
          Hektar, Feldpreis) fuer ALLE Farmlands der laufenden Map

    Architektur-Leitprinzip: Die Bridge bleibt bewusst "dumm" - sie liest nur
    Rohwerte aus der GIANTS-Engine und schreibt sie unveraendert (nach
    Normalisierung) heraus. Jegliche komplexere Logik (Auswahl, Aggregation,
    Bewertung) lebt auf Core-Seite. Dieses Skript ist deshalb bewusst kurz
    gehalten; die eigentliche Verarbeitungs-/Serialisierungslogik steckt in den
    testbaren, GIANTS-unabhaengigen Modulen unter scripts/ (JsonEncoder,
    PollTimer, FieldCollector, TelemetryCollector).

    ACHTUNG - unbestaetigtes Kategorie-C-Wissen: Die konkreten FS25-Engine-Aufrufe
    unten (welches Objekt haelt den Kontostand, in welcher Einheit liegt die
    Tageszeit vor, wie heissen Tag/Monat/Jahr/Feldliste auf Environment- bzw.
    FarmlandManager-Ebene) sind ein fundierter, aber NICHT im laufenden Spiel
    bestaetigter erster Entwurf, abgeleitet aus oeffentlich dokumentierten
    GIANTS-Engine-Mustern (Community-LUADOC, vergleichbare Open-Source-
    Telemetrie-Mods). Jeder Lesezugriff ist deshalb ueber pcall() mit teils
    mehreren Fallback-Strategien abgesichert, damit ein einzelner falscher
    API-Name nicht die gesamte Bridge zum Absturz bringt, sondern nur einen
    Platzhalterwert (0 bzw. eine leere fields-Liste) liefert und eine Warnung in
    log.txt hinterlaesst. Bitte nach dem ersten Testlauf im Spiel log.txt
    pruefen (siehe README.md, Abschnitt "Test-Feedback-Loop").

    Aktivierung: registriert sich ueber Mission00.update (Utils.appendedFunction),
    dasselbe bereits empirisch bestaetigte Hook-Muster wie im urspruenglichen
    Bridge-Prototyp - g_currentMission besitzt in diesem FS25-Build keine
    addModEventListener-Methode, daher KEINE Registrierung darueber.
]]

FarmPulseBridge = {}

FarmPulseBridge.EXCHANGE_SUBFOLDER = "FarmPulseBridge"
FarmPulseBridge.TELEMETRY_FILENAME = "telemetry.json"
FarmPulseBridge.POLL_INTERVAL_MS = 5000
FarmPulseBridge.LOG_PREFIX = "[FarmPulseBridge] "

local modDirectory = g_currentModDirectory

-- Reine, GIANTS-unabhaengige Logikmodule einbinden (siehe deren Dateikommentare).
source(modDirectory .. "scripts/JsonEncoder.lua")
source(modDirectory .. "scripts/PollTimer.lua")
source(modDirectory .. "scripts/FieldCollector.lua")
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
-- Gegen zwei Quellen bestaetigt (siehe README.md):
--   - Offizielle GDN-Dokumentation (Klasse AbstractMission): environment.dayTime
--     ist in Millisekunden seit Mitternacht (Verrechnung mit `24*60*60*1000` in
--     AbstractMission:getMinutesLeft()), environment.daysPerPeriod ist ein
--     echtes Feld (AbstractMission:setDefaultEndDate()), und der Tag-im-Monat
--     wird NICHT ueber ein rohes Feld, sondern ueber die Methode
--     environment:getDayInPeriodFromDay(currentMonotonicDay) berechnet (ebenfalls
--     setDefaultEndDate()) - environment.currentMonotonicDay ist dabei der
--     fortlaufende Tageszaehler seit Spielbeginn, kein Tag-im-Monat.
--   - FS25 AI Coding Reference (XelaNull/FS25_UsedPlus), gegen eine
--     veroeffentlichte Mod (UsedPlus) validiert, mit Datei-/Zeilenbeleg
--     (CreditSystem.lua:223-227): environment.currentMonth und
--     environment.currentYear sind echte, direkte Felder.
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

        -- Bestaetigt (siehe Funktionskommentar, FS25 AI Coding Reference):
        -- currentMonth/currentYear sind echte, direkte Felder.
        month = environment.currentMonth or 0
        year = environment.currentYear or 0
    end)

    if not ok then
        FarmPulseBridge.log("WARNUNG: Kalenderwerte (Uhrzeit/Tag/Monat/Jahr/Tage je Monat) konnten nicht vollstaendig gelesen werden.")
    end

    return hour, minute, day, month, year, daysPerMonth
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

--- Baut die aktuelle Telemetrie-Nutzlast und schreibt sie als telemetry.json in
-- den Austauschordner.
function FarmPulseBridge.exportTelemetry()
    if FarmPulseBridge.exchangeDirectory == nil then
        return
    end

    local hour, minute, day, month, year, daysPerMonth = FarmPulseBridge.readCalendar()
    local money = FarmPulseBridge.readMoney()
    local farmId = FarmPulseBridge.readFarmId()
    local rawFarmlands = FarmPulseBridge.readFarmlands()

    local payload = TelemetryCollector.buildPayload({
        hour = hour,
        minute = minute,
        day = day,
        month = month,
        year = year,
        daysPerMonth = daysPerMonth,
        money = money,
        farmId = farmId,
        fields = FieldCollector.buildFields(rawFarmlands),
    })

    local json = TelemetryCollector.toJson(payload)
    local path = FarmPulseBridge.exchangeDirectory .. FarmPulseBridge.TELEMETRY_FILENAME

    local file, openError = io.open(path, "w")
    if file == nil then
        FarmPulseBridge.log("FEHLER: Konnte '" .. path .. "' nicht zum Schreiben oeffnen: " .. tostring(openError))
        return
    end
    file:write(json)
    file:close()
end

--- Fasst die Aufgaben eines Poll-Ticks zusammen: aktuell nur der Telemetrie-
-- Export. Als eigene Funktion gehalten (statt inline in onMissionUpdate), damit
-- ein sofortiger erster Export bei der Aktivierung (siehe tryActivate) denselben
-- Code-Pfad wie jeder spaetere Timer-Tick durchlaeuft.
function FarmPulseBridge.onPollTick()
    FarmPulseBridge.exportTelemetry()
end

--- Einmalige, idempotente Aktivierung: haelt das Missionsobjekt fest,
-- initialisiert den Poll-Timer und den Austauschordner und fuehrt einen ersten
-- Sofort-Export durch. Wird ausschliesslich aus dem Mission00.update-Hook heraus
-- aufgerufen (siehe Registrierung am Dateiende) - dort ist "mission" garantiert
-- eine gueltige Missionsinstanz, da die Engine update() schliesslich AUF der
-- laufenden Mission aufruft.
-- @param mission die laufende Mission (self aus Mission00.update)
function FarmPulseBridge.tryActivate(mission)
    if FarmPulseBridge.activated or type(mission) ~= "table" then
        return
    end

    FarmPulseBridge.activated = true
    FarmPulseBridge.mission = mission
    FarmPulseBridge.pollTimer = PollTimer.new(FarmPulseBridge.POLL_INTERVAL_MS)
    FarmPulseBridge.exchangeDirectory = FarmPulseBridge.resolveExchangeDirectory()

    if FarmPulseBridge.exchangeDirectory ~= nil then
        FarmPulseBridge.log("Aktiviert (ueber Mission00.update). Austauschordner: " .. FarmPulseBridge.exchangeDirectory)
        -- Sofortiger erster Poll-Tick nach der Aktivierung, statt bis zu
        -- POLL_INTERVAL_MS auf den ersten Timer-Tick zu warten - das Dashboard
        -- soll direkt nach dem Spielstart Daten zeigen.
        FarmPulseBridge.onPollTick()
    end
end

--- Wird bei jedem Update der laufenden Mission aufgerufen (siehe Registrierung
-- am Dateiende). Aktiviert die Bridge beim ersten Aufruf (idempotent) und treibt
-- danach den Poll-Timer an.
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
