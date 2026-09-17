import { WeatherInfo, WeatherType } from '../models/dashboard.model';

const WEATHER_LABELS: Record<WeatherType, string> = {
  SUN: 'Sonnig',
  PARTIALLY_CLOUDY: 'Leicht bewölkt',
  CLOUDY: 'Bewölkt',
  RAIN: 'Regen',
  SNOW: 'Schnee',
  HAIL: 'Hagel',
  THUNDER: 'Gewitter',
  TWISTER: 'Tornado',
  UNKNOWN: 'Unbekannt',
};

const WEATHER_ICONS: Record<WeatherType, string> = {
  SUN: 'sun',
  PARTIALLY_CLOUDY: 'cloud',
  CLOUDY: 'cloud',
  RAIN: 'cloud-rain',
  SNOW: 'cloud-snow',
  HAIL: 'cloud-hail',
  THUNDER: 'cloud-lightning',
  TWISTER: 'tornado',
  UNKNOWN: 'cloud',
};

/** Textlabel des Wettertyps (ohne Temperatur) - gemeinsam genutzt von TopBar und Dashboard-Hero-Kachel. */
export function weatherTypeLabel(type: WeatherType): string {
  return WEATHER_LABELS[type] ?? type;
}

/** Icon-Name (siehe @lucide/angular) des Wettertyps. */
export function weatherIconName(type: WeatherType): string {
  return WEATHER_ICONS[type] ?? 'cloud';
}

/** "12° · Sonnig" - kombiniertes Label wie in der TopBar. */
export function weatherLabel(weather: WeatherInfo | null | undefined): string {
  if (!weather) {
    return '—';
  }
  return `${Math.round(weather.temperature)}° · ${weatherTypeLabel(weather.type)}`;
}
