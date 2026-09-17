import { Component, computed, effect, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { LucideSprout, LucideCheck, LucideLoaderCircle, LucideCircleDashed } from '@lucide/angular';
import { SavegameService } from '../../core/services/savegame.service';
import { SavegameStatus } from '../../core/models/savegame-status.model';

interface ProgressStep {
  label: string;
  done: (status: SavegameStatus) => boolean;
}

const STEPS: ProgressStep[] = [
  { label: 'Vorgeschichte eingegeben', done: (s) => s.backstorySubmitted },
  { label: 'Telemetrie empfangen (telemetry.json)', done: (s) => s.telemetryPolled },
  { label: 'Welt empfangen (world.json)', done: (s) => s.worldPolled },
  { label: 'Farmdaten empfangen (farm.json)', done: (s) => s.farmDataPolled },
];

@Component({
  selector: 'app-start',
  standalone: true,
  imports: [FormsModule, LucideSprout, LucideCheck, LucideLoaderCircle, LucideCircleDashed],
  templateUrl: './start.component.html',
})
export class StartComponent {
  private readonly savegameService = inject(SavegameService);
  private readonly router = inject(Router);

  protected readonly status = toSignal(this.savegameService.status$, { initialValue: null });
  protected readonly steps = STEPS;

  protected readonly backstory = signal('');
  protected readonly submitting = signal(false);
  protected readonly errorMessage = signal<string | null>(null);

  protected readonly backstorySubmitted = computed(() => this.status()?.backstorySubmitted ?? false);

  constructor() {
    // Sobald das Savegame vollständig gestartet ist, zur Dashboard-Landingpage wechseln.
    effect(() => {
      if (this.status()?.started) {
        this.router.navigateByUrl('/dashboard');
      }
    });
  }

  submit(): void {
    const text = this.backstory().trim();
    if (!text) {
      this.errorMessage.set('Die Vorgeschichte darf nicht leer sein.');
      return;
    }
    this.submitting.set(true);
    this.errorMessage.set(null);
    this.savegameService.submitBackstory(text).subscribe({
      next: () => {
        this.submitting.set(false);
      },
      error: (err) => {
        this.submitting.set(false);
        this.errorMessage.set(
          err?.error?.message ?? 'Die Vorgeschichte konnte nicht gespeichert werden.',
        );
      },
    });
  }

  isDone(step: ProgressStep): boolean {
    const current = this.status();
    return current ? step.done(current) : false;
  }
}
