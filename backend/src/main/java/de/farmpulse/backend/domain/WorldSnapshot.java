package de.farmpulse.backend.domain;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderColumn;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Eine historisierte Momentaufnahme von world.json (siehe Bridge/README.md,
 * Abschnitt "Dateiformat: world.json"): Fuhrpark-Wert plus die zugehoerigen
 * Fahrzeug-, Feld- und Lagerbestandslisten dieses Zeitpunkts. Da die Bridge
 * bei jedem Poll die vollstaendige Fahrzeug-/Feld-/Lagerliste neu liefert
 * (kein Delta), wird auch hier je Snapshot die volle Liste gespeichert statt
 * einzelne Felder fortzuschreiben.
 */
@Entity
@Table(name = "world_snapshot")
public class WorldSnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "farm_id", nullable = false)
    private Farm farm;

    @Column(name = "fleet_value", nullable = false)
    private long fleetValue;

    /** Realer Zeitpunkt des Exports (Datei-mtime von world.json). */
    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @OneToMany(mappedBy = "worldSnapshot", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderColumn(name = "list_index")
    private List<FieldSnapshot> fields = new ArrayList<>();

    @OneToMany(mappedBy = "worldSnapshot", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderColumn(name = "list_index")
    private List<VehicleSnapshot> vehicles = new ArrayList<>();

    @OneToMany(mappedBy = "worldSnapshot", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderColumn(name = "list_index")
    private List<StorageSnapshot> storages = new ArrayList<>();

    protected WorldSnapshot() {
        // fuer JPA
    }

    public WorldSnapshot(Farm farm, long fleetValue, Instant recordedAt, Instant createdAt) {
        this.farm = farm;
        this.fleetValue = fleetValue;
        this.recordedAt = recordedAt;
        this.createdAt = createdAt;
    }

    public void addField(FieldSnapshot field) {
        field.setWorldSnapshot(this);
        fields.add(field);
    }

    public void addVehicle(VehicleSnapshot vehicle) {
        vehicle.setWorldSnapshot(this);
        vehicles.add(vehicle);
    }

    public void addStorage(StorageSnapshot storage) {
        storage.setWorldSnapshot(this);
        storages.add(storage);
    }

    public Long getId() {
        return id;
    }

    public Farm getFarm() {
        return farm;
    }

    public long getFleetValue() {
        return fleetValue;
    }

    public Instant getRecordedAt() {
        return recordedAt;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public List<FieldSnapshot> getFields() {
        return fields;
    }

    public List<VehicleSnapshot> getVehicles() {
        return vehicles;
    }

    public List<StorageSnapshot> getStorages() {
        return storages;
    }
}
