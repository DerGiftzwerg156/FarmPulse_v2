package de.farmpulse.backend.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.MapsId;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import java.time.Instant;

/**
 * Weiche Farm-Kennzahlen jenseits des Kontostands (siehe
 * MockDashboard/Finances.html, Panel "Werte"): Reputation und
 * Mitarbeiterzufriedenheit, je 0-100%. Genau eine Zeile je Farm (die
 * Farm-ID ist zugleich Primaerschluessel).
 *
 * <p><b>Wichtig:</b> Dieses Konzept stammt nicht aus der Bridge - FS25 kennt
 * weder Reputation noch Mitarbeiterzufriedenheit. Die Werte starten mit
 * einem neutralen Platzhalter und werden aktuell nicht fortgeschrieben; die
 * eigentliche Berechnungslogik ist noch nicht implementiert (siehe
 * {@code de.farmpulse.backend.progression.ProgressionService}).
 */
@Entity
@Table(name = "farm_values")
public class FarmValues {

    @Id
    @Column(name = "farm_id")
    private Long farmId;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "farm_id")
    private Farm farm;

    @Column(name = "reputation_percent", nullable = false)
    private int reputationPercent;

    @Column(name = "employee_satisfaction_percent", nullable = false)
    private int employeeSatisfactionPercent;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected FarmValues() {
        // fuer JPA
    }

    public FarmValues(Farm farm, int reputationPercent, int employeeSatisfactionPercent, Instant updatedAt) {
        this.farm = farm;
        this.reputationPercent = reputationPercent;
        this.employeeSatisfactionPercent = employeeSatisfactionPercent;
        this.updatedAt = updatedAt;
    }

    public Long getFarmId() {
        return farmId;
    }

    public Farm getFarm() {
        return farm;
    }

    public int getReputationPercent() {
        return reputationPercent;
    }

    public int getEmployeeSatisfactionPercent() {
        return employeeSatisfactionPercent;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
