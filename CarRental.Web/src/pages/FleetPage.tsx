import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Search, SlidersHorizontal, Fuel, Users, Gauge, ArrowRight, MapPin } from 'lucide-react';
import { getCars, getLocations } from '../api/client';
import { useCurrency } from '../contexts/CurrencyContext';
import type { Car, Location } from '../types';
import './FleetPage.css';

const CAR_IMAGES: Record<string, string> = {
  default:        'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=600&q=80',
  'Land Cruiser': 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=600&q=80',
  'GLE':          'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=600&q=80',
  '5 Series':     'https://images.unsplash.com/photo-1556189250-72ba954cfc2b?w=600&q=80',
  'Sport':        'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=600&q=80',
  'Hilux':        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80',
  'Fortuner':     'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?w=600&q=80',
  'Corolla':      'https://images.unsplash.com/photo-1550355291-bbee04a92027?w=600&q=80',
};

function getCarImage(car: Car): string {
  if (car.imageUrls && car.imageUrls.length > 0) return car.imageUrls[0];
  for (const key of Object.keys(CAR_IMAGES)) {
    if (car.model.includes(key) || car.make.includes(key)) return CAR_IMAGES[key];
  }
  return CAR_IMAGES.default;
}



export default function FleetPage() {
  const [cars, setCars] = useState<Car[]>([]);
  const [locations, setLocations] = useState<Location[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState('All');
  const [filterTransmission, setFilterTransmission] = useState('All');
  const [filterFuel, setFilterFuel] = useState('All');
  const [maxRate, setMaxRate] = useState(5000);
  const [showFilters, setShowFilters] = useState(false);
  const { format } = useCurrency();

  useEffect(() => {
    Promise.all([getCars(), getLocations()])
      .then(([c, l]) => { setCars(c); setLocations(l); })
      .catch(() => { setCars([]); })
      .finally(() => setLoading(false));
  }, []);

  const filtered = cars.filter(c => {
    const q = search.toLowerCase();
    const matchSearch = !q || `${c.make} ${c.model}`.toLowerCase().includes(q);
    const matchStatus = filterStatus === 'All' || c.status === filterStatus;
    const matchTrans = filterTransmission === 'All' || c.transmission === filterTransmission;
    const matchFuel = filterFuel === 'All' || c.fuelType === filterFuel;
    const matchRate = c.dailyRateZmw <= maxRate;
    return matchSearch && matchStatus && matchTrans && matchFuel && matchRate;
  });

  return (
    <div className="fleet-page" style={{ paddingTop: 80 }}>
      <div className="container">

        {/* Header */}
        <div className="page-header">
          <h1>Our <span className="gold-text">Fleet</span></h1>
          <p>Browse {cars.length} premium vehicles available across Zambia</p>
        </div>

        {/* Search + Filter Bar */}
        <div className="fleet__toolbar">
          <div className="fleet__search">
            <Search size={16} className="fleet__search-icon" />
            <input
              id="fleet-search"
              className="form-input"
              placeholder="Search by make, model..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              style={{ paddingLeft: 40 }}
            />
          </div>
          <button
            className={`btn btn-outline btn-sm ${showFilters ? 'btn-gold' : ''}`}
            onClick={() => setShowFilters(f => !f)}
            id="filter-toggle-btn"
          >
            <SlidersHorizontal size={15}/> Filters
          </button>
        </div>

        {/* Expanded Filters */}
        {showFilters && (
          <div className="fleet__filters animate-slide">
            <div className="form-group">
              <label className="form-label">Status</label>
              <select className="form-input" value={filterStatus} onChange={e => setFilterStatus(e.target.value)} id="filter-status">
                {['All','Available','Rented','In Maintenance','Damaged','Unavailable'].map(o => <option key={o} value={o}>{o}</option>)}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Transmission</label>
              <select className="form-input" value={filterTransmission} onChange={e => setFilterTransmission(e.target.value)} id="filter-transmission">
                {['All','Automatic','Manual'].map(o => <option key={o}>{o}</option>)}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Fuel Type</label>
              <select className="form-input" value={filterFuel} onChange={e => setFilterFuel(e.target.value)} id="filter-fuel">
                {['All','Petrol','Diesel','Hybrid','Electric'].map(o => <option key={o}>{o}</option>)}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Max Rate — K{maxRate.toLocaleString()}/day</label>
              <input type="range" min={500} max={5000} step={100} value={maxRate}
                onChange={e => setMaxRate(+e.target.value)} id="filter-rate"
                className="rate-slider"
              />
            </div>
          </div>
        )}

        {/* Results count */}
        <p className="fleet__count muted">
          Showing <strong style={{color:'var(--gold)'}}>{filtered.length}</strong> of {cars.length} vehicles
        </p>

        {/* Grid */}
        {loading ? (
          <div className="grid-cards">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="car-card-skeleton">
                <div className="skeleton" style={{ height: 200 }} />
                <div style={{ padding: 20, display:'flex', flexDirection:'column', gap:10 }}>
                  <div className="skeleton" style={{ height: 24, width: '60%' }} />
                  <div className="skeleton" style={{ height: 14, width: '80%' }} />
                  <div className="skeleton" style={{ height: 36 }} />
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="grid-cards">
            {filtered.map(car => (
              <div key={car.id} className="card car-card">
                <Link to={`/fleet/${car.id}`} className="car-card__img" style={{ display: 'block' }}>
                  <img src={getCarImage(car)} alt={`${car.make} ${car.model}`} loading="lazy" />
                  <span className={`badge car-card__status ${
                    car.status === 'Available' ? 'badge-green' :
                    car.status === 'Rented' ? 'badge-gold' : 'badge-grey'
                  }`}>{car.status}</span>
                  {car.isShuttleOnly && (
                    <span className="badge" style={{ position: 'absolute', top: 12, left: 12, background: 'var(--blue)', color: '#fff', fontSize: '0.7rem' }}>
                      SHUTTLE ONLY
                    </span>
                  )}
                </Link>
                <div className="car-card__body">
                  {/* Year removed */}
                  <Link to={`/fleet/${car.id}`} style={{ textDecoration: 'none', color: 'inherit' }}>
                    <h3 className="car-card__name">{car.make} {car.model}</h3>
                  </Link>
                  {car.location && (
                    <div className="car-card__location">
                      <MapPin size={12}/> {car.location.name}
                    </div>
                  )}
                  <div className="car-card__specs">
                    <span><Gauge size={13}/> {car.transmission}</span>
                    <span><Fuel size={13}/> {car.fuelType}</span>
                    <span><Users size={13}/> {car.seats} seats</span>
                  </div>
                  <div className="car-card__footer">
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                      <div className="car-card__rate">
                        <span className="rate-zmw">{format(car.dailyRateZmw, car.dailyRateUsd)}</span>
                        <span className="rate-label">/day (local)</span>
                      </div>
                      {car.dailyRateOutofTownZmw && (
                        <div className="car-card__rate">
                          <span className="rate-zmw">{format(car.dailyRateOutofTownZmw, car.dailyRateOutofTownUsd)}</span>
                          <span className="rate-label">/day (out-of-town)</span>
                        </div>
                      )}
                    </div>
                    {car.status === 'Available' && (
                      <Link to={`/fleet/${car.id}`} className="btn btn-gold btn-sm" id={`book-car-${car.id}`}>
                        {car.isShuttleOnly ? 'Request' : 'Book'} <ArrowRight size={13}/>
                      </Link>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {!loading && filtered.length === 0 && (
          <div className="fleet__empty">
            <p className="muted">No vehicles match your filters.</p>
            <button className="btn btn-outline btn-sm" onClick={() => { setSearch(''); setFilterStatus('All'); setFilterTransmission('All'); setFilterFuel('All'); setMaxRate(5000); }}>
              Clear Filters
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
