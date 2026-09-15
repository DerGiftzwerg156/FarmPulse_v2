# FarmPulse

FarmPulse verbindet einen laufenden [Farming Simulator 25](https://www.farming-simulator.com/)-Spielstand
mit einer externen Dashboard-Anwendung. Dieses Repository enthaelt aktuell
den Datenexport-Teil des Projekts:

| Ordner | Inhalt |
|---|---|
| [`Bridge/`](Bridge/) | **FarmPulse Bridge** - der eigentliche FS25-Mod (Lua). Exportiert periodisch `telemetry.json`, `world.json` und `farm.json` in einen Austauschordner. Siehe [`Bridge/README.md`](Bridge/README.md) fuer Dateiformate, Architektur, Installation und Testlauf. |
| [`Tools/`](Tools/) | Hilfsskripte fuer die Entwicklung, u.a. [`mock-bridge.sh`](Tools/mock-bridge.sh), das die Ausgabedateien der Bridge simuliert, ohne dass FS25 laufen muss. |

Eine **FarmPulse Core**-Anwendung (das Dashboard, das die drei JSON-Dateien
konsumiert und visualisiert) ist noch nicht Teil dieses Repos.

## Schnellstart

### Bridge-Mod installieren

Siehe [`Bridge/README.md`, Abschnitt "Installation"](Bridge/README.md#installation).

### Bridge-Ausgabe lokal simulieren (ohne FS25)

```bash
./Tools/mock-bridge.sh
```

Schreibt `telemetry.json`, `world.json` und `farm.json` mit plausiblen,
sich veraendernden Testdaten nach `mock-exchange/` im Repo-Root (Zielordner
und Intervall optional als Argumente, siehe Skript-Kopf).

### Tests ausfuehren

Die GIANTS-unabhaengigen Logikmodule der Bridge sind vollstaendig ohne FS25
testbar:

```bash
cd Bridge
lua5.4 tests/run_tests.lua
```

Details siehe [`Bridge/README.md`, Abschnitt "Tests ausfuehren"](Bridge/README.md#tests-ausfuehren).
Diese Tests laufen auch automatisch in CI, siehe unten.

## CI

Jeder Push und Pull Request durchlaeuft die GitHub-Actions-Pipeline
[`.github/workflows/test.yml`](.github/workflows/test.yml), welche die
Bridge-Unit-Tests ausfuehrt.

## Mitarbeiten

Bevor du einen Pull Request eroeffnest, lies bitte [`CONTRIBUTING.md`](CONTRIBUTING.md) -
dort steht insbesondere eine Checkliste, was vor jedem PR zu erledigen ist
(Tests, Doku, `modDesc.xml`, ...).

## Lizenz

Dieses Projekt steht unter der [MIT-Lizenz](LICENSE).
