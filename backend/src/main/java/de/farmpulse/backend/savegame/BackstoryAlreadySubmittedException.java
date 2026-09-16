package de.farmpulse.backend.savegame;

/** Wird geworfen, wenn bereits einmalig eine Vorgeschichte gespeichert wurde. */
public class BackstoryAlreadySubmittedException extends RuntimeException {

    public BackstoryAlreadySubmittedException(String message) {
        super(message);
    }
}
