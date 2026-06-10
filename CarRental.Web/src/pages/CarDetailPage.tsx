import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Fuel, Users, Gauge, Calendar, MapPin, Shield, ArrowLeft, CheckCircle, X } from 'lucide-react';
import { getCar, getLocations, checkoutBooking } from '../api/client';
import { useCurrency } from '../contexts/CurrencyContext';
import { useAuth } from '../contexts/AuthContext';
import type { Car, Location } from '../types';
import './CarDetailPage.css';

const CAR_IMAGES: Record<string, string> = {
  default:        'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=1200&q=85',
  'Land Cruiser': 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=1200&q=85',
  'GLE':          'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=1200&q=85',
  '5 Series':     'https://images.unsplash.com/photo-1556189250-72ba954cfc2b?w=1200&q=85',
  'Sport':        'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=1200&q=85',
  'Hilux':        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=1200&q=85',
};

function getCarImages(car: Car): string[] {
  if (car.imageUrls && car.imageUrls.length > 0) return car.imageUrls;
  for (const k of Object.keys(CAR_IMAGES)) {
    if (car.model.includes(k)) return [CAR_IMAGES[k]];
  }
  return [CAR_IMAGES.default];
}

// Sample for when API is offline
const SAMPLE: Car = {
  id:'s1', make:'Toyota', model:'Land Cruiser 200', year:2022, licensePlate:'ABX 1234 ZM', vin:'JT3GN86R2X0123456',
  transmission:'Automatic', fuelType:'Diesel', seats:7, dailyRateZmw:1800, dailyRateUsd:85,
  currentOdometer:45000, status:'Available',
  features:['7-Seater','Air Conditioning','4WD','Sunroof','Bluetooth','Reverse Camera','GPS Navigation'],
};

const STEPS = ['Dates','Locations','Review','Confirm'];

export default function CarDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { format } = useCurrency();
  const { user } = useAuth();

  const [car, setCar] = useState<Car | null>(null);
  const [locations, setLocations] = useState<Location[]>([]);
  const [loading, setLoading] = useState(true);
  const [step, setStep] = useState(0);
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState('');

  // Booking form state
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate]     = useState('');
  const [pickupId, setPickupId]   = useState('');
  const [dropoffId, setDropoffId] = useState('');

  // Payment form state
  const [paymentMethod, setPaymentMethod] = useState<'Pay Later' | 'Mobile Money'>('Pay Later');
  const [mobileNumber, setMobileNumber] = useState('');
  const [provider, setProvider] = useState<'mtn' | 'airtel' | 'zamtel'>('mtn');
  const [isOutofTown, setIsOutofTown] = useState(false);

  const [activeImg, setActiveImg] = useState(0);
  const [lightboxOpen, setLightboxOpen] = useState(false);

  useEffect(() => {
    Promise.all([getCar(id!), getLocations()])
      .then(([c, l]) => { setCar(c); setLocations(l); if (l.length) { setPickupId(l[0].id); setDropoffId(l[0].id); } })
      .catch(() => { setCar(SAMPLE); })
      .finally(() => setLoading(false));
  }, [id]);

  useEffect(() => {
    setActiveImg(0);
  }, [car?.id]);

  const days = (() => {
    if (!startDate || !endDate) return 0;
    const dtStart = new Date(startDate);
    const dtEnd = new Date(endDate);
    const diffTime = Math.abs(dtEnd.getTime() - dtStart.getTime());
    const d = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return d;
  })();

  const isValidDuration = days >= 2;

  // Determine active rate based on user selection
  const activeRateZmw = isOutofTown && car?.dailyRateOutofTownZmw
    ? car.dailyRateOutofTownZmw
    : car?.dailyRateZmw ?? 0;
  const activeRateUsd = isOutofTown && car?.dailyRateOutofTownUsd
    ? car.dailyRateOutofTownUsd
    : car?.dailyRateUsd;

  const totalZmw = activeRateZmw * days;
  const totalUsd = activeRateUsd ? activeRateUsd * days : undefined;

  const handleBook = async () => {
    if (!car) return;
    setSubmitting(true);
    setError('');
    try {
      await checkoutBooking({
        booking: {
          carId: car.id,
          customerId: user?.id ?? '00000000-0000-0000-0000-000000000000',
          startDate,
          endDate,
          pickupLocationId: pickupId,
          dropoffLocationId: dropoffId,
          totalPriceZmw: totalZmw,
          isOutofTown,
        },
        paymentMethod,
        mobileNumber: paymentMethod === 'Mobile Money' ? mobileNumber : undefined,
        provider: paymentMethod === 'Mobile Money' ? provider : undefined
      });
      setSuccess(true);
    } catch (e: any) {
      setError(e.message || 'Booking failed. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return (
    <div className="flex-center" style={{ height: '100vh' }}>
      <div className="spinner" />
    </div>
  );
  if (!car) return <div className="container" style={{ paddingTop: 100 }}>Car not found.</div>;

  return (
    <div className="detail-page" style={{ paddingTop: 80 }}>

      <div className="detail-header">
        <div className="container">
          <button className="btn btn-ghost btn-sm detail-hero__back" onClick={() => navigate(-1)}>
            <ArrowLeft size={16}/> Back to Fleet
          </button>
          <div className="detail-hero__title">
            {/* Year removed */}
            <h1>{car.make} {car.model}</h1>
            <span className={`badge ${car.status === 'Available' ? 'badge-green' : 'badge-grey'}`}>{car.status}</span>
          </div>
        </div>
      </div>

      <div className="container detail-body">
        
        {/* Left — Car Info & Images */}
        <div className="detail-info">
          
          {/* Main Large Image */}
          <div className="car-main-image" onClick={() => setLightboxOpen(true)} style={{ cursor: 'zoom-in' }}>
            <img src={getCarImages(car)[activeImg]} alt={`${car.make} ${car.model}`} />
          </div>

          {/* Lightbox Modal */}
          {lightboxOpen && (
            <div className="lightbox-overlay" onClick={() => setLightboxOpen(false)}>
              <button className="lightbox-close" onClick={() => setLightboxOpen(false)}>
                <X size={24} color="#fff" />
              </button>
              <img src={getCarImages(car)[activeImg]} alt={`${car.make} ${car.model}`} className="lightbox-img" onClick={e => e.stopPropagation()} />
            </div>
          )}

          {/* Gallery Thumbnails */}
          {getCarImages(car).length > 1 && (
            <div className="car-gallery-thumbs">
              {getCarImages(car).map((src, i) => (
                <button 
                  key={i} 
                  className={`car-thumb ${i === activeImg ? 'car-thumb--active' : ''}`}
                  onClick={() => setActiveImg(i)}
                >
                  <img src={src} alt="thumbnail" />
                </button>
              ))}
            </div>
          )}

          {/* Key Specs */}
          <div className="specs-grid">
            {[
              { icon: Gauge,    label: 'Transmission', value: car.transmission },
              { icon: Fuel,     label: 'Fuel Type',    value: car.fuelType     },
              { icon: Users,    label: 'Seats',        value: `${car.seats} Passengers` },
              {/* Year removed */}
              {/* License Plate removed */}
              { icon: MapPin,   label: 'Odometer',     value: `${car.currentOdometer.toLocaleString()} km` },
            ].map(s => (
              <div key={s.label} className="spec-card">
                <s.icon size={18} className="gold-text"/>
                <div>
                  <div className="spec-label">{s.label}</div>
                  <div className="spec-value">{s.value}</div>
                </div>
              </div>
            ))}
          </div>

          {/* Features */}
          {car.features && car.features.length > 0 && (
            <div className="detail-section">
              <h3>Features & Amenities</h3>
              <div className="features-grid">
                {car.features.map((f, i) => (
                  <div key={i} className="feature-item">
                    <CheckCircle size={14} className="gold-text"/> {f}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Pricing — Dual Rate Selector */}
          <div className="detail-section">
            <h3 style={{ marginBottom: 16 }}>Select Trip Type</h3>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              {/* LOCAL rate card */}
              <div
                onClick={() => setIsOutofTown(false)}
                style={{
                  border: `2px solid ${!isOutofTown ? 'var(--gold)' : 'var(--border)'}`,
                  borderRadius: 'var(--radius)',
                  padding: '16px',
                  cursor: 'pointer',
                  background: !isOutofTown ? 'rgba(212,175,55,0.07)' : 'var(--bg-card)',
                  transition: 'all 0.2s ease',
                }}
              >
                <div style={{ fontSize: '0.65rem', fontWeight: 700, letterSpacing: '0.1em', textTransform: 'uppercase', color: !isOutofTown ? 'var(--gold)' : 'var(--text-3)', marginBottom: 6 }}>Local</div>
                <div style={{ fontSize: '1.3rem', fontWeight: 700, color: 'var(--text-1)', fontFamily: 'var(--font-head)' }}>{format(car.dailyRateZmw, car.dailyRateUsd)}</div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-3)', marginTop: 2 }}>/day</div>
              </div>
              {/* OUT OF TOWN rate card */}
              <div
                onClick={() => setIsOutofTown(true)}
                style={{
                  border: `2px solid ${isOutofTown ? 'var(--blue)' : 'var(--border)'}`,
                  borderRadius: 'var(--radius)',
                  padding: '16px',
                  cursor: car.dailyRateOutofTownZmw ? 'pointer' : 'not-allowed',
                  background: isOutofTown ? 'rgba(26,86,219,0.07)' : 'var(--bg-card)',
                  opacity: car.dailyRateOutofTownZmw ? 1 : 0.45,
                  transition: 'all 0.2s ease',
                }}
              >
                <div style={{ fontSize: '0.65rem', fontWeight: 700, letterSpacing: '0.1em', textTransform: 'uppercase', color: isOutofTown ? 'var(--blue)' : 'var(--text-3)', marginBottom: 6 }}>Out of Town</div>
                <div style={{ fontSize: '1.3rem', fontWeight: 700, color: 'var(--text-1)', fontFamily: 'var(--font-head)' }}>
                  {car.dailyRateOutofTownZmw ? format(car.dailyRateOutofTownZmw, car.dailyRateOutofTownUsd) : 'Not set'}
                </div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-3)', marginTop: 2 }}>/day</div>
              </div>
            </div>
            {days > 0 && (
              <div style={{ marginTop: 16, padding: '12px 16px', background: 'var(--bg-2)', borderRadius: 'var(--radius)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ color: 'var(--text-2)', fontSize: '0.9rem' }}>{days} days × {format(activeRateZmw, activeRateUsd)}</span>
                <strong style={{ color: 'var(--gold)', fontSize: '1.1rem', fontFamily: 'var(--font-head)' }}>{format(totalZmw, totalUsd)}</strong>
              </div>
            )}
          </div>
        </div>

        {/* Right — Booking Wizard */}
        <div className="booking-wizard">
          {car.isShuttleOnly ? (
            <div className="wizard-panel animate-slide" style={{ textAlign: 'center', padding: '48px 24px' }}>
              <div style={{ width: 64, height: 64, borderRadius: 16, background: '#eff6ff', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 24px auto' }}>
                <MapPin size={32} color="var(--blue)" />
              </div>
              <h3>Shuttle Service Only</h3>
              <p style={{ color: 'var(--text-2)', marginBottom: 24 }}>
                This {car.make} {car.model} is reserved exclusively for our premium chauffeur and shuttle services. 
                Pricing is determined by your specific route and requirements.
              </p>
              <a 
                href={`https://wa.me/260962431222?text=Hi! I am interested in booking the ${car.make} ${car.model} for a shuttle service.`}
                target="_blank" rel="noopener noreferrer"
                className="btn btn-gold" 
                style={{ width: '100%', justifyContent: 'center' }}
              >
                Request Quote via WhatsApp
              </a>
            </div>
          ) : success ? (
            <div className="wizard-success animate-slide">
              <CheckCircle size={48} color="var(--success)" />
              <h3>Booking Confirmed!</h3>
              <p>Your reservation for the {car.make} {car.model} has been placed.</p>
              <button className="btn btn-gold" onClick={() => navigate('/bookings')} id="view-bookings-btn">
                View My Bookings
              </button>
            </div>
          ) : (
            <>
              {/* Step Progress */}
              <div className="wizard-steps">
                {STEPS.map((s, i) => (
                  <div key={s} className={`wizard-step ${i === step ? 'active' : ''} ${i < step ? 'done' : ''}`}>
                    <div className="wizard-step__dot">{i < step ? '✓' : i + 1}</div>
                    <span>{s}</span>
                  </div>
                ))}
              </div>

              <div className="wizard-body">
                {step === 0 && (
                  <div className="wizard-panel animate-slide">
                    <h3>Select Rental Dates</h3>
                    <div className="form-group">
                      <label className="form-label" htmlFor="start-date">Pickup Date</label>
                      <input id="start-date" type="date" className="form-input"
                        value={startDate} min={new Date().toISOString().split('T')[0]}
                        onChange={e => setStartDate(e.target.value)} />
                    </div>
                    <div className="form-group">
                      <label className="form-label" htmlFor="end-date">Return Date</label>
                      <input id="end-date" type="date" className="form-input"
                        value={endDate} min={startDate ? new Date(new Date(startDate).getTime() + 86400000).toISOString().split('T')[0] : new Date().toISOString().split('T')[0]}
                        onChange={e => setEndDate(e.target.value)} />
                    </div>
                    {days > 0 && (
                      <div className="wizard-summary-pill">
                        {days} day{days > 1 ? 's' : ''} — {format(totalZmw, totalUsd)}
                        {!isValidDuration && <div style={{ color: 'var(--red)', fontSize: '0.8rem', marginTop: 4 }}>Minimum 2 days required</div>}
                      </div>
                    )}
                    <button className="btn btn-gold" disabled={!startDate || !endDate || !isValidDuration}
                      onClick={() => setStep(1)} id="wizard-next-1">
                      Continue
                    </button>
                  </div>
                )}

                {step === 1 && (
                  <div className="wizard-panel animate-slide">
                    <h3>Pickup & Dropoff</h3>
                    <div className="form-group">
                      <label className="form-label" htmlFor="pickup-loc">Pickup Location</label>
                      <select id="pickup-loc" className="form-input" value={pickupId} onChange={e => setPickupId(e.target.value)}>
                        {locations.length ? locations.map(l => <option key={l.id} value={l.id}>{l.name} — {l.address}</option>)
                          : <option value="default">Lusaka — Cairo Road Branch</option>}
                      </select>
                    </div>
                    <div className="form-group">
                      <label className="form-label" htmlFor="dropoff-loc">Dropoff Location</label>
                      <select id="dropoff-loc" className="form-input" value={dropoffId} onChange={e => setDropoffId(e.target.value)}>
                        {locations.length ? locations.map(l => <option key={l.id} value={l.id}>{l.name} — {l.address}</option>)
                          : <option value="default">Lusaka — Cairo Road Branch</option>}
                      </select>
                    </div>
                    <div className="wizard-nav">
                      <button className="btn btn-ghost btn-sm" onClick={() => setStep(0)}>Back</button>
                      <button className="btn btn-gold" onClick={() => setStep(2)} id="wizard-next-2">Continue</button>
                    </div>
                  </div>
                )}

                {step === 2 && (
                  <div className="wizard-panel animate-slide">
                    <h3>Review Booking</h3>
                    <div className="review-rows">
                      <div className="review-row"><span>Vehicle</span><strong>{car.make} {car.model}</strong></div>
                      <div className="review-row"><span>Dates</span><strong>{startDate} → {endDate}</strong></div>
                      <div className="review-row"><span>Duration</span><strong>{days} day{days !== 1 ? 's' : ''}</strong></div>
                      <div className="review-row"><span>Trip Type</span><strong style={{ color: isOutofTown ? 'var(--blue)' : 'var(--gold)' }}>{isOutofTown ? 'Out of Town' : 'Local'}</strong></div>
                      <div className="review-row"><span>Daily Rate</span><strong>{format(activeRateZmw, activeRateUsd)}</strong></div>
                      <div className="review-row review-row--total">
                        <span>Total</span>
                        <strong className="gold-text">{format(totalZmw, totalUsd)}</strong>
                      </div>
                    </div>
                    <div className="wizard-nav">
                      <button className="btn btn-ghost btn-sm" onClick={() => setStep(1)}>Back</button>
                      <button className="btn btn-gold" onClick={() => setStep(3)} id="wizard-next-3">Confirm Details</button>
                    </div>
                  </div>
                )}

                {step === 3 && (
                  <div className="wizard-panel animate-slide">
                    <h3>Finalise & Pay</h3>
                    <div className="form-group" style={{ marginBottom: 24 }}>
                      <label className="form-label">Payment Method</label>
                      <select className="form-input" value="Pay Later" disabled>
                        <option value="Pay Later">Pay Later (at counter)</option>
                      </select>
                      <p className="muted" style={{ fontSize: '0.8rem', marginTop: 8 }}>
                        Online payments are temporarily disabled. Please pay at the counter when you pick up your vehicle.
                      </p>
                    </div>

                    <p className="muted" style={{ fontSize: '0.875rem', marginBottom: 16 }}>
                      By confirming, you agree to our rental terms. A commercial invoice will be generated automatically.
                    </p>
                    {error && <div className="wizard-error">{error}</div>}
                    <div className="wizard-nav">
                      <button className="btn btn-ghost btn-sm" onClick={() => setStep(2)}>Back</button>
                      <button className="btn btn-gold" onClick={handleBook} disabled={submitting || (paymentMethod === 'Mobile Money' && !mobileNumber)} id="wizard-submit-btn">
                        {submitting ? 'Processing...' : 'Confirm Booking'}
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
