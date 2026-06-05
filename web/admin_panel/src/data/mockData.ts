// Static helper data for the admin panel. All operational data now comes from
// the API; only a few constants live here.
import { NEIGHBORHOOD } from '../lib/meta';

/** Suggested contractors offered when assigning a report. */
export const contractors = [
  'Energo Service LLP',
  'Water Pro KZ',
  'Road Master',
  'Clean City',
  'Security Plus',
];

/** Pre-filled WhatsApp invitation text for a new resident. */
export function inviteMessage(address: string, code: string): string {
  const nbhd =
    (typeof localStorage !== 'undefined' && localStorage.getItem('korshi_admin_nbhd')) || NEIGHBORHOOD;
  return [
    'Здравствуйте!',
    `Вас подключили к приложению района ${nbhd}.`,
    `Адрес: ${address}`,
    `Код активации: ${code}`,
    'Скачайте приложение и установите пароль при первом входе.',
  ].join('\n');
}
