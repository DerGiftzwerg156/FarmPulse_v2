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
-- @return farmId (number), source (string, zu Debug-/Logzwecken)
function FarmPulseBridge.readFarmId()
    local mission = getMission()

    local ok, result = pcall(function()
        return mission:getFarmId()
    end)
    if ok and type(result) == "number" then
        return result, "currentMission.getFarmId()"
    end

    FarmPulseBridge.log("WARNUNG: Konnte FarmID ueber keine bekannte API lesen - exportiere 0.")
    return 0, "fallback-zero"
end

--- Liest den aktuellen Kontostand des Spieler-Betriebs.
-- Mehrere Fallback-Strategien (siehe Modul-Kommentar oben zu Kategorie-C-Wissen).
-- @return money (number), source (string, zu Debug-/Logzwecken)
function FarmPulseBridge.readMoney()
    local mission = getMission()

    -- Strategie 1 (FS22/FS25-Stil): Geld liegt pro Betrieb (Farm) im FarmManager.
    local ok, result = pcall(function()
        local farmId = mission:getFarmId()
        local farm = g_farmManager:getFarmById(farmId)
        return farm.money
    end)
    if ok and type(result) == "number" then
        return result, "farmManager.getFarmById(farmId).money"
    end

    -- Strategie 2 (aeltere/vereinfachte API, evtl. weiterhin als Komfort-Wrapper
    -- vorhanden): direkter Money-Getter auf der Mission.
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
-- @return hour, minute, day, month, year, daysPerMonth (jeweils number, Rohwerte
--         vor Normalisierung durch TelemetryCollector)
function FarmPulseBridge.readCalendar()
    local hour, minute, day, month, year, daysPerMonth = 0, 0, 0, 0, 0, 0
    local mission = getMission()

    local ok = pcall(function()
        local environment = mission.environment

        -- ANNAHME (unbestaetigt): environment.dayTime liegt in Millisekunden seit
        -- Mitternacht vor (0..86399999).
        local rawDayTime = environment.dayTime or 0
        hour = math.floor(rawDayTime / (1000 * 60 * 60))
        minute = math.floor((rawDayTime % (1000 * 60 * 60)) / (1000 * 60))

        -- ANNAHME (unbestaetigt): Feldnamen fuer Tag/Monat/Jahr innerhalb des
        -- Kalenders. currentDayInPeriod = Tag im aktuellen Monat (1-basiert),
        -- currentPeriod = Monat (1-12), currentYear = Jahr (1-basiert).
        day = environment.currentDayInPeriod or 0
        month = environment.currentPeriod or 0
        year = environment.currentYear or 0

        -- ANNAHME (unbestaetigt, bereits aus dem urspruenglichen Bridge-Prototyp
        -- uebernommen): Feldname fuer die Anzahl Spieltage je Monat.
        daysPerMonth = environment.daysPerPeriod or 0
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
-- ANNAHME (unbestaetigt): g_farmlandManager:getFarmlands() liefert eine Liste/
-- Tabelle von Farmland-Objekten mit den Feldern id, farmId, areaInHa, price. Fuer
-- areaInHa/price werden je zwei plausible Namensvarianten probiert (areaInHa/
-- size bzw. price/landPrice), damit ein einzelner falscher Feldname nicht
-- sofort zu 0 fuehrt.
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
                areaInHa = farmland.areaInHa or farmland.size or 0,
                price = farmland.price or farmland.landPrice or 0,
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
