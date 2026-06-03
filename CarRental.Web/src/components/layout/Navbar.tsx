import { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Menu, X, Bell, User, LogOut, Car } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import './Navbar.css';

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const { user, isAdmin, signOut } = useAuth();
  const location = useLocation();

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40);
    window.addEventListener('scroll', onScroll);
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => { setMenuOpen(false); }, [location.pathname]);

  const navLinks = [
    { to: '/',        label: 'Home'     },
    { to: '/fleet',   label: 'Our Fleet' },
    { to: '/services',label: 'Services' },
    { to: '/bookings',label: 'My Bookings' },
  ];

  return (
    <header className={`navbar ${scrolled ? 'navbar--scrolled' : ''}`}>
      <div className="container navbar__inner">
        {/* Logo */}
        <Link to="/" className="navbar__logo">
          <img src="/logo.png" alt="Retrix Car Rental" style={{ height: '70px', objectFit: 'contain' }} />
        </Link>

        {/* Desktop Nav */}
        <nav className="navbar__links hide-mobile">
          <Link to="/" className={`navbar__link ${location.pathname === '/' ? 'navbar__link--active' : ''}`}>Home</Link>
          <Link to="/fleet" className={`navbar__link ${location.pathname.startsWith('/fleet') ? 'navbar__link--active' : ''}`}>Our Fleet</Link>
          <Link to="/services" className={`navbar__link ${location.pathname.startsWith('/services') ? 'navbar__link--active' : ''}`}>Services</Link>
          {user && (
            <Link to="/bookings" className={`navbar__link ${location.pathname.startsWith('/bookings') ? 'navbar__link--active' : ''}`}>My Bookings</Link>
          )}
          {isAdmin && (
            <Link to="/admin" className={`navbar__link ${location.pathname.startsWith('/admin') ? 'navbar__link--active' : ''}`}>Admin</Link>
          )}
        </nav>

        {/* Actions */}
        <div className="navbar__actions">
          {user ? (
            <>
              <button className="btn-ghost btn btn-sm hide-mobile" onClick={signOut} id="sign-out-btn">
                <LogOut size={15} />
                Sign Out
              </button>
              {isAdmin && (
                <Link to="/admin" className="navbar__avatar hide-mobile" id="admin-link">
                  <User size={16} />
                </Link>
              )}
            </>
          ) : (
            <Link to="/login" className="btn btn-gold btn-sm hide-mobile" id="login-btn">
              Sign In
            </Link>
          )}

          {/* Hamburger */}
          <button
            className="navbar__hamburger"
            onClick={() => setMenuOpen(o => !o)}
            aria-label="Toggle menu"
            id="hamburger-btn"
          >
            {menuOpen ? <X size={22} /> : <Menu size={22} />}
          </button>
        </div>
      </div>

      {/* Mobile Menu */}
      {menuOpen && (
        <div className="navbar__mobile">
          <Link to="/" className="navbar__mobile-link">Home</Link>
          <Link to="/fleet" className="navbar__mobile-link">Our Fleet</Link>
          <Link to="/services" className="navbar__mobile-link">Services</Link>
          {user && <Link to="/bookings" className="navbar__mobile-link">My Bookings</Link>}
          {isAdmin && <Link to="/admin" className="navbar__mobile-link">Admin</Link>}
          <div className="navbar__mobile-divider" />
          {user ? (
            <button className="navbar__mobile-link" onClick={signOut}>Sign Out</button>
          ) : (
            <Link to="/login" className="navbar__mobile-link gold-text">Sign In</Link>
          )}
        </div>
      )}
    </header>
  );
}
