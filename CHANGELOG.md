# Changelog

Alle nennenswerten Aenderungen an diesem Projekt werden hier dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
Versionsnummern der Bridge folgen [Semantic Versioning](https://semver.org/lang/de/)
(siehe `Bridge/modDesc.xml`, `<version>`).

## [Unreleased]

- Projekt-Grundlagen ergaenzt: Root-`README.md`, `LICENSE` (MIT),
  `CONTRIBUTING.md`, GitHub-Actions-Testpipeline, PR-/Issue-Templates.

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
