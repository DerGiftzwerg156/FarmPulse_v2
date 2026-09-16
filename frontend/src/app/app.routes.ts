import { Routes } from '@angular/router';
import { notStartedGuard, startedGuard } from './core/guards/savegame.guards';

export const routes: Routes = [
  { path: '', pathMatch: 'full', redirectTo: 'start' },
  {
    path: 'start',
    canActivate: [notStartedGuard],
    loadComponent: () => import('./pages/start/start.component').then((m) => m.StartComponent),
  },
  {
    path: 'dashboard',
    canActivate: [startedGuard],
    loadComponent: () => import('./pages/dashboard/dashboard.component').then((m) => m.DashboardComponent),
  },
  { path: '**', redirectTo: 'start' },
];
