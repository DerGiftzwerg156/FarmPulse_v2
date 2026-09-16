import { Component, computed, input } from '@angular/core';

@Component({
  selector: 'app-sparkline',
  standalone: true,
  template: `
    <svg viewBox="0 0 100 28" preserveAspectRatio="none" class="h-7 w-full">
      <polyline [attr.points]="linePoints()" fill="none" stroke="#38B000" stroke-width="1.5" vector-effect="non-scaling-stroke" />
      <polyline [attr.points]="areaPoints()" fill="#38B000" opacity="0.12" />
    </svg>
  `,
})
export class SparklineComponent {
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
