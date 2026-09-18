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
      {
        path: 'fields',
        loadComponent: () => import('./pages/fields/fields.component').then((m) => m.FieldsComponent),
      },
      {
        path: 'fleet',
        loadComponent: () => import('./pages/vehicles/vehicles.component').then((m) => m.VehiclesComponent),
      },
      {
        path: 'finance',
        loadComponent: () => import('./pages/finance/finance.component').then((m) => m.FinanceComponent),
      },
      {
        path: 'storage',
        loadComponent: () => import('./pages/storage/storage.component').then((m) => m.StorageComponent),
      },
    ],
  },
  { path: '**', redirectTo: 'start' },
];
