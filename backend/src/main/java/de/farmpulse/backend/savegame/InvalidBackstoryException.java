package de.farmpulse.backend.savegame;

/** Wird geworfen, wenn die per {@code POST /api/savegame/backstory} eingegebene Vorgeschichte ungueltig ist. */
public class InvalidBackstoryException extends RuntimeException {

    public InvalidBackstoryException(String message) {
        super(message);
    }
}
