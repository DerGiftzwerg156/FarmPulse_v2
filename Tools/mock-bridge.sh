#!/usr/bin/env bash
#
# mock-bridge.sh - simuliert FarmPulseBridge.lua, ohne dass FS25 laufen muss.
#
# Schreibt periodisch die drei Austauschdateien telemetry.json, world.json und
# farm.json in ein Zielverzeichnis, exakt in Feldnamen/-reihenfolge/-typen wie
# von der echten Bridge exportiert (siehe TelemetryCollector.toJson(),
# WorldCollector.toJson(), FarmCollector.toJson() sowie die "Dateiformat"-
# Abschnitte in Bridge/README.md). Damit laesst sich ein Downstream-Konsument
# (z.B. ein Dashboard) End-to-End gegen einen plausiblen, sich ueber die Zeit
# aendernden Datensatz testen, ohne dass die echte Bridge im Spiel laufen muss.
#
# telemetry.json wird bei jedem Tick neu geschrieben (Standard-Intervall 5s,
# identisch zu FarmPulseBridge.POLL_INTERVAL_MS), world.json alle 6 Ticks
# (identisch zum Verhaeltnis FarmPulseBridge.WORLD_POLL_INTERVAL_MS /
# FarmPulseBridge.POLL_INTERVAL_MS = 30000 / 5000 = 6), farm.json einmalig
# beim Start - dasselbe Aktualisierungsmuster wie in der echten Bridge.
#
# Verwendung:
#   ./mock-bridge.sh [Zielverzeichnis] [Intervall-Sekunden]
#
# Die echte Bridge schreibt in
# "<FS25-Nutzerprofil>/modSettings/FarmPulseBridge/" (siehe Bridge/README.md,
# Abschnitt "Installation"). Dieses Repo enthaelt (noch) keine FarmPulse-Core-
# Anwendung, die dieses Verzeichnis vorgibt - Standard-Zielverzeichnis ist
# daher ein einfaches lokales Scratch-Verzeichnis; falls gegen einen echten
# Downstream-Konsumenten getestet wird, dessen konfiguriertes Austausch-
# verzeichnis als erstes Argument uebergeben.
# Standard-Intervall: 5 Sekunden (identisch zu FarmPulseBridge.POLL_INTERVAL_MS).
#
# Mit Strg+C beenden.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TARGET_DIR="${1:-../mock-exchange}"
INTERVAL_SECONDS="${2:-5}"
WORLD_TICK_RATIO=6   # FarmPulseBridge.WORLD_POLL_INTERVAL_MS / FarmPulseBridge.POLL_INTERVAL_MS

mkdir -p "${TARGET_DIR}"
TELEMETRY_FILE="${TARGET_DIR}/telemetry.json"
WORLD_FILE="${TARGET_DIR}/world.json"
FARM_FILE="${TARGET_DIR}/farm.json"

echo "[mock-bridge] telemetry.json alle ${INTERVAL_SECONDS}s, world.json alle $((INTERVAL_SECONDS * WORLD_TICK_RATIO))s, farm.json einmalig -> ${TARGET_DIR}"
echo "[mock-bridge] Beenden mit Strg+C."

# --- Telemetrie-Zustand (siehe TelemetryCollector.lua fuer die Feldsemantik) ---
hour=8
minute=30
day=1
month=1
year=1
days_per_month=3
money=50000
farm_id=1
weather_type="SUN"
temperature=15
WEATHER_TYPES=("SUN" "PARTIALLY_CLOUDY" "CLOUDY" "RAIN" "SNOW")

# --- Welt-Zustand (siehe FieldCollector/VehicleCollector/StorageCollector) ---
fleet_value=125000
wheat_amount=5000
wheat_capacity=20000
barley_amount=1200
barley_capacity=20000

# --- Anbaudaten je eigenem Feld (siehe FieldCollector.computeCropInfo()) ---
# growth_pct laeuft 0..100 (Prozent von growthState) und startet nach dem
# "erntereif"-Punkt wieder bei 0 (simulierte Wiederaussaat).
field1_fruit="WHEAT"
field1_area_ha=4.53
field1_liter_per_sqm=0.35
field1_growth_pct=10
field2_fruit="BARLEY"
field2_area_ha=6.1
field2_liter_per_sqm=0.30
field2_growth_pct=55

# --- Betriebs-/Spieleridentitaet (siehe FarmCollector.lua), einmalig ---
farm_name="Sonnenhof"
player_name="Keno"

write_telemetry() {
    local tmp_file="${TELEMETRY_FILE}.tmp"

    cat > "${tmp_file}" <<JSON
{"hour":${hour},"minute":${minute},"day":${day},"month":${month},"year":${year},"daysPerMonth":${days_per_month},"money":${money},"farmId":${farm_id},"weatherType":"${weather_type}","temperature":${temperature}}
JSON
    mv "${tmp_file}" "${TELEMETRY_FILE}"
}

write_world() {
    local tmp_file="${WORLD_FILE}.tmp"
    # growthState/estimatedYieldLiters als Dezimalzahlen - Bash rechnet nur
    # mit Ganzzahlen, daher hier per awk berechnet (siehe
    # FieldCollector.computeCropInfo() fuer dieselbe Formel in Lua).
    local field1_growth field1_yield field2_growth field2_yield
    field1_growth=$(awk "BEGIN { printf \"%.2f\", ${field1_growth_pct} / 100 }")
    field1_yield=$(awk "BEGIN { printf \"%.1f\", ${field1_liter_per_sqm} * ${field1_area_ha} * 10000 * ${field1_growth_pct} / 100 }")
    field2_growth=$(awk "BEGIN { printf \"%.2f\", ${field2_growth_pct} / 100 }")
    field2_yield=$(awk "BEGIN { printf \"%.1f\", ${field2_liter_per_sqm} * ${field2_area_ha} * 10000 * ${field2_growth_pct} / 100 }")

    cat > "${tmp_file}" <<JSON
{"fleetValue":${fleet_value},"fields":[{"fieldId":1,"ownerFarmId":${farm_id},"sizeHa":${field1_area_ha},"price":32000,"fruitType":"${field1_fruit}","growthState":${field1_growth},"estimatedYieldLiters":${field1_yield}},{"fieldId":2,"ownerFarmId":${farm_id},"sizeHa":${field2_area_ha},"price":45000,"fruitType":"${field2_fruit}","growthState":${field2_growth},"estimatedYieldLiters":${field2_yield}},{"fieldId":3,"ownerFarmId":0,"sizeHa":3.2,"price":28000,"fruitType":null,"growthState":null,"estimatedYieldLiters":null}],"storages":[{"fillType":"BARLEY","amount":${barley_amount},"capacity":${barley_capacity}},{"fillType":"WHEAT","amount":${wheat_amount},"capacity":${wheat_capacity}}]}
JSON
    mv "${tmp_file}" "${WORLD_FILE}"
}

write_farm() {
    local tmp_file="${FARM_FILE}.tmp"

    cat > "${tmp_file}" <<JSON
{"farmName":"${farm_name}","playerName":"${player_name}"}
JSON
    mv "${tmp_file}" "${FARM_FILE}"
}

# farm.json aendert sich praktisch nie waehrend eines Spielstands - wird
# deshalb, wie bei der echten Bridge (siehe FarmPulseBridge.tryActivate()),
# nur einmalig geschrieben.
write_farm

tick=0
while true; do
    # Tageszeit voranschreiten lassen (5 Sim-Minuten je Tick, damit man einen
    # Tages-/Monats-/Jahreswechsel in ueberschaubarer Zeit beobachten kann).
    minute=$((minute + 5))
    if [ "${minute}" -ge 60 ]; then
        minute=$((minute - 60))
        hour=$((hour + 1))
        if [ "${hour}" -ge 24 ]; then
            hour=$((hour - 24))
            day=$((day + 1))
            if [ "${day}" -gt "${days_per_month}" ]; then
                day=1
                month=$((month + 1))
                if [ "${month}" -gt 12 ]; then
                    month=1
                    year=$((year + 1))
                fi
            fi
        fi
    fi

    # Kontostand und Lagerbestaende leicht schwanken lassen, damit der Verlauf
    # im Dashboard sichtbar etwas tut (kein echtes Wirtschaftsmodell - nur zu
    # Demo-/Testzwecken).
    money=$((money + (RANDOM % 401) - 150))
    fleet_value=$((fleet_value + (RANDOM % 2001) - 1000))
    if [ "${fleet_value}" -lt 0 ]; then
        fleet_value=0
    fi
    wheat_amount=$(((wheat_amount + (RANDOM % 601) - 200) % (wheat_capacity + 1)))
    if [ "${wheat_amount}" -lt 0 ]; then
        wheat_amount=0
    fi
    barley_amount=$(((barley_amount + (RANDOM % 301) - 100) % (barley_capacity + 1)))
    if [ "${barley_amount}" -lt 0 ]; then
        barley_amount=0
    fi

    # Wachstum der beiden simulierten Felder voranschreiten lassen; nach
    # Erreichen von 100% (erntereif) wieder bei 0 beginnen (Wiederaussaat).
    field1_growth_pct=$(((field1_growth_pct + 1) % 101))
    field2_growth_pct=$(((field2_growth_pct + 1) % 101))

    # Wetter/Temperatur ebenfalls leicht schwanken lassen (kein echtes
    # Wettermodell - nur zu Demo-/Testzwecken, analog zu Kontostand/Lager oben).
    temperature=$((temperature + (RANDOM % 3) - 1))
    if [ "$((RANDOM % 5))" -eq 0 ]; then
        weather_type="${WEATHER_TYPES[$((RANDOM % ${#WEATHER_TYPES[@]}))]}"
    fi

    write_telemetry
    if [ "$((tick % WORLD_TICK_RATIO))" -eq 0 ]; then
        write_world
    fi

    echo "[mock-bridge] Jahr ${year}, Tag ${day}/${days_per_month} (Monat ${month}), $(printf '%02d:%02d' "${hour}" "${minute}"), Kontostand ${money} EUR, ${weather_type} ${temperature}°C"

    tick=$((tick + 1))
    sleep "${INTERVAL_SECONDS}"
done
