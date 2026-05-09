export const TOKEN_KEY = 'semanur_token';
export const USER_KEY = 'semanur_user';
export const AUTH_UNAUTHORIZED_EVENT = 'semanur:auth:unauthorized';

export function getStoredToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function getStoredUser() {
  const savedUser = localStorage.getItem(USER_KEY);
  return savedUser ? JSON.parse(savedUser) : null;
}

export function persistStoredSession(token, user) {
  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(USER_KEY, JSON.stringify(user));
}

export function clearStoredSession() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
}
