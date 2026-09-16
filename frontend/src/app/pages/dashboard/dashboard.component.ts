import { Component, computed, inject, signal } from '@angular/core';
import { CurrencyPipe, DecimalPipe } from '@angular/common';
import { toSignal } from '@angular/core/rxjs-interop';
import { RouterLink } from '@angular/router';
import {
  LucideArrowRight,
  LucideBanknote,
  LucideCloudRain,
  LucideLandmark,
  LucideMail,
  LucideMegaphone,
  LucideSprout,
  LucideTractor,
  LucideTriangleAlert,
  LucideUsers,
  LucideWallet,
  LucideWrench,
} from '@lucide/angular';
import { DashboardService } from '../../core/services/dashboard.service';
import { MailboxService } from '../../core/services/mailbox.service';
import { FieldsService } from '../../core/services/fields.service';
import { MailboxMessage } from '../../core/models/mailbox.model';
import { FieldsResponse } from '../../core/models/fields.model';
import { HeroStatComponent } from '../../shared/components/hero-stat/hero-stat.component';
import { SparklineComponent } from '../../shared/components/sparkline/sparkline.component';
import { MailboxMessageModalComponent } from '../../shared/components/mailbox-message-modal/mailbox-message-modal.component';
import { fieldCropLabel, fieldGrowthPercent, fieldStatus, fieldStatusLabel } from '../../core/utils/field-status.util';
import { mailboxCategoryIcon, mailboxGameTimeLabel, mailboxPriorityLabel } from '../../core/utils/mailbox-category.util';

const MAILBOX_PREVIEW_LIMIT = 5;
const FIELDS_PREVIEW_LIMIT = 6;
const EMPTY_FIELDS: FieldsResponse = { count: 0, totalAreaHa: 0, totalValue: 0, totalEstimatedYieldLiters: 0, items: [] };

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
    LucideBanknote,
    LucideCloudRain,
    LucideLandmark,
    LucideMail,
    LucideMegaphone,
    LucideSprout,
    LucideTractor,
    LucideTriangleAlert,
    LucideUsers,
    LucideWallet,
    LucideWrench,
  ],
  templateUrl: './dashboard.component.html',
})
export class DashboardComponent {
  private readonly dashboardService = inject(DashboardService);
  private readonly mailboxService = inject(MailboxService);
  private readonly fieldsService = inject(FieldsService);

  protected readonly dashboard = toSignal(this.dashboardService.dashboard$, { initialValue: null });
  protected readonly history = toSignal(this.dashboardService.moneyHistory$, { initialValue: [] });
  protected readonly messages = toSignal(this.mailboxService.messages$, { initialValue: [] });
  protected readonly fields = toSignal(this.fieldsService.fields$, { initialValue: EMPTY_FIELDS });

  protected readonly moneyValues = computed(() => this.history().map((point) => point.money));
  protected readonly previewMessages = computed(() => this.messages().slice(0, MAILBOX_PREVIEW_LIMIT));
  protected readonly unreadMailCount = computed(() => this.messages().filter((m) => !m.read).length);
  protected readonly previewFields = computed(() => this.fields().items.slice(0, FIELDS_PREVIEW_LIMIT));

  protected readonly selectedMessage = signal<MailboxMessage | null>(null);

  protected readonly cropLabel = fieldCropLabel;
  protected readonly fieldStatus = fieldStatus;
  protected readonly fieldStatusLabel = fieldStatusLabel;
  protected readonly growthPercent = fieldGrowthPercent;

  protected readonly categoryIcon = mailboxCategoryIcon;
  protected readonly gameTimeLabel = mailboxGameTimeLabel;
  protected readonly priorityLabel = mailboxPriorityLabel;

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
