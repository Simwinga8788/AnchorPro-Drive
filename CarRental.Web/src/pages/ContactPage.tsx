import { useLocation } from 'react-router-dom';
import { MessageCircle, Phone, MapPin, ArrowRight } from 'lucide-react';

export default function ContactPage() {
  const location = useLocation();
  const searchParams = new URLSearchParams(location.search);
  const subject = searchParams.get('subject') || 'General Inquiry';

  const waNumber = '260962431222';
  const waMessage = encodeURIComponent(`Hi Retrix Car Rental, I'm reaching out regarding a ${subject}. Could you provide more details?`);
  const waLink = `https://wa.me/${waNumber}?text=${waMessage}`;

  return (
    <div style={{ paddingTop: 80, paddingBottom: 60, minHeight: '80vh' }}>
      <div className="container" style={{ textAlign: 'center', marginBottom: 48 }}>
        <h1 style={{ fontSize: '3rem', fontFamily: 'var(--font-head)', marginBottom: 16 }}>
          Contact <span className="gold-text">Us</span>
        </h1>
        <p style={{ color: 'var(--text-2)', maxWidth: 600, margin: '0 auto', fontSize: '1.1rem' }}>
          We are available 24/7 on WhatsApp. Tap the button below to instantly chat with our booking team for your {subject.toLowerCase()}.
        </p>
      </div>

      <div className="container" style={{ display: 'flex', justifyContent: 'center' }}>
        <div style={{ background: '#fff', borderRadius: 12, padding: 48, boxShadow: '0 10px 30px rgba(0,0,0,0.05)', border: '1px solid #f1f5f9', maxWidth: 500, width: '100%', textAlign: 'center' }}>
          
          <div style={{ width: 80, height: 80, borderRadius: '50%', background: '#dcf8c6', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 24px auto' }}>
            <MessageCircle size={40} color="#25D366" />
          </div>
          
          <h2 style={{ fontSize: '1.8rem', marginBottom: 8, fontFamily: 'var(--font-head)' }}>Chat with us on WhatsApp</h2>
          <p style={{ color: 'var(--text-2)', marginBottom: 32 }}>
            Get instant replies, custom quotes, and finalize your booking quickly.
          </p>
          
          <a href={waLink} target="_blank" rel="noopener noreferrer" className="btn btn-gold" style={{ width: '100%', justifyContent: 'center', fontSize: '1.1rem', padding: '16px', background: '#25D366', color: '#fff', borderColor: '#25D366' }}>
            Open WhatsApp <ArrowRight size={18} style={{ marginLeft: 8 }} />
          </a>

          <div style={{ marginTop: 48, display: 'flex', flexDirection: 'column', gap: 16, textAlign: 'left', borderTop: '1px solid #eee', paddingTop: 24 }}>
            <div style={{ display: 'flex', gap: 12, alignItems: 'center', color: 'var(--text-1)' }}>
              <Phone size={18} className="gold-text" /> 
              <span>Call Us: +260 972 996 902</span>
            </div>
            <div style={{ display: 'flex', gap: 12, alignItems: 'center', color: 'var(--text-1)' }}>
              <MapPin size={18} className="gold-text" /> 
              <span>Plot 1234, Kitwe, Zambia</span>
            </div>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-3)', marginTop: 8 }}>
              * Email contact form coming soon. For now, please use WhatsApp or call us directly.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
