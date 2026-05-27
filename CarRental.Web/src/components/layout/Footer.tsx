import { Link } from 'react-router-dom';
import { Car, MapPin, Phone, Mail } from 'lucide-react';
import './Footer.css';

export default function Footer() {
  return (
    <footer className="footer">
      <div className="gold-divider" />
      <div className="container footer__grid">
        <div className="footer__brand">
          <div className="footer__logo">
            <Car size={20} />
            <span>AnchorPro<em>Drive</em></span>
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
            <li><Phone size={14}/> +260 97 123 4567</li>
            <li><Mail size={14}/> info@anchorprodrive.zm</li>
          </ul>
        </div>
      </div>

      <div className="footer__bottom">
        <p>© {new Date().getFullYear()} AnchorPro Drive Zambia. All rights reserved.</p>
        <p>ZRA Registered — Compliant with Zambia Revenue Authority</p>
      </div>
    </footer>
  );
}
