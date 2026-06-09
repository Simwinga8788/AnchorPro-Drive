import { MessageCircle } from 'lucide-react';

export default function WhatsAppBubble() {
  const waNumber = '260962431222';
  const waLink = `https://wa.me/${waNumber}`;

  return (
    <a 
      href={waLink} 
      target="_blank" 
      rel="noopener noreferrer"
      style={{
        position: 'fixed',
        bottom: 24,
        right: 24,
        width: 60,
        height: 60,
        backgroundColor: '#25D366',
        color: '#fff',
        borderRadius: '50%',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        boxShadow: '0 4px 12px rgba(37, 211, 102, 0.4)',
        zIndex: 9999,
        transition: 'transform 0.2s',
      }}
      onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.1)'}
      onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
      title="Chat with us on WhatsApp"
    >
      <MessageCircle size={32} />
    </a>
  );
}
