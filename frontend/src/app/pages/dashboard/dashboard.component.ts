import { Component, computed, inject, signal } from '@angular/core';
import { CurrencyPipe, DecimalPipe } from '@angular/common';
import { toSignal } from '@angular/core/rxjs-interop';
import { RouterLink } from '@angular/router';
import {
  LucideArrowRight,
  LucideMail,
  LucideSprout,
  LucideTractor,
  LucideTriangleAlert,
  LucideWallet,
} from '@lucide/angular';
import { DashboardService } from '../../core/services/dashboard.service';
import { MailboxService } from '../../core/services/mailbox.service';
import { MailboxMessage } from '../../core/models/mailbox.model';
import { HeroStatComponent } from '../../shared/components/hero-stat/hero-stat.component';
import { SparklineComponent } from '../../shared/components/sparkline/sparkline.component';
import { MailboxMessageModalComponent } from '../../shared/components/mailbox-message-modal/mailbox-message-modal.component';

const MAILBOX_PREVIEW_LIMIT = 5;

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CurrencyPipe,
    DecimalPipe,
    RouterLink,
    HeroStatComponent,
    SparklineComponent,
    MailboxMessageModalComponent,
    LucideArrowRight,
    LucideMail,
    LucideSprout,
    LucideTractor,
    LucideTriangleAlert,
    LucideWallet,
  ],
  templateUrl: './dashboard.component.html',
})
export class DashboardComponent {
  private readonly dashboardService = inject(DashboardService);
  private readonly mailboxService = inject(MailboxService);

  protected readonly dashboard = toSignal(this.dashboardService.dashboard$, { initialValue: null });
  protected readonly history = toSignal(this.dashboardService.moneyHistory$, { initialValue: [] });
  protected readonly messages = toSignal(this.mailboxService.messages$, { initialValue: [] });

  protected readonly moneyValues = computed(() => this.history().map((point) => point.money));
  protected readonly previewMessages = computed(() => this.messages().slice(0, MAILBOX_PREVIEW_LIMIT));
  protected readonly unreadMailCount = computed(() => this.messages().filter((m) => !m.read).length);

  protected readonly selectedMessage = signal<MailboxMessage | null>(null);

  openMessage(message: MailboxMessage): void {
    this.selectedMessage.set(message);
    if (!message.read) {
      this.mailboxService.markRead(message.id).subscribe(() => this.mailboxService.refreshNow());
    }
  }

  closeMessage(): void {
    this.selectedMessage.set(null);
  }
}
