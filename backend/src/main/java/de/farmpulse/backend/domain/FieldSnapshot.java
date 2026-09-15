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
 * Ein Feld/Farmland innerhalb eines WorldSnapshot, siehe Bridge/README.md,
 * Abschnitt "Dateiformat: world.json" (world.json/fields[]).
 *
 * <p>{@code ownerFarmId} ist bewusst KEIN Fremdschluessel auf {@link Farm}:
 * Die Bridge liefert alle Felder der Karte, auch unbesitzte (0) und solche
 * anderer, hier nicht separat verfolgter Farmen.
 */
@Entity
@Table(name = "field_snapshot")
public class FieldSnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "world_snapshot_id", nullable = false)
    private WorldSnapshot worldSnapshot;

    @Column(name = "field_id", nullable = false)
    private int fieldId;

    @Column(name = "owner_farm_id", nullable = false)
    private int ownerFarmId;

    @Column(name = "size_ha", nullable = false)
    private double sizeHa;

    @Column(name = "price", nullable = false)
    private long price;

    protected FieldSnapshot() {
        // fuer JPA
    }

    public FieldSnapshot(int fieldId, int ownerFarmId, double sizeHa, long price) {
        this.fieldId = fieldId;
        this.ownerFarmId = ownerFarmId;
        this.sizeHa = sizeHa;
        this.price = price;
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

    public int getFieldId() {
        return fieldId;
    }

    public int getOwnerFarmId() {
        return ownerFarmId;
    }

    public double getSizeHa() {
        return sizeHa;
    }

    public long getPrice() {
        return price;
    }
}
