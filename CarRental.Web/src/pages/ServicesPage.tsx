import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Plane, Users, Briefcase, Car as CarIcon, ArrowRight, CheckCircle } from 'lucide-react';
import './ServicesPage.css';

const services = [
  {
    id: 'airport',
    title: 'Airport Transfers',
    icon: <Plane size={24} />,
    image: 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=1200&q=80',
    description: 'Skip the taxi queues. Our professional drivers track your flight and wait at arrivals with a personalized sign.',
    features: ['Flat rate pricing to your hotel', '60 minutes complimentary wait time', 'Professional Chauffeurs'],
  },
  {
    id: 'wedding',
    title: 'Weddings & Events',
    icon: <Users size={24} />,
    image: 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=1200&q=80',
    description: 'Make your special day perfect with our luxury fleet. Specialized hourly rates and chauffeur services for VIP guests.',
    features: ['Immaculate luxury vehicles', 'Flexible hourly bookings', 'Optional vehicle decorations'],
  },
  {
    id: 'corporate',
    title: 'Corporate Leasing',
    icon: <Briefcase size={24} />,
    image: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1200&q=80',
    description: 'Long-term vehicle solutions for your business. Reliable fleet management with full maintenance and insurance included.',
    features: ['Discounted monthly rates', 'Dedicated account manager', 'Replacement vehicle guarantee'],
  },
  {
    id: 'chauffeur',
    title: 'Chauffeur Services',
    icon: <CarIcon size={24} />,
    image: 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=1200&q=80',
    description: 'Experience the ultimate convenience with our highly-trained chauffeurs for full-day or half-day city engagements.',
    features: ['Discreet & professional drivers', 'Deep local knowledge', 'On-call flexibility'],
  }
];

export default function ServicesPage() {
  const [activeIndex, setActiveIndex] = useState(0);

  return (
    <div className="services-page animate-fade-in">
      <div className="container services__header">
        <h1>Premium <em>Services</em></h1>
        <p>Beyond standard car rentals, we offer tailored transportation solutions designed for absolute comfort and convenience.</p>
      </div>

      <div className="services__accordion">
        {services.map((service, index) => {
          const isActive = activeIndex === index;
          return (
            <div 
              key={service.id}
              className={`service-panel ${isActive ? 'active' : ''}`}
              onMouseEnter={() => setActiveIndex(index)}
              onClick={() => setActiveIndex(index)}
            >
              {/* Background Image */}
              <div 
                className="service-panel__bg" 
                style={{ backgroundImage: `url(${service.image})` }} 
              />
              <div className="service-panel__overlay" />

              {/* Content */}
              <div className="service-panel__content">
                <div className="service-panel__icon">
                  {service.icon}
                </div>
                <h2 className="service-panel__title">{service.title}</h2>
                
                <div className="service-panel__details">
                  <p>{service.description}</p>
                  <ul>
                    {service.features.map((f, i) => (
                      <li key={i}><CheckCircle size={16} /> {f}</li>
                    ))}
                  </ul>
                  <Link to={`/contact?subject=${encodeURIComponent(service.title)}`} className="btn btn-gold btn-sm">
                    Request a Quote <ArrowRight size={14} style={{ marginLeft: 6 }} />
                  </Link>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
