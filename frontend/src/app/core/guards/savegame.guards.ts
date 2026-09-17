import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { catchError, map, of } from 'rxjs';
import { SavegameService } from '../services/savegame.service';

/** Lässt /dashboard nur zu, wenn das Savegame bereits gestartet ist. */
export const startedGuard: CanActivateFn = () => {
  const savegameService = inject(SavegameService);
  const router = inject(Router);

  return savegameService.fetchStatus().pipe(
    map((status) => (status.started ? true : router.createUrlTree(['/start']))),
    catchError(() => of(router.createUrlTree(['/start']))),
  );
};

/** Schickt von /start bereits weiter zu /dashboard, wenn das Savegame schon läuft. */
export const notStartedGuard: CanActivateFn = () => {
  const savegameService = inject(SavegameService);
  const router = inject(Router);

  return savegameService.fetchStatus().pipe(
    map((status) => (status.started ? router.createUrlTree(['/dashboard']) : true)),
    catchError(() => of(true)),
  );
};
