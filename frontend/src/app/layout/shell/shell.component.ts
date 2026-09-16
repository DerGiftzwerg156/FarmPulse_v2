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
import { WeatherType } from '../../core/models/dashboard.model';

const WEATHER_LABELS: Record<WeatherType, string> = {
  SUN: 'Sonnig',
  PARTIALLY_CLOUDY: 'Leicht bewölkt',
  CLOUDY: 'Bewölkt',
  RAIN: 'Regen',
  SNOW: 'Schnee',
  HAIL: 'Hagel',
  THUNDER: 'Gewitter',
  TWISTER: 'Tornado',
  UNKNOWN: 'Unbekannt',
};

const WEATHER_ICONS: Record<WeatherType, string> = {
  SUN: 'sun',
  PARTIALLY_CLOUDY: 'cloud',
  CLOUDY: 'cloud',
  RAIN: 'cloud-rain',
  SNOW: 'cloud-snow',
  HAIL: 'cloud-hail',
  THUNDER: 'cloud-lightning',
  TWISTER: 'tornado',
  UNKNOWN: 'cloud',
};

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

  protected readonly weatherLabel = computed(() => {
    const weather = this.dashboard()?.weather;
    if (!weather) {
      return '—';
    }
    const temp = Math.round(weather.temperature);
    return `${temp}° · ${WEATHER_LABELS[weather.type] ?? weather.type}`;
  });

  protected readonly weatherIcon = computed(() => {
    const type = this.dashboard()?.weather?.type;
    return type ? (WEATHER_ICONS[type] ?? 'cloud') : 'cloud';
  });

  refresh(): void {
    this.dashboardService.refreshNow();
    this.mailboxService.refreshNow();
  }
}
