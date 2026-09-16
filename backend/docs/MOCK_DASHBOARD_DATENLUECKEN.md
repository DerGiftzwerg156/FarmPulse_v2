# Datenlücken zwischen MockDashboard und der Bridge

Das visuelle Vorbild für das Angular-Dashboard (`MockDashboard/Dashboard.html`,
generiert aus einem Beispiel-Prototyp) zeigt mehr Widgets, als die aktuelle
FarmPulse Bridge (`Bridge/FarmPulseBridge.lua`, siehe `Bridge/README.md`)
exportiert. `GET /api/dashboard` (siehe
`de.farmpulse.backend.dashboard.DashboardController`) liefert deshalb bewusst
**nur echte, aus telemetry.json/world.json/farm.json abgeleitete Werte** -
keine erfundenen Platzhalterwerte. Diese Datei listet die Mock-Widgets ohne
aktuelle Datenquelle, damit sie gezielt nachgezogen werden können, sobald die
Bridge die nötigen Daten liefert.

## Einzelfahrzeug-Telemetrie (FleetTracker im Mock)

Der Mock zeigt pro Fahrzeug: Name/Typ, zugewiesener Mitarbeiter (oder "Auto
GPS"), Status (aktiv/Leerlauf/Werkstatt), Kraftstoff- und Schadenprozent,
aktuellen Job sowie GPS-Position (X/Y).

Aktuell liefert `world.json` nur den **aggregierten** Fuhrparkwert
(`fleetValue`, siehe `WorldSnapshot.getFleetValue()`), keine Liste einzelner
Fahrzeuge. Um das nachzuziehen, müsste die Bridge `world.json` (oder eine
neue Datei) um ein `vehicles[]`-Array ergänzen, z.B. mit `id`, `name`,
`type`, `fuelPercent`, `damagePercent`, `assignedWorker`, `currentJob`,
`positionX`/`positionY`, `isActive`.

## Wetter

Der Mock zeigt Temperatur und Bedingung (z.B. "11° · Bedeckt") in der TopBar.
Weder `telemetry.json` noch `world.json`/`farm.json` enthalten
Wetterdaten (siehe Bridge/README.md, Abschnitte "Dateiformat: ..."). Die
Bridge müsste FS25s Wetter-API abfragen und exportieren.

## Server-/Sitzungsinfos

Der Mock zeigt Servername, Kartenname, Ping sowie Spieleranzahl
(z.B. "1/16"). Keine dieser Angaben wird aktuell exportiert - die Bridge
läuft aus Sicht des Spiels als Mod im dedizierten Server, hat aber bisher
keinen Export für Session-Metadaten oder verbundene Spieler.

## Ertragsprognose

Der Mock zeigt eine Ertragsprognose in Tonnen mit Konfidenzprozent
("184,5 t", "Konfidenz 78%"). Das erfordert Wachstumsdaten pro Feld/Frucht
(aktueller Wachstumsstand, Fruchtart, historische Erträge) sowie eine
Prognoselogik - beides existiert weder in der Bridge noch im Backend.

## Postfach / Farm-Mailbox

**Teilweise umgesetzt.** Es gibt jetzt eine `MailboxMessage`-Entität
(`de.farmpulse.backend.domain.MailboxMessage`, Tabelle `mailbox_message`)
sowie `de.farmpulse.backend.mailbox.MailboxGenerationService`, der periodisch
neue Nachrichten erzeugt und unter `GET /api/mailbox` abrufbar macht. Die
Inhalte sind aber (noch) **keine KI-generierten** Nachrichten wie im Mock,
sondern zufällig ausgewählte, statische Beispiele aus der mitgelieferten
`mailbox-templates.json`. Die Stelle, an der spätere KI-generierte statt
vorlagenbasierter Inhalte eingesetzt werden sollen, ist in
`MailboxGenerationService.selectTemplate()` explizit mit `TODO(KI-Integration)`
markiert. Es existiert bewusst noch keine eigene Frontend-Seite dafür (nicht
angefordert) und auch keine Marktpreis-Datenquelle (z.B. Weizenpreis in €/t
mit Trend) in der Bridge.

## Was das Dashboard stattdessen zeigt

Damit die Hero-Kacheln und Panels trotzdem mit dem echten Datenmodell gefüllt
sind, bildet `DashboardService` die vier Mock-Kacheln auf tatsächlich
vorhandene Werte ab:

| Mock-Konzept (nicht verfügbar) | Ersetzt durch echte Daten                     |
|---------------------------------|-----------------------------------------------|
| Active Fleet (X/6 im Einsatz)   | Fuhrparkwert (`fleetValue`, aggregiert)        |
| Yield Forecast (Tonnen, Konfidenz) | Felder-Übersicht (Anzahl, Gesamtfläche)     |
| Unread Mail                     | Lagerauslastung (Lagerbestände mit Füllgrad)  |

Zusätzlich leitet `DashboardService.deriveAlerts(...)` einfache, auf echten
Daten basierende Hinweise ab (negativer Kontostand, Lager ≥ 90% voll) - im
Gegensatz zu den KI-generierten Mailbox-Einträgen im Mock sind das simple
Schwellwert-Regeln, keine erfundenen Inhalte.
