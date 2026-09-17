import { GameTime } from '../models/dashboard.model';

/** "Jahr 3 · Monat 6, Tag 47 · 08:01" - gemeinsam genutzt von TopBar und Dashboard-Hero-Kachel. */
export function gameTimeLabel(time: GameTime | null | undefined): string {
  if (!time) {
    return '—';
  }
  const day = String(time.day).padStart(2, '0');
  const hour = String(time.hour).padStart(2, '0');
  const minute = String(time.minute).padStart(2, '0');
  return `Jahr ${time.year} · Monat ${time.month}, Tag ${day} · ${hour}:${minute}`;
}
