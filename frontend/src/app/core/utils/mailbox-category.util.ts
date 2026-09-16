import { MailboxMessage } from '../models/mailbox.model';

/** Icon-Name (siehe @lucide/angular) je Nachrichtenkategorie - gemeinsam genutzt von Postfach-Seite und Dashboard-Vorschau. */
export function mailboxCategoryIcon(category: string): string {
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
      return 'landmark';
    case 'BANK':
      return 'landmark';
    case 'PRESS':
      return 'megaphone';
    default:
      return 'mail';
  }
}

export function mailboxGameTimeLabel(message: MailboxMessage): string {
  const day = String(message.gameDay).padStart(2, '0');
  const hour = String(message.gameHour).padStart(2, '0');
  const minute = String(message.gameMinute).padStart(2, '0');
  return `Tag ${day}, ${hour}:${minute}`;
}

export function mailboxPriorityLabel(priority: MailboxMessage['priority']): string {
  switch (priority) {
    case 'HIGH':
      return 'Hoch';
    case 'MEDIUM':
      return 'Mittel';
    default:
      return 'Niedrig';
  }
}
