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
    path: '',
    canActivate: [startedGuard],
    loadComponent: () => import('./layout/shell/shell.component').then((m) => m.ShellComponent),
    children: [
      {
        path: 'dashboard',
        loadComponent: () => import('./pages/dashboard/dashboard.component').then((m) => m.DashboardComponent),
      },
      {
        path: 'mailbox',
        loadComponent: () => import('./pages/mailbox/mailbox.component').then((m) => m.MailboxComponent),
      },
    ],
  },
  { path: '**', redirectTo: 'start' },
];
