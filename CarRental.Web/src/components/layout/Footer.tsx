import { Link } from 'react-router-dom';
import { Car, MapPin, Phone, Mail } from 'lucide-react';
import './Footer.css';

export default function Footer() {
  return (
    <footer className="footer">
      <div className="gold-divider" />
      <div className="container footer__grid">
        <div className="footer__brand">
          <div className="footer__logo" style={{ marginBottom: '1rem' }}>
            <img src="/logo.png" alt="Retrix Car Rental" style={{ height: '90px', objectFit: 'contain' }} />
          </div>
          <p>Zambia's premier luxury car rental service. Experience the road with elegance.</p>
          <p className="footer__tagline">Est. in Kitwe — Serving Zambia</p>
        </div>

        <div>
          <h4>Quick Links</h4>
          <ul>
            <li><Link to="/">Home</Link></li>
            <li><Link to="/fleet">Our Fleet</Link></li>
            <li><Link to="/bookings">My Bookings</Link></li>
            <li><Link to="/login">Sign In</Link></li>
          </ul>
        </div>

        <div>
          <h4>Contact</h4>
          <ul>
            <li><MapPin size={14}/> Plot 1234, Kitwe</li>
            <li><Phone size={14}/> <a href="tel:0962431222" style={{ color: 'inherit', textDecoration: 'none' }}>0962431222</a></li>
            <li><Mail size={14}/> <a href="mailto:retrixrentals@gmail.com" onClick={(e) => { navigator.clipboard.writeText('retrixrentals@gmail.com'); }} style={{ color: 'inherit', textDecoration: 'none' }} title="Click to email (or copy to clipboard)">retrixrentals@gmail.com</a></li>
            <li>
              <a href="https://www.facebook.com/profile.php?id=61590504902516" target="_blank" rel="noreferrer" style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', color: 'inherit', textDecoration: 'none' }}>
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z"></path></svg>
                Retrix Car Rental
              </a>
            </li>
          </ul>
        </div>
      </div>

      <div className="footer__bottom">
        <p>&copy; {new Date().getFullYear()} Retrix Car Rental. All rights reserved.</p>
      </div>
    </footer>
  );
}
