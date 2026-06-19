# Architecture Guide

This document outlines the architectural decisions, directory structure, and data flow of the `CarRental.Web` application.

## 1. Directory Structure
```text
CarRental.Web/
├── public/                 # Static assets (images, favicon)
├── src/
│   ├── components/         # Reusable React components
│   │   ├── admin/          # Admin-specific components (e.g., Sidebar, Modals)
│   │   ├── auth/           # Route protectors (ProtectedRoute, AdminRoute)
│   │   ├── layout/         # Navbar, Footer, and AdminLayout
│   │   └── ...             # Generic UI components (WhatsAppBubble, etc.)
│   ├── contexts/           # React Contexts (AuthContext, CurrencyContext)
│   ├── pages/              # Top-level route components
│   │   ├── admin/          # Admin portal pages
│   │   └── ...             # Public facing pages (Home, Fleet, etc.)
│   ├── services/           # Data fetching and API integration (api.ts)
│   ├── store/              # Redux slices and store configuration
│   ├── types/              # TypeScript interface definitions
│   ├── App.tsx             # Root component mapping Routes
│   └── main.tsx            # React application entry point
├── package.json
└── vite.config.ts          # Vite bundler configuration
```

## 2. Routing (`react-router-dom`)
The application relies on `react-router-dom` v7 for client-side routing.
Routes are split into three categories in `App.tsx`:
1. **Public Routes**: Accessible by anyone (`/`, `/fleet`, `/services`, `/contact`, `/login`).
2. **Protected Routes**: Wrapped by `<ProtectedRoute />`. Requires a valid user session. (`/bookings`, `/profile`).
3. **Admin Routes**: Wrapped by `<AdminRoute />`. Requires the user to have the `isAdmin` boolean set to true in their database profile. (`/admin/*`).

## 3. State Management
The application employs a hybrid state management approach:
- **React Context API:** Used for truly global, infrequently changing state.
  - `AuthContext`: Tracks the current authenticated user session and triggers Supabase listeners.
  - `CurrencyContext`: Handles the toggle between USD and ZMW, providing a conversion function to all nested components.
- **Redux Toolkit:** Used for complex feature states, though much of the data fetching is handled directly via custom hooks or standard state within components.

## 4. Authentication Flow (Supabase)
Authentication is completely offloaded to Supabase.
1. **Login:** Users log in via email/password through the Supabase client (`supabase.auth.signInWithPassword`).
2. **Session Storage:** Supabase securely stores the JWT session in `localStorage`.
3. **Profile Hydration:** `AuthContext` listens for `onAuthStateChange`. Once a session is detected, it immediately queries the `Profiles` table in the backend/Supabase to determine if the user is an `Admin`.
4. **Token Usage:** The JWT Bearer token is attached to the headers of outgoing requests to the .NET API to authenticate protected actions.

## 5. API Integration (`services/api.ts`)
The `api.ts` file acts as the primary bridge between the React frontend and the `.NET Core` backend (`CarRental.Api`).
- Uses standard `fetch` API.
- Automatically injects the Supabase JWT into the `Authorization` header by retrieving the session from `supabase.auth.getSession()`.
- Provides strongly-typed functions (e.g., `getFleet()`, `createBooking()`) returning Promises that resolve to interfaces defined in `/types`.
