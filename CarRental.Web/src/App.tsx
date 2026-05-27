import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { CurrencyProvider } from './contexts/CurrencyContext';
import Navbar from './components/layout/Navbar';
import Footer from './components/layout/Footer';
import LandingPage from './pages/LandingPage';
import FleetPage from './pages/FleetPage';
import CarDetailPage from './pages/CarDetailPage';
import BookingsPage from './pages/BookingsPage';
import LoginPage from './pages/LoginPage';
import AdminLayout from './components/layout/AdminLayout';
import AdminDashboard from './pages/admin/AdminDashboard';
import AdminFleet from './pages/admin/AdminFleet';
import AdminBookings from './pages/admin/AdminBookings';
import AdminPayments from './pages/admin/AdminPayments';
import AdminDamages from './pages/admin/AdminDamages';
import AdminInvoices from './pages/admin/AdminInvoices';
import AdminSettings from './pages/admin/AdminSettings';

function App() {
  return (
    <AuthProvider>
      <CurrencyProvider>
        <BrowserRouter>
          <Routes>
            {/* Public pages with Navbar + Footer */}
            <Route path="/" element={<><Navbar /><LandingPage /><Footer /></>} />
            <Route path="/fleet" element={<><Navbar /><FleetPage /><Footer /></>} />
            <Route path="/fleet/:id" element={<><Navbar /><CarDetailPage /><Footer /></>} />
            <Route path="/bookings" element={<><Navbar /><BookingsPage /><Footer /></>} />
            <Route path="/login" element={<LoginPage />} />

            {/* Admin pages with sidebar layout */}
            <Route path="/admin" element={<AdminLayout />}>
              <Route index element={<AdminDashboard />} />
              <Route path="fleet" element={<AdminFleet />} />
              <Route path="bookings" element={<AdminBookings />} />
              <Route path="payments" element={<AdminPayments />} />
              <Route path="damages" element={<AdminDamages />} />
              <Route path="invoices" element={<AdminInvoices />} />
              <Route path="settings" element={<AdminSettings />} />
            </Route>

            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
      </CurrencyProvider>
    </AuthProvider>
  );
}

export default App;
