import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, Subject, merge, shareReplay, switchMap, timer } from 'rxjs';
import { VehiclesResponse } from '../models/vehicles.model';

const POLL_INTERVAL_MS = 5000;

@Injectable({ providedIn: 'root' })
export class VehiclesService {
  private readonly http = inject(HttpClient);
  private readonly manualRefresh$ = new Subject<void>();

  /** Pollt die Fuhrpark-Telemetrie alle 5 Sekunden, solange mindestens ein Abonnent aktiv ist. */
  readonly vehicles$: Observable<VehiclesResponse> = merge(timer(0, POLL_INTERVAL_MS), this.manualRefresh$).pipe(
    switchMap(() => this.http.get<VehiclesResponse>('/api/vehicles')),
    shareReplay({ bufferSize: 1, refCount: true }),
  );

  refreshNow(): void {
    this.manualRefresh$.next();
  }
}
