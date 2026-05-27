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
  return res.json() as Promise<T>;
}

import type { Car, Booking, Payment, Damage, Location, Notification, ZraInvoice } from '../types';

// Cars
export const getCars = () => request<Car[]>('/cars');
export const getCar = (id: string) => request<Car>(`/cars/${id}`);
export const createCar = (car: Partial<Car>) => request<Car>('/cars', { method: 'POST', body: JSON.stringify(car) });
export const updateCar = (id: string, car: Partial<Car>) => request<void>(`/cars/${id}`, { method: 'PUT', body: JSON.stringify({ id, ...car }) });
export const deleteCar = (id: string) => request<void>(`/cars/${id}`, { method: 'DELETE' });

// Bookings
export const getBookings = () => request<Booking[]>('/bookings');
export const getBooking = (id: string) => request<Booking>(`/bookings/${id}`);
export const checkoutBooking = (booking: Partial<Booking>) => request<Booking>('/bookings/checkout', { method: 'POST', body: JSON.stringify(booking) });
export const updateBooking = (id: string, b: Partial<Booking>) => request<void>(`/bookings/${id}`, { method: 'PUT', body: JSON.stringify({ id, ...b }) });
export const deleteBooking = (id: string) => request<void>(`/bookings/${id}`, { method: 'DELETE' });

// Locations
export const getLocations = () => request<Location[]>('/locations');

// Payments
export const getPayments = () => request<Payment[]>('/payments');

// Damages
export const getDamages = () => request<Damage[]>('/damages');

// Notifications
export const getNotifications = () => request<Notification[]>('/notifications');
export const markNotificationRead = (id: string) => request<void>(`/notifications/${id}/read`, { method: 'PUT' });

// ZRA Invoices
export const getInvoices = () => request<ZraInvoice[]>('/zrainvoices');

// Site Settings
export const getHeroImages = () => request<string[]>('/settings/hero-images');
export const updateHeroImages = (images: string[]) => request<string[]>('/settings/hero-images', { method: 'PUT', body: JSON.stringify(images) });

