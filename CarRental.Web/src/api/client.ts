const API_BASE = '/api';

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { 'Content-Type': 'application/json', ...options?.headers },
    ...options,
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

import type { Car, Booking, Payment, Damage, Location, Notification, Profile } from '../types';

// Cars
export const getCars = () => request<Car[]>('/cars');
export const getCar = (id: string) => request<Car>(`/cars/${id}`);
export const createCar = (car: Partial<Car>) => request<Car>('/cars', { method: 'POST', body: JSON.stringify(car) });
export const updateCar = (id: string, car: Partial<Car>) => request<void>(`/cars/${id}`, { method: 'PUT', body: JSON.stringify({ id, ...car }) });
export const deleteCar = (id: string) => request<void>(`/cars/${id}`, { method: 'DELETE' });
export const login = (creds: any) => request<{token: string, user: Profile}>('/auth/login', { method: 'POST', body: JSON.stringify(creds) });
export const register = (data: any) => request<Profile>('/auth/register', { method: 'POST', body: JSON.stringify(data) });
export const getProfile = () => request<Profile>('/auth/me');
export const updateProfile = (data: any) => request<Profile>('/auth/me', { method: 'PUT', body: JSON.stringify(data) });

// Profiles (Admin)
export const getProfiles = () => request<Profile[]>('/profiles');

// Bookings
export const getBookings = () => request<Booking[]>('/bookings');
export const getBooking = (id: string) => request<Booking>(`/bookings/${id}`);
export const createBooking = (b: Partial<Booking>) => request<Booking>('/bookings', { method: 'POST', body: JSON.stringify(b) });
export const checkoutBooking = (payload: { booking: Partial<Booking>, paymentMethod?: string, mobileNumber?: string, provider?: string }) => request<Booking>('/bookings/checkout', { method: 'POST', body: JSON.stringify(payload) });
export const updateBooking = (id: string, b: Partial<Booking>) => request<void>(`/bookings/${id}`, { method: 'PUT', body: JSON.stringify({ id, ...b }) });
export const deleteBooking = (id: string) => request<void>(`/bookings/${id}`, { method: 'DELETE' });

// Locations
export const getLocations = () => request<Location[]>('/locations');
export const createLocation = (loc: Partial<Location>) => request<Location>('/locations', { method: 'POST', body: JSON.stringify(loc) });
export const updateLocation = (id: string, loc: Partial<Location>) => request<void>(`/locations/${id}`, { method: 'PUT', body: JSON.stringify({ id, ...loc }) });
export const deleteLocation = (id: string) => request<void>(`/locations/${id}`, { method: 'DELETE' });

// Payments
export const getPayments = () => request<Payment[]>('/payments');

// Damages
export const getDamages = () => request<Damage[]>('/damages');
export const createDamage = (d: Partial<Damage>) => request<Damage>('/damages', { method: 'POST', body: JSON.stringify(d) });
export const updateDamage = (id: string, d: Partial<Damage>) => request<void>(`/damages/${id}`, { method: 'PUT', body: JSON.stringify({ id, ...d }) });

// Notifications
export const getAdminNotifications = () => request<any[]>('/adminnotifications');
export const getAdminUnreadCount = () => request<{ count: number }>('/adminnotifications/unread-count');
export const markNotificationRead = (id: string) => request<void>(`/adminnotifications/${id}/mark-read`, { method: 'PUT' });
export const markAllNotificationsRead = () => request<void>('/adminnotifications/mark-read', { method: 'PUT' });

// Site Settings
export const getHeroImages = () => request<string[]>('/settings/hero-images');
export const updateHeroImages = (images: string[]) => request<string[]>('/settings/hero-images', { method: 'PUT', body: JSON.stringify(images) });
export const getHeroVideo = () => request<{url: string}>('/settings/hero-video');
export const updateHeroVideo = (url: string) => request<{url: string}>('/settings/hero-video', { method: 'PUT', body: JSON.stringify({ url }) });
export const deleteHeroVideo = () => request<{url: string}>('/settings/hero-video', { method: 'DELETE' });
