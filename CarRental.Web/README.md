# Retrix Car Rental - Web Portal

Welcome to the **Retrix Car Rental Web Portal**. This React-based web application serves as both the customer-facing storefront and the powerful Admin Portal for managing the entire car rental fleet, bookings, payments, and customers.

## Table of Contents
1. [Overview](#overview)
2. [Tech Stack](#tech-stack)
3. [Getting Started](#getting-started)
4. [Project Structure](#project-structure)
5. [Additional Documentation](#additional-documentation)

## Overview
The web portal offers two distinct experiences based on user roles:
- **Public / Customer Portal:** Allows users to browse the fleet, view car details, and place rental bookings. Features WhatsApp integration for instant communication.
- **Admin Portal:** A secured dashboard where administrators can manage vehicles, approve/reject bookings, log payments, report damages, and generate professional PDF Quotations and Invoices.

## Tech Stack
- **Frontend Framework:** React 19 with TypeScript
- **Build Tool:** Vite
- **Styling:** CSS / Lucide React Icons
- **State Management:** Redux Toolkit & React Context (`AuthContext`, `CurrencyContext`)
- **Authentication:** Supabase Auth (JWT)
- **PDF Generation:** `html2pdf.js` for Quotes and Invoices
- **Backend:** Communicates with the `.NET Core` API (`CarRental.Api`)

## Getting Started

### Prerequisites
- [Node.js](https://nodejs.org/) (v18+ recommended)
- `npm` or `yarn`

### Installation
1. Clone the repository and navigate to the web portal directory:
   ```bash
   cd CarRental.Web
   ```
2. Install dependencies:
   ```bash
   npm install
   ```

### Environment Variables
Create a `.env` file in the root directory (alongside `package.json`) and configure the following:
```env
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
VITE_API_BASE_URL=http://localhost:5265/api  # Path to your local .NET API
```

### Running the Development Server
Start the Vite development server:
```bash
npm run dev
```
The application will usually be available at `http://localhost:5173`.

### Building for Production
To build the optimized static assets:
```bash
npm run build
```
Deployment specifics (e.g., Vercel, Netlify, IIS) will be provided in a later update.

## Project Structure
- `/src/components`: Reusable UI elements, Layouts, and Auth wrappers.
- `/src/pages`: Top-level page views (Public and Admin).
- `/src/contexts`: React Context providers for global Auth and Currency state.
- `/src/services`: API service wrappers and Supabase client configuration.

## Additional Documentation
For a deep dive into specific areas of the application, refer to the `/docs` folder:
- [Architecture Guide](docs/ARCHITECTURE.md): Deep dive into Routing, State Management, and API Integration.
- [Features Manual](docs/FEATURES.md): Comprehensive breakdown of all Customer and Admin features.
