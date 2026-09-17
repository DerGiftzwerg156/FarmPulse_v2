import { Component, input } from '@angular/core';

@Component({
  selector: 'app-hero-stat',
  standalone: true,
  templateUrl: './hero-stat.component.html',
})
export class HeroStatComponent {
  readonly label = input.required<string>();
  readonly value = input.required<string>();
  readonly sub = input<string | null>(null);
  readonly accent = input<'accent' | 'warn'>('accent');
}
