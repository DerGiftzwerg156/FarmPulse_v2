# FarmPulse Bridge

Lua-Mod fuer Farming Simulator 25. Exportiert periodisch drei getrennte
Austauschdateien des laufenden Spielstands in einen gemeinsamen
Austauschordner, den FarmPulse Core ausliest - aufgeteilt nach
Aenderungsfrequenz statt eines einzigen monolithischen Schnappschusses:

- **`telemetry.json`** (alle paar Sekunden, schnelle "Puls"-Werte): Uhrzeit,
  Spieltag/Monat/Jahr/Tage je Monat, Kontostand, FarmID, Jahreszeit, Wetter.
- **`world.json`** (seltener, "was mir gehoert" jenseits des Kontostands):
  Feld-/Farmland-Informationen fuer **alle** Felder der Karte, aggregierter
  Fuhrpark-Wert, Lager-/Silobestaende.
- **`farm.json`** (einmalig bei Aktivierung, aendert sich praktisch nie):
  Hofname, Spielername.

Bewusst **nicht** exportiert - diese Entscheidungen wurden explizit im
Projekt getroffen, nicht vergessen: Fahrzeugzustand (Tankfuellung, Verschleiss
- beobachtet der Spieler ohnehin selbst im laufenden Spiel; einzig der
aggregierte Vermoegenswert des Fuhrparks ist als `fleetValue` relevant),
Tiere, Anbaudaten je Feld (welche Frucht, Wachstumsstadium - im Sinne dieser
Bridge geht es bei `fields` nur um Besitz, nicht um Bewirtschaftung),
Vertraege/Missionen, Kredite/Schulden (diese Logik uebernimmt FarmPulse Core
vollstaendig, statt die Ingame-Kreditlogik zu spiegeln), sowie jede Form von
Verlauf/Historie (das Spiel selbst bzw. Core fuehren Buch, die Bridge liefert
nur Momentaufnahmen).

## Wichtiger Hinweis zur Vertrauenswuerdigkeit dieses Codes

Dieser Mod wurde geschrieben, ohne ihn gegen ein laufendes FS25 testen zu
koennen. Die grobe Architektur (Datei-Polling, kein Netzwerk aus Lua, kein
JSON-Parser in der Engine, `Mission00.update`-Hook fuer Aktivierung/Taktgeber)
ist bereits aus einem vorherigen Testlauf bestaetigt (siehe Git-Historie des
urspruenglichen Bridge-Prototyps).

Die konkreten Engine-API-Aufrufe fuer die urspruenglichen Werte (Uhrzeit,
Kalender, Kontostand, FarmID, Feldliste) wurden gegen drei Quellen
abgeglichen:

1. Die **[FS25 Community LUADOC](https://github.com/umbraprior/FS25-Community-LUADOC)**,
   die Klassen/Methoden inkl. des tatsaechlichen dekompilierten Lua-Quellcodes
   direkt aus dem Spiel extrahiert, aber nur Klassen erfasst, deren Methoden
   einem bestimmten Registrierungsmuster folgen (eine eigene Seite fuer die
   `Environment`-Klasse existiert dort trotz eines (veralteten/gebrochenen)
   Verweises aus Quelle 3 nachweislich nicht - mehrfach gezielt gesucht; siehe
   auch weiter unten, "Wetter").
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

Fuer die neu hinzugekommenen Werte (Wetter/Jahreszeit, Hofname, Spielername,
Fuhrpark-Wert, Lagerbestaende) kamen zusaetzlich vier echte, aktuell
veroeffentlichte FS25-Mods als Quellen dazu (recherchiert per Web-Suche, da
weder GDN noch die Community-LUADOC diese Bereiche abdecken - siehe Tabelle
unten fuer Details je Wert):

4. **[FS25_InfoDisplayExtension](https://github.com/Achimobil/FS25_InfoDisplayExtension)** (Achimobil)
5. **[FS25_Tardis](https://github.com/sperrgebiet/FS25_Tardis)** (sperrgebiet)
6. **[FS25_UsedPlus](https://github.com/Seamforge/FS25_UsedPlus)** (Seamforge, nicht zu verwechseln mit der FS25 AI Coding Reference oben, die im selben Ursprungs-Repo von XelaNull liegt)
7. **[FS25_UpgradableFactories](https://github.com/demortes/FS25_UpgradableFactories)** (demortes)
8. **[FS25_LeaseToOwn](https://github.com/ColinM9991/FS25_LeaseToOwn)** (ColinM9991) - nach dem ersten Live-Test (siehe "Erster Live-Test" unten) als zusaetzliche Quelle fuer FarmID recherchiert
9. **[FS25_LumberJack](https://github.com/loki79uk/FS25_LumberJack)** (loki79uk) - dito, belegt `g_localPlayer` als reales, aber gelegentlich `nil` werdendes Objekt

| Wert | Verwendeter Ansatz | Status |
|---|---|---|
| Stunde/Minute | `g_currentMission.environment.dayTime`, in Millisekunden seit Mitternacht, umgerechnet in Stunde/Minute | **Bestaetigt** (Quelle 2): `AbstractMission:getMinutesLeft()` verrechnet `environment.dayTime` direkt mit `24*60*60*1000` |
| Tag im Monat | `g_currentMission.environment:getDayInPeriodFromDay(environment.currentMonotonicDay)` | **Bestaetigt** (Quelle 2): `AbstractMission:setDefaultEndDate()` berechnet den Tag-im-Monat exakt so - **kein** rohes Feld `currentDayInPeriod` (fruehere Annahme war falsch, siehe Korrektur unten). Quelle 3 belegt zwar auch ein rohes Feld `environment.currentDay`, dessen Semantik (Tag-im-Monat vs. fortlaufender Tageszaehler wie `currentMonotonicDay`) aus dem eingesehenen Ausschnitt aber nicht eindeutig hervorgeht - deshalb bewusst weiter die von Quelle 2 eindeutig belegte Methode verwendet |
| Monat | `g_currentMission.environment.currentMonth` (1-12) | **Bestaetigt** (Quelle 3, produktiv validiert) |
| Jahr | `g_currentMission.environment.currentYear` | **Bestaetigt** (Quelle 3, produktiv validiert) |
| Tage je Monat | `g_currentMission.environment.daysPerPeriod` | **Bestaetigt** (Quelle 2): direktes Feld, referenziert in `AbstractMission:setDefaultEndDate()` |
| FarmID | `g_farmManager:getFarmByUserId(mission.playerUserId).farmId`, Fallback `g_localPlayer.farmId`, Fallback `g_currentMission:getFarmId()` | **Strategie 1 bestaetigt** (Quelle 8, FS25_LeaseToOwn, echter veroeffentlichter Mod): ermittelt die Farm exakt so (`g_farmManager:getFarmByUserId(g_currentMission.playerUserId)` -> `.farmId`). Im **ersten Live-Test** (siehe "Erster Live-Test" unten) schlugen die beiden vorherigen Strategien (`g_localPlayer.farmId` bzw. `mission:getFarmId()`) durchgehend fehl - plausibelster Grund: `g_localPlayer` ist laut Quelle 9 (FS25_LumberJack, das deshalb selbst mit `if not g_localPlayer then ...` absichert) haeufig `nil`, u.a. waehrend der Spieler in einem Fahrzeug sitzt. Die neue Strategie 1 haengt nicht von der physischen Spielerfigur ab und sollte deshalb auch waehrend der Fahrzeugfahrt funktionieren. `g_localPlayer.farmId` (Strategie 2) bleibt als Fallback bestehen - der Feldname selbst ist ueber `Player.md` (Quelle 1, `Player.createServerInstance()`: `self.farmId = farmId`) bestaetigt, nur die Verfuegbarkeit von `g_localPlayer` nicht. `getFarmId()` (Strategie 3) bleibt unbestaetigter letzter Fallback |
| Kontostand | `g_farmManager:getFarmById(farmId):getBalance()`, Fallback `g_currentMission:getMoney()` | **Bestaetigt** (Quelle 1): `Farm.md` zeigt die dokumentierte Methode `Farm:getBalance()` ("Get the current account balance of the farm", keine Argumente). Ein rohes `.money`-Feld ist NICHT dokumentiert und wird deshalb nicht mehr verwendet (Korrektur gegenueber einer fruehen Fassung dieser Bridge). `getFarmById()` selbst ist in `FarmManager.md` ("Get the farm object by given farmId") ebenfalls dokumentiert |
| Feldliste | `g_farmlandManager:getFarmlands()`, je Eintrag `.id`/`.farmId`/`.areaInHa`/`.price` | **Bestaetigt** (Quelle 1): `FarmlandManager.md` zeigt `getFarmlands()` liefert `self.farmlands` (eine per Farmland-ID indizierte Tabelle - daher `pairs()` statt einer 1-indizierten Sequenz), und `Farmland.md` zeigt in `Farmland:load()` den Quellcode, der genau diese vier Felder setzt (Default-Besitzer `FarmlandManager.NO_OWNER_FARM_ID`, laut `getFarmlandOwner()`-Doku `0`) |
| Jahreszeit (`season`) | reine Berechnung aus dem bereits bestaetigten Monatsfeld (1-12), **kein** zusaetzlicher Engine-Zugriff (siehe `WeatherCollector.seasonFromMonth`) | **Bestaetigt** (folgt direkt aus dem oben bestaetigten Monatsfeld - keine neue, unbestaetigte Engine-Abhaengigkeit noetig) |
| Wetter (`weather`) | Zwei Strategien: `environment.weather.type.name`, Fallback `environment.currentWeatherType` | **UNBESTAETIGT - die groesste verbleibende Unsicherheit im gesamten Mod**: GIANTS veroeffentlicht `Weather.lua`/`WeatherForecast.lua`/`Environment.lua` nachweislich weder im offiziellen SDK-Dump noch in Quelle 1 ("FS25 withholds Weather.lua, WeatherForecast.lua and Environment.lua from the SDK dump, the Community LUADOC and FS25-lua-scripting") - dafuer existiert schlicht **keine** oeffentliche Quelle mit echtem Engine-Quellcode. Beide Strategien oben sind plausible, aber unbestaetigte Vermutungen anhand verbreiteter Feldnamen in Community-Wetter-Mods. Ein GDN-Forumsthread genau zu dieser Frage existiert ("Where do i find the contents of all owned silos/storage?" behandelt zwar primaer Lager, angrenzende Threads zu Environment/Weather ebenso), war aber durch die Netzwerk-Policy dieser Entwicklungsumgebung (`gdn.giants-software.com` blockiert) nicht abrufbar. Fallback bei Fehlschlag beider Strategien: `"unknown"` |
| Hofname (`farmName`) | `g_farmManager:getFarmById(farmId).name` | **Bestaetigt** (Quelle 4, FS25_InfoDisplayExtension, echter veroeffentlichter Mod): liest `owningFarm.name` auf demselben Farm-Objekt, das diese Bridge bereits fuer `getBalance()` verwendet |
| Spielername (`playerName`) | `g_currentMission.playerNickname` | **Bestaetigt** (Quelle 5, FS25_Tardis, echter veroeffentlichter Mod): referenziert dieses Feld direkt |
| Fuhrpark-Wert (`fleetValue`) | `g_currentMission.vehicleSystem.vehicles` (Liste aller Fahrzeuge), je Eintrag `vehicle:getOwnerFarmId()` zum Filtern + `vehicle:getSellPrice()`, aufsummiert | **Bestaetigt** (Quelle 5, FS25_Tardis, und ein weiterer veroeffentlichter Mod, FS25_VehicleExplorer von teknogeek, fuer `g_currentMission.vehicleSystem.vehicles` als Fahrzeugliste dieser FS25-Engine-Generation - abgeloest gegenueber `g_currentMission.vehicles` aus FS19-FS22 -, Quelle 6 fuer `Vehicle:getSellPrice()` als real gehookte Methode). Bewusst nur der aggregierte Wert, keine Einzelfahrzeug-Details (siehe Einleitung) |
| Lager-/Silobestaende (`storages`) | `g_currentMission.productionChainManager.productionPoints`, je Punkt `.storage.fillLevels`/`.storage.capacities` (indiziert nach Fill-Typ, aufgeloest ueber `g_fillTypeManager:getFillTypeNameByIndex()`) | **Teilweise bestaetigt** (Quelle 7, FS25_UpgradableFactories, echter veroeffentlichter Mod, fuer die Struktur von `.storage.fillLevels`/`.capacities` und `productionChainManager.productionPoints`): deckt damit bestaetigt Produktionspunkt-Lager ab. Ob dieselbe Struktur auch frei platzierte Hof-Silos (Placeables ohne Produktionspunkt-Charakter) umfasst, ist **nicht** bestaetigt - eine Web-Suche fand Hinweise auf `g_currentMission.placeableSystem.placeables`, gefiltert nach einer Lager-Spezialisierung (`spec_objectStorage`/`spec_palletSpawner`), als moeglichen zusaetzlichen Weg, aber ohne handfesten Quellcode-Beleg. Siehe Abschnitt "Bekannte Luecken" unten |

Ein vollstaendiger erneuter Abgleich aller urspruenglichen Werte
ausschliesslich gegen die Community-LUADOC (Quelle 1) bestaetigt: Diese deckt
weiterhin **keine** `Mission`/`BaseMission`- oder `Environment`-Klassenseite
ab (auch nicht unter den Kategorien "Base" oder "Misc", die dafuer
naheliegend waeren, und nicht unter `getMoney`, `getDayInPeriodFromDay`,
`currentMonth`, `currentYear`, `daysPerPeriod` oder `dayTime` als
Funktionsnamen) - `mission:getFarmId()`, `mission:getMoney()` und saemtliche
Environment-/Kalenderfelder bleiben also ausschliesslich durch Quelle 2 bzw.
3 belegt, nicht durch Quelle 1. Ebenso undokumentiert in Quelle 1:
`Utils.appendedFunction()` und die `Mission00`-Klasse (der Aktivierungs-Hook
der Bridge) - dieser Mechanismus ist stattdessen bereits durch echte
In-Game-Testlaeufe des urspruenglichen Bridge-Prototyps empirisch bestaetigt
(siehe Git-Historie), was staerker wiegt als jede statische Dokumentation.

Jeder dieser Zugriffe ist trotzdem ueber `pcall()` abgesichert: Schlaegt ein
Aufruf fehl, wird ein Platzhalterwert (`0`, `"unknown"` bzw. eine leere
Liste) exportiert und eine Warnung in `log.txt` hinterlassen, statt dass die
Bridge abstuerzt. Das Verhalten laesst sich also risikofrei ausprobieren.

### Erster Live-Test (Ergebnis)

Der erste tatsaechliche Testlauf im Spiel (siehe "Test-Feedback-Loop" unten)
lieferte folgendes `log.txt`-Bild:

- Aktivierung erfolgreich: `Aktiviert (ueber Mission00.update). Austauschordner: ...`
- `hour`/`minute`/`day`/`month`/`year`/`daysPerMonth` (Kalender) und `money`
  (Kontostand): **keine Warnung** - beide gelten damit als im laufenden Spiel
  bestaetigt.
- `farmId`: **beide** damals vorhandenen Strategien (`g_localPlayer.farmId`,
  `mission:getFarmId()`) schlugen durchgehend fehl (`WARNUNG: Konnte FarmID
  ueber keine bekannte API lesen - exportiere 0.`), ueber die gesamte
  Spielsitzung hinweg, nicht nur beim allerersten Tick. Das spricht klar
  gegen einen reinen Timing-Effekt (z.B. Aktivierung vor vollstaendigem
  Login) und fuer eine strukturelle Erklaerung - siehe oben ("FarmID"-Zeile
  der Tabelle) fuer die daraufhin recherchierte, neue Strategie 1
  (`g_farmManager:getFarmByUserId(...)`) und ihre Begruendung
  (`g_localPlayer` vermutlich `nil`, weil der Spieler im Fahrzeug sass).
- `weather`: **beide** Strategien schlugen ebenfalls fehl (`WARNUNG: Konnte
  Wetter ueber keine bekannte API lesen - exportiere 'unknown'.`) - erwartbar,
  siehe "groesste verbleibende Unsicherheit" oben. Bleibt weiterhin ungeloest.
- `world.json`/`farm.json` wurden nicht separat zurueckgemeldet - noch offen.

Als direkte Konsequenz aus diesem Test:

1. `FarmPulseBridge.readFarmId()` bekam die oben beschriebene neue Strategie 1.
2. Beide `readFarmId()`/`readWeather()` loggen ihre `WARNUNG:` jetzt nur noch
   **einmal pro Spielsitzung** (`logOnce()`), nicht mehr bei jedem Poll-Tick -
   im ersten Test erschien dieselbe Zeile ueber die gesamte Sitzung hinweg
   dutzendfach und haette echte Probleme im Log verschleiert.
3. Schlaegt eine der beiden Funktionen weiterhin fehl, wird direkt danach
   einmalig eine `DEBUG`-Zeile mit den tatsaechlich vorhandenen, thematisch
   passenden Tabellenschluesseln geloggt (`logMatchingFieldNamesOnce()`,
   z.B. alle Schluessel von `environment`, die `"weath"`/`"sky"`/`"rain"`/
   `"cloud"`/`"forecast"` enthalten) - damit liefert der **naechste**
   Live-Test direkt die richtigen Feldnamen, statt erneut blind raten zu
   muessen bzw. einen separaten Daten-Dump-Mod zu benoetigen.

### Bekannte Luecken (Stand nach dem ersten Live-Test)

- **Wetter** bleibt die groesste Unsicherheit - beide Strategien in
  `FarmPulseBridge.readWeather()` sind weiterhin unbestaetigt und im ersten
  Live-Test nachweislich fehlgeschlagen (siehe "Erster Live-Test" oben). Die
  neu hinzugekommene `DEBUG`-Diagnose sollte im naechsten Testlauf die
  tatsaechlichen Feldnamen auf `environment` offenlegen; alternativ bleibt
  ein Daten-Dump-Mod (siehe z.B. "Developer PowerTools" im Modhub) als
  Rueckfalloption.
- **FarmID** hat jetzt eine gegen einen echten Mod bestaetigte Strategie 1
  (siehe oben) - sollte diese im naechsten Test ebenfalls fehlschlagen,
  greift dieselbe neue `DEBUG`-Diagnose (Schluessel auf `mission` mit
  `"farm"`/`"player"`/`"user"` im Namen).
- **Lagerbestaende** decken bestaetigt nur Produktionspunkte ab (Fabriken,
  Verarbeitungsanlagen), noch nicht zwingend frei platzierte Hof-Silos. Falls
  `storages` im Live-Test dauerhaft leer bleibt oder erkennbar unvollstaendig
  ist (z.B. bekannte Getreidesilos fehlen), ist die naheliegende Erweiterung,
  in `FarmPulseBridge.readStorages()` zusaetzlich
  `g_currentMission.placeableSystem.placeables` nach einer
  Lager-Spezialisierung zu durchsuchen.

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
   (`modSettings/FarmPulseBridge/`) alle drei Dateien (`telemetry.json`,
   `world.json`, `farm.json`) tatsaechlich entstehen und ob
   `money`/`farmId`/`hour`/`minute` mit dem, was im Spiel angezeigt wird,
   uebereinstimmen.
5. Pruefen, ob `day`/`month`/`year`/`daysPerMonth` sowie die daraus
   berechnete `season` mit der im Spiel angezeigten Kalenderanzeige
   uebereinstimmen.
6. Pruefen, ob `weather` einen plausiblen, sich ueber die Zeit aenderenden
   Wert liefert (nicht dauerhaft `"unknown"`) - siehe "Bekannte Luecken"
   oben, falls nicht.
7. In `world.json` pruefen, ob `fields` eine plausible Anzahl Eintraege
   enthaelt (Anzahl Felder der geladenen Karte) und ob Groesse/Preis/Besitzer
   fuer ein paar bekannte, bereits gekaufte Felder mit der Ingame-Kartenansicht
   uebereinstimmen.
8. In `world.json` pruefen, ob `fleetValue` grob zur Anzahl/Klasse der
   eigenen Fahrzeuge passt, und ob `storages` bekannte Lagerbestaende
   (zumindest aus Produktionspunkten) korrekt widerspiegelt.
9. In `farm.json` pruefen, ob `farmName`/`playerName` mit dem im Spiel
   gewaehlten Hof-/Spielernamen uebereinstimmen.
10. Diese Beobachtungen (Log-Auszug + ob die Werte stimmen, je Datei) 
    zurueckmelden - weicht z.B. `hour`/`minute` sichtbar ab, muss vermutlich
    nur die Umrechnung in `FarmPulseBridge.readCalendar()` angepasst werden;
    liefert `fields` immer eine leere Liste, ist entweder der Managername
    oder eine der Feldbezeichnungen auf dem Farmland-Objekt falsch (siehe
    Tabelle oben).

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
  neu geschrieben, alle 30 Sekunden (`FarmPulseBridge.WORLD_POLL_INTERVAL_MS`)
  `world.json` - siehe Format unten. `farm.json` wird nur einmal bei der
  Aktivierung geschrieben.
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
  "season": "summer",
  "weather": "sun"
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
  `ownerFarmId`-Wert in `world.json`/`fields` "mir gehoert".
- `season`: Jahreszeit, rein aus `month` berechnet - `"winter"`, `"spring"`,
  `"summer"` oder `"autumn"`.
- `weather`: aktueller Wetterzustand als roher, unbestaetigter Engine-String
  (siehe "Wichtiger Hinweis" oben), oder `"unknown"`, falls kein Zugriff
  moeglich war.

## Dateiformat: `world.json`

```json
{
  "fleetValue": 125000,
  "fields": [
    { "fieldId": 1, "ownerFarmId": 0, "sizeHa": 4.53, "price": 32000 },
    { "fieldId": 2, "ownerFarmId": 1, "sizeHa": 6.10, "price": 45000 }
  ],
  "storages": [
    { "fillType": "BARLEY", "amount": 1200, "capacity": 20000 },
    { "fillType": "WHEAT", "amount": 5000, "capacity": 20000 }
  ]
}
```

- `fleetValue`: aggregierter Verkaufswert aller Fahrzeuge der aktuellen Farm
  (Summe von `Vehicle:getSellPrice()`) - **kein** Einzelfahrzeug-Zustand
  (Tankfuellung, Verschleiss), siehe Einleitung.
- `fields`: Liste **aller** Felder/Farmlands der geladenen Karte, aufsteigend
  nach `fieldId` sortiert:
    - `fieldId`: eindeutige ID des Feldes/Farmlands.
    - `ownerFarmId`: FarmID des Besitzers, `0` = noch niemandem gehoerend.
    - `sizeHa`: Groesse des Feldes in Hektar.
    - `price`: aktueller Kaufpreis des Feldes.
- `storages`: Lager-/Silobestaende der aktuellen Farm, nach Fill-Typ
  aggregiert (mehrere Lagerstaetten desselben Fill-Typs werden
  zusammengefasst) und alphabetisch nach `fillType` sortiert. Siehe "Bekannte
  Luecken" oben zur aktuellen Abdeckung:
    - `fillType`: Name des Fill-Typs (z.B. `"WHEAT"`), `"UNKNOWN"` falls
      nicht auflösbar.
    - `amount`: aktuell gelagerte Menge.
    - `capacity`: Gesamtkapazitaet fuer diesen Fill-Typ.

## Dateiformat: `farm.json`

```json
{
  "farmName": "Sonnenhof",
  "playerName": "Keno"
}
```

- `farmName`: Name des Betriebs, `"Unbekannt"` falls nicht auflösbar.
- `playerName`: Spieler-/Nickname, `"Unbekannt"` falls nicht auflösbar.

## Architektur des Mod-Codes

```
Bridge/
├── modDesc.xml                  Mod-Manifest
├── FarmPulseBridge.lua          GIANTS-Engine-Glue (Zeitplan, Datei-I/O, Engine-Zugriffe)
└── scripts/
    ├── JsonEncoder.lua          Minimaler JSON-Encoder (keine GIANTS-Abhaengigkeit)
    ├── PollTimer.lua            Timer-/Edge-Logik fuer den Update-Loop (keine GIANTS-Abhaengigkeit)
    ├── FieldCollector.lua       Normalisierung der Feld-/Farmland-Liste (keine GIANTS-Abhaengigkeit)
    ├── VehicleCollector.lua     Aggregation des Fuhrpark-Werts (keine GIANTS-Abhaengigkeit)
    ├── StorageCollector.lua     Normalisierung/Aggregation der Lagerbestaende (keine GIANTS-Abhaengigkeit)
    ├── WeatherCollector.lua     Jahreszeit-Berechnung + Wetter-Normalisierung (keine GIANTS-Abhaengigkeit)
    ├── FarmCollector.lua        Normalisierung + Payload-Aufbau fuer farm.json (keine GIANTS-Abhaengigkeit)
    ├── WorldCollector.lua       Normalisierung + Payload-Aufbau fuer world.json (keine GIANTS-Abhaengigkeit)
    └── TelemetryCollector.lua   Normalisierung + Payload-Aufbau fuer telemetry.json (keine GIANTS-Abhaengigkeit)
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

Erwartete Ausgabe: alle Tests `[ OK ]`, am Ende `79 bestanden, 0
fehlgeschlagen` (16 JsonEncoder, 9 PollTimer, 8 FieldCollector,
6 VehicleCollector, 7 StorageCollector, 8 WeatherCollector, 6 FarmCollector,
6 WorldCollector, 13 TelemetryCollector). `FarmPulseBridge.lua` selbst hat
bewusst **keine** automatisierten Tests - es enthaelt ausschliesslich
GIANTS-Engine-Aufrufe, die sich ausserhalb des laufenden Spiels nicht
sinnvoll pruefen lassen (siehe Abschnitt "Test-Feedback-Loop" oben).
