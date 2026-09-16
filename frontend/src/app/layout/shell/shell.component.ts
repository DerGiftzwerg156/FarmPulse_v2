import { Component, computed, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import {
  LucideActivity,
  LucideClock,
  LucideCloud,
  LucideCloudHail,
  LucideCloudLightning,
  LucideCloudRain,
  LucideCloudSnow,
  LucideLayoutDashboard,
  LucideMail,
  LucideRefreshCw,
  LucideServer,
  LucideSettings,
  LucideSprout,
  LucideSun,
  LucideTornado,
  LucideTractor,
  LucideWallet,
} from '@lucide/angular';
import { DashboardService } from '../../core/services/dashboard.service';
import { MailboxService } from '../../core/services/mailbox.service';
import { gameTimeLabel } from '../../core/utils/game-time.util';
import { weatherIconName, weatherLabel } from '../../core/utils/weather.util';

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [
    RouterLink,
    RouterLinkActive,
    RouterOutlet,
    LucideActivity,
    LucideClock,
    LucideCloud,
    LucideCloudHail,
    LucideCloudLightning,
    LucideCloudRain,
    LucideCloudSnow,
    LucideLayoutDashboard,
    LucideMail,
    LucideRefreshCw,
    LucideServer,
    LucideSettings,
    LucideSprout,
    LucideSun,
    LucideTornado,
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

  protected readonly gameTimeLabel = computed(() => gameTimeLabel(this.dashboard()?.gameTime));

  protected readonly weatherLabel = computed(() => weatherLabel(this.dashboard()?.weather));

  protected readonly weatherIcon = computed(() => weatherIconName(this.dashboard()?.weather?.type ?? 'UNKNOWN'));

  refresh(): void {
    this.dashboardService.refreshNow();
    this.mailboxService.refreshNow();
  }
}
