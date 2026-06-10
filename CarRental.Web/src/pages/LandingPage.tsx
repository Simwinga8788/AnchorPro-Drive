import { useEffect, useState, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { ArrowRight, Shield, Clock, MapPin, Fuel, Users, Gauge, CalendarCheck, Car as CarIcon, Search, ChevronLeft, ChevronRight } from 'lucide-react';
import { useCurrency } from '../contexts/CurrencyContext';
import { getHeroImages, getCars, getHeroVideo } from '../api/client';
import type { Car } from '../types';
import ParticleNetwork from '../components/ui/ParticleNetwork';
import './LandingPage.css';

export default function LandingPage() {
  const { format } = useCurrency();
  const [heroVideoUrl, setHeroVideoUrl] = useState('');
  const [heroBg, setHeroBg] = useState('');
  const [featuredCars, setFeaturedCars] = useState<Car[]>([]);
  const [shuttleCars, setShuttleCars] = useState<Car[]>([]);
  const [photoStripImages, setPhotoStripImages] = useState<string[]>([]);
  const [slideIndex, setSlideIndex] = useState(0);
  const [activeFeaturedIndex, setActiveFeaturedIndex] = useState(0);
  const [activeShuttleIndex, setActiveShuttleIndex] = useState(0);
  const navigate = useNavigate();

  useEffect(() => {
    getHeroImages().then(imgs => {
      if (imgs && imgs.length > 0) {
        setHeroBg(imgs[0]);
      } else {
        setHeroBg('');
      }
    }).catch(console.error);

    getHeroVideo().then(video => {
      if (video?.url) setHeroVideoUrl(video.url);
    }).catch(console.error);

    getCars().then(cars => {
      setFeaturedCars(cars.filter(c => !c.isShuttleOnly).slice(0, 3));
      setShuttleCars(cars.filter(c => c.isShuttleOnly).slice(0, 3));
      setPhotoStripImages(cars.flatMap(c => c.imageUrls || []).filter(Boolean).slice(0, 4));
    }).catch(console.error);
  }, []);

  // Slideshow: only real car images from the DB
  const captions = [
    { eye: 'Premium Fleet',   title: 'Built for the Road',   sub: 'Every journey, perfected.' },
    { eye: 'Across Zambia',   title: 'Drive in Confidence',  sub: 'Fully insured. Always ready.' },
    { eye: 'Your Terms',      title: 'No Hidden Fees',       sub: 'Transparent pricing, always.' },
    { eye: '24/7 Support',    title: "We've Got Your Back",  sub: 'Help, wherever the road takes you.' },
    { eye: 'Kitwe to Lusaka', title: 'Zambia, Covered',      sub: 'Multiple locations nationwide.' },
    { eye: 'Instant Booking', title: 'Confirm in Seconds',   sub: 'Pick your dates. We handle the rest.' },
  ];
  const slides = featuredCars
    .flatMap(c => (c.imageUrls || []).slice(0, 2))
    .map((src, i) => ({ src, ...captions[i % captions.length] }));

  const prevSlide = useCallback(() => setSlideIndex(i => (i - 1 + slides.length) % slides.length), [slides.length]);
  const nextSlide = useCallback(() => setSlideIndex(i => (i + 1) % slides.length), [slides.length]);

  // Auto-advance every 4 seconds
  useEffect(() => {
    const t = setInterval(nextSlide, 4000);
    return () => clearInterval(t);
  }, [nextSlide]);

  const steps = [
    { icon: <Search size={20} />, n: '01', title: 'Browse & Choose', desc: 'Filter our fleet by type, location, and budget. Every car is verified and road-ready.' },
    { icon: <CalendarCheck size={20} />, n: '02', title: 'Book & Confirm', desc: 'Select your pickup and drop-off dates. Instant booking confirmation, no hidden fees.' },
    { icon: <CarIcon size={20} />, n: '03', title: 'Drive & Enjoy', desc: 'Collect your vehicle at the agreed time. Full insurance included. 24/7 roadside support.' },
  ];



  return (
    <div className="landing">

      {/* ── HERO: SPLIT LAYOUT ──────────────────────────────────── */}
      <section className="hero">
        <div style={{ position: 'absolute', inset: 0, width: '50vw', zIndex: 0 }}>
          <ParticleNetwork />
        </div>

        {/* LEFT */}
        <div className="container" style={{ display: 'contents' }}>
          <div className="hero__left container" style={{ paddingRight: 0 }}>
            <h1 className="hero__headline">
              Drive in<br />
              <em>Style</em> &amp;<br />
              Comfort
            </h1>

            <p className="hero__sub">
              Premium vehicles for business, leisure, and adventure.
              From Kitwe to Livingstone.
            </p>

            <div className="hero__actions">
              <Link to="/fleet" className="btn btn-gold" id="hero-browse-btn">
                Explore Fleet <ArrowRight size={16} />
              </Link>
              <Link to="/services" className="btn btn-outline" id="hero-services-btn">
                Our Services
              </Link>
            </div>
          </div>
        </div>

        {/* RIGHT IMAGE / VIDEO */}
        <div className="hero__right">
          {heroVideoUrl ? (
            <video
              key={heroVideoUrl}
              autoPlay muted loop playsInline
              className="hero__right-img"
              style={{ objectFit: 'cover', width: '100%', height: '100%' }}
            >
              <source src={heroVideoUrl} />
            </video>
          ) : heroBg ? (
            <div className="hero__right-img" style={{ backgroundImage: `url('${heroBg}')` }} />
          ) : null}
          <div className="hero__right-overlay" />
        </div>
      </section>



      {/* ── FEATURED VEHICLES ───────────────────────────────────── */}
      <section className="section featured">
        <div className="container">
          <div className="featured__header">
            <div className="featured__header-left">
              <span className="section-eyebrow">Handpicked for You</span>
              <h2 className="section-title">Featured <span className="gold-text">Vehicles</span></h2>
              <p className="section-subtitle">Our most popular rentals — premium, reliable, and always road-ready.</p>
            </div>
            <Link to="/fleet" className="btn btn-outline hide-mobile" id="view-all-btn">
              View Full Fleet <ArrowRight size={15} />
            </Link>
          </div>

          <div className="featured__accordion">
            {featuredCars.map((car, index) => {
              const isActive = activeFeaturedIndex === index;
              const bgImg = car.imageUrls?.[0] || 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=1200&q=80';
              
              return (
                <div 
                  key={car.id} 
                  className={`featured-panel ${isActive ? 'active' : ''}`}
                  onMouseEnter={() => setActiveFeaturedIndex(index)}
                  onClick={() => {
                    if (!isActive) {
                      // First tap: expand the card
                      setActiveFeaturedIndex(index);
                    } else {
                      // Second tap (or desktop click on active): navigate
                      navigate(`/fleet/${car.id}`);
                    }
                  }}
                  style={{ cursor: 'pointer', textDecoration: 'none' }}
                >
                  <div 
                    className="featured-panel__bg"
                    style={{ backgroundImage: `url('${bgImg}')` }}
                  />
                  <div className="featured-panel__overlay" />

                  <div className="featured-panel__content">
                    <div className="featured-panel__title-wrap">
                      {/* Year removed */}
                      <h3 className="featured-panel__title">{car.make} {car.model}</h3>
                      <span className={`badge ${car.status === 'Available' ? 'badge-green' : 'badge-grey'}`} style={{ marginTop: 8, display: 'inline-block', alignSelf: 'flex-start' }}>
                        {car.status}
                      </span>
                    </div>

                    <div className="featured-panel__details">
                      <div className="featured-panel__specs">
                        <span><Gauge size={14} /> {car.transmission}</span>
                        <span><Fuel size={14} /> {car.fuelType}</span>
                        <span><Users size={14} /> {car.seats} Seats</span>
                      </div>
                      
                      <div className="featured-panel__footer">
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                          <div className="featured-panel__price">
                            <span className="price-amount">{format(car.dailyRateZmw, car.dailyRateUsd)}</span>
                            <span className="price-per">/day (local)</span>
                          </div>
                          {car.dailyRateOutofTownZmw && (
                            <div className="featured-panel__price">
                              <span className="price-amount">{format(car.dailyRateOutofTownZmw, car.dailyRateOutofTownUsd)}</span>
                              <span className="price-per">/day (out-of-town)</span>
                            </div>
                          )}
                        </div>
                        <div className="btn btn-gold btn-sm" id={`featured-car-${car.id}`}>
                          View Vehicle <ArrowRight size={14} />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          <div style={{ textAlign: 'center', marginTop: 36 }} className="hide-desktop">
            <Link to="/fleet" className="btn btn-outline" id="view-all-mobile-btn">
              View Full Fleet <ArrowRight size={15} />
            </Link>
          </div>
        </div>
      </section>

      {/* ── SHUTTLE SERVICES ────────────────────────────────────── */}
      {shuttleCars.length > 0 && (
        <section className="section featured" style={{ background: 'var(--bg)' }}>
          <div className="container">
            <div className="featured__header">
              <div className="featured__header-left">
                <span className="section-eyebrow">Chauffeur &amp; Transfers</span>
                <h2 className="section-title">Shuttle <span className="gold-text">Services</span></h2>
                <p className="section-subtitle">Exclusive vehicles for weddings, airport transfers, and executive travel.</p>
              </div>
              <Link to="/services" className="btn btn-outline hide-mobile" id="view-services-btn">
                View All Services <ArrowRight size={15} />
              </Link>
            </div>

            <div className="featured__accordion">
              {shuttleCars.map((car, index) => {
                const isActive = activeShuttleIndex === index;
                const bgImg = car.imageUrls?.[0] || 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=1200&q=80';
                
                return (
                  <div 
                    key={car.id} 
                    className={`featured-panel ${isActive ? 'active' : ''}`}
                    onMouseEnter={() => setActiveShuttleIndex(index)}
                    onClick={(e) => {
                      // Only navigate if they didn't click the WhatsApp button
                      if (!(e.target as HTMLElement).closest('a')) {
                        navigate(`/fleet/${car.id}`);
                      }
                    }}
                    style={{ cursor: 'pointer' }}
                  >
                    <div 
                      className="featured-panel__bg"
                      style={{ backgroundImage: `url('${bgImg}')` }}
                    />
                    <div className="featured-panel__overlay" />

                    <div className="featured-panel__content">
                      <div className="featured-panel__title-wrap">
                        {/* Year removed */}
                        <h3 className="featured-panel__title">{car.make} {car.model}</h3>
                        <span className="badge badge-blue" style={{ marginTop: 8, display: 'inline-block', alignSelf: 'flex-start' }}>
                          Shuttle Only
                        </span>
                      </div>

                      <div className="featured-panel__details">
                        <div className="featured-panel__specs">
                          <span><Gauge size={14} /> {car.transmission}</span>
                          <span><Fuel size={14} /> {car.fuelType}</span>
                          <span><Users size={14} /> {car.seats} Seats</span>
                        </div>
                        
                        <div className="featured-panel__footer">
                          <div className="featured-panel__price">
                            <span className="price-amount" style={{ fontSize: '1.2rem' }}>Custom Pricing</span>
                          </div>
                          <a 
                            href={`https://wa.me/260962431222?text=Hi! I'm interested in booking the ${car.make} ${car.model} for a shuttle service.`}
                            target="_blank" rel="noopener noreferrer"
                            className="btn btn-gold btn-sm" id={`shuttle-car-${car.id}`}
                            onClick={(e) => e.stopPropagation()}
                          >
                            Request Quote <ArrowRight size={14} />
                          </a>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </section>
      )}

      {/* ── HOW IT WORKS: NEW ICON LAYOUT ───────────────────────── */}
      <section className="section how-it-works">
        <div className="container">
          <div className="how-it-works__grid">
            {/* Left: heading + steps */}
            <div>
              <span className="section-eyebrow">Simple Process</span>
              <h2 className="section-title" style={{ marginBottom: 16 }}>
                How It <span className="gold-text">Works</span>
              </h2>
              <p className="section-subtitle" style={{ marginBottom: 48 }}>
                Three steps to your next journey. No hassle, no surprises.
              </p>

              <div className="steps-list">
                {steps.map((s, i) => (
                  <div key={i} className="step">
                    <div className="step__icon-wrap">{s.icon}</div>
                    <div>
                      <div className="step__number">Step {s.n}</div>
                      <h4 className="step__title">{s.title}</h4>
                      <p className="step__desc">{s.desc}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Right: auto-sliding photo panel */}
            <div className="how-it-works__visual">
              {/* Slide images */}
              <div className="hiw-slideshow">
                {slides.map((slide, i) => (
                  <div
                    key={i}
                    className={`hiw-slide ${i === slideIndex ? 'hiw-slide--active' : ''}`}
                    style={{ backgroundImage: `url('${slide.src}')` }}
                  />
                ))}

                {/* Dark gradient overlay */}
                <div className="hiw-slide__overlay" />

                {/* Text on top */}
                <div className="hiw-slide__caption">
                  <span className="hiw-slide__caption-eye">{slides[slideIndex]?.eye}</span>
                  <h3 className="hiw-slide__caption-title">{slides[slideIndex]?.title}</h3>
                  <span className="hiw-slide__caption-sub">{slides[slideIndex]?.sub}</span>
                </div>

                {/* Prev / Next arrows */}
                <button className="hiw-slide__arrow hiw-slide__arrow--left" onClick={prevSlide} aria-label="Previous">
                  <ChevronLeft size={18} />
                </button>
                <button className="hiw-slide__arrow hiw-slide__arrow--right" onClick={nextSlide} aria-label="Next">
                  <ChevronRight size={18} />
                </button>

                {/* Dot indicators */}
                <div className="hiw-slide__dots">
                  {slides.map((_, i) => (
                    <button
                      key={i}
                      className={`hiw-dot ${i === slideIndex ? 'hiw-dot--active' : ''}`}
                      onClick={() => setSlideIndex(i)}
                      aria-label={`Slide ${i + 1}`}
                    />
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── PHOTO STRIP ─────────────────────────────────────────── */}
      <section className="photo-strip" style={{ gridTemplateColumns: `repeat(${photoStripImages.length > 0 ? photoStripImages.length : 4}, 1fr)` }}>
        {(() => {

          return photoStripImages.length > 0
            ? photoStripImages.map((src, i) => (
                <div key={i} className="photo-strip__item">
                  <img src={src} alt="Car" loading="lazy" />
                </div>
              ))
            : null;
        })()}
      </section>

      {/* ── CTA BANNER ──────────────────────────────────────────── */}
      <section className="section cta-banner">
        <div className="container">
          <div className="cta-box">
            <div>
              <h2>Ready to Hit the Road?</h2>
              <p>Experience Zambia's finest roads in absolute comfort and style.</p>
            </div>
            <Link to="/fleet" className="btn btn-gold" id="cta-browse-btn">
              Explore the Fleet <ArrowRight size={16} />
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
