package de.farmpulse.backend.vehicles;

import de.farmpulse.backend.vehicles.dto.VehiclesResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST-Schnittstelle fuer die Flotten-Seite im Frontend.
 */
@RestController
@RequestMapping("/api/vehicles")
public class VehiclesController {

    private final VehiclesService vehiclesService;

    public VehiclesController(VehiclesService vehiclesService) {
        this.vehiclesService = vehiclesService;
    }

    @GetMapping
    public VehiclesResponse vehicles() {
        return vehiclesService.getVehicles();
    }
}
