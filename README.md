# FarmPulse

FarmPulse verbindet einen laufenden [Farming Simulator 25](https://www.farming-simulator.com/)-Spielstand
mit einer externen Dashboard-Anwendung:

| Ordner | Inhalt |
|---|---|
| [`Bridge/`](Bridge/) | **FarmPulse Bridge** - der eigentliche FS25-Mod (Lua). Exportiert periodisch `telemetry.json`, `world.json` und `farm.json` in einen Austauschordner. Siehe [`Bridge/README.md`](Bridge/README.md) fuer Dateiformate, Architektur, Installation und Testlauf. |
| [`backend/`](backend/) | **FarmPulse Backend** - Spring-Boot-Anwendung, die die drei Austauschdateien periodisch einliest und in MariaDB historisiert (Flyway-Migrationen fuer das Schema), sowie eine REST-Schnittstelle fuer das Frontend bereitstellt (Dashboard, Felder, Finanzen, Postfach). Siehe [`backend/README.md`](backend/README.md) fuer Architektur, Endpunkte, Konfiguration und lokale Entwicklung. |
| [`frontend/`](frontend/) | **FarmPulse Dashboard** - Angular-Oberflaeche, die die Backend-REST-Schnittstelle alle 5 Sekunden pollt und live anzeigt (Dashboard, Felder, Finanzen, Lagerbestaende, Postfach). Optisch an `MockDashboard/*.html` angelehnt, zeigt aber ausschliesslich echte, aus der Bridge stammende Werte - siehe [`backend/docs/MOCK_DASHBOARD_DATENLUECKEN.md`](backend/docs/MOCK_DASHBOARD_DATENLUECKEN.md) fuer Mock-Werte ohne (vollstaendige) Bridge-Datenquelle. |
| [`Tools/`](Tools/) | Hilfsskripte fuer die Entwicklung, u.a. [`mock-bridge.sh`](Tools/mock-bridge.sh) (simuliert die Bridge-Ausgabedateien ohne laufendes FS25) und [`docker-compose.dev.yml`](Tools/docker-compose.dev.yml) (lokale MariaDB + optional containerisiertes Backend). |

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

### Backend lokal starten

```bash
docker compose -f Tools/docker-compose.dev.yml up -d   # MariaDB
cd backend && mvn spring-boot:run                       # liest standardmaessig repo-root/mock-exchange
```

Alternativ komplett containerisiert (Backend + MariaDB, siehe
[`backend/README.md`, Abschnitt "Docker"](backend/README.md#docker)):

```bash
docker compose -f Tools/docker-compose.dev.yml --profile backend up -d --build
```

Details siehe [`backend/README.md`](backend/README.md).

### Frontend lokal starten

```bash
cd frontend
npm ci
ng serve   # http://localhost:4200, erwartet das Backend auf localhost:8080
```

Zum Testen ohne laufendes Backend/FS25 reicht `./Tools/mock-bridge.sh` (siehe
oben) plus ein lokal laufendes Backend, das dessen Ausgabeordner einliest.
Details siehe [`frontend/README.md`](frontend/README.md).

## CI

Jeder Push und Pull Request durchlaeuft die GitHub-Actions-Pipeline
[`.github/workflows/test.yml`](.github/workflows/test.yml), welche die
Bridge-Unit-Tests sowie die Backend-Tests (Maven, inkl. Testcontainers-
Integrationstests gegen MariaDB, und einen Docker-Image-Build) ausfuehrt.
**Frontend-Tests laufen aktuell nicht in CI** - `ng build`/`ng test` muessen
vor einem PR, der `frontend/` betrifft, lokal ausgefuehrt werden (siehe
[`CONTRIBUTING.md`](CONTRIBUTING.md)).

## Mitarbeiten

Bevor du einen Pull Request eroeffnest, lies bitte [`CONTRIBUTING.md`](CONTRIBUTING.md) -
dort steht insbesondere eine Checkliste, was vor jedem PR zu erledigen ist
(Tests, Doku, `modDesc.xml`, `Tools/mock-bridge.sh` bei Bridge-
Formataenderungen, ...).

## Lizenz

Dieses Projekt steht unter der [MIT-Lizenz](LICENSE).
