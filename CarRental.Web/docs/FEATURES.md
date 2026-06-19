# Features Manual

This document details the functionality provided by the Retrix Car Rental web portal, divided into Public/Customer features and Admin features.

## 1. Public & Customer Portal
The customer-facing application is designed for ease of use, allowing customers to quickly browse cars and reserve them.

### Fleet & Car Details
- **Dynamic Fleet Browsing:** Users can view all active cars. Filters are available by vehicle class.
- **Detailed View:** Clicking a car displays full specifications (seats, transmission, luggage capacity, and high-resolution images).
- **Currency Conversion:** A global toggle allows users to instantly convert prices between Zambian Kwacha (ZMW) and US Dollars (USD).

### Bookings & Reservations
- **Booking Flow:** Users can select start/end dates, pickup locations, and drop-off locations directly from the car detail page.
- **My Bookings:** Authenticated users have a dedicated dashboard to view past, present, and upcoming reservations.
- **Invoicing:** Users can view generated invoices for their bookings.

### Communications
- **WhatsApp Integration:** A persistent floating WhatsApp bubble allows customers to instantly message support at any time.

---

## 2. Admin Portal
The Admin Portal (`/admin/*`) is restricted to accounts flagged as `isAdmin` in the database.

### Dashboard (`/admin`)
- Provides high-level KPIs: Total Revenue, Active Bookings, Total Fleet Size, and Total Customers.
- Quick summary charts to visualize recent business performance.

### Fleet Management (`/admin/fleet`)
- **CRUD Operations:** Admins can add new vehicles, update existing specifications (mileage, price, condition), and permanently delete retired vehicles.
- **Image Handling:** Supports uploading vehicle images which are stored directly on the server or cloud storage.

### Bookings & Quotations (`/admin/bookings`)
- **Status Management:** Admins can transition bookings through various states (e.g., Pending, Confirmed, Active, Completed, Cancelled).
- **Custom Quote Generation:** Allows manual creation of custom bookings (useful for walk-in customers or negotiated corporate rates).
- **PDF Export:** Integrates `html2pdf.js` to render beautiful native PDF quotations and invoices that can be downloaded and emailed to clients.

### Customer Management (`/admin/customers`)
- Directory of all registered users.
- Admins can view customer contact information, license numbers, and their booking history.
- **Privilege Escalation:** Admins can promote other users to Admin status.

### Payments Management (`/admin/payments`)
- Log manual payments (Cash, Bank Transfer) against specific bookings.
- Track remaining balances dynamically to ensure bookings are fully paid before completion.

### Damages Management (`/admin/damages`)
- Report scratches, dents, or accidents tied to specific bookings/vehicles.
- Attach photographic evidence.
- Log estimated repair costs and pass those penalties onto the customer's final invoice.

### Locations & Settings (`/admin/locations`, `/admin/settings`)
- **Locations:** Add and remove authorized pickup and dropoff zones (e.g., Kenneth Kaunda Airport, Manda Hill).
- **Settings:** Configure global application parameters such as base deposit rules, mileage limits, and terms of service.

### Reports (`/admin/reports`)
- Comprehensive financial and utilization analytics.
- **Exporting:** Integrated with `exceljs` and `file-saver` to export raw tabular data into `.xlsx` or `.csv` files for accounting purposes.
