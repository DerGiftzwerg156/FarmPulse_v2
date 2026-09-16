import { Component, computed, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import {
  LucideActivity,
  LucideClock,
  LucideLayoutDashboard,
  LucideMail,
  LucideRefreshCw,
  LucideServer,
  LucideSettings,
  LucideSprout,
  LucideTractor,
  LucideWallet,
} from '@lucide/angular';
import { DashboardService } from '../../core/services/dashboard.service';
import { MailboxService } from '../../core/services/mailbox.service';

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [
    RouterLink,
    RouterLinkActive,
    RouterOutlet,
    LucideActivity,
    LucideClock,
    LucideLayoutDashboard,
    LucideMail,
    LucideRefreshCw,
    LucideServer,
    LucideSettings,
    LucideSprout,
    LucideTractor,
    LucideWallet,
  ],
  templateUrl: './shell.component.html',
})
export class ShellComponent {
  private readonly dashboardService = inject(DashboardService);
  private readonly mailboxService = inject(MailboxService);

  protected readonly dashboard = toSignal(this.dashboardService.dashboard$, { initialValue: null });
  protected readonly messages = toSignal(this.mailboxService.messages$, { initialValue: [] });

  protected readonly unreadMailCount = computed(() => this.messages().filter((m) => !m.read).length);

  protected readonly gameTimeLabel = computed(() => {
    const time = this.dashboard()?.gameTime;
    if (!time) {
      return '—';
    }
    const day = String(time.day).padStart(2, '0');
    const hour = String(time.hour).padStart(2, '0');
    const minute = String(time.minute).padStart(2, '0');
    return `Jahr ${time.year} · Monat ${time.month}, Tag ${day} · ${hour}:${minute}`;
  });

  refresh(): void {
    this.dashboardService.refreshNow();
    this.mailboxService.refreshNow();
  }
}
