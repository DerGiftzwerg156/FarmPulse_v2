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
 * Ein Lager-/Silobestand innerhalb eines WorldSnapshot, siehe
 * Bridge/README.md, Abschnitt "Dateiformat: world.json"
 * (world.json/storages[]).
 *
 * <p>Die Marktpreisfelder (currentPricePer1000L/bestPricePer1000L/
 * bestPricePeriod/bestPricePeriodLabel) sind nullable, da die Bridge den
 * Preis nicht fuer jeden Fill-Typ zuverlaessig lesen kann (siehe
 * Bridge/README.md, Abschnitt "Bekannte Luecken").
 */
@Entity
@Table(name = "storage_snapshot")
public class StorageSnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "world_snapshot_id", nullable = false)
    private WorldSnapshot worldSnapshot;

    @Column(name = "fill_type", nullable = false, length = 64)
    private String fillType;

    @Column(name = "amount", nullable = false)
    private long amount;

    @Column(name = "capacity", nullable = false)
    private long capacity;

    @Column(name = "current_price_per_1000l")
    private Double currentPricePer1000L;

    @Column(name = "best_price_per_1000l")
    private Double bestPricePer1000L;

    @Column(name = "best_price_period")
    private Integer bestPricePeriod;

    @Column(name = "best_price_period_label", length = 64)
    private String bestPricePeriodLabel;

    protected StorageSnapshot() {
        // fuer JPA
    }

    public StorageSnapshot(String fillType, long amount, long capacity, Double currentPricePer1000L,
            Double bestPricePer1000L, Integer bestPricePeriod, String bestPricePeriodLabel) {
        this.fillType = fillType;
        this.amount = amount;
        this.capacity = capacity;
        this.currentPricePer1000L = currentPricePer1000L;
        this.bestPricePer1000L = bestPricePer1000L;
        this.bestPricePeriod = bestPricePeriod;
        this.bestPricePeriodLabel = bestPricePeriodLabel;
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

    public String getFillType() {
        return fillType;
    }

    public long getAmount() {
        return amount;
    }

    public long getCapacity() {
        return capacity;
    }

    public Double getCurrentPricePer1000L() {
        return currentPricePer1000L;
    }

    public Double getBestPricePer1000L() {
        return bestPricePer1000L;
    }

    public Integer getBestPricePeriod() {
        return bestPricePeriod;
    }

    public String getBestPricePeriodLabel() {
        return bestPricePeriodLabel;
    }
}
