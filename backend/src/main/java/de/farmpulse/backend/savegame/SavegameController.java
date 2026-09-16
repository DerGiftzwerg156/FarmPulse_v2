package de.farmpulse.backend.savegame;

import de.farmpulse.backend.savegame.dto.BackstoryRequest;
import de.farmpulse.backend.savegame.dto.ErrorResponse;
import de.farmpulse.backend.savegame.dto.SavegameStatusResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST-Schnittstelle fuer den Start eines Savegames: Statusabfrage und
 * einmalige Eingabe der Vorgeschichte, siehe {@link SavegameService}.
 */
@RestController
@RequestMapping("/api/savegame")
public class SavegameController {

    private final SavegameService savegameService;

    public SavegameController(SavegameService savegameService) {
        this.savegameService = savegameService;
    }

    @GetMapping
    public SavegameStatusResponse status() {
        return savegameService.getStatus();
    }

    @PostMapping("/backstory")
    @ResponseStatus(HttpStatus.CREATED)
    public SavegameStatusResponse submitBackstory(@RequestBody BackstoryRequest request) {
        return savegameService.submitBackstory(request.backstory());
    }

    @ExceptionHandler(BackstoryAlreadySubmittedException.class)
    public ResponseEntity<ErrorResponse> handleAlreadySubmitted(BackstoryAlreadySubmittedException exception) {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(new ErrorResponse(exception.getMessage()));
    }

    @ExceptionHandler(InvalidBackstoryException.class)
    public ResponseEntity<ErrorResponse> handleInvalid(InvalidBackstoryException exception) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ErrorResponse(exception.getMessage()));
    }
}
