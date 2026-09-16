import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, Subject, merge, shareReplay, switchMap, timer } from 'rxjs';
import { FinanceResponse } from '../models/finance.model';

const POLL_INTERVAL_MS = 5000;

@Injectable({ providedIn: 'root' })
export class FinanceService {
  private readonly http = inject(HttpClient);
  private readonly manualRefresh$ = new Subject<void>();

  /** Pollt Kontostand-Verlauf und Einnahmen/Ausgaben alle 5 Sekunden, solange mindestens ein Abonnent aktiv ist. */
  readonly finance$: Observable<FinanceResponse> = merge(timer(0, POLL_INTERVAL_MS), this.manualRefresh$).pipe(
    switchMap(() => this.http.get<FinanceResponse>('/api/finance')),
    shareReplay({ bufferSize: 1, refCount: true }),
  );

  refreshNow(): void {
    this.manualRefresh$.next();
  }
}
