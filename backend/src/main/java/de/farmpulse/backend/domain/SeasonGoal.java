package de.farmpulse.backend.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;

/**
 * Ein Saisonziel einer Farm (siehe MockDashboard/Finances.html, Panel
 * "Saisonziel"), z.B. "500 t Weizen ernten" oder "Einen Kontostand von
 * 2.000.000 EUR erreichen". Es gibt hoechstens ein {@link SeasonGoalStatus#ACTIVE}
 * Ziel je Farm gleichzeitig - siehe
 * {@code de.farmpulse.backend.progression.ProgressionService}.
 *
 * <p><b>Wichtig:</b> Dieses Konzept stammt nicht aus der Bridge (FS25 kennt
 * weder Saisonziele noch eine Kampagnen-Logik) - Ziele werden zufaellig aus
 * einer mitgelieferten Vorlagendatei ({@code season-goal-templates.json}}
 * ausgewaehlt, analog zum Postfach ({@link MailboxMessage}, siehe
 * {@code de.farmpulse.backend.mailbox.MailboxGenerationService}). Die
 * Berechnung von {@link #getCurrentValue()} aus dem tatsaechlichen
 * Farm-Zustand ist noch nicht implementiert (bleibt bis dahin bei 0) - siehe
 * {@code de.farmpulse.backend.progression.ProgressionService}.
 */
@Entity
@Table(name = "season_goal")
public class SeasonGoal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "farm_id", nullable = false)
    private Farm farm;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 32)
    private SeasonGoalType type;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "unit", nullable = false, length = 32)
    private String unit;

    @Column(name = "target_value", nullable = false)
    private double targetValue;

    @Column(name = "current_value", nullable = false)
    private double currentValue;

    /** Nur gesetzt bei {@link SeasonGoalType#HARVEST_AMOUNT} (z.B. "WHEAT"). */
    @Column(name = "fill_type", length = 64)
    private String fillType;

    /** Freitext-Frist, z.B. "Bis Jahresende" - keine strukturierte Auswertung. */
    @Column(name = "deadline_label", length = 128)
    private String deadlineLabel;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 16)
    private SeasonGoalStatus status;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected SeasonGoal() {
        // fuer JPA
    }

    public SeasonGoal(Farm farm, SeasonGoalType type, String title, String unit, double targetValue,
            double currentValue, String fillType, String deadlineLabel, SeasonGoalStatus status, Instant createdAt) {
        this.farm = farm;
        this.type = type;
        this.title = title;
        this.unit = unit;
        this.targetValue = targetValue;
        this.currentValue = currentValue;
        this.fillType = fillType;
        this.deadlineLabel = deadlineLabel;
        this.status = status;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public Farm getFarm() {
        return farm;
    }

    public SeasonGoalType getType() {
        return type;
    }

    public String getTitle() {
        return title;
    }

    public String getUnit() {
        return unit;
    }

    public double getTargetValue() {
        return targetValue;
    }

    public double getCurrentValue() {
        return currentValue;
    }

    public String getFillType() {
        return fillType;
    }

    public String getDeadlineLabel() {
        return deadlineLabel;
    }

    public SeasonGoalStatus getStatus() {
        return status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
