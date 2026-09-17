import { Component, computed, input } from '@angular/core';

@Component({
  selector: 'app-sparkline',
  standalone: true,
  template: `
    <svg viewBox="0 0 100 28" preserveAspectRatio="none" class="h-full w-full">
      <defs>
        <linearGradient [attr.id]="gradientId" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="#38B000" stop-opacity="0.4" />
          <stop offset="100%" stop-color="#38B000" stop-opacity="0" />
        </linearGradient>
      </defs>
      <polyline [attr.points]="areaPoints()" [attr.fill]="'url(#' + gradientId + ')'" stroke="none" />
      <polyline [attr.points]="linePoints()" fill="none" stroke="#38B000" stroke-width="1.5" vector-effect="non-scaling-stroke" />
    </svg>
  `,
})
export class SparklineComponent {
  private static nextId = 0;

  protected readonly gradientId = `sparkline-fill-${SparklineComponent.nextId++}`;

  readonly values = input.required<number[]>();

  private readonly coords = computed(() => {
    const values = this.values();
    if (values.length < 2) {
      return [] as { x: number; y: number }[];
    }
    const min = Math.min(...values);
    const max = Math.max(...values);
    const range = max - min || 1;
    const step = 100 / (values.length - 1);
    return values.map((value, index) => ({
      x: index * step,
      y: 28 - ((value - min) / range) * 28,
    }));
  });

  readonly linePoints = computed(() => this.coords().map((c) => `${c.x},${c.y}`).join(' '));

  readonly areaPoints = computed(() => {
    const coords = this.coords();
    if (coords.length === 0) {
      return '';
    }
    const last = coords[coords.length - 1];
    return `0,28 ${this.linePoints()} ${last.x},28`;
  });
}
