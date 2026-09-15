# FarmPulse Bridge

Lua-Mod fuer Farming Simulator 25. Exportiert alle paar Sekunden einen
umfangreichen Telemetrie-Schnappschuss des laufenden Spielstands als
`telemetry.json` in einen gemeinsamen Austauschordner, den FarmPulse Core
ausliest.

Im Vergleich zum urspruenglichen Test-Prototyp (nur Kontostand, Spieltag,
Uhrzeit) exportiert diese Bridge deutlich mehr:

- Uhrzeit (Stunde/Minute)
- Spieltag, Monat, Jahr (innerhalb des Kalenders)
- Anzahl Spieltage je Monat
- Kontostand
- FarmID des aktuellen Spielers
- Feld-/Farmland-Informationen fuer **alle** Felder der Karte: Besitzer
  (anhand der FarmID), Groesse in Hektar, Feldpreis

## Wichtiger Hinweis zur Vertrauenswuerdigkeit dieses Codes

Dieser Mod wurde geschrieben, ohne ihn gegen ein laufendes FS25 testen zu
koennen. Die grobe Architektur (Datei-Polling, kein Netzwerk aus Lua, kein
JSON-Parser in der Engine, `Mission00.update`-Hook fuer Aktivierung/Taktgeber)
ist bereits aus einem vorherigen Testlauf bestaetigt (siehe Git-Historie des
urspruenglichen Bridge-Prototyps).

Die konkreten Engine-API-Aufrufe wurden gegen drei Quellen abgeglichen:

1. Die **[FS25 Community LUADOC](https://github.com/umbraprior/FS25-Community-LUADOC)**,
   die Klassen/Methoden inkl. des tatsaechlichen dekompilierten Lua-Quellcodes
   direkt aus dem Spiel extrahiert, aber nur Klassen erfasst, deren Methoden
   einem bestimmten Registrierungsmuster folgen (eine eigene Seite fuer die
   `Environment`-Klasse existiert dort trotz eines (veralteten/gebrochenen)
   Verweises aus Quelle 3 nachweislich nicht - mehrfach gezielt gesucht).
2. Die **offizielle [GDN-Dokumentation](https://gdn.giants-software.com/documentation_scripting_fs25.php)**
   (`gdn.giants-software.com`) selbst - aus dieser Entwicklungsumgebung heraus
   per Netzwerk-Policy nicht direkt erreichbar, aber die Seite fuer die Klasse
   `AbstractMission` (Category 59, ebenfalls mit echtem Quellcode) wurde
   manuell bereitgestellt und ausgewertet. Sie referenziert an mehreren
   Stellen `g_currentMission.environment` und `g_localPlayer`.
3. Das **[FS25 AI Coding Reference](https://github.com/XelaNull/FS25_UsedPlus/tree/master/FS25_AI_Coding_Reference)**
   von XelaNull/FS25_UsedPlus - explizit gegen eine tatsaechlich
   veroeffentlichte Mod (UsedPlus, Version 2.6.0) validiert, mit
   Datei-/Zeilenbelegen aus deren Quellcode (z.B. `CreditSystem.lua:223-227`).

| Wert | Verwendeter Ansatz | Status |
|---|---|---|
| Stunde/Minute | `g_currentMission.environment.dayTime`, in Millisekunden seit Mitternacht, umgerechnet in Stunde/Minute | **Bestaetigt** (Quelle 2): `AbstractMission:getMinutesLeft()` verrechnet `environment.dayTime` direkt mit `24*60*60*1000` |
| Tag im Monat | `g_currentMission.environment:getDayInPeriodFromDay(environment.currentMonotonicDay)` | **Bestaetigt** (Quelle 2): `AbstractMission:setDefaultEndDate()` berechnet den Tag-im-Monat exakt so - **kein** rohes Feld `currentDayInPeriod` (fruehere Annahme war falsch, siehe Korrektur unten). Quelle 3 belegt zwar auch ein rohes Feld `environment.currentDay`, dessen Semantik (Tag-im-Monat vs. fortlaufender Tageszaehler wie `currentMonotonicDay`) aus dem eingesehenen Ausschnitt aber nicht eindeutig hervorgeht - deshalb bewusst weiter die von Quelle 2 eindeutig belegte Methode verwendet |
| Monat | `g_currentMission.environment.currentMonth` (1-12) | **Bestaetigt** (Quelle 3, produktiv validiert) |
| Jahr | `g_currentMission.environment.currentYear` | **Bestaetigt** (Quelle 3, produktiv validiert) |
| Tage je Monat | `g_currentMission.environment.daysPerPeriod` | **Bestaetigt** (Quelle 2): direktes Feld, referenziert in `AbstractMission:setDefaultEndDate()` |
| FarmID | `g_localPlayer.farmId`, Fallback `g_currentMission:getFarmId()` | **Bestaetigt** (Quelle 2): `AbstractMission:update()` prueft `g_localPlayer.farmId == self.farmId` direkt gegen ein echtes Feld. `getFarmId()` bleibt als unbestaetigter, aber in der Community weit verbreiteter Fallback |
| Kontostand | `g_farmManager:getFarmById(farmId):getBalance()`, Fallback `g_currentMission:getMoney()` | **Bestaetigt** (Quelle 1): `Farm.md` zeigt die dokumentierte Methode `Farm:getBalance()`. Ein rohes `.money`-Feld ist NICHT dokumentiert und wird deshalb nicht mehr verwendet (Korrektur gegenueber einer fruehen Fassung dieser Bridge) |
| Feldliste | `g_farmlandManager:getFarmlands()`, je Eintrag `.id`/`.farmId`/`.areaInHa`/`.price` | **Bestaetigt** (Quelle 1): `FarmlandManager.md` zeigt `getFarmlands()` liefert `self.farmlands` (eine per Farmland-ID indizierte Tabelle - daher `pairs()` statt einer 1-indizierten Sequenz), und `Farmland.md` zeigt in `Farmland:load()` den Quellcode, der genau diese vier Felder setzt (Default-Besitzer `FarmlandManager.NO_OWNER_FARM_ID`, laut `getFarmlandOwner()`-Doku `0`) |

Damit sind mittlerweile alle exportierten Werte gegen mindestens eine
Quelle mit echtem Engine-Quellcode (nicht nur Signaturlisten) abgeglichen.
Ein Live-Test im Spiel bleibt trotzdem sinnvoll, insbesondere um die
Feldsemantik von `currentDay` vs. `getDayInPeriodFromDay()` und das genaue
Zusammenspiel von `currentMonth`/`currentYear`/`daysPerPeriod` ueber
Periodenwechsel hinweg zu verifizieren.

Jeder dieser Zugriffe ist trotzdem ueber `pcall()` abgesichert: Schlaegt ein
Aufruf fehl, wird ein Platzhalterwert (0 bzw. eine leere `fields`-Liste)
exportiert und eine Warnung in `log.txt` hinterlassen, statt dass die Bridge
abstuerzt. Das Verhalten laesst sich also risikofrei ausprobieren.

## Test-Feedback-Loop (bitte einmal durchfuehren)

1. Mod installieren (siehe unten).
2. Farming Simulator 25 mit einem Spielstand starten, in dem der Mod aktiviert
   ist.
3. Ein paar Minuten spielen, dann
   `Documents/My Games/FarmingSimulator2025/log.txt` oeffnen und nach
   `[FarmPulseBridge]` suchen. Erwartet wird eine Zeile wie
   `Aktiviert (ueber Mission00.update). Austauschordner: ...`, kurz nach
   `Info: Entered Gameplay`. Warnungen (`WARNUNG:`) zeigen an, welcher der
   obigen Zugriffe fehlgeschlagen ist.
4. Pruefen, ob im Austauschordner
   (`modSettings/FarmPulseBridge/telemetry.json`) tatsaechlich eine Datei
   entsteht und ob `money`/`farmId`/`hour`/`minute` mit dem, was im Spiel
   angezeigt wird, uebereinstimmen.
5. Pruefen, ob `day`/`month`/`year`/`daysPerMonth` mit der im Spiel
   angezeigten Kalenderanzeige uebereinstimmen.
6. Pruefen, ob `fields` eine plausible Anzahl Eintraege enthaelt (Anzahl
   Felder der geladenen Karte) und ob Groesse/Preis/Besitzer fuer ein paar
   bekannte, bereits gekaufte Felder mit der Ingame-Kartenansicht
   uebereinstimmen.
7. Diese Beobachtungen (Log-Auszug + ob die Werte stimmen) zurueckmelden -
   weicht z.B. `hour`/`minute` sichtbar ab, muss vermutlich nur die
   Umrechnung in `FarmPulseBridge.readCalendar()` angepasst werden; liefert
   `fields` immer eine leere Liste, ist entweder der Managername oder eine
   der Feldbezeichnungen auf dem Farmland-Objekt falsch (siehe Tabelle oben).

## Installation

1. Diesen gesamten Ordner (`Bridge/`) nach
   `Documents/My Games/FarmingSimulator2025/mods/FarmPulseBridge/` kopieren
   (oder als `FarmPulseBridge.zip` mit demselben Inhalt in denselben Ordner
   legen - beides wird von FS25 als Mod erkannt).
2. Im Spiel unter "Mods verwalten" aktivieren und im gewuenschten Spielstand
   einschalten.
3. Der Austauschordner
   `Documents/My Games/FarmingSimulator2025/modSettings/FarmPulseBridge/`
   wird beim ersten Laden automatisch angelegt.

## Was die Bridge tut (und was nicht)

- Alle 5 Sekunden (`FarmPulseBridge.POLL_INTERVAL_MS`) wird `telemetry.json`
  neu geschrieben - siehe Format unten.
- Die Bridge ist rein lesend: Anders als der urspruengliche Test-Prototyp
  liest diese Version **keine** `commands.xml`/`notification.xml` und greift
  nicht schreibend in den Spielzustand ein. Sie exportiert ausschliesslich
  Telemetrie.
- Multiplayer wird nicht unterstuetzt (`modDesc.xml`,
  `<multiplayer supported="false" />`).

## Dateiformat: `telemetry.json`

```json
{
  "hour": 8,
  "minute": 30,
  "day": 4,
  "month": 6,
  "year": 2,
  "daysPerMonth": 3,
  "money": 84250,
  "farmId": 1,
  "fields": [
    { "fieldId": 1, "ownerFarmId": 0, "sizeHa": 4.53, "price": 32000 },
    { "fieldId": 2, "ownerFarmId": 1, "sizeHa": 6.10, "price": 45000 }
  ]
}
```

Feldreihenfolge und -namen sind verbindlich - Core-seitiger Code sollte sich
nicht auf eine bestimmte JSON-Formatierung (Whitespace etc.) verlassen,
sondern per JSON-Parser auf die benannten Felder zugreifen.

- `hour`/`minute`: aktuelle In-Game-Uhrzeit (0-23 bzw. 0-59).
- `day`: aktueller Tag innerhalb des Monats.
- `month`: aktueller Monat (1-12).
- `year`: aktuelles Jahr.
- `daysPerMonth`: konfigurierte Anzahl Spieltage je Monat (Spielstand-
  Einstellung, i.d.R. konstant waehrend eines Spielstands).
- `money`: aktueller Kontostand des Spieler-Betriebs (kann negativ sein).
- `farmId`: FarmID des aktuellen Spielers - identifiziert, welcher
  `ownerFarmId`-Wert in `fields` "mir gehoert".
- `fields`: Liste **aller** Felder/Farmlands der geladenen Karte, aufsteigend
  nach `fieldId` sortiert:
    - `fieldId`: eindeutige ID des Feldes/Farmlands.
    - `ownerFarmId`: FarmID des Besitzers, `0` = noch niemandem gehoerend.
    - `sizeHa`: Groesse des Feldes in Hektar.
    - `price`: aktueller Kaufpreis des Feldes.

## Architektur des Mod-Codes

```
Bridge/
├── modDesc.xml                  Mod-Manifest
├── FarmPulseBridge.lua          GIANTS-Engine-Glue (Zeitplan, Datei-I/O, Engine-Zugriffe)
└── scripts/
    ├── JsonEncoder.lua          Minimaler JSON-Encoder (keine GIANTS-Abhaengigkeit)
    ├── PollTimer.lua            Timer-/Edge-Logik fuer den Update-Loop (keine GIANTS-Abhaengigkeit)
    ├── FieldCollector.lua       Normalisierung der Feld-/Farmland-Liste (keine GIANTS-Abhaengigkeit)
    └── TelemetryCollector.lua   Normalisierung + Payload-Aufbau (keine GIANTS-Abhaengigkeit)
```

Diese Trennung folgt dem Architektur-Leitprinzip "die Bridge bleibt bewusst
dumm": Alles, was sich ohne FS25 testen laesst, steckt in den
`scripts/*.lua`-Modulen. Nur `FarmPulseBridge.lua` selbst fasst die
riskanten, unbestaetigten Engine-Zugriffe an - und tut das an moeglichst
wenigen, klar markierten Stellen.

## Tests ausfuehren

Alle Module unter `scripts/` sind vollstaendig ohne FS25/GIANTS-Engine
testbar. Mit einem lokal installierten Lua-Interpreter (getestet mit Lua 5.4,
z.B. `apt-get install lua5.4` unter Debian/Ubuntu):

```bash
cd Bridge
lua tests/run_tests.lua
```

Erwartete Ausgabe: alle Tests `[ OK ]`, am Ende `45 bestanden, 0
fehlgeschlagen` (16 JsonEncoder, 9 PollTimer, 8 FieldCollector, 12
TelemetryCollector). `FarmPulseBridge.lua` selbst hat bewusst **keine**
automatisierten Tests - es enthaelt ausschliesslich GIANTS-Engine-Aufrufe,
die sich ausserhalb des laufenden Spiels nicht sinnvoll pruefen lassen (siehe
Abschnitt "Test-Feedback-Loop" oben).
