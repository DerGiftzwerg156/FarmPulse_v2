package de.farmpulse.backend.fields;

import de.farmpulse.backend.fields.dto.FieldsResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST-Schnittstelle fuer die Felder-Seite im Frontend (Vorlage
 * MockDashboard/Fields.html).
 */
@RestController
@RequestMapping("/api/fields")
public class FieldsController {

    private final FieldsService fieldsService;

    public FieldsController(FieldsService fieldsService) {
        this.fieldsService = fieldsService;
    }

    @GetMapping
    public FieldsResponse fields() {
        return fieldsService.getFields();
    }
}
