package de.farmpulse.backend.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;

/**
 * Eine historisierte Momentaufnahme von telemetry.json (siehe
 * Bridge/README.md, Abschnitt "Dateiformat: telemetry.json"). Jeder
 * tatsaechlich veraenderte Poll der Bridge erzeugt eine eigene Zeile - so
 * entsteht die vom Backend gefuehrte Zeitreihe, die die Bridge selbst
 * bewusst nicht haelt (siehe Bridge/README.md, Einleitung: "jede Form von
 * Verlauf/Historie ... liefert nur Momentaufnahmen").
 */
@Entity
@Table(name = "telemetry_snapshot")
public class TelemetrySnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "farm_id", nullable = false)
    private Farm farm;

    @Column(name = "game_year", nullable = false)
    private int gameYear;

    @Column(name = "game_month", nullable = false)
    private int gameMonth;

    @Column(name = "game_day", nullable = false)
    private int gameDay;

    @Column(name = "game_hour", nullable = false)
    private int gameHour;

    @Column(name = "game_minute", nullable = false)
    private int gameMinute;

    @Column(name = "days_per_month", nullable = false)
    private int daysPerMonth;

    @Column(name = "money", nullable = false)
    private long money;

    /** Realer Zeitpunkt des Exports (Datei-mtime von telemetry.json). */
    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected TelemetrySnapshot() {
        // fuer JPA
    }

    public TelemetrySnapshot(Farm farm, int gameYear, int gameMonth, int gameDay, int gameHour,
            int gameMinute, int daysPerMonth, long money, Instant recordedAt, Instant createdAt) {
        this.farm = farm;
        this.gameYear = gameYear;
        this.gameMonth = gameMonth;
        this.gameDay = gameDay;
        this.gameHour = gameHour;
        this.gameMinute = gameMinute;
        this.daysPerMonth = daysPerMonth;
        this.money = money;
        this.recordedAt = recordedAt;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public Farm getFarm() {
        return farm;
    }

    public int getGameYear() {
        return gameYear;
    }

    public int getGameMonth() {
        return gameMonth;
    }

    public int getGameDay() {
        return gameDay;
    }

    public int getGameHour() {
        return gameHour;
    }

    public int getGameMinute() {
        return gameMinute;
    }

    public int getDaysPerMonth() {
        return daysPerMonth;
    }

    public long getMoney() {
        return money;
    }

    public Instant getRecordedAt() {
        return recordedAt;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
