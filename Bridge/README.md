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

Die konkreten Engine-API-Aufrufe wurden zusaetzlich gegen die
**[FS25 Community LUADOC](https://github.com/umbraprior/FS25-Community-LUADOC)**
abgeglichen (die offizielle GIANTS Developer Network-Doku unter
`gdn.giants-software.com` war aus dieser Entwicklungsumgebung heraus nicht
erreichbar). Diese Community-Doku extrahiert Klassen/Methoden inkl. des
tatsaechlichen dekompilierten Lua-Quellcodes direkt aus dem Spiel, deckt aber
nur Klassen ab, deren Methoden einem bestimmten Registrierungsmuster folgen -
die zentrale `Mission`/`Environment`-Kernklasse hinter `g_currentMission`
faellt NICHT darunter und bleibt daher unbestaetigt:

| Wert | Verwendeter Ansatz | Status |
|---|---|---|
| Stunde/Minute | `g_currentMission.environment.dayTime`, angenommen in Millisekunden seit Mitternacht, umgerechnet in Stunde/Minute | **Unbestaetigt** - `Environment`-Klasse wird von der Community-LUADOC nicht erfasst |
| Tag im Monat | `g_currentMission.environment.currentDayInPeriod` | **Unbestaetigt**, Feldname aus dem "Period"-Vokabular abgeleitet (siehe `MessageType.PERIOD_CHANGED`/`periodChanged()`-Hooks, die in der Doku fuer mehrere Klassen belegt sind) |
| Monat | `g_currentMission.environment.currentPeriod` (1-12) | **Unbestaetigt**, gleiche Herleitung |
| Jahr | `g_currentMission.environment.currentYear` | **Unbestaetigt** |
| Tage je Monat | `g_currentMission.environment.daysPerPeriod` | **Unbestaetigt** (bereits im urspruenglichen Prototyp so verwendet) |
| FarmID | `g_currentMission:getFarmId()` | **Unbestaetigt** durch die Community-LUADOC (Mission-Kernklasse nicht erfasst), aber eine in zahlreichen FS22/FS25-Community-Mods etablierte, weit verbreitete API |
| Kontostand | `g_farmManager:getFarmById(farmId):getBalance()`, Fallback `g_currentMission:getMoney()` | **Bestaetigt**: `Farm.md` in der Community-LUADOC zeigt die dokumentierte Methode `Farm:getBalance()` ("Get the current account balance of the farm"). Ein rohes `.money`-Feld ist NICHT dokumentiert und wird deshalb nicht mehr verwendet (Korrektur gegenueber einer fruehen Fassung dieser Bridge) |
| Feldliste | `g_farmlandManager:getFarmlands()`, je Eintrag `.id`/`.farmId`/`.areaInHa`/`.price` | **Bestaetigt**: `FarmlandManager.md` zeigt `getFarmlands()` liefert `self.farmlands` (eine per Farmland-ID indizierte Tabelle - daher `pairs()` statt einer 1-indizierten Sequenz), und `Farmland.md` zeigt in `Farmland:load()` den Quellcode, der genau diese vier Felder setzt (Default-Besitzer `FarmlandManager.NO_OWNER_FARM_ID`, laut `getFarmlandOwner()`-Doku `0`) |

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
