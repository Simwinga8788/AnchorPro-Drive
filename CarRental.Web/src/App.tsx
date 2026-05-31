import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { CurrencyProvider } from './contexts/CurrencyContext';
import Navbar from './components/layout/Navbar';
import Footer from './components/layout/Footer';
import LandingPage from './pages/LandingPage';
import FleetPage from './pages/FleetPage';
import CarDetailPage from './pages/CarDetailPage';
import BookingsPage from './pages/BookingsPage';
import QuotationView from './pages/QuotationView';
import LoginPage from './pages/LoginPage';
import ServicesPage from './pages/ServicesPage';
import ContactPage from './pages/ContactPage';
import WhatsAppBubble from './components/WhatsAppBubble';
import AdminLayout from './components/layout/AdminLayout';
import AdminDashboard from './pages/admin/AdminDashboard';
import AdminFleet from './pages/admin/AdminFleet';
import AdminBookings from './pages/admin/AdminBookings';
import AdminLocations from './pages/admin/AdminLocations';
import AdminPayments from './pages/admin/AdminPayments';
import AdminDamages from './pages/admin/AdminDamages';
import AdminSettings from './pages/admin/AdminSettings';

function App() {
  return (
    <AuthProvider>
      <CurrencyProvider>
        <BrowserRouter>
          <Routes>
            {/* Public pages with Navbar + Footer + WhatsApp Bubble */}
            <Route path="/" element={<><Navbar /><LandingPage /><Footer /></>} />
            <Route path="/fleet" element={<><Navbar /><FleetPage /><Footer /><WhatsAppBubble /></>} />
            <Route path="/fleet/:id" element={<><Navbar /><CarDetailPage /><Footer /><WhatsAppBubble /></>} />
            <Route path="/bookings" element={<><Navbar /><BookingsPage /><Footer /><WhatsAppBubble /></>} />
            <Route path="/quote/:id" element={<><Navbar /><QuotationView /><Footer /><WhatsAppBubble /></>} />
            <Route path="/services" element={<><Navbar /><ServicesPage /><Footer /><WhatsAppBubble /></>} />
            <Route path="/contact" element={<><Navbar /><ContactPage /><Footer /><WhatsAppBubble /></>} />
            <Route path="/login" element={<LoginPage />} />

            {/* Admin pages with sidebar layout */}
            <Route path="/admin" element={<AdminLayout />}>
              <Route index element={<AdminDashboard />} />
              <Route path="fleet" element={<AdminFleet />} />
              <Route path="bookings" element={<AdminBookings />} />
              <Route path="locations" element={<AdminLocations />} />
              <Route path="payments" element={<AdminPayments />} />
              <Route path="damages" element={<AdminDamages />} />
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
