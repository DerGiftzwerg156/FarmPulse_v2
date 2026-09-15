# FarmPulse Backend

Spring-Boot-Anwendung, die die von der [FarmPulse Bridge](../Bridge/) exportierten
Austauschdateien (`telemetry.json`, `world.json`, `farm.json`) periodisch einliest,
in sinnvolle Entitaeten verpackt und in MariaDB historisiert. Eine
Dashboard-Oberflaeche ist (noch) nicht Teil dieser Anwendung - siehe Root-`README.md`.

## Architektur

```
backend/
├── pom.xml
├── docker-compose.yml                MariaDB fuer die lokale Entwicklung
└── src/main/java/de/farmpulse/backend/
    ├── FarmPulseBackendApplication.java
    ├── config/
    │   └── BridgeExchangeProperties.java   Konfiguration: Austauschordner + Poll-Intervalle
    ├── ingest/
    │   ├── dto/                            Rohabbild der drei JSON-Dateien (1:1 zum Bridge-Format)
    │   ├── ExchangeFileReader.java          Liest eine Austauschdatei, wenn sie sich (per mtime) geaendert hat
    │   ├── TelemetryIngestService.java      telemetry.json -> Farm (Upsert) + TelemetrySnapshot
    │   ├── WorldIngestService.java          world.json -> WorldSnapshot + Field-/StorageSnapshot
    │   ├── FarmIngestService.java           farm.json -> Name/Spielername der Farm
    │   ├── IngestScheduler.java             @Scheduled-Jobs, ein Intervall je Datei
    │   └── IngestController.java            POST /api/ingest/trigger - einmaliger manueller Durchlauf
    ├── processing/                          Verarbeitungsschritt-Erweiterungspunkt (siehe unten)
    ├── domain/                              JPA-Entitaeten
    └── repository/                          Spring-Data-Repositories
└── src/main/resources/
    ├── application.yml
    └── db/migration/                        Flyway-Migrationen (V1-V5)
```

### Ingest-Pipeline

Fuer jede der drei Dateien laeuft (via `IngestScheduler`, Standardintervalle an
`FarmPulseBridge.POLL_INTERVAL_MS`/`WORLD_POLL_INTERVAL_MS` angelehnt) derselbe Ablauf:

1. **Lesen**: `ExchangeFileReader` prueft die Datei-mtime und liest/parst die Datei nur,
   wenn sie sich seit dem letzten Durchlauf tatsaechlich geaendert hat. Die Bridge selbst
   schreibt keinen Wall-Clock-Zeitstempel in die Dateien (nur In-Game-Datum/-Uhrzeit) - die
   Datei-mtime dient deshalb als realer Zeitpunkt des Exports (`recordedAt`).
2. **Verarbeitungsschritt** (`processing/*ProcessingStep`): aktuell ein reiner
   Passthrough (`NoOp*ProcessingStep`), aber ein bewusster Erweiterungspunkt zwischen
   Rohdaten und Persistenz fuer spaetere fachliche Logik (Plausibilisierung, Ableitung
   weiterer Kennzahlen, ...), ohne dass die Pipeline drumherum angefasst werden muss.
3. **Abbildung + Persistenz**: Die verarbeiteten Rohdaten werden auf die JPA-Entitaeten
   abgebildet und gespeichert - `telemetry.json`/`world.json` als historisierte Zeitreihe
   (eine Zeile je tatsaechlicher Aenderung), `farm.json` als Update der Stammdaten der Farm.

Zusaetzlich zum Scheduler kann `POST /api/ingest/trigger` einen Durchlauf aller drei
Ingest-Services manuell anstossen (z.B. fuer Tests, direkt nach dem Start).

### Bekannte Einschraenkung: eine aktive Farm pro Instanz

`world.json` und `farm.json` enthalten selbst keine FarmID (nur `telemetry.json`, siehe
[`Bridge/README.md`](../Bridge/README.md#dateiformat-telemetryjson)). Solange die Bridge
pro laufendem FS25-Client ohnehin nur einen aktiven Spielstand exportiert, ordnet das
Backend `world.json`/`farm.json` deshalb eindeutig der zuletzt ueber `telemetry.json`
gesehenen Farm zu (`FarmRepository.findTopByOrderByUpdatedAtDesc()`). Sollen spaeter
mehrere gleichzeitige Farmen/Spielstaende pro Backend-Instanz unterstuetzt werden, muesste
die Bridge `world.json`/`farm.json` um eine `farmId` ergaenzen (siehe `Bridge/README.md`
fuer den Erweiterungsprozess).

## Datenmodell

| Tabelle | Inhalt |
|---|---|
| `farm` | Ein Betrieb, ID = FarmID aus `telemetry.json`. Name/Spielername aus `farm.json`. |
| `telemetry_snapshot` | Eine Zeile je tatsaechlich geaendertem `telemetry.json`-Poll (Kontostand, Spielzeit/-kalender). |
| `world_snapshot` | Eine Zeile je tatsaechlich geaendertem `world.json`-Poll (Fuhrpark-Wert). |
| `field_snapshot` | Volle Feldliste je `world_snapshot` (kein Delta, siehe Bridge-Format). |
| `storage_snapshot` | Volle Lagerbestandsliste je `world_snapshot`. |

Schema-Aenderungen erfolgen ausschliesslich ueber neue Flyway-Migrationen unter
`src/main/resources/db/migration/` (`Vn__beschreibung.sql`) - niemals durch Hibernate
(`ddl-auto: validate`).

## Voraussetzungen

- Java 21
- Maven (`mvn`)
- Docker (fuer die lokale MariaDB via `docker-compose.yml` sowie fuer die
  Testcontainers-Integrationstests)

## Lokale Entwicklung

```bash
# 1. MariaDB starten
cd backend
docker compose up -d

# 2. Backend starten (liest standardmaessig ../mock-exchange, siehe Tools/mock-bridge.sh)
mvn spring-boot:run
```

Zum Simulieren von Bridge-Daten ohne laufendes FS25 (siehe Root-`README.md`):

```bash
./Tools/mock-bridge.sh
```

## Konfiguration

Alle Werte sind per Umgebungsvariable ueberschreibbar (siehe `src/main/resources/application.yml`):

| Variable | Default | Bedeutung |
|---|---|---|
| `DB_HOST` | `localhost` | MariaDB-Host |
| `DB_PORT` | `3306` | MariaDB-Port |
| `DB_NAME` | `farmpulse` | Datenbankname |
| `DB_USERNAME` | `farmpulse` | DB-Benutzer |
| `DB_PASSWORD` | `farmpulse` | DB-Passwort |
| `FARMPULSE_BRIDGE_EXCHANGE_DIR` | `../mock-exchange` | Ordner mit `telemetry.json`/`world.json`/`farm.json` |
| `FARMPULSE_TELEMETRY_INTERVAL_MS` | `5000` | Poll-Intervall telemetry.json |
| `FARMPULSE_WORLD_INTERVAL_MS` | `30000` | Poll-Intervall world.json |
| `FARMPULSE_FARM_INTERVAL_MS` | `60000` | Poll-Intervall farm.json |

Fuer einen echten FS25-Client zeigt `FARMPULSE_BRIDGE_EXCHANGE_DIR` auf
`Documents/My Games/FarmingSimulator2025/modSettings/FarmPulseBridge/` (siehe
[`Bridge/README.md`, Abschnitt "Installation"](../Bridge/README.md#installation)).

## Tests ausfuehren

```bash
cd backend
mvn test
```

Enthaelt Unit-Tests (DTO-Parsing, Ingest-Logik gegen gemockte Repositories) sowie
`IngestIntegrationTest`, der via Testcontainers eine echte MariaDB startet, die
Flyway-Migrationen anwendet und einen vollstaendigen Ingest-Durchlauf End-to-End prueft -
dafuer muss Docker lokal verfuegbar sein.
