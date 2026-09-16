import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, Subject, merge, shareReplay, switchMap, timer } from 'rxjs';
import { MailboxMessage } from '../models/mailbox.model';

const POLL_INTERVAL_MS = 5000;

@Injectable({ providedIn: 'root' })
export class MailboxService {
  private readonly http = inject(HttpClient);
  private readonly manualRefresh$ = new Subject<void>();

  /** Pollt die Postfach-Nachrichten alle 5 Sekunden, solange mindestens ein Abonnent aktiv ist. */
  readonly messages$: Observable<MailboxMessage[]> = merge(timer(0, POLL_INTERVAL_MS), this.manualRefresh$).pipe(
    switchMap(() => this.http.get<MailboxMessage[]>('/api/mailbox')),
    shareReplay({ bufferSize: 1, refCount: true }),
  );

  markRead(id: number): Observable<void> {
    return this.http.post<void>(`/api/mailbox/${id}/read`, {});
  }

  refreshNow(): void {
    this.manualRefresh$.next();
  }
}
