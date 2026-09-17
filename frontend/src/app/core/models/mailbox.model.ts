export type MailboxPriority = 'HIGH' | 'MEDIUM' | 'LOW';

export interface MailboxMessage {
  id: number;
  sender: string;
  subject: string;
  body: string;
  category: string;
  priority: MailboxPriority;
  gameYear: number;
  gameMonth: number;
  gameDay: number;
  gameHour: number;
  gameMinute: number;
  read: boolean;
  createdAt: string;
}
