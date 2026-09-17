import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, Subject, merge, shareReplay, switchMap, timer } from 'rxjs';
import { FieldsResponse } from '../models/fields.model';

const POLL_INTERVAL_MS = 5000;

@Injectable({ providedIn: 'root' })
export class FieldsService {
  private readonly http = inject(HttpClient);
  private readonly manualRefresh$ = new Subject<void>();

  /** Pollt die Feld-Telemetrie alle 5 Sekunden, solange mindestens ein Abonnent aktiv ist. */
  readonly fields$: Observable<FieldsResponse> = merge(timer(0, POLL_INTERVAL_MS), this.manualRefresh$).pipe(
    switchMap(() => this.http.get<FieldsResponse>('/api/fields')),
    shareReplay({ bufferSize: 1, refCount: true }),
  );

  refreshNow(): void {
    this.manualRefresh$.next();
  }
}
