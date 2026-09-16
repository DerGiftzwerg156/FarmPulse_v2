package de.farmpulse.backend.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

/**
 * Ein von der Bridge exportierter Betrieb. Die ID entspricht bewusst der
 * FarmID aus telemetry.json (natuerlicher Schluessel aus dem Spiel, siehe
 * Bridge/README.md, Abschnitt "Dateiformat: telemetry.json") statt eines
 * generierten Surrogatschluessels - telemetry.json ist die einzige Datei,
 * die die FarmID mitliefert.
 */
@Entity
@Table(name = "farm")
public class Farm {

    @Id
    private Long id;

    @Column(name = "name")
    private String name;

    @Column(name = "player_name")
    private String playerName;

    @Column(name = "first_seen_at", nullable = false)
    private Instant firstSeenAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Farm() {
        // fuer JPA
    }

    public Farm(Long id, Instant firstSeenAt) {
        this.id = id;
        this.firstSeenAt = firstSeenAt;
        this.updatedAt = firstSeenAt;
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getPlayerName() {
        return playerName;
    }

    public Instant getFirstSeenAt() {
        return firstSeenAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void updateIdentity(String name, String playerName, Instant updatedAt) {
        this.name = name;
        this.playerName = playerName;
        this.updatedAt = updatedAt;
    }

    public void touch(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}
