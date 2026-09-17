import { Component, input, output } from '@angular/core';
import {
  LucideBanknote,
  LucideCloudRain,
  LucideLandmark,
  LucideMail,
  LucideMegaphone,
  LucideUsers,
  LucideWrench,
  LucideX,
} from '@lucide/angular';
import { MailboxMessage } from '../../../core/models/mailbox.model';

@Component({
  selector: 'app-mailbox-message-modal',
  standalone: true,
  imports: [
    LucideBanknote,
    LucideCloudRain,
    LucideLandmark,
    LucideMail,
    LucideMegaphone,
    LucideUsers,
    LucideWrench,
    LucideX,
  ],
  templateUrl: './mailbox-message-modal.component.html',
})
export class MailboxMessageModalComponent {
  readonly message = input<MailboxMessage | null>(null);
  readonly closed = output<void>();

  categoryIcon(category: string): string {
    switch (category) {
      case 'MARKET':
        return 'banknote';
      case 'EQUIPMENT':
        return 'wrench';
      case 'STAFFING':
      case 'PAYROLL':
        return 'users';
      case 'WEATHER':
        return 'cloud-rain';
      case 'AUTHORITY':
      case 'BANK':
        return 'landmark';
      case 'PRESS':
        return 'megaphone';
      default:
        return 'mail';
    }
  }

  gameTimeLabel(message: MailboxMessage): string {
    const day = String(message.gameDay).padStart(2, '0');
    const hour = String(message.gameHour).padStart(2, '0');
    const minute = String(message.gameMinute).padStart(2, '0');
    return `Tag ${day}, ${hour}:${minute}`;
  }

  priorityLabel(message: MailboxMessage): string {
    return message.priority === 'HIGH' ? 'hoch' : message.priority === 'MEDIUM' ? 'mittel' : 'niedrig';
  }

  close(): void {
    this.closed.emit();
  }
}
