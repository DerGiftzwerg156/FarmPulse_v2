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

    protected StorageSnapshot() {
        // fuer JPA
    }

    public StorageSnapshot(String fillType, long amount, long capacity) {
        this.fillType = fillType;
        this.amount = amount;
        this.capacity = capacity;
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
}
