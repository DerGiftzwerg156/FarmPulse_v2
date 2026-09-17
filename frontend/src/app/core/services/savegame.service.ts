import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, shareReplay, switchMap, timer } from 'rxjs';
import { SavegameStatus } from '../models/savegame-status.model';

const POLL_INTERVAL_MS = 5000;

@Injectable({ providedIn: 'root' })
export class SavegameService {
  private readonly http = inject(HttpClient);

  /** Pollt den Savegame-Status alle 5 Sekunden, solange mindestens ein Abonnent aktiv ist. */
  readonly status$: Observable<SavegameStatus> = timer(0, POLL_INTERVAL_MS).pipe(
    switchMap(() => this.http.get<SavegameStatus>('/api/savegame')),
    shareReplay({ bufferSize: 1, refCount: true }),
  );

  fetchStatus(): Observable<SavegameStatus> {
    return this.http.get<SavegameStatus>('/api/savegame');
  }

  submitBackstory(backstory: string): Observable<SavegameStatus> {
    return this.http.post<SavegameStatus>('/api/savegame/backstory', { backstory });
  }
}
