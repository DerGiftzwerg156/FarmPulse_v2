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
 * Eine Nachricht im Postfach ("Farm Mailbox", siehe
 * MockDashboard/Postfach.html) einer Farm. Inhalte stammen aktuell aus
 * mitgelieferten Mock-Vorlagen statt aus einer echten KI-Anbindung - siehe
 * {@code de.farmpulse.backend.mailbox.MailboxGenerationService} fuer die
 * als TODO markierte Stelle, an der spaeter generierter statt vorlagenbasierter
 * Inhalt eingesetzt werden soll.
 */
@Entity
@Table(name = "mailbox_message")
public class MailboxMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "farm_id", nullable = false)
    private Farm farm;

    @Column(name = "sender", nullable = false)
    private String sender;

    @Column(name = "subject", nullable = false)
    private String subject;

    @Column(name = "body", nullable = false, columnDefinition = "TEXT")
    private String body;

    @Column(name = "category", nullable = false, length = 64)
    private String category;

    @Enumerated(EnumType.STRING)
    @Column(name = "priority", nullable = false, length = 16)
    private MailboxPriority priority;

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

    @Column(name = "is_read", nullable = false)
    private boolean read;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected MailboxMessage() {
        // fuer JPA
    }

    public MailboxMessage(Farm farm, String sender, String subject, String body, String category,
            MailboxPriority priority, int gameYear, int gameMonth, int gameDay, int gameHour, int gameMinute,
            Instant createdAt) {
        this.farm = farm;
        this.sender = sender;
        this.subject = subject;
        this.body = body;
        this.category = category;
        this.priority = priority;
        this.gameYear = gameYear;
        this.gameMonth = gameMonth;
        this.gameDay = gameDay;
        this.gameHour = gameHour;
        this.gameMinute = gameMinute;
        this.read = false;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public Farm getFarm() {
        return farm;
    }

    public String getSender() {
        return sender;
    }

    public String getSubject() {
        return subject;
    }

    public String getBody() {
        return body;
    }

    public String getCategory() {
        return category;
    }

    public MailboxPriority getPriority() {
        return priority;
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

    public boolean isRead() {
        return read;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void markRead() {
        this.read = true;
    }
}
