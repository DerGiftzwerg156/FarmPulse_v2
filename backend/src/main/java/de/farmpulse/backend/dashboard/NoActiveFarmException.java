package de.farmpulse.backend.dashboard;

/**
 * Wird geworfen, wenn das Dashboard abgefragt wird, bevor ueberhaupt eine
 * Farm bekannt ist (siehe {@code de.farmpulse.backend.savegame.SavegameService}
 * fuer den Fortschritt bis zum Start des Savegames - das Frontend sollte in
 * diesem Fall auf die Savegame-Erstellen-Seite verweisen).
 */
public class NoActiveFarmException extends RuntimeException {

    public NoActiveFarmException(String message) {
        super(message);
    }
}
