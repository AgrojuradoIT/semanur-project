export const SCHEDULER_DAY_LABELS = ['DOM', 'LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB'];
export const SCHEDULER_MONTH_SHORT = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'];

const AVATAR_COLORS = [
  '#E53935', '#D81B60', '#8E24AA', '#5E35B1',
  '#3949AB', '#1E88E5', '#039BE5', '#00ACC1',
  '#00897B', '#43A047', '#7CB342', '#C0CA33',
  '#FFB300', '#FB8C00', '#F4511E', '#6D4C41',
];

export function employeeFullName(employee) {
  if (!employee) return 'Sin nombre';
  if (employee.name) return employee.name;
  return `${employee.nombres || ''} ${employee.apellidos || ''}`.trim() || 'Sin nombre';
}

export function initials(text) {
  const parts = String(text || '').trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
  return String(text || 'SN').slice(0, 2).toUpperCase();
}

export function avatarColor(text) {
  const value = String(text || '');
  let hash = 0;
  for (let i = 0; i < value.length; i += 1) {
    hash = value.charCodeAt(i) + ((hash << 5) - hash);
  }
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

export function scheduleDateLabel(entry) {
  const date = new Date(String(entry?.fecha || '').slice(0, 10));
  if (Number.isNaN(date.getTime())) return '-';
  return date.toLocaleDateString('es-CO');
}

export function scheduleTimeLabel(entry) {
  if (entry?.hora_inicio) return String(entry.hora_inicio).slice(0, 5);
  return '08:00';
}

export function stateClass(entry) {
  const state = String(entry?.estado || '').toLowerCase();
  const isIssue = entry?.es_novedad === true || state === 'novedad' || state === 'pausado';
  if (isIssue) return 'state-issue';
  if (state === 'completado' || state === 'cerrado') return 'state-done';
  return 'state-pending';
}

export function stateIcon(entry) {
  const state = String(entry?.estado || '').toLowerCase();
  const isIssue = entry?.es_novedad === true || state === 'novedad' || state === 'pausado';
  if (isIssue) return 'warning';
  if (state === 'completado' || state === 'cerrado') return 'check_circle';
  return 'schedule';
}
