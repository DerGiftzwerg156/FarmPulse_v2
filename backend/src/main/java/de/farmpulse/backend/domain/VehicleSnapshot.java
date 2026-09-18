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

/**
 * Ein Fahrzeug innerhalb eines WorldSnapshot, siehe Bridge/README.md,
 * Abschnitt "Dateiformat: world.json" (world.json/vehicles[]).
 *
 * <p>{@code horsepowerHp}/{@code operatingHours}/{@code conditionPercent}
 * sind nullable: die Bridge liest jedes Detail-Feld einzeln ab (siehe
 * {@code FarmPulseBridge.readVehicleDetails()}) - schlaegt z.B. nur die
 * PS-Ermittlung fehl (z.B. bei einem nicht-motorisierten Anhaenger), bleiben
 * die uebrigen Felder trotzdem befuellt. {@code ownershipStatus} ist einer
 * von {@code OWNED}/{@code LEASED}/{@code MISSION}/{@code SHOP_CONFIG}/
 * {@code UNKNOWN}, siehe Bridge-seitiges {@code VehicleCollector.lua}.
 */
@Entity
@Table(name = "vehicle_snapshot")
public class VehicleSnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "world_snapshot_id", nullable = false)
    private WorldSnapshot worldSnapshot;

    @Column(name = "name", nullable = false, length = 128)
    private String name;

    @Column(name = "category", nullable = false, length = 64)
    private String category;

    @Column(name = "horsepower_hp")
    private Double horsepowerHp;

    @Column(name = "operating_hours")
    private Double operatingHours;

    @Column(name = "condition_percent")
    private Double conditionPercent;

    @Column(name = "ownership_status", nullable = false, length = 16)
    private String ownershipStatus;

    @Column(name = "sell_price", nullable = false)
    private long sellPrice;

    protected VehicleSnapshot() {
        // fuer JPA
    }

    public VehicleSnapshot(String name, String category, Double horsepowerHp, Double operatingHours,
            Double conditionPercent, String ownershipStatus, long sellPrice) {
        this.name = name;
        this.category = category;
        this.horsepowerHp = horsepowerHp;
        this.operatingHours = operatingHours;
        this.conditionPercent = conditionPercent;
        this.ownershipStatus = ownershipStatus;
        this.sellPrice = sellPrice;
    }

    void setWorldSnapshot(WorldSnapshot worldSnapshot) {
        this.worldSnapshot = worldSnapshot;
    }

    public Long getId() {
        return id;
    }

    public WorldSnapshot getWorldSnapshot() {
        return worldSnapshot;
    }

    public String getName() {
        return name;
    }

    public String getCategory() {
        return category;
    }

    public Double getHorsepowerHp() {
        return horsepowerHp;
    }

    public Double getOperatingHours() {
        return operatingHours;
    }

    public Double getConditionPercent() {
        return conditionPercent;
    }

    public String getOwnershipStatus() {
        return ownershipStatus;
    }

    public long getSellPrice() {
        return sellPrice;
    }
}
