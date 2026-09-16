# Changelog

Alle nennenswerten Aenderungen an diesem Projekt werden hier dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
Versionsnummern der Bridge folgen [Semantic Versioning](https://semver.org/lang/de/)
(siehe `Bridge/modDesc.xml`, `<version>`).

## [Unreleased]

- **Frontend** (neu): Angular-Dashboard unter `frontend/` (Standalone-
  Components, Signals, Tailwind CSS, `@lucide/angular`), optisch an
  `MockDashboard/*.html` angelehnt, pollt alle 5 Sekunden gegen das Backend:
  `/start` (Savegame erstellen), `/dashboard` (Landingpage), `/fields`
  (Feld-Telemetrie/Ertragsprognose), `/finance` (Kontostand-Verlauf,
  Einnahmen/Ausgaben), `/storage` (Lagerbestaende inkl. Marktpreise),
  `/mailbox` (Firmenpostfach). Siehe `frontend/README.md`.
- **Backend**: um vier neue REST-Module erweitert - `fields/`
  (`GET /api/fields`), `finance/` (`GET /api/finance`, Einnahmen/Ausgaben
  aus Telemetrie-Deltas), `mailbox/` (`GET /api/mailbox`,
  `POST /api/mailbox/{id}/read`, periodische Nachrichtengenerierung aus
  Mock-Vorlagen mit `TODO(KI-Integration)`-Markierung fuer spaetere
  KI-Anbindung), sowie `dashboard/` um Wetter und Lagerbestand-Marktpreise
  erweitert. Neue Flyway-Migrationen V7-V10 (Postfach-Tabelle,
  Wetter-/Anbau-/Marktpreis-Spalten). Siehe `backend/README.md`.
- **Backend** (neu, urspruenglich): Spring-Boot-Anwendung unter `backend/`, die
  `telemetry.json`/`world.json`/`farm.json` periodisch einliest, ueber einen
  Verarbeitungsschritt-Erweiterungspunkt reicht und als historisierte
  Entitaeten in MariaDB speichert (Schema per Flyway-Migrationen). Siehe
  `backend/README.md`.
- Projekt-Grundlagen ergaenzt: Root-`README.md`, `LICENSE` (MIT),
  `CONTRIBUTING.md`, GitHub-Actions-Testpipeline, PR-/Issue-Templates,
  Dependabot (`.github/dependabot.yml`: Maven/Docker fuer `backend/`,
  GitHub Actions).
- `season`/`weather` aus `telemetry.json` entfernt und `WeatherCollector`
  komplett entfernt, da dessen einziger Zweck (Jahreszeit-/Wetter-Werte fuer
  `telemetry.json`) damit entfaellt. (Wetter kam mit Version 2.2.0 der
  Bridge in anderer Form - direkt in `telemetry.json`, ohne eigenes
  `WeatherCollector`-Modul - wieder zurueck, siehe unten.)

## [2.2.1] - Bridge

- **Bugfix**: `month` in `telemetry.json` war immer `0`, da
  `environment.currentMonth` in FS25 nicht existiert (fruehere, falsch
  zugeordnete Quellenangabe - siehe `Bridge/README.md`, "Monat"-Zeile der
  Konfidenz-Tabelle). Der Monat wird jetzt korrekt aus
  `environment.currentPeriod` plus derselben Nord-/Suedhalbkugel-Verschiebung
  berechnet, die die Engine selbst in `I18N:formatPeriod()` verwendet
  (`TelemetryCollector.calendarMonthFromPeriod()`, neu, unit-getestet).
- **Bugfix**: `fruitType`/`growthState` einzelner Felder in `world.json`
  konnten durch eine Kollision zwischen der bestaetigten
  `field.farmland`-Zuordnung und dem unbestaetigten
  `fieldState.farmlandId`-Fallback nichtdeterministisch mit den Anbaudaten
  eines anderen Feldes ueberschrieben werden. `FarmPulseBridge.readFieldCrops()`
  verwirft jetzt einen Fallback-Eintrag, sobald fuer dieselbe farmlandId
  bereits ein bestaetigter Eintrag vorliegt (`FieldCollector.shouldReplaceCropEntry()`,
  neu, unit-getestet). Ausserdem in `Bridge/README.md` dokumentiert: die
  verbleibende, inhaerente Engine-Grenze der Einzelpunkt-Abtastung von
  `field:getFieldState()` (misst nur den Feld-Polygon-Mittelpunkt, keine
  Flaechen-Aggregation) kann weiterhin dazu fuehren, dass der gemeldete Zustand
  bei teilweise bewirtschafteten Feldern vom Rest der Flaeche abweicht.

## [2.2.0] - Bridge

- Aktuellen Wettertyp + Temperatur zu `telemetry.json` ergaenzt
  (`FarmPulseBridge.readWeather()`, `TelemetryCollector`).
- Feld-Anbaudaten (Fruchtart, Wachstumsfortschritt, Ertragsschaetzung) zu
  `world.json`/`fields[]` ergaenzt - liest zusaetzlich `g_fieldManager.fields`
  (nicht nur `g_farmlandManager`), siehe `FarmPulseBridge.readFieldCrops()`,
  `FieldCollector.computeCropInfo()`.
- Aktuellen sowie besten Marktpreis (samt Periode) je Fill-Typ zu
  `world.json`/`storages[]` ergaenzt (neues, testbares
  `PriceCollector.lua`-Modul), siehe `FarmPulseBridge.readFillTypePrice()`.
- `Tools/mock-bridge.sh` bei jeder der drei obigen Erweiterungen mitgezogen.

## [2.1.0] - Bridge

- `mock-bridge.sh` auf das aktuelle 3-Datei-Format (`telemetry.json`,
  `world.json`, `farm.json`) umgebaut.

## [2.0.0] - Bridge

- Export in drei getrennte Dateien aufgeteilt statt eines einzigen
  Snapshots: `telemetry.json` (schnelle Pulswerte), `world.json` (Felder,
  Fuhrpark-Wert, Lagerbestaende), `farm.json` (Hofname, Spielername,
  einmalig).
- Wetter- und Jahreszeiten-Export ergaenzt (`WeatherCollector`).
- Aggregierten Fuhrpark-Wert ergaenzt (`VehicleCollector`).
- Lager-/Silobestaende ergaenzt (`StorageCollector`).

## [1.0.0] - Bridge

- Erste Version der FarmPulse Bridge fuer Farming Simulator 25: periodischer
  Export von Uhrzeit, Kalenderdaten, Kontostand, FarmID und Feldliste.
