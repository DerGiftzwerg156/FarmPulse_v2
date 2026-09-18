# Datenlücken zwischen MockDashboard und der Bridge

Das visuelle Vorbild für das Angular-Frontend (`MockDashboard/*.html`,
generiert aus einem Beispiel-Prototyp) zeigt mehr Widgets, als die aktuelle
FarmPulse Bridge (`Bridge/FarmPulseBridge.lua`, siehe `Bridge/README.md`)
exportieren kann. Die Backend-Endpunkte (`/api/dashboard`, `/api/fields`,
`/api/finance`, `/api/mailbox`) liefern deshalb bewusst **nur echte, aus
telemetry.json/world.json/farm.json abgeleitete Werte** - keine erfundenen
Platzhalterwerte. Diese Datei listet die Mock-Widgets ohne (oder mit nur
teilweiser) Datenquelle, damit sie gezielt nachgezogen werden können, sobald
die Bridge die nötigen Daten liefert, bzw. dokumentiert bewusste
Scope-Entscheidungen.

## Wetter — ✅ umgesetzt

Der Mock zeigt Temperatur und Bedingung (z.B. "11° · Bedeckt") in der TopBar.
`telemetry.json` enthält jetzt `weatherType`/`temperature`
(`TelemetryCollector.buildPayload`/`normalizeWeatherType`), von
`FarmPulseBridge.readWeather()` gelesen (Strategie 1: Wetter-Vorhersagekette
via `WeatherType.getName()`, HERGELEITET; Strategie 2: `getIsRaining()` /
`getIsSnowing()` / `getIsHailing()` als bestätigter Fallback - siehe
`Bridge/README.md`, Abschnitt "Wetter"). Backend: `TelemetrySnapshot`
speichert `weatherType`/`temperature` (Migration V8), `GET /api/dashboard`
liefert sie über `WeatherInfo`. Frontend: TopBar in `shell.component.html`
zeigt Icon + Temperatur + Label.

## Ertragsprognose — ✅ umgesetzt (mit Einschränkungen)

Der Mock zeigt eine Ertragsprognose in Tonnen mit Konfidenzprozent
("184,5 t", "Konfidenz 78%") sowie benannte Wachstumsphasen ("Reif",
"Blüte", "Keim" ...) pro Feld. Umgesetzt wurde eine vereinfachte Variante:

- Bridge: `FarmPulseBridge.readFieldCrops()` liest `g_fieldManager.fields`
  (nicht zu verwechseln mit `g_farmlandManager.farmlands`, die weiterhin für
  Flächengröße/Preis verwendet werden) und liefert pro Feld Fruchtart,
  Wachstumsstand und `literPerSqm`. `FieldCollector.computeCropInfo()`
  berechnet daraus einen Fortschrittswert (0..1) und eine geschätzte
  Erntemenge in **Litern** (nicht Tonnen - die Bridge kennt keine
  Dichte/Umrechnung Liter→Gewicht pro Fruchtart).
- Backend: `field_snapshot` speichert `fruit_type`/`growth_state`/
  `estimated_yield_liters` (Migration V9). `GET /api/fields`
  (`de.farmpulse.backend.fields`) liefert Einzelfelder samt Summen.
- Frontend: `/fields`-Seite (Vorlage `MockDashboard/Fields.html`) zeigt
  Gesamtfläche/Parzellen/Prognose-Ertrag sowie pro Feld Fruchtart,
  Wachstumsbalken, Ertrag-Prognose (in Litern) und eine Phase.

**Einschränkungen:** Es gibt weder eine Konfidenzangabe noch von FS25
benannte Wachstumsphasen über die Modding-API (bestätigt nicht verfügbar,
siehe `Bridge/README.md`). Status/Phase auf der Felder-Seite werden daher
im Frontend (`fields.component.ts`) aus dem Fortschrittswert **abgeleitet**
(z.B. "Erntereif" bei `growthState >= 1`) - das ist eine Näherung, keine
von FS25 gelieferte Bezeichnung. Feld-Namen ("Feld 01 – Nord") existieren
nicht; es wird nur die numerische `fieldId` angezeigt.

## Feld-Feuchtigkeit (Bodenfeuchte)

Der Mock zeigt pro Feld einen Feuchtigkeitswert in Prozent ("14%"). Die
FS25-Modding-API bietet dafür keine bestätigte Datenquelle (Bodenfeuchte ist
- soweit recherchiert - kein von der Basis-Engine exponiertes Feld-Attribut;
das könnte an das Precision-Farming-DLC gebunden sein, dessen API nicht
Teil dieser Recherche war). Die Felder-Seite zeigt daher **keinen**
Feuchtigkeitswert an, statt einen erfundenen Platzhalter zu zeigen.

## Finanzen: Kontostand-Chart und Einnahmen/Ausgaben — ✅ umgesetzt

Der Mock zeigt einen Kontostand-Chart über eine Kalenderwoche sowie
"Einnahmen"/"Ausgaben (Zeitraum)". `GET /api/finance`
(`de.farmpulse.backend.finance.FinanceService`) berechnet das aus den
periodisch aufgezeichneten `TelemetrySnapshot`-Kontoständen: Summe aller
positiven Deltas zwischen aufeinanderfolgenden Snapshots = Einnahmen, Summe
aller negativen Deltas = Ausgaben, jeweils über die letzten `limit`
Snapshots (kein Kalenderzeitraum wie "diese Woche", da die Bridge keine
Wanduhrzeit-Aggregation vorsieht). Absichtlich **kein** invasiver Hook in
`Farm:changeBalance()`/`MoneyType`, um das Prinzip "Bridge bleibt dumm,
keine Historie in der Bridge" nicht zu verletzen - die Bridge liefert
weiterhin nur den aktuellen Kontostand pro Poll, die Deltas werden erst im
Backend aus der Historie gebildet. Frontend: `/finance`-Seite (Vorlage
`MockDashboard/Finances.html`) zeigt Kontostand + Sparkline sowie die
beiden Einnahmen/Ausgaben-Kacheln.

## Transaktions-Logs

Der Mock zeigt eine Tabelle einzelner, benannter Transaktionen (z.B.
"Verkauf Weizen 8.200 L +1.788 €", "Diesel-Lieferung -1.240 €"). Das
erfordert einen Event-Feed einzelner Geldbewegungen mit Beschreibung -
FS25s Modding-API liefert dafür keinen bestätigten Hook (nur den
aggregierten `Farm:getBalance()`). Ein Mitschnitt jeder
`Farm:changeBalance()`-Aufrufe in der Bridge wäre technisch denkbar, wurde
aber bewusst nicht umgesetzt (würde die Bridge von einem reinen
Zustands-Exporteur zu einem zustandsbehafteten Event-Logger machen). Die
Finanzen-Seite zeigt daher nur aggregierte Einnahmen/Ausgaben statt
erfundener Einzelposten.

## Reputation, Mitarbeiterzufriedenheit, Saisonziel — ✅ umgesetzt (Werte, keine Berechnung)

Der Mock zeigt zusätzlich einen Reputationswert (%), eine
Mitarbeiterzufriedenheit (%) sowie ein Saison-Kampagnenziel ("184,5 / 500 t
Getreide", 37% erreicht). Für keinen dieser drei Werte gibt es ein
Gegenstück in der FS25-Modding-API oder im Spielzustand - es handelt sich um
Konzepte des fiktiven Mock-Prototyps ohne Bezug zu echten Spieldaten.
Anders als bei den übrigen Datenlücken in dieser Datei war hier explizit
gewünscht, das Konzept trotzdem einzubauen, statt es wegzulassen: die
Datenmodelle existieren, werden in der Datenbank gespeichert und im
Frontend angezeigt - nur die eigentliche Berechnungslogik fehlt noch
bewusst.

- **Reputation/Mitarbeiterzufriedenheit** (`FarmValues`, Migration V11):
  genau eine Zeile je Farm, `reputationPercent`/`employeeSatisfactionPercent`
  (0-100). `ProgressionService` legt beim ersten Aufruf je Farm einen
  neutralen Platzhalter (je 50%) an und schreibt ihn danach nicht mehr fort
  - wie sich diese Werte aus dem Farm-Zustand berechnen sollen, ist noch
  offen.
- **Saisonziel** (`SeasonGoal`, Migration V11): typisiertes Ziel
  (`SeasonGoalType`: `MONEY_BALANCE`/`HARVEST_AMOUNT`/`EMPLOYEE_COUNT`/
  `CUSTOM`) mit `targetValue`/`currentValue`/`unit` sowie optionalem
  `fillType` (bei `HARVEST_AMOUNT`) und `deadlineLabel` (Freitext, keine
  strukturierte Frist-Auswertung). `ProgressionService` wählt beim ersten
  Aufruf je Farm zufällig eines von mehreren Beispielzielen aus
  `progression/season-goal-templates.json` (analog zu den
  Postfach-Vorlagen, siehe `MailboxGenerationService`) und setzt
  `currentValue` auf 0 - die Fortschrittsberechnung aus dem tatsächlichen
  Farm-Zustand (z.B. Kontostand mit `targetValue` vergleichen, geerntete
  Menge eines Fill-Typs aufsummieren) ist noch nicht implementiert.
- Backend: `GET /api/progression` (neues Modul
  `de.farmpulse.backend.progression`, bewusst getrennt von `/api/finance`,
  das ausschließlich Bridge-abgeleitete Geldwerte liefert). Frontend:
  `/finance`-Seite zeigt die Panels "Werte" (zwei Fortschrittsbalken) und
  "Saisonziel" (aktueller/Ziel-Wert, Fortschrittsbalken, "X% erreicht") -
  Letzteres nur, sofern ein aktives Ziel vorliegt.

## Einzelfahrzeug-Telemetrie (FleetTracker im Mock) — ✅ teilweise umgesetzt

Der Mock zeigt pro Fahrzeug: Name/Typ, zugewiesener Mitarbeiter (oder "Auto
GPS"), Status (aktiv/Leerlauf/Werkstatt), Kraftstoff- und Schadenprozent,
aktuellen Job sowie GPS-Position (X/Y).

`world.json`/`vehicles[]` liefert inzwischen "Grundlegende" Fahrzeugdaten je
Fahrzeug (statt nur des aggregierten `fleetValue`): `name` (Marke + Modell,
`Vehicle:getFullName()`), `horsepowerHp` (Motorleistung, `null` bei
nicht-motorisierten Fahrzeugen), `operatingHours` (Betriebsstunden,
`Vehicle:getOperatingTime()`), `conditionPercent` (Zustand in %, aus
`Vehicle:getDamageAmount()` abgeleitet) sowie `sellPrice` (Verkaufspreis,
`Vehicle:getSellPrice()`) - siehe `Bridge/README.md`, Abschnitt
"Fuhrpark-Details"/Tabelle, für die Konfidenz je Feld (insbesondere die
Einheit von `horsepowerHp` ist HERGELEITET, nicht abschließend bestätigt).

- Backend: `vehicle_snapshot` (Migration V12) speichert die Liste je
  `WorldSnapshot`, analog zu `field_snapshot`/`storage_snapshot`.
  `GET /api/vehicles` (`de.farmpulse.backend.vehicles`) liefert die Fahrzeuge
  der aktiven Farm samt Zusammenfassung (Anzahl, Gesamt-Verkaufswert,
  durchschnittlicher Zustand).
- Frontend: eigene `/fleet`-Seite (Sidebar-Punkt "Flotte", vormals
  ausgegraut) zeigt Name, PS, Betriebsstunden, Zustand (Balken) und
  Verkaufspreis je Fahrzeug.

**Weiterhin nicht abgedeckt** (keine bestätigte FS25-Modding-API-Quelle
gefunden, siehe `Bridge/README.md`): zugewiesener Mitarbeiter, Status
(aktiv/Leerlauf/Werkstatt), aktueller Job, GPS-Position sowie
Kraftstofffüllstand (letzterer zusätzlich eine bewusste Scope-Entscheidung -
siehe `Bridge/FarmPulseBridge.lua` - der Spieler sieht das ohnehin selbst im
laufenden Spiel).

## Server-/Sitzungsinfos — bewusst nicht umgesetzt

Der Mock zeigt Servername, Kartenname, Ping sowie Spieleranzahl
(z.B. "1/16"). Das wurde auf ausdrücklichen Wunsch **nicht** umgesetzt
("Die Server-/Sitzungsinfo ist egal, das waren nur Mock sachen!") - keine
offene Datenlücke, sondern eine bewusste Scope-Entscheidung.

## Postfach / Farm-Mailbox — ✅ umgesetzt (Generierung weiterhin Mock statt KI)

Es gibt eine `MailboxMessage`-Entität
(`de.farmpulse.backend.domain.MailboxMessage`, Tabelle `mailbox_message`)
sowie `de.farmpulse.backend.mailbox.MailboxGenerationService`, der periodisch
neue Nachrichten erzeugt und unter `GET /api/mailbox` abrufbar macht sowie
`POST /api/mailbox/{id}/read`. Die Inhalte sind aber (noch) **keine
KI-generierten** Nachrichten wie im Mock, sondern zufällig ausgewählte,
statische Beispiele aus der mitgelieferten `mailbox-templates.json`. Die
Stelle, an der spätere KI-generierte statt vorlagenbasierter Inhalte
eingesetzt werden sollen, ist in `MailboxGenerationService.selectTemplate()`
explizit mit `TODO(KI-Integration)` markiert. Frontend: Dashboard zeigt eine
Vorschau der letzten 5 Nachrichten, die `/mailbox`-Seite (Vorlage
`MockDashboard/Postfach.html`) die vollständige Liste mit Suche/Filtern;
beide öffnen Nachrichten in einem Modal. Seit der Marktpreis-Anbindung (siehe
Abschnitt "Lagerbestände: Marktpreise" unten) existiert zwar eine
Preis-Datenquelle je Fill-Typ in `world.json`/`GET /api/dashboard`, die
`MailboxGenerationService` nutzt sie aber noch **nicht** - die generierten
Nachrichten bleiben rein vorlagenbasiert und beziehen sich inhaltlich nicht
auf echte Kontostand-/Preisänderungen. Das waere ein sinnvoller nächster
Schritt für `TODO(KI-Integration)`.

## Lagerbestände: Marktpreise — ✅ umgesetzt

Der Mock (`MockDashboard/Dashboard.html`, "Economic Market Ticker") zeigt je
Fruchtart einen aktuellen Preis samt Trend. Umgesetzt wurde eine auf
Lagerbestände bezogene Variante: `world.json`/`storages[]` liefert je
Fill-Typ zusätzlich `currentPricePer1000L` (aktueller Marktpreis),
`bestPricePer1000L`/`bestPricePeriod`/`bestPricePeriodLabel` (höchster Preis
der letzten 12 FS25-"Perioden" samt aufgelöstem Monatsnamen) - siehe
`Bridge/scripts/PriceCollector.lua` sowie `Bridge/README.md`, Abschnitt
"Marktpreise", für die Konfidenzeinordnung der zugrunde liegenden Engine-
Aufrufe. Alle vier Felder sind nullable, falls die Bridge den Preis für
einen Fill-Typ nicht lesen konnte. Frontend: die `/storage`-Seite zeigt
beide Preise je Lagerbestand; kein "Trend" (Preis vs. letzte Periode) und
kein fruchtartenweiter Ticker unabhängig vom Lagerbestand - das wäre die
naheliegende Erweiterung, sollte sie benötigt werden.

## Was das Dashboard zeigt

Die Hero-Kacheln des Dashboards (`dashboard.component.html`) bilden
ausschließlich real vorhandene Werte ab: Spielzeit (Tag/Jahr/Monat/Uhrzeit),
Wetter (Temperatur + Typ), Kontostand (mit Sparkline aus
`GET /api/dashboard/history`) sowie die Anzahl ungelesener
Postfach-Nachrichten aus `GET /api/mailbox`. Darunter zeigen zwei Panels
eine Felder- (`GET /api/fields`) und eine Postfach-Vorschau. Zusätzlich
leitet `DashboardService.deriveAlerts(...)` einen einfachen, auf echten
Daten basierenden Hinweis ab (negativer Kontostand) - im Gegensatz zu den
KI-generierten Mailbox-Einträgen im Mock ist das eine simple
Schwellwert-Regel, kein erfundener Inhalt. Lagerbestände werden bewusst
nicht mehr auf dem Dashboard angezeigt (auch die frühere "Lager fast
voll"-Warnung wurde entfernt) - dafür gibt es die eigene `/storage`-Seite.
