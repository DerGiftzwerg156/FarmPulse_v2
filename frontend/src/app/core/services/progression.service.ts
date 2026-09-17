import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, Subject, merge, shareReplay, switchMap, timer } from 'rxjs';
import { ProgressionResponse } from '../models/progression.model';

const POLL_INTERVAL_MS = 5000;

@Injectable({ providedIn: 'root' })
export class ProgressionService {
  private readonly http = inject(HttpClient);
  private readonly manualRefresh$ = new Subject<void>();

  /** Pollt Werte (Reputation, Mitarbeiterzufriedenheit) und Saisonziel alle 5 Sekunden, solange mindestens ein Abonnent aktiv ist. */
  readonly progression$: Observable<ProgressionResponse> = merge(timer(0, POLL_INTERVAL_MS), this.manualRefresh$).pipe(
    switchMap(() => this.http.get<ProgressionResponse>('/api/progression')),
    shareReplay({ bufferSize: 1, refCount: true }),
  );

  refreshNow(): void {
    this.manualRefresh$.next();
  }
}
