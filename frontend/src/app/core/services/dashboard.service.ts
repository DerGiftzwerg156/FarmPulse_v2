import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, Subject, merge, shareReplay, switchMap, timer } from 'rxjs';
import { DashboardResponse, HistoryPoint } from '../models/dashboard.model';

const POLL_INTERVAL_MS = 5000;
const HISTORY_LIMIT = 20;

@Injectable({ providedIn: 'root' })
export class DashboardService {
  private readonly http = inject(HttpClient);
  private readonly manualRefresh$ = new Subject<void>();

  /** Pollt den Dashboard-Zustand alle 5 Sekunden, solange die Seite geöffnet ist. */
  readonly dashboard$: Observable<DashboardResponse> = merge(timer(0, POLL_INTERVAL_MS), this.manualRefresh$).pipe(
    switchMap(() => this.http.get<DashboardResponse>('/api/dashboard')),
    shareReplay({ bufferSize: 1, refCount: true }),
  );

  readonly moneyHistory$: Observable<HistoryPoint[]> = merge(timer(0, POLL_INTERVAL_MS), this.manualRefresh$).pipe(
    switchMap(() => this.http.get<HistoryPoint[]>(`/api/dashboard/history?limit=${HISTORY_LIMIT}`)),
    shareReplay({ bufferSize: 1, refCount: true }),
  );

  /** Löst sofort einen neuen Abruf beider Streams aus, ohne auf das 5s-Intervall zu warten. */
  refreshNow(): void {
    this.manualRefresh$.next();
  }
}
