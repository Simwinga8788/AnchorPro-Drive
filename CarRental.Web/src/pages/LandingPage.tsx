import { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, Shield, Clock, MapPin, Star, ChevronLeft, ChevronRight, Fuel, Users, Gauge } from 'lucide-react';
import { useCurrency } from '../contexts/CurrencyContext';
import { getHeroImages, getCars } from '../api/client';
import type { Car } from '../types';
import './LandingPage.css';



export default function LandingPage() {
  const { format } = useCurrency();
  const [heroBg, setHeroBg] = useState('https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=1600&q=90');
  const [featuredCars, setFeaturedCars] = useState<Car[]>([]);

  useEffect(() => {
    getHeroImages().then(imgs => {
      if (imgs && imgs.length > 0) setHeroBg(imgs[0]);
    }).catch(() => {});

    getCars().then(data => {
      setFeaturedCars(data.slice(0, 4));
    }).catch(() => {});
  }, []);

  return (
    <div className="landing">

      {/* ── HERO ─────────────────────────────────────────────── */}
      <section className="hero">
        <div
          className="hero__bg"
          style={{
            backgroundImage: `url('${heroBg}')`,
          }}
        />
        <div className="hero__overlay" />
        {/* Animated gold grid */}
        <div className="hero__grid" aria-hidden="true" />

        <div className="container hero__content">
          <p className="hero__eyebrow">Zambia's Premier Car Rental</p>
          <h1 className="hero__headline">
            Drive in <em>Elegance</em><br />
            Across Zambia
          </h1>
          <p className="hero__sub">
            Premium vehicles for business, leisure, and adventure.<br />
            From Kitwe to Livingstone — we've got you covered.
          </p>
          <div className="hero__actions">
            <Link to="/fleet" className="btn btn-gold" id="hero-browse-btn">
              Browse Our Fleet <ArrowRight size={16} />
            </Link>
            <Link to="/login" className="btn btn-outline-gold" id="hero-signin-btn" style={{color:'var(--white)',borderColor:'rgba(255,255,255,0.35)'}}>
              Sign In
            </Link>
          </div>

          {/* Quick booking strip */}
          <div className="hero__strip">
            <div className="hero__strip-item">
              <MapPin size={16} className="gold-text"/>
              <span>Multiple Locations</span>
            </div>
            <div className="hero__strip-sep" />
            <div className="hero__strip-item">
              <Shield size={16} className="gold-text"/>
              <span>Fully Insured</span>
            </div>
            <div className="hero__strip-sep" />
            <div className="hero__strip-item">
              <Clock size={16} className="gold-text"/>
              <span>24/7 Support</span>
            </div>
            <div className="hero__strip-sep" />
            <div className="hero__strip-item">
              <Star size={16} className="gold-text"/>
              <span>ZRA Compliant</span>
            </div>
          </div>
        </div>
      </section>



      {/* ── FEATURED CARS ─────────────────────────────────────── */}
      <section className="section featured">
        <div className="container">
          <p className="section-eyebrow">Handpicked for You</p>
          <h2 className="section-title">Featured <span className="gold-text">Vehicles</span></h2>
          <p className="section-subtitle">Our most popular rentals — premium, reliable, and always road-ready.</p>

          <div className="featured__grid">
            {featuredCars.map(car => (
              <div key={car.id} className="featured__card">
                <div className="featured__img-wrap">
                  <img src={car.imageUrls?.[0] || 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&q=80'} alt={`${car.make} ${car.model}`} loading="lazy" />
                </div>
                <div className="featured__info">
                  <div className="featured__meta">
                    <span className="featured__year">{car.year}</span>
                    <span className={`badge ${car.status === 'Available' ? 'badge-green' : 'badge-grey'}`}>
                      {car.status}
                    </span>
                  </div>
                  <h3>{car.make} {car.model}</h3>
                  <div className="featured__specs">
                    <span><Gauge size={13}/> {car.transmission}</span>
                    <span><Fuel size={13}/> {car.fuelType}</span>
                    <span><Users size={13}/> {car.seats} Seats</span>
                  </div>
                  <div className="featured__price">
                    <span className="price-amount">{format(car.dailyRateZmw, car.dailyRateUsd)}</span>
                    <span className="price-per">/day</span>
                  </div>
                  <Link to={`/fleet/${car.id}`} className="btn btn-gold btn-sm" id={`featured-car-${car.id}`}>
                    Book Now <ArrowRight size={14}/>
                  </Link>
                </div>
              </div>
            ))}
          </div>

          <div style={{ textAlign: 'center', marginTop: 40 }}>
            <Link to="/fleet" className="btn btn-outline" id="view-all-btn">
              View Full Fleet <ArrowRight size={15}/>
            </Link>
          </div>
        </div>
      </section>

      {/* ── HOW IT WORKS ──────────────────────────────────────── */}
      <section className="section how-it-works">
        <div className="container">
          <p className="section-eyebrow">Simple Process</p>
          <h2 className="section-title">How It <span className="gold-text">Works</span></h2>
          <p className="section-subtitle">Three steps to your next journey.</p>

          <div className="steps">
            {[
              { n: '01', title: 'Browse & Select', desc: 'Choose from our curated fleet of premium vehicles. Filter by type, location, and budget.' },
              { n: '02', title: 'Book & Confirm',  desc: 'Pick your dates, pickup and dropoff locations. Instant confirmation with ZRA-compliant invoice.' },
              { n: '03', title: 'Drive & Enjoy',   desc: 'Collect your vehicle at the agreed time. Full insurance included. 24/7 roadside support.' },
            ].map((s, i) => (
              <div key={i} className="step">
                <div className="step__number">{s.n}</div>
                <h3 className="step__title">{s.title}</h3>
                <p className="step__desc">{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── PHOTO STRIP ───────────────────────────────────────── */}
      <section className="photo-strip">
        {(() => {
          const dbImages = featuredCars
            .flatMap(car => car.imageUrls || [])
            .filter(Boolean);
            
          const imagesToShow = dbImages.length >= 4 
            ? dbImages.slice(0, 4)
            : [
                'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=600&q=80',
                'https://images.unsplash.com/photo-1511919884226-fd3cad34687c?w=600&q=80',
                'https://images.unsplash.com/photo-1570733577524-3a047079e80d?w=600&q=80',
                'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=600&q=80',
              ];

          return imagesToShow.map((src, i) => (
            <div key={i} className="photo-strip__item">
              <img src={src} alt="Car" loading="lazy" />
            </div>
          ));
        })()}
      </section>

      {/* ── CTA BANNER ────────────────────────────────────────── */}
      <section className="section cta-banner">
        <div className="container">
          <div className="cta-box">
            <h2>Ready to Hit the Road?</h2>
            <p>Experience Zambia's finest roads in absolute comfort and style.</p>
            <Link to="/fleet" className="btn btn-gold" id="cta-browse-btn">
              Explore the Fleet <ArrowRight size={16}/>
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
