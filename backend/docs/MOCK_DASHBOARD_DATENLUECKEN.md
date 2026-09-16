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

## Reputation, Mitarbeiterzufriedenheit, Saisonziel

Der Mock zeigt zusätzlich einen Reputationswert (%), eine
Mitarbeiterzufriedenheit (%) sowie ein Saison-Kampagnenziel ("184,5 / 500 t
Getreide", 37% erreicht). Für keinen dieser drei Werte gibt es ein
Gegenstück in der FS25-Modding-API oder im Spielzustand - es handelt sich
um Konzepte des fiktiven Mock-Prototyps ohne Bezug zu echten
Spieldaten. Diese Widgets wurden daher nicht in die Finanzen-Seite
übernommen, statt Zufallswerte zu erfinden.

## Einzelfahrzeug-Telemetrie (FleetTracker im Mock)

Der Mock zeigt pro Fahrzeug: Name/Typ, zugewiesener Mitarbeiter (oder "Auto
GPS"), Status (aktiv/Leerlauf/Werkstatt), Kraftstoff- und Schadenprozent,
aktuellen Job sowie GPS-Position (X/Y).

Aktuell liefert `world.json` nur den **aggregierten** Fuhrparkwert
(`fleetValue`, siehe `WorldSnapshot.getFleetValue()`), keine Liste einzelner
Fahrzeuge. Um das nachzuziehen, müsste die Bridge `world.json` (oder eine
neue Datei) um ein `vehicles[]`-Array ergänzen, z.B. mit `id`, `name`,
`type`, `fuelPercent`, `damagePercent`, `assignedWorker`, `currentJob`,
`positionX`/`positionY`, `isActive`. Der "Flotte"-Punkt im Sidebar bleibt
bis dahin ausgegraut.

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
beide öffnen Nachrichten in einem Modal. Es existiert weiterhin keine
Marktpreis-Datenquelle (z.B. Weizenpreis in €/t mit Trend) in der Bridge,
auf die sich generierte Nachrichten inhaltlich beziehen könnten.

## Was das Dashboard zeigt

Die Hero-Kacheln des Dashboards (`dashboard.component.html`) bilden
ausschließlich real vorhandene Werte ab: Kontostand (mit Sparkline aus
`GET /api/dashboard/history`), Fuhrparkwert, Anzahl/Gesamtfläche eigener
Felder sowie die Anzahl ungelesener Postfach-Nachrichten (jetzt eine echte
Zahl aus `GET /api/mailbox`, kein Platzhalter mehr). Zusätzlich leitet
`DashboardService.deriveAlerts(...)` einfache, auf echten Daten basierende
Hinweise ab (negativer Kontostand, Lager ≥ 90% voll) - im Gegensatz zu den
KI-generierten Mailbox-Einträgen im Mock sind das simple
Schwellwert-Regeln, keine erfundenen Inhalte.
