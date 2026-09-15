# Changelog

Alle nennenswerten Aenderungen an diesem Projekt werden hier dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
Versionsnummern der Bridge folgen [Semantic Versioning](https://semver.org/lang/de/)
(siehe `Bridge/modDesc.xml`, `<version>`).

## [Unreleased]

- **Backend** (neu): Spring-Boot-Anwendung unter `backend/`, die
  `telemetry.json`/`world.json`/`farm.json` periodisch einliest, ueber einen
  Verarbeitungsschritt-Erweiterungspunkt reicht und als historisierte
  Entitaeten in MariaDB speichert (Schema per Flyway-Migrationen). Siehe
  `backend/README.md`.
- Projekt-Grundlagen ergaenzt: Root-`README.md`, `LICENSE` (MIT),
  `CONTRIBUTING.md`, GitHub-Actions-Testpipeline, PR-/Issue-Templates.
- `season`/`weather` aus `telemetry.json` entfernt und `WeatherCollector`
  komplett entfernt, da dessen einziger Zweck (Jahreszeit-/Wetter-Werte fuer
  `telemetry.json`) damit entfaellt.

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
