import { Component, computed, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormsModule } from '@angular/forms';
import {
  LucideBanknote,
  LucideCheck,
  LucideCloudRain,
  LucideLandmark,
  LucideMail,
  LucideMegaphone,
  LucideSearch,
  LucideUsers,
  LucideWrench,
} from '@lucide/angular';
import { MailboxService } from '../../core/services/mailbox.service';
import { MailboxMessage } from '../../core/models/mailbox.model';
import { MailboxMessageModalComponent } from '../../shared/components/mailbox-message-modal/mailbox-message-modal.component';
import { mailboxCategoryIcon, mailboxGameTimeLabel } from '../../core/utils/mailbox-category.util';

interface CategoryFilter {
  label: string;
  value: string | null;
}

const CATEGORIES: CategoryFilter[] = [
  { label: 'Alle', value: null },
  { label: 'Markt', value: 'MARKET' },
  { label: 'Ausrüstung', value: 'EQUIPMENT' },
  { label: 'Personal', value: 'STAFFING' },
  { label: 'Gehalt', value: 'PAYROLL' },
  { label: 'Wetter', value: 'WEATHER' },
  { label: 'Behörde', value: 'AUTHORITY' },
  { label: 'Bank', value: 'BANK' },
  { label: 'Öffentlichkeit', value: 'PRESS' },
];

@Component({
  selector: 'app-mailbox',
  standalone: true,
  imports: [
    FormsModule,
    MailboxMessageModalComponent,
    LucideBanknote,
    LucideCheck,
    LucideCloudRain,
    LucideLandmark,
    LucideMail,
    LucideMegaphone,
    LucideSearch,
    LucideUsers,
    LucideWrench,
  ],
  templateUrl: './mailbox.component.html',
})
export class MailboxComponent {
  private readonly mailboxService = inject(MailboxService);

  protected readonly messages = toSignal(this.mailboxService.messages$, { initialValue: [] });
  protected readonly categories = CATEGORIES;

  protected readonly search = signal('');
  protected readonly onlyUnread = signal(false);
  protected readonly activeCategory = signal<string | null>(null);

  protected readonly unreadCount = computed(() => this.messages().filter((m) => !m.read).length);
  protected readonly selectedMessage = signal<MailboxMessage | null>(null);

  protected readonly filteredMessages = computed(() => {
    const search = this.search().trim().toLowerCase();
    const onlyUnread = this.onlyUnread();
    const category = this.activeCategory();

    return this.messages().filter((message) => {
      if (onlyUnread && message.read) {
        return false;
      }
      if (category && message.category !== category) {
        return false;
      }
      if (search) {
        const haystack = `${message.sender} ${message.subject} ${message.body}`.toLowerCase();
        if (!haystack.includes(search)) {
          return false;
        }
      }
      return true;
    });
  });

  protected readonly categoryIcon = mailboxCategoryIcon;
  protected readonly gameTimeLabel = mailboxGameTimeLabel;

  selectCategory(value: string | null): void {
    this.activeCategory.set(value);
  }

  toggleOnlyUnread(): void {
    this.onlyUnread.update((value) => !value);
  }

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
