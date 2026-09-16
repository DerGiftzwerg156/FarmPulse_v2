# FarmPulse Backend

Spring-Boot-Anwendung, die die von der [FarmPulse Bridge](../Bridge/) exportierten
Austauschdateien (`telemetry.json`, `world.json`, `farm.json`) periodisch einliest,
in sinnvolle Entitaeten verpackt und in MariaDB historisiert. Eine
Dashboard-Oberflaeche ist (noch) nicht Teil dieser Anwendung - siehe Root-`README.md`.

## Architektur

```
backend/
├── pom.xml
├── Dockerfile                        Baut das Backend als eigenstaendiges Image (siehe "Docker")
└── src/main/java/de/farmpulse/backend/
    ├── FarmPulseBackendApplication.java
    ├── config/
    │   └── BridgeExchangeProperties.java   Konfiguration: Austauschordner + Poll-Intervalle
    ├── ingest/
    │   ├── IngestScheduler.java             @Scheduled-Jobs, ein Intervall je Datei
    │   ├── dto/                             Rohabbild der drei JSON-Dateien (1:1 zum Bridge-Format)
    │   └── service/
    │       ├── ExchangeFileReader.java      Liest eine Austauschdatei, wenn sie sich (per mtime) geaendert hat
    │       ├── TelemetryIngestService.java  telemetry.json -> Farm (Upsert) + TelemetrySnapshot
    │       ├── WorldIngestService.java      world.json -> WorldSnapshot + Field-/StorageSnapshot
    │       └── FarmIngestService.java       farm.json -> Name/Spielername der Farm
    ├── processing/                          Verarbeitungsschritt-Erweiterungspunkt (siehe unten, je Interface + NoOp in einer Datei)
    ├── savegame/                            REST-Schnittstelle rund um den Start eines Savegames (siehe unten)
    │   ├── SavegameController.java          GET/POST /api/savegame
    │   ├── SavegameService.java             Statuslogik + einmalige Vorgeschichte-Eingabe
    │   └── dto/
    ├── domain/                              JPA-Entitaeten
    └── repository/                          Spring-Data-Repositories
└── src/main/resources/
    ├── application.yml
    ├── application-docker.yml            Ueberschreibt DB-Host/Austauschordner fuer den Container-Betrieb
    └── db/migration/                        Flyway-Migrationen (V1-V6)
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

Die Ingest-Services sind bewusst ausschliesslich ueber `IngestScheduler` erreichbar -
kein manueller REST-Trigger.

### Savegame-Start (`savegame/`)

`SavegameController` stellt zwei Endpunkte bereit, ueber die ein neuer Spielstand
("Savegame") gestartet wird:

- `GET /api/savegame` - Fortschritt bis zum Start: `backstorySubmitted` (Vorgeschichte
  eingegeben), `telemetryPolled`/`worldPolled`/`farmDataPolled` (die jeweilige
  Austauschdatei wurde mindestens einmal erfolgreich gepollt) sowie `started`, das erst
  `true` wird, wenn alle vier Flags erfuellt sind.
- `POST /api/savegame/backstory` (Body `{"backstory": "..."}`) - speichert die
  "Vorgeschichte" des neuen Spielstands einmalig (`SavegameBackstory`, Tabelle
  `savegame_backstory`). Ein zweiter Aufruf liefert `409 Conflict`, eine leere/zu lange
  Vorgeschichte `400 Bad Request`. Die Vorgeschichte selbst wird hier nur gespeichert -
  die inhaltliche (KI-gestuetzte) Auswertung ist einem spaeteren Ticket vorbehalten.

Da `farm.json`/`world.json` erst nach dem ersten `telemetry.json`-Poll einer Farm
zugeordnet werden koennen (siehe "Bekannte Einschraenkung" unten), kann die Vorgeschichte
bereits vorher eingegeben werden: `SavegameBackstory.farm` ist dafuer nullable und wird
nachtraeglich verknuepft, sobald `TelemetryIngestService` eine neue Farm anlegt (via
`FarmCreatedEvent`, `SavegameService.onFarmCreated`).

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
| `savegame_backstory` | Die einmalig eingegebene "Vorgeschichte" eines Savegames (siehe "Savegame-Start" oben). Hoechstens eine Zeile; `farm_id` nullable, solange die Farm noch nicht bekannt ist. |

Schema-Aenderungen erfolgen ausschliesslich ueber neue Flyway-Migrationen unter
`src/main/resources/db/migration/` (`Vn__beschreibung.sql`) - niemals durch Hibernate
(`ddl-auto: validate`).

## Voraussetzungen

- Java 21
- Maven (`mvn`)
- Docker (fuer die lokale MariaDB via `Tools/docker-compose.dev.yml` sowie fuer
  die Testcontainers-Integrationstests und den optionalen Backend-Container)

## Lokale Entwicklung

Backend lokal (ohne Container) gegen eine containerisierte MariaDB:

```bash
# 1. MariaDB starten (aus dem Repo-Root)
docker compose -f Tools/docker-compose.dev.yml up -d

# 2. Backend starten (liest standardmaessig repo-root/mock-exchange, siehe
#    Tools/mock-bridge.sh - `mvn spring-boot:run` laeuft dafuer mit dem
#    Repo-Root als Arbeitsverzeichnis, siehe pom.xml)
cd backend
mvn spring-boot:run
```

Zum Simulieren von Bridge-Daten ohne laufendes FS25 (siehe Root-`README.md`):

```bash
./Tools/mock-bridge.sh
```

## Docker

Das Backend laesst sich ueber `backend/Dockerfile` als eigenstaendiges Image bauen
(mehrstufiger Build: Maven baut das Jar, das Runtime-Image enthaelt nur eine JRE +
das fertige Jar). Aktiv ist dabei standardmaessig das Spring-Profil `docker`
(`application-docker.yml`), das den DB-Host auf `mariadb` (statt `localhost`) und den
Austauschordner auf den absoluten Pfad `/mock-exchange` (statt des relativen lokalen
Defaults) umstellt - beides passend zum Dev-Compose-Setup.

Ueber `Tools/docker-compose.dev.yml` (Compose-Profil `backend`, siehe Kommentar am
Dateianfang) laesst sich das Backend zusammen mit MariaDB komplett containerisiert
starten, inkl. Mount von `mock-exchange/` aus dem Repo-Root:

```bash
docker compose -f Tools/docker-compose.dev.yml --profile backend up -d --build
```

Eigenstaendig bauen/starten (z.B. um das Image isoliert zu testen):

```bash
cd backend
docker build -t farmpulse-backend .
docker run --rm -p 8080:8080 \
  -e DB_HOST=host.docker.internal \
  -v "$(pwd)/../mock-exchange:/mock-exchange:ro" \
  farmpulse-backend
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
| `FARMPULSE_BRIDGE_EXCHANGE_DIR` | `./mock-exchange` (relativ zum Repo-Root, siehe "Lokale Entwicklung") | Ordner mit `telemetry.json`/`world.json`/`farm.json` |
| `FARMPULSE_TELEMETRY_INTERVAL_MS` | `5000` | Poll-Intervall telemetry.json |
| `FARMPULSE_WORLD_INTERVAL_MS` | `30000` | Poll-Intervall world.json |
| `FARMPULSE_FARM_INTERVAL_MS` | `60000` | Poll-Intervall farm.json |
| `FARMPULSE_LOG_LEVEL` | `DEBUG` | Log-Level fuer `de.farmpulse.backend` (siehe Abschnitt "Logging") |

Fuer einen echten FS25-Client zeigt `FARMPULSE_BRIDGE_EXCHANGE_DIR` auf
`Documents/My Games/FarmingSimulator2025/modSettings/FarmPulseBridge/` (siehe
[`Bridge/README.md`, Abschnitt "Installation"](../Bridge/README.md#installation)).

## Logging

`de.farmpulse.backend` laeuft standardmaessig auf `DEBUG` (ueber `FARMPULSE_LOG_LEVEL`
auf z.B. `INFO` reduzierbar). Direkt nach dem Start protokolliert der
`IngestScheduler` einmalig (auf `INFO`, unabhaengig vom Log-Level) den tatsaechlich
aufgeloesten Austauschordner sowie die konfigurierten Poll-Intervalle - hilfreich, um
z.B. eine falsch aufgeloeste Pfadkonfiguration sofort zu erkennen. Jeder Scheduler-Tick
sowie jeder Schritt der Ingest-Pipeline (Datei gelesen/uebersprungen,
Verarbeitungsschritt, Farm angelegt/aktualisiert, Snapshot gespeichert) wird zusaetzlich
auf `DEBUG` protokolliert.

## Tests ausfuehren

```bash
cd backend
mvn test
```

Enthaelt Unit-Tests (DTO-Parsing, Ingest-/Savegame-Logik gegen gemockte Repositories,
`SavegameController` via `@WebMvcTest`) sowie `IngestIntegrationTest`/
`SavegameIntegrationTest`, die via Testcontainers eine echte MariaDB starten, die
Flyway-Migrationen anwenden und den Ingest- bzw. Savegame-Ablauf End-to-End pruefen -
dafuer muss Docker lokal verfuegbar sein.
