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
 * Die einmalig eingegebene "Vorgeschichte" eines neuen Spielstands (siehe
 * de.farmpulse.backend.savegame.SavegameService). Es existiert zu jedem
 * Zeitpunkt hoechstens eine Zeile - siehe
 * de.farmpulse.backend.repository.SavegameBackstoryRepository.
 *
 * <p>{@code farm} ist bewusst nullable: die Vorgeschichte kann bereits vor
 * dem ersten telemetry.json-Poll (und damit vor der ersten {@link Farm})
 * eingegeben werden. Sie wird dann nachtraeglich verknuepft, sobald die
 * Farm bekannt ist (siehe de.farmpulse.backend.ingest.event.FarmCreatedEvent).
 */
@Entity
@Table(name = "savegame_backstory")
public class SavegameBackstory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "text", nullable = false, columnDefinition = "TEXT")
    private String text;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @ManyToOne(fetch = FetchType.LAZY, optional = true)
    @JoinColumn(name = "farm_id", nullable = true)
    private Farm farm;

    protected SavegameBackstory() {
        // fuer JPA
    }

    public SavegameBackstory(String text, Instant createdAt) {
        this.text = text;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public String getText() {
        return text;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Farm getFarm() {
        return farm;
    }

    public void linkToFarm(Farm farm) {
        this.farm = farm;
    }
}
