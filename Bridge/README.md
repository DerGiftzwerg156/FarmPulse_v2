# FarmPulse Bridge

Lua-Mod fuer Farming Simulator 25. Exportiert periodisch drei getrennte
Austauschdateien des laufenden Spielstands in einen gemeinsamen
Austauschordner, den FarmPulse Core ausliest - aufgeteilt nach
Aenderungsfrequenz statt eines einzigen monolithischen Schnappschusses:

- **`telemetry.json`** (alle paar Sekunden, schnelle "Puls"-Werte): Uhrzeit,
  Spieltag/Monat/Jahr/Tage je Monat, Kontostand, FarmID, aktueller Wettertyp
  und Temperatur.
- **`world.json`** (seltener, "was mir gehoert" jenseits des Kontostands):
  Feld-/Farmland-Informationen fuer **alle** Felder der Karte (inkl.
  optionaler Anbaudaten - Fruchtart, Wachstumsfortschritt, Ertragsschaetzung -
  fuer die Ertragsprognose im Frontend), aggregierter Fuhrpark-Wert samt einer
  Liste einzelner Fahrzeuge (Name, Kategorie, PS, Betriebsstunden, Zustand,
  Eigentumsstatus, Verkaufspreis), Lager-/Silobestaende (inkl. aktuellem Marktpreis sowie
  bestem Preis + Periode der letzten 12 FS25-Perioden je Fill-Typ).
- **`farm.json`** (einmalig bei Aktivierung, aendert sich praktisch nie):
  Hofname, Spielername.

Bewusst **nicht** exportiert - diese Entscheidungen wurden explizit im
Projekt getroffen, nicht vergessen: Kraftstofffuellstand je Fahrzeug
(beobachtet der Spieler ohnehin selbst im laufenden Spiel), Tiere,
Vertraege/Missionen, Kredite/Schulden (diese Logik uebernimmt FarmPulse Core
vollstaendig, statt die Ingame-Kreditlogik zu spiegeln), sowie jede Form von
Verlauf/Historie (das Spiel selbst bzw. Core fuehren Buch, die Bridge liefert
nur Momentaufnahmen). Anbaudaten je Feld waren urspruenglich ebenfalls aus
dieser Liste ("bei `fields` geht es nur um Besitz, nicht um Bewirtschaftung")
- diese Entscheidung wurde fuer die Ertragsprognose im Frontend bewusst
revidiert (siehe Tabelle unten). Einzelfahrzeug-Zustand (Verschleiss/Schaden)
war ebenfalls urspruenglich bewusst ausgeschlossen ("einzig der aggregierte
Vermoegenswert des Fuhrparks ist als `fleetValue` relevant") - auch diese
Entscheidung wurde fuer eine eigene Fuhrpark-Uebersicht im Frontend revidiert
(siehe Abschnitt "Fuhrpark-Details" sowie Tabelle unten).

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
   Verweises aus Quelle 3 nachweislich nicht - mehrfach gezielt gesucht).
2. Die **offizielle [GDN-Dokumentation](https://gdn.giants-software.com/documentation_scripting_fs25.php)**
   (`gdn.giants-software.com`) selbst - aus dieser Entwicklungsumgebung heraus
   per Netzwerk-Policy nicht direkt erreichbar, aber die Seite fuer die Klasse
   `AbstractMission` (Category 59, ebenfalls mit echtem Quellcode) wurde
   manuell bereitgestellt und ausgewertet. Sie referenziert an mehreren
   Stellen `g_currentMission.environment` und `g_localPlayer`.
3. Das **[FS25 AI Coding Reference](https://github.com/Seamforge/FS25_UsedPlus/tree/master/FS25_AI_Coding_Reference)**
   von Seamforge/FS25_UsedPlus (**Korrektur**: in einer frueheren Fassung
   dieser Datei faelschlich `XelaNull/FS25_UsedPlus` zugeschrieben - dieses
   Repo existiert nicht als Quelle fuer diese Mod, die Verwechslung stammt
   vermutlich aus einem unabhaengigen, thematisch unverwandten Discord-Bot-
   Repo desselben Nutzernamens) - explizit gegen eine tatsaechlich
   veroeffentlichte Mod (UsedPlus, Version 2.6.0) validiert, mit
   Datei-/Zeilenbelegen aus deren Quellcode. **Wichtige Einschraenkung**: die
   Referenzdatei buendelt mehrere Environment-Felder (`currentDay`,
   `currentMonth`, `currentYear`) unter einem gemeinsamen "validiert"-Haken,
   obwohl `CreditSystem.lua` (die dort zitierte Belegstelle) nachweislich nur
   `currentYear` tatsaechlich verwendet - `currentMonth` selbst wurde dort nie
   durch echten Aufrufcode belegt (siehe Korrektur bei "Monat" unten).

Fuer die neu hinzugekommenen Werte (Hofname, Spielername,
Fuhrpark-Wert, Lagerbestaende) kamen zusaetzlich vier echte, aktuell
veroeffentlichte FS25-Mods als Quellen dazu (recherchiert per Web-Suche, da
weder GDN noch die Community-LUADOC diese Bereiche abdecken - siehe Tabelle
unten fuer Details je Wert):

4. **[FS25_InfoDisplayExtension](https://github.com/Achimobil/FS25_InfoDisplayExtension)** (Achimobil)
5. **[FS25_Tardis](https://github.com/sperrgebiet/FS25_Tardis)** (sperrgebiet)
6. **[FS25_UsedPlus](https://github.com/Seamforge/FS25_UsedPlus)** (Seamforge) - derselbe Ursprungs-Repo
   wie die FS25 AI Coding Reference oben (Quelle 3); hier jedoch der eigentliche Mod-Code
   selbst als Beleg, nicht die separate Referenzdokumentation im Unterordner
7. **[FS25_UpgradableFactories](https://github.com/demortes/FS25_UpgradableFactories)** (demortes)

Fuer Wetter (Temperatur, Wettertyp) sowie Feld-Anbaudaten/Ertragsschaetzung
kam zusaetzlich eine weitere Quelle dazu (siehe Tabelle unten):

8. **[FS25_RealisticWeather](https://github.com/arrow-kb/FS25_RealisticWeather)** (arrow-kb) - ueberschreibt/erweitert
   die (von GIANTS weder im SDK-Dump noch in der LUADOC offengelegte)
   `Weather`-Klasse und baut dabei u.a. die Wetteranzeige des Basisspiel-HUD
   nach (`src/gui/hud/GameInfoDisplay.lua`) - einzige gefundene Quelle mit
   echtem Aufrufcode fuer die sonst verborgenen Wetter-Interna.
9. **[fs25-lua-api](https://github.com/MyGameSteamOfficial/fs25-lua-api)** (MyGameSteamOfficial) - ein Dump von
   `dataS/scripts` aus FS25 selbst (886 Lua-Dateien; Funktionsrumpfe teils von
   GIANTS entfernt, Aufrufstellen aber intakt) - fuer `Field`/`FieldManager`/
   `FieldState`/`FruitTypeDesc`, spaeter zusaetzlich fuer die Fuhrpark-Details
   fuer `vehicles/Vehicle.lua` (`getFullName()`/`getOperatingTime()`/
   `getSellPrice()`/`calculateSellPrice()`/`getPropertyState()`) sowie
   `vehicles/specializations/Wearable.lua` (`getDamageAmount()`),
   `vehicles/specializations/Motorized.lua` (`getSpecValuePower()`) und
   `shop/StoreManager.lua` (`addCategory()`/`getCategoryByName()` fuer den
   lokalisierten Kategorie-Anzeigenamen), als echter, wenn auch nicht offiziell
   dokumentierter Basisspiel-Quellcode.

Fuer Marktpreise (aktueller Preis, Preishistorie je Fill-Typ) kamen zwei
weitere Quellen dazu:

10. **[FarmingSimulator25_dataS](https://github.com/maxkra1985/FarmingSimulator25_dataS)**
    (maxkra1985) - ein weiterer, unabhaengiger Dekompilat-Dump von
    `dataS/scripts` aus FS25 (u.a. `economy/EconomyManager.lua`,
    `economy/PricingHistoryEvent.lua`/`PricingHistoryInitialEvent.lua`,
    `fillTypes/FillTypeDesc.lua`, `gui/InGameMenuStatisticsFrame.lua`,
    `I18N.lua`) - ueber sechs Dateien hinweg intern konsistent (Preis-
    Historie wird an derselben Struktur geschrieben, synchronisiert und von
    der Ingame-Preisstatistik-Ansicht gelesen).
11. **[VDTelemetry](https://github.com/VertexDezign/VDTelemetry)** (VertexDezign) - ein echter,
    aktiv gepflegter FS25-Telemetrie-Mod mit vergleichbarem Zweck wie
    FarmPulse, dessen `PricesExporter.lua` exakt dieselbe Aufgabe loest
    ("bester Preis + welche Periode" aus `fillType.economy.history`
    ermitteln) - staerkste verfuegbare Bestaetigung, da unabhaengig
    entwickelt und fuer denselben Anwendungsfall produktiv im Einsatz.
12. **[FS25_AdjustStorageCapacity](https://github.com/rittermod/FS25_AdjustStorageCapacity)**
    (rittermod) - ein echter, aktiv gepflegter FS25-Mod (`scripts/RmAdjustStorageCapacity.lua`),
    der frei platzierte Hof-Silos ueber `g_currentMission.placeableSystem.placeables`
    findet und deren Lagerobjekte unter `placeable.spec_silo.storages` liest
    (jeweils mit `.fillLevels`/`.capacities`, sowie `.capacity` als
    Fallback fuer eine je Fill-Typ gemeinsame Kapazitaet) - loest die zuvor
    unbestaetigte Luecke bei frei platzierten Silos auf, siehe Tabelle unten.

| Wert | Verwendeter Ansatz | Status |
|---|---|---|
| Stunde/Minute | `g_currentMission.environment.dayTime`, in Millisekunden seit Mitternacht, umgerechnet in Stunde/Minute | **Bestaetigt** (Quelle 2): `AbstractMission:getMinutesLeft()` verrechnet `environment.dayTime` direkt mit `24*60*60*1000` |
| Tag im Monat | `g_currentMission.environment:getDayInPeriodFromDay(environment.currentMonotonicDay)` | **Bestaetigt** (Quelle 2): `AbstractMission:setDefaultEndDate()` berechnet den Tag-im-Monat exakt so - **kein** rohes Feld `currentDayInPeriod` (fruehere Annahme war falsch, siehe Korrektur unten). Quelle 3 belegt zwar auch ein rohes Feld `environment.currentDay`, dessen Semantik (Tag-im-Monat vs. fortlaufender Tageszaehler wie `currentMonotonicDay`) aus dem eingesehenen Ausschnitt aber nicht eindeutig hervorgeht - deshalb bewusst weiter die von Quelle 2 eindeutig belegte Methode verwendet |
| Monat | `TelemetryCollector.calendarMonthFromPeriod(environment.currentPeriod, environment.daylight.latitude < 0)` | **Bestaetigt** (Quelle 10, Quelle 11): **Korrektur** gegenueber einer fruehen Fassung dieser Bridge, die faelschlich ein rohes Feld `environment.currentMonth` annahm (angeblich durch Quelle 3 "produktiv validiert") - dieses Feld existiert in FS25 nicht. Tatsaechlich liefert die Engine nur `environment.currentPeriod` (1-12, saisonbezogen: Periode 1 = "frueher Fruehling"). Die Umrechnung in einen Kalendermonat uebernimmt clientseitig `I18N:formatPeriod(period)` (Quelle 10, `I18N.lua`) per `m = period + 2 + (isSouthern and 6 or 0)`, wobei `isSouthern = environment.daylight.latitude < 0` - exakt dieselbe Formel implementiert `TelemetryCollector.calendarMonthFromPeriod()`. Quelle 11 (`VDTelemetry`, echter veroeffentlichter Mod) bestaetigt unabhaengig, dass Periode 1 auf einer Nordhalbkugel-Karte Maerz entspricht (bzw. September auf der Suedhalbkugel) |
| Jahr | `g_currentMission.environment.currentYear` | **Bestaetigt** (Quelle 3, produktiv validiert) |
| Tage je Monat | `g_currentMission.environment.daysPerPeriod` | **Bestaetigt** (Quelle 2): direktes Feld, referenziert in `AbstractMission:setDefaultEndDate()` |
| FarmID | `g_localPlayer.farmId`, Fallback `g_currentMission:getFarmId()` | **Bestaetigt** (Quelle 2, zusaetzlich gestuetzt durch Quelle 1): `AbstractMission:update()` prueft `g_localPlayer.farmId == self.farmId` direkt gegen ein echtes Feld. Unabhaengig davon zeigt `Player.md` in der Community-LUADOC (Quelle 1) in `Player.createServerInstance()` den Quellcode `self.farmId = farmId`, durchgaengig verwendet (u.a. `g_farmManager:getSpawnPoint(self.farmId)`) - dasselbe Feld auf derselben Klassenfamilie, unabhaengig bestaetigt. `getFarmId()` bleibt als unbestaetigter, aber in der Community weit verbreiteter Fallback |
| Kontostand | `g_farmManager:getFarmById(farmId):getBalance()`, Fallback `g_currentMission:getMoney()` | **Bestaetigt** (Quelle 1): `Farm.md` zeigt die dokumentierte Methode `Farm:getBalance()` ("Get the current account balance of the farm", keine Argumente). Ein rohes `.money`-Feld ist NICHT dokumentiert und wird deshalb nicht mehr verwendet (Korrektur gegenueber einer fruehen Fassung dieser Bridge). `getFarmById()` selbst ist in `FarmManager.md` ("Get the farm object by given farmId") ebenfalls dokumentiert |
| Feldliste | `g_farmlandManager:getFarmlands()`, je Eintrag `.id`/`.farmId`/`.areaInHa`/`.price` | **Bestaetigt** (Quelle 1): `FarmlandManager.md` zeigt `getFarmlands()` liefert `self.farmlands` (eine per Farmland-ID indizierte Tabelle - daher `pairs()` statt einer 1-indizierten Sequenz), und `Farmland.md` zeigt in `Farmland:load()` den Quellcode, der genau diese vier Felder setzt (Default-Besitzer `FarmlandManager.NO_OWNER_FARM_ID`, laut `getFarmlandOwner()`-Doku `0`) |
| Fruchtart/Wachstum je Feld (`fruitType`/`growthState`) | `g_fieldManager.fields` (NICHT `g_farmlandManager`, siehe FieldCollector.lua), je Feld `field:getFieldState()` -> `FieldState.fruitTypeIndex`/`.growthState`/`.isValid`, verknuepft mit dem zugehoerigen Farmland ueber `field.farmland.id` | **Bestaetigt** (Quelle 2 offizielle LUADOC fuer `FieldState.new()`, Quelle 9 fuer den tatsaechlichen `field:getFieldState()`-Aufruf in Basisspiel-Missionsklassen wie `AbstractFieldMission`/`StonePickMission`/`PlowMission`). Die Aufloesung von `fruitTypeIndex` zu einem lesbaren Namen (`fruitType`) ist dagegen **nicht bestaetigt** - siehe `FarmPulseBridge.readFieldCrops()` fuer die zwei unbestaetigten Fallback-Strategien |
| Ertragsschaetzung (`estimatedYieldLiters`) | `g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)` -> `.literPerSqm`/`.minHarvestingGrowthState`/`:getIsHarvestable(growthState)`, verrechnet mit `field:getAreaHa()` (siehe `FieldCollector.computeCropInfo()` fuer die Formel) | **Bestaetigt** (Quelle 2 offizielle LUADOC `FruitTypeDesc.md` fuer `literPerSqm`/`getIsHarvestable`/etc., Quelle 9 fuer `field:getAreaHa()` in Basisspiel-Code). Die konkrete Ertragsformel selbst (Flaeche × Literwert × Wachstumsfortschritt) ist eine eigene, aus bestaetigten Bausteinen abgeleitete Naeherung - das tatsaechliche Ingame-Ergebnis beim Dreschen beruecksichtigt zusaetzlich Spritz-/Pflug-/Walz-/Unkraut-Faktoren (`FieldState:getHarvestScaleMultiplier()`), die hier bewusst NICHT nachgebildet werden |
| Hofname (`farmName`) | `g_farmManager:getFarmById(farmId).name` | **Bestaetigt** (Quelle 4, FS25_InfoDisplayExtension, echter veroeffentlichter Mod): liest `owningFarm.name` auf demselben Farm-Objekt, das diese Bridge bereits fuer `getBalance()` verwendet |
| Spielername (`playerName`) | `g_currentMission.playerNickname` | **Bestaetigt** (Quelle 5, FS25_Tardis, echter veroeffentlichter Mod): referenziert dieses Feld direkt |
| Fuhrpark-Wert (`fleetValue`) | `g_currentMission.vehicleSystem.vehicles` (Liste aller Fahrzeuge), je Eintrag `vehicle:getOwnerFarmId()` zum Filtern + `vehicle:getSellPrice()`, aufsummiert | **Bestaetigt** (Quelle 5, FS25_Tardis, und ein weiterer veroeffentlichter Mod, FS25_VehicleExplorer von teknogeek, fuer `g_currentMission.vehicleSystem.vehicles` als Fahrzeugliste dieser FS25-Engine-Generation - abgeloest gegenueber `g_currentMission.vehicles` aus FS19-FS22 -, Quelle 6 fuer `Vehicle:getSellPrice()` als real gehookte Methode) |
| Fahrzeugname (`vehicles[].name`) | `vehicle:getFullName()` | **Bestaetigt**: gegen den dekompilierten Basisspiel-Quellcode (Quelle 9, `vehicles/Vehicle.lua`, Funktion `Vehicle:getFullName()`) UND unabhaengig gegen einen echten, veroeffentlichten Mod (`Templeton-Peck/FS25_CabCinematic`, der `vehicle:getFullName()` fuer Logging nutzt) geprueft - liefert Markenname + Modellname (z.B. "John Deere 8R 410"), NICHT den vom Spieler ggf. vergebenen individuellen Fahrzeugnamen (dafuer gibt es in FS25 keine bestaetigte separate API) |
| Fahrzeugkategorie (`vehicles[].category`) | `g_storeManager:getItemByXMLFilename(vehicle.configFileName).categoryName` -> `g_storeManager:getCategoryByName(categoryName).title` | **Bestaetigt** (Quelle 9, `vehicles/Vehicle.lua`, Funktion `Vehicle:saveStatsToXMLFile()`, sowie `shop/StoreManager.lua`, Funktionen `StoreManager:addCategory()`/`StoreManager:getCategoryByName()`): `storeItem.categoryName` ist derselbe rohe, interne Kategorie-Schluessel, den `saveStatsToXMLFile()` fuer die Statistik-Ablage verwendet - roh waere das aber kein Anzeige-String (z.B. `"tractorsL"` statt "Traktoren"), deshalb zusaetzlich ueber `getCategoryByName(...).title` aufgeloest, das `StoreManager:addCategory()` nachweislich mit dem lokalisierten, im Shop angezeigten Titel befuellt. Fallback auf den rohen Schluessel, falls die Kategorie selbst nicht aufloesbar ist |
| Fahrzeug-PS (`vehicles[].horsepowerHp`) | `g_storeManager:getItemByXMLFilename(vehicle.configFileName)` -> `StoreItemUtil.loadSpecsFromXML(storeItem)` -> `storeItem.specs.power` | **Bestaetigt, Einheit HERGELEITET** (Quelle 9, `vehicles/Vehicle.lua`, Funktion `Vehicle.calculateSellPrice()`, sowie `vehicles/specializations/Motorized.lua`, Funktion `Motorized.getSpecValuePower()`): der Lesezugriff selbst ist echter, im Spiel verwendeter Basisspiel-Code. Die Einheit (das Spiel zeigt diesen Wert im Shop typischerweise als "PS"/"hp" an, je nach Sprache) konnte mangels Zugriffs auf die l10n-Textdateien NICHT gegen den exakten Anzeige-Text verifiziert werden - falls FS25 hier tatsaechlich kW liefern sollte, waere eine Umrechnung (`× 1.35962`) noetig, die diese Bridge bewusst NICHT vornimmt, um keine unbestaetigte Annahme in eine unsichtbare Umrechnung zu verstecken. Fahrzeuge ohne Motor-Konfiguration (z.B. Anhaenger) liefern `nil`/`null`, statt `0` zu erfinden |
| Betriebsstunden (`vehicles[].operatingHours`) | `vehicle:getOperatingTime()`, in Millisekunden, umgerechnet in Stunden (`/ (1000*60*60)`) | **Bestaetigt** (Quelle 9, `vehicles/Vehicle.lua`): `Vehicle:getOperatingTime()` liefert direkt `self.operatingTime` (Millisekunden); dieselbe Umrechnung verwendet die Engine selbst in `Vehicle.getSpecValueOperatingTime()` fuer die Shop-Anzeige ("Betriebsstunden") |
| Fahrzeugzustand (`vehicles[].conditionPercent`) | `vehicle:getDamageAmount()` (0..1, Schaden), umgerechnet zu `(1 - damageAmount) * 100` (Prozent Zustand, nicht Schaden) | **Bestaetigt** (Quelle 9, `vehicles/specializations/Wearable.lua`, Funktion `Wearable:getDamageAmount()`): dieselbe Basisspiel-Methode wird intern u.a. fuer die Schadensanzeige-Prozentzahl verwendet (`realItem:getDamageAmount() * 100` im selben Modul). Bewusst als "Zustand" (100% = neuwertig) statt als "Schaden" exportiert, da fuer eine Fuhrpark-**Uebersicht** intuitiver |
| Eigentumsstatus (`vehicles[].ownershipStatus`) | `vehicle:getPropertyState()`, verglichen mit `VehiclePropertyState.OWNED`/`.LEASED`/`.MISSION`/`.SHOP_CONFIG` | **Bestaetigt** (Quelle 9, `vehicles/Vehicle.lua`, Funktion `Vehicle:getPropertyState()` sowie mehrere echte Vergleichsstellen gegen `VehiclePropertyState.OWNED`/`.LEASED`/`.SHOP_CONFIG` im selben Modul; `VehiclePropertyState.MISSION` zusaetzlich in `vehicles/specializations/Wearable.lua` referenziert): alle vier Konstanten sind echte, im Basisspiel-Quellcode verwendete Werte. Die `VehiclePropertyState`-Klasse selbst ist von GIANTS nicht im SDK-Dump enthalten (kein `getName()`-Hilfsmethode gefunden) - die Bridge bildet die vier bekannten Konstanten deshalb selbst auf lesbare Strings ab, unbekannte/zukuenftige Werte werden zu `"UNKNOWN"`. `SHOP_CONFIG` sollte in `g_currentMission.vehicleSystem.vehicles` praktisch nie vorkommen (nur Shop-Vorschauobjekte), wird aber der Vollstaendigkeit halber unterstuetzt |
| Verkaufspreis je Fahrzeug (`vehicles[].sellPrice`) | `vehicle:getSellPrice()` | **Bestaetigt** (Quelle 6, FS25_UsedPlus, sowie zusaetzlich Quelle 9, `vehicles/Vehicle.lua`, Funktion `Vehicle:getSellPrice()`/`Vehicle.calculateSellPrice()` als echter Basisspiel-Quellcode fuer dieselbe Methode) - bereits zuvor fuer `fleetValue` verwendet, jetzt zusaetzlich je Fahrzeug einzeln exportiert |
| Lager-/Silobestaende (`storages`) | Zwei Quellen kombiniert: (1) `g_currentMission.productionChainManager.productionPoints`, je Punkt `.storage.fillLevels`/`.storage.capacities`; (2) `g_currentMission.placeableSystem.placeables`, gefiltert nach `.spec_silo`, je Silo-Objekt in `.spec_silo.storages` ebenfalls `.fillLevels`/`.capacities`/`.capacity` - jeweils indiziert nach Fill-Typ, aufgeloest ueber `g_fillTypeManager:getFillTypeNameByIndex()` | **Bestaetigt** (Quelle 7, FS25_UpgradableFactories, fuer die Produktionspunkt-Struktur; Quelle 12, FS25_AdjustStorageCapacity, echter veroeffentlichter Mod, fuer `placeable.spec_silo.storages` als Struktur frei platzierter Hof-Silos). **Korrektur**: eine fruehere Fassung dieser Bridge deckte ausschliesslich Produktionspunkte ab - `amount` blieb dadurch fuer alle Fill-Typen `0`, sobald die Ernte (wie beim Regelfall der meisten Hoefe) in frei platzierten Silos statt in Produktionspunkten lagerte, waehrend `capacity` durchaus befuellt sein konnte, falls ein Produktionspunkt mit derselben Fill-Typ-Liste existierte |
| Temperatur (`temperature`) | `g_currentMission.environment.weather:getCurrentTemperature()` | **Bestaetigt** (Quelle 5 FS25_Tardis-Umfeld sowie Basisspiel-Skripte): mehrere echte FS25-Basisspiel-Skripte (`vehicles/specializations/Washable.lua`, `vehicles/VehicleSystem.lua`, `vehicles/specializations/Enterable.lua` - dort direkt an die Cockpit-Aussentemperaturanzeige gebunden) lesen an exakt dieser Stelle dieselbe Methode |
| Wettertyp (`weatherType`) | Strategie 1: `weather.forecast:dataForTime(environment.currentMonotonicDay, environment.dayTime)` -> `weather:getWeatherObjectByIndex(season, objectIndex)` -> `WeatherType.getName(weatherObject.weatherType)`. Strategie 2 (Fallback): grobe Ableitung aus `weather:getIsHailing()`/`getIsSnowing()`/`getIsRaining()` | Strategie 1 **hergeleitet, nicht bestaetigt** (Quelle 8): Die `Weather`-Klasse selbst ist von GIANTS weder im SDK-Dump noch in der LUADOC offengelegt: die Aufrufkette wurde stattdessen aus echtem HUD-Nachbau-Code (Quelle 8) uebernommen. Die `WeatherType`-Konstanten (`SUN`/`PARTIALLY_CLOUDY`/`CLOUDY`/`RAIN`/`SNOW`/`HAIL`/`TWISTER`/`THUNDER`) selbst sind dagegen **bestaetigt** (Basisspiel `gui/hud/GameInfoDisplay.lua`). Strategie 2 nutzt ausschliesslich **bestaetigte** Einzelmethoden (Basisspiel `objects/SunAdmirer.lua`, `placeables/BeehiveSystem.lua`), liefert dafuer nur eine grobe Naeherung ohne "bewoelkt"/"Gewitter"/"Tornado" |
| Aktueller Marktpreis (`currentPricePer1000L`) | `g_currentMission.economyManager:getPricePerLiter(fillType.index)` (Euro je Liter, × 1000 fuer den Export - siehe Dateiformat) | **Bestaetigt** (Quelle 10, dekompilierter Basisspiel-Quellcode, sowie unabhaengig durch ~10 echte, aktuell gepflegte FS25-Mods, die exakt dieselbe Signatur in Produktionscode aufrufen, u.a. `FS25_ForestryHelper`, `FS25_AutoDrive`, `VDTelemetry`, `FS25_MarketDynamics` - ungewoehnlich breite unabhaengige Bestaetigung fuer einen nicht offiziell dokumentierten Aufruf). Liefert einen **globalen** Marktpreis, keinen Preis je Verkaufsstelle (die einzelnen Verkaufsstellen/`SellingStation`-Objekte koennen den Basispreis noch mit stationsspezifischen Faktoren multiplizieren, das wird hier bewusst nicht nachgebildet) |
| Bester Preis + Periode (`bestPricePer1000L`/`bestPricePeriod`) | `g_fillTypeManager:getFillTypeByName(name).economy.history` (12-Eintraege-Tabelle, Index 1-12 = FS25-"Periode"), Maximum + Index ermittelt in `PriceCollector.findBestPrice()` | **Bestaetigt** (Quelle 10, ueber sechs Basisspiel-Dateien hinweg intern konsistent: `EconomyManager:updateFillTypeHistory()` befuellt die Tabelle, `PricingHistoryEvent`/`PricingHistoryInitialEvent` synchronisieren sie, `InGameMenuStatisticsFrame.lua` liest exakt dieselbe Tabelle fuer die Ingame-Preisstatistik-Ansicht). Zusaetzlich durch Quelle 11 (`VDTelemetry`, echter, aktiv gepflegter FS25-Mod) bestaetigt, der denselben "bester Preis + Periode"-Algorithmus gegen dieselbe Datenstruktur produktiv einsetzt. Konnte **nicht** gegen die offizielle GDN-Dokumentation verifiziert werden (dort nicht erreichbar aus dieser Entwicklungsumgebung) |
| Perioden-Monatsname (`bestPricePeriodLabel`) | `g_i18n:formatPeriod(period)` | **Bestaetigt** (Quelle 10): dieselbe Funktion, die die Ingame-Preisstatistik-Ansicht fuer die Monatsbeschriftung nutzt. **Wichtig**: Periode `1` ist NICHT zwingend Januar - `formatPeriod()` verschiebt die Zuordnung um den Kartenbreitengrad (`environment.daylight.latitude`, Nord-/Suedhalbkugel) |

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

### Bekannte Luecken (Stand jetzt, vor dem ersten Live-Test)

- **`fruitType`** kann trotz tatsaechlich angebauter Frucht `null` bleiben,
  falls beide Aufloesungs-Strategien in `FarmPulseBridge.readFieldCrops()`
  fehlschlagen (`FruitType.getName()` ist unbestaetigt, der Fallback ueber
  `g_fillTypeManager:getFillTypeNameByIndex()` setzt voraus, dass Frucht- und
  Fuelltyp-Index fuer dieselbe Basisfrucht uebereinstimmen). `growthState`/
  `estimatedYieldLiters` bleiben dann ebenfalls `null`, auch wenn die reinen
  Rohwerte (Wachstumsstand, Literwert) intern gelesen werden konnten - siehe
  `FieldCollector.computeCropInfo()`, das ohne `fruitTypeName` bewusst nichts
  zurueckgibt, statt eine unbenannte Frucht zu exportieren.
- **`fruitType`/`growthState` je Feld koennen von der tatsaechlich im Spiel
  angebauten Frucht abweichen** - zwei bestaetigte, mit der Read-only-Natur
  dieser Bridge nicht vollstaendig behebbare Ursachen:
  1. **Einzelpunkt-Abtastung** (bestaetigt, Quelle 9): `field:getFieldState()`
     liefert den Zustand exakt einer abgetasteten Stelle des Feldes (dem
     Polygon-Mittelpunkt), keine Flaechen-Aggregation. Bei einem grossen Feld,
     das der Spieler nur teilweise neu eingesaet/beerntet hat, kann der an
     diesem einen Punkt gemessene Zustand vom Rest der Flaeche abweichen -
     eine inhaerente Engine-Grenze, kein Bug dieser Bridge.
  2. **Farmland-Zuordnungs-Kollision beim unbestaetigten Fallback** (jetzt
     gehaertet, siehe `FieldCollector.shouldReplaceCropEntry()`): Die
     bestaetigte Zuordnung ueber `field.farmland.id` ist laut Engine
     (`FieldManager.farmlandIdFieldMapping`) eindeutig 1:1. Der Fallback
     `fieldState.farmlandId` (fuer den seltenen Fall, dass `field.farmland`
     fehlt) ist dagegen selbst wieder nur ueber denselben Einzelpunkt
     ermittelt und daher bei fehlerhaften/unvollstaendigen Kartendaten
     theoretisch mehrdeutig. Vor dieser Haertung konnte die (nicht
     garantierte) Iterationsreihenfolge von `g_fieldManager.fields`
     nichtdeterministisch dazu fuehren, dass ein Fallback-Eintrag eine
     bereits bestaetigte Zuordnung eines anderen Feldes ueberschreibt -
     `FarmPulseBridge.readFieldCrops()` verwirft einen Fallback-Eintrag jetzt
     immer, sobald fuer dieselbe farmlandId bereits ein bestaetigter Eintrag
     vorliegt.
- **`bestPricePer1000L`/`bestPricePeriod`** koennen fuer einen Fill-Typ `null`
  bleiben, obwohl `currentPricePer1000L` erfolgreich gelesen wurde: die
  Preishistorie (`fillType.economy.history`) wird laut Quelle 10 nur
  synchronisiert, solange `fillType.economy.sychronizeData` (Standard `true`)
  nicht von einer Mod-Fruchtart ueberschrieben wurde. Betrifft voraussichtlich
  nur seltene Custom-Fill-Typen, keine Basisspiel-Fruchtarten. Ausserdem ist
  die erste Preishistorie eines neuen Spielstands ggf. noch nicht vollstaendig
  befuellt (nur bereits durchlaufene Perioden haben einen Wert) - das ist kein
  Bug, sondern der erwartete Zustand kurz nach Spielstart.
- **`vehicles[].horsepowerHp`** koennte in einer falschen Einheit vorliegen
  (siehe Tabelle oben): der Lesezugriff (`storeItem.specs.power`) selbst ist
  bestaetigter Basisspiel-Code, die Einheit (PS/hp vs. kW) konnte mangels
  Zugriffs auf die l10n-Textdateien aber nicht verifiziert werden. Sollte sich
  im Live-Test zeigen, dass der exportierte Wert nicht zur Ingame-Shop-Anzeige
  passt, ist das der erste Verdacht (Faktor ~1.36 zwischen PS und kW).

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
5. Pruefen, ob `day`/`month`/`year`/`daysPerMonth` mit der im Spiel
   angezeigten Kalenderanzeige uebereinstimmen.
5b. Pruefen, ob `temperature` in `telemetry.json` grob zur im Spiel
    angezeigten Aussentemperatur (z.B. Cockpit-Anzeige) passt, und ob
    `weatherType` zum aktuell sichtbaren Wetter passt (`SUN` bei
    Sonnenschein, `RAIN`/`SNOW`/`HAIL` bei entsprechendem Niederschlag).
    Bleibt `weatherType` dauerhaft `"UNKNOWN"`, ist vermutlich Strategie 1
    in `FarmPulseBridge.readWeather()` fehlgeschlagen (siehe log.txt) - das
    ist kein Bug, sondern der erwartete Fall, falls die hergeleitete
    Aufrufkette in diesem FS25-Build nicht stimmt; Strategie 2 sollte dann
    trotzdem grobe Werte (`SUN`/`RAIN`/`SNOW`/`HAIL`) liefern.
6. In `world.json` pruefen, ob `fields` eine plausible Anzahl Eintraege
   enthaelt (Anzahl Felder der geladenen Karte) und ob Groesse/Preis/Besitzer
   fuer ein paar bekannte, bereits gekaufte Felder mit der Ingame-Kartenansicht
   uebereinstimmen.
7. In `world.json` pruefen, ob `fleetValue` grob zur Anzahl/Klasse der
   eigenen Fahrzeuge passt, ob `vehicles` alle eigenen Fahrzeuge enthaelt
   (Anzahl, Namen) und ob `storages` bekannte Lagerbestaende (sowohl aus
   Produktionspunkten als auch aus frei platzierten Hof-Silos) korrekt
   widerspiegelt.
7a. In `world.json` bei einem bekannten Fahrzeug pruefen, ob `horsepowerHp`
    zur im Shop/Kaufmenue angezeigten PS-Zahl passt (siehe Abschnitt "Bekannte
    Luecken" zur Einheiten-Unsicherheit), ob `operatingHours` zu den im Spiel
    angezeigten Betriebsstunden passt, ob `conditionPercent` grob zum
    sichtbaren Fahrzeugzustand (Schadensanzeige) passt - `100 - conditionPercent`
    sollte dem angezeigten Schadensprozentwert entsprechen -, ob `category`
    zur im Shop angezeigten Fahrzeugkategorie passt (z.B. "Traktoren") und ob
    `ownershipStatus` bei einem gekauften Fahrzeug `"OWNED"` und bei einem
    geleasten Fahrzeug `"LEASED"` liefert.
7b. In `world.json` bei einem bekannt bestellten Feld pruefen, ob `fruitType`
    zur im Spiel angezeigten Frucht passt und `growthState` grob zum
    sichtbaren Wachstumsstand (0 = gerade gesaet, 1 = erntereif). Bleiben
    `fruitType`/`growthState`/`estimatedYieldLiters` bei einem bekannt
    bestellten Feld dauerhaft `null`, siehe Abschnitt "Bekannte Luecken"
    oben - das ist der erwartete Fallback, kein Absturz.
7c. In `world.json` bei einem `storages`-Eintrag pruefen, ob
    `currentPricePer1000L` grob zum im Spiel angezeigten Verkaufspreis dieses
    Fill-Typs passt (z.B. an einer Verkaufsstelle/im Preis-Statistik-Menue
    ablesbar), und ob `bestPricePer1000L`/`bestPricePeriodLabel` zu einem
    dort sichtbaren Preis-Hoch der letzten 12 Perioden passen. Bleiben diese
    Felder dauerhaft `null`, siehe Abschnitt "Bekannte Luecken" oben.
8. In `farm.json` pruefen, ob `farmName`/`playerName` mit dem im Spiel
   gewaehlten Hof-/Spielernamen uebereinstimmen.
9. Diese Beobachtungen (Log-Auszug + ob die Werte stimmen, je Datei) 
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
  "weatherType": "SUN",
  "temperature": 11.4
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
- `weatherType`: aktueller Wettertyp - einer von `SUN`, `PARTIALLY_CLOUDY`,
  `CLOUDY`, `RAIN`, `SNOW`, `HAIL`, `THUNDER`, `TWISTER`, oder `UNKNOWN`,
  falls sich der Typ nicht ermitteln liess (siehe
  `FarmPulseBridge.readWeather()` zur Herkunft/Konfidenz).
- `temperature`: aktuelle Umgebungstemperatur in °C (kann negativ sein).

## Dateiformat: `world.json`

```json
{
  "fleetValue": 125000,
  "vehicles": [
    { "name": "John Deere 8R 410", "category": "Traktoren", "horsepowerHp": 410,
      "operatingHours": 128.50, "conditionPercent": 92, "ownershipStatus": "OWNED",
      "sellPrice": 245000 },
    { "name": "Kroger Agroliner TAW 35", "category": "Anhänger", "horsepowerHp": null,
      "operatingHours": 95.00, "conditionPercent": 88, "ownershipStatus": "LEASED",
      "sellPrice": 42000 }
  ],
  "fields": [
    { "fieldId": 1, "ownerFarmId": 0, "sizeHa": 4.53, "price": 32000,
      "fruitType": null, "growthState": null, "estimatedYieldLiters": null },
    { "fieldId": 2, "ownerFarmId": 1, "sizeHa": 6.10, "price": 45000,
      "fruitType": "WHEAT", "growthState": 0.65, "estimatedYieldLiters": 27716.5 }
  ],
  "storages": [
    { "fillType": "BARLEY", "amount": 1200, "capacity": 20000,
      "currentPricePer1000L": 175.20, "bestPricePer1000L": 198.50,
      "bestPricePeriod": 7, "bestPricePeriodLabel": "Juli" },
    { "fillType": "WHEAT", "amount": 5000, "capacity": 20000,
      "currentPricePer1000L": 218.40, "bestPricePer1000L": 254.10,
      "bestPricePeriod": 3, "bestPricePeriodLabel": "März" }
  ]
}
```

- `fleetValue`: aggregierter Verkaufswert aller Fahrzeuge der aktuellen Farm
  (Summe von `Vehicle:getSellPrice()`, identisch zur Summe der einzelnen
  `sellPrice`-Werte in `vehicles`).
- `vehicles`: Liste der Fahrzeuge der aktuellen Farm (gefiltert nach
  `vehicle:getOwnerFarmId() == farmId`, siehe `telemetry.json`/`farmId`),
  sortiert nach Name (bei Gleichstand nach Verkaufspreis absteigend). Jedes
  Detail-Feld ist einzeln ueber `pcall()` abgesichert (siehe
  `FarmPulseBridge.readVehicleDetails()`) - schlaegt z.B. nur die PS-Ermittlung
  fehl, bleiben die uebrigen Felder trotzdem befuellt:
    - `name`: Markenname + Modellname (`Vehicle:getFullName()`, z.B.
      `"John Deere 8R 410"`), `"Unbekanntes Fahrzeug"` falls nicht auflösbar.
    - `category`: lokalisierter Kategorie-Anzeigename (z.B. `"Traktoren"`,
      `"Anhänger"`), `"Sonstiges"` falls nicht auflösbar.
    - `horsepowerHp`: Motorleistung, `null` bei nicht-motorisierten Fahrzeugen
      (z.B. Anhaengern) oder falls nicht auflösbar. Siehe Tabelle oben zur
      Einschraenkung bei der Einheit (PS/hp vs. evtl. kW).
    - `operatingHours`: Betriebsstunden des Fahrzeugs (`Vehicle:getOperatingTime()`
      in Millisekunden, umgerechnet in Stunden), oder `null` falls nicht
      auflösbar.
    - `conditionPercent`: Fahrzeugzustand in Prozent (`100` = neuwertig, `0` =
      maximal beschaedigt; aus `Vehicle:getDamageAmount()` abgeleitet), oder
      `null` falls nicht auflösbar.
    - `ownershipStatus`: Eigentumsstatus - einer von `"OWNED"` (gekauft),
      `"LEASED"` (geleast), `"MISSION"` (im Rahmen eines Vertrags/einer
      Mission genutzt) oder `"SHOP_CONFIG"` (sollte in der Praxis nicht
      vorkommen, siehe Tabelle oben), `"UNKNOWN"` falls nicht auflösbar.
    - `sellPrice`: aktueller Verkaufspreis dieses Fahrzeugs
      (`Vehicle:getSellPrice()`), `0` falls nicht auflösbar.
- `fields`: Liste **aller** Felder/Farmlands der geladenen Karte, aufsteigend
  nach `fieldId` sortiert:
    - `fieldId`: eindeutige ID des Feldes/Farmlands.
    - `ownerFarmId`: FarmID des Besitzers, `0` = noch niemandem gehoerend.
    - `sizeHa`: Groesse des Feldes in Hektar.
    - `price`: aktueller Kaufpreis des Feldes.
    - `fruitType`: Name der aktuell angebauten Frucht (z.B. `"WHEAT"`), oder
      `null`, falls kein Feld-Objekt zu diesem Farmland gefunden wurde oder
      dort aktuell keine Frucht steht (unbestellt, gerade geerntet, ...).
    - `growthState`: Wachstumsfortschritt der aktuellen Frucht zwischen `0`
      (gerade gesaet) und `1` (erntereif), oder `null` wie bei `fruitType`.
    - `estimatedYieldLiters`: grobe Ertragsschaetzung in Litern (FS-
      Ingame-Einheit, wie `storages`/`amount`) fuer den aktuellen
      Wachstumsstand, oder `null` wie bei `fruitType`. Siehe Tabelle oben zur
      Konfidenz - eine Naeherung ohne Spritz-/Pflug-/Wetter-Boni.
- `storages`: Lager-/Silobestaende der aktuellen Farm, nach Fill-Typ
  aggregiert (mehrere Lagerstaetten desselben Fill-Typs werden
  zusammengefasst) und alphabetisch nach `fillType` sortiert. Siehe "Bekannte
  Luecken" oben zur aktuellen Abdeckung:
    - `fillType`: Name des Fill-Typs (z.B. `"WHEAT"`), `"UNKNOWN"` falls
      nicht auflösbar.
    - `amount`: aktuell gelagerte Menge.
    - `capacity`: Gesamtkapazitaet fuer diesen Fill-Typ.
    - `currentPricePer1000L`: aktueller Marktpreis in Euro je 1000 Liter
      (globaler Preis, nicht je Verkaufsstelle - siehe Tabelle unten), oder
      `null` falls nicht auflösbar.
    - `bestPricePer1000L`: hoechster Preis der letzten 12 FS25-"Perioden"
      (siehe `bestPricePeriod`), oder `null` falls keine Preishistorie
      gelesen werden konnte.
    - `bestPricePeriod`: die FS25-Periode (`1`-`12`) mit dem hoechsten Preis.
      **Keine** Kalendermonate - Periode `1` ist auf einer Nordhalbkugel-
      Standardkarte z.B. Maerz, nicht Januar (siehe `bestPricePeriodLabel`
      sowie Tabelle unten). `null` wie bei `bestPricePer1000L`.
    - `bestPricePeriodLabel`: bereits zu einem lokalisierten Monatsnamen
      aufgeloeste `bestPricePeriod` (z.B. `"März"`, in der im Spiel
      eingestellten Sprache), oder `null` wie bei `bestPricePeriod`.

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
    ├── PriceCollector.lua       Bester Preis + Periode aus roher Preishistorie (keine GIANTS-Abhaengigkeit)
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

Erwartete Ausgabe: alle Tests `[ OK ]`, am Ende `110 bestanden, 0
fehlgeschlagen` (16 JsonEncoder, 9 PollTimer, 21 FieldCollector,
17 VehicleCollector, 7 StorageCollector, 8 PriceCollector, 6 FarmCollector,
8 WorldCollector, 18 TelemetryCollector). `FarmPulseBridge.lua` selbst hat
bewusst **keine** automatisierten Tests - es enthaelt ausschliesslich
GIANTS-Engine-Aufrufe, die sich ausserhalb des laufenden Spiels nicht
sinnvoll pruefen lassen (siehe Abschnitt "Test-Feedback-Loop" oben).
