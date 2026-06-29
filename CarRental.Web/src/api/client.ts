import { supabase } from '../lib/supabase';

const API_BASE = import.meta.env.PROD 
  ? 'https://anchorpro-drive-production.up.railway.app/api' 
  : '/api';

// ── In-memory cache ──────────────────────────────────────────────────────────
// Caches GET responses so repeat navigations are instant (stale-while-revalidate).
// TTL: 60s for cars, 300s for locations. Writes always bypass the cache.
const _cache = new Map<string, { data: any; expires: number }>();

function cacheGet<T>(key: string): T | null {
  const entry = _cache.get(key);
  if (entry && Date.now() < entry.expires) return entry.data as T;
  return null;
}

function cacheSet(key: string, data: any, ttlMs: number) {
  _cache.set(key, { data, expires: Date.now() + ttlMs });
}

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const { data: { session } } = await supabase.auth.getSession();
  const token = session?.access_token;
  
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...options?.headers,
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `HTTP ${res.status}`);
  }

  if (res.status === 204) {
    return null as any;
  }

  return res.json() as Promise<T>;
}

// Cached GET — returns cached data instantly if fresh, fetches otherwise.
// Also revalidates in background so next call is always fast.
async function cachedGet<T>(path: string, ttlMs: number): Promise<T> {
  const cached = cacheGet<T>(path);
  if (cached !== null) {
    // Revalidate in background (stale-while-revalidate)
    request<T>(path).then(data => cacheSet(path, data, ttlMs)).catch(() => {});
    return cached;
  }
  const data = await request<T>(path);
  cacheSet(path, data, ttlMs);
  return data;
}

// Warm up Railway immediately — fires and forgets so the server is hot
// before the user actually needs data.
export function warmupApi() {
  fetch(`${API_BASE}/health`).catch(() => {});
}

import type { Car, Booking, Payment, Damage, Location, Notification, Profile } from '../types';

// Cars
export const getMe = () => request<Profile>('/Profiles/me');
export const getCars = () => cachedGet<Car[]>('/cars', 60_000);
export const getCar = (id: string) => cachedGet<Car>(`/cars/${id}`, 60_000);
export const createCar = (car: Partial<Car>) => { _cache.delete('/cars'); return request<Car>('/cars', { method: 'POST', body: JSON.stringify(car) }); };
export const updateCar = (id: string, car: Partial<Car>) => { _cache.delete('/cars'); _cache.delete(`/cars/${id}`); return request<void>(`/cars/${id}`, { method: 'PUT', body: JSON.stringify({ id, ...car }) }); };
export const deleteCar = (id: string) => { _cache.delete('/cars'); _cache.delete(`/cars/${id}`); return request<void>(`/cars/${id}`, { method: 'DELETE' }); };
export const login = (creds: any) => request<{token: string, user: Profile}>('/auth/login', { method: 'POST', body: JSON.stringify(creds) });
export const register = (data: any) => request<Profile>('/auth/register', { method: 'POST', body: JSON.stringify(data) });
export const getProfile = () => request<Profile>('/Profiles/me');
export const createProfile = (data: any) => request<Profile>('/Profiles', { method: 'POST', body: JSON.stringify(data) });
export const updateProfile = (id: string, data: any) => request<Profile>(`/Profiles/${id}`, { method: 'PUT', body: JSON.stringify({ id, ...data }) });

// Profiles (Admin)
export const getProfiles = () => request<Profile[]>('/profiles');
export const toggleAdminProfile = (id: string) => request<Profile>(`/profiles/${id}/toggle-admin`, { method: 'PUT' });
export const toggleSuspendProfile = (id: string) => request<Profile>(`/profiles/${id}/toggle-suspend`, { method: 'PUT' });
export const deleteProfile = (id: string) => request<void>(`/profiles/${id}`, { method: 'DELETE' });
export const cleanupOrphans = () => request<{deleted: number}>('/profiles/cleanup-orphans', { method: 'DELETE' });

// Bookings
export const getBookings = () => request<Booking[]>('/bookings');
export const getBooking = (id: string) => request<Booking>(`/bookings/${id}`);
export const createBooking = (b: Partial<Booking>) => request<Booking>('/bookings', { method: 'POST', body: JSON.stringify(b) });
export const checkoutBooking = (payload: { booking: Partial<Booking>, paymentMethod?: string, mobileNumber?: string, provider?: string }) => request<Booking>('/bookings/checkout', { method: 'POST', body: JSON.stringify(payload) });
export const updateBooking = (id: string, b: Partial<Booking>) => request<void>(`/bookings/${id}`, { method: 'PUT', body: JSON.stringify({ id, ...b }) });
export const deleteBooking = (id: string) => request<void>(`/bookings/${id}`, { method: 'DELETE' });

// Locations
export const getLocations = () => cachedGet<Location[]>('/locations', 300_000);
export const createLocation = (loc: Partial<Location>) => { _cache.delete('/locations'); return request<Location>('/locations', { method: 'POST', body: JSON.stringify(loc) }); };
export const updateLocation = (id: string, loc: Partial<Location>) => { _cache.delete('/locations'); return request<void>(`/locations/${id}`, { method: 'PUT', body: JSON.stringify({ id, ...loc }) }); };
export const deleteLocation = (id: string) => { _cache.delete('/locations'); return request<void>(`/locations/${id}`, { method: 'DELETE' }); };

// Payments
export const getPayments = () => request<Payment[]>('/payments');
export const createPayment = (p: Partial<Payment>) => request<Payment>('/payments', { method: 'POST', body: JSON.stringify(p) });

// Damages
export const getDamages = () => request<Damage[]>('/damages');
export const createDamage = (d: Partial<Damage>) => request<Damage>('/damages', { method: 'POST', body: JSON.stringify(d) });
export const updateDamage = (id: string, d: Partial<Damage>) => request<void>(`/damages/${id}`, { method: 'PUT', body: JSON.stringify({ id, ...d }) });
export const deleteDamage = (id: string) => request<void>(`/damages/${id}`, { method: 'DELETE' });

// Notifications
export const getAdminNotifications = () => request<any[]>('/adminnotifications');
export const getAdminUnreadCount = () => request<{ count: number }>('/adminnotifications/unread-count');
export const markNotificationRead = (id: string) => request<void>(`/adminnotifications/${id}/mark-read`, { method: 'PUT' });
export const markAllNotificationsRead = () => request<void>('/adminnotifications/mark-read', { method: 'PUT' });

// Site Settings
export const getHeroImages = () => cachedGet<string[]>('/settings/hero-images', 300_000);
export const updateHeroImages = (images: string[]) => { _cache.delete('/settings/hero-images'); return request<string[]>('/settings/hero-images', { method: 'PUT', body: JSON.stringify(images) }); };
export const getHeroVideo = () => cachedGet<{url: string}>('/settings/hero-video', 300_000);
export const updateHeroVideo = (url: string) => { _cache.delete('/settings/hero-video'); return request<{url: string}>('/settings/hero-video', { method: 'PUT', body: JSON.stringify({ url }) }); };
export const deleteHeroVideo = () => { _cache.delete('/settings/hero-video'); return request<{url: string}>('/settings/hero-video', { method: 'DELETE' }); };

// Email Settings
export const getEmailConfig = () => request<{ smtpHost: string; smtpPort: string; senderEmail: string; senderName: string; appPassword: string; adminEmail: string }>('/settings/email-config');
export const saveEmailConfig = (config: { smtpHost: string; smtpPort: string; senderEmail: string; senderName: string; appPassword: string; adminEmail: string }) =>
  request<{ message: string }>('/settings/email-config', { method: 'PUT', body: JSON.stringify(config) });
export const sendTestEmail = (toEmail: string) =>
  request<{ message: string }>('/settings/email-config/test', { method: 'POST', body: JSON.stringify({ toEmail }) });
