import { useState, useEffect } from 'react';
import { Calendar, Car, MapPin, CreditCard, Clock, FileText } from 'lucide-react';
import { Link } from 'react-router-dom';
import { getBookings } from '../api/client';
import { useCurrency } from '../contexts/CurrencyContext';
import type { Booking } from '../types';

import { useAuth } from '../contexts/AuthContext';

const STATUS_BADGE: Record<string, string> = {
  Confirmed: 'badge-gold',
  Active: 'badge-blue',
  Completed: 'badge-green',
  Cancelled: 'badge-red',
};
const PAYMENT_BADGE: Record<string, string> = {
  Pending: 'badge-grey',
  Paid: 'badge-green',
  Refunded: 'badge-blue',
};

export default function BookingsPage() {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const { format } = useCurrency();

  const { user } = useAuth();

  useEffect(() => {
    if (!user) {
      setLoading(false);
      return;
    }
    getBookings()
      .then(b => {
        const myBookings = b.filter(x => x.customerId === user.id);
        setBookings(myBookings);
      })
      .catch(() => setBookings([]))
      .finally(() => setLoading(false));
  }, [user]);

  return (
    <div style={{ paddingTop: 80 }}>
      <div className="container">
        <div className="page-header">
          <h1>My <span className="gold-text">Bookings</span></h1>
          <p>Track and manage all your rental reservations</p>
        </div>

        {loading ? (
          <div className="flex-center" style={{ padding: 80 }}><div className="spinner"/></div>
        ) : bookings.length === 0 ? (
          <div style={{ textAlign:'center', padding:'80px 0' }}>
            <Calendar size={48} color="var(--text-3)" style={{ margin:'0 auto 16px' }}/>
            <p className="muted">No bookings yet. <a href="/fleet" className="gold-text">Browse our fleet</a> to get started.</p>
          </div>
        ) : (
          <div style={{ display:'flex', flexDirection:'column', gap:16 }}>
            {bookings.map(b => (
              <div key={b.id} className="card booking-card animate-fade" style={{ padding: 0 }}>
                <div className="booking-card__body">
                  <div className="booking-card__left">
                    <div className="booking-card__header">
                      <Car size={15} className="gold-text"/>
                      <strong>{b.car?.make} {b.car?.model} {b.car?.year}</strong>
                    </div>
                    <div className="booking-card__dates">
                      <Clock size={13} className="gold-text"/>
                      {b.startDate} → {b.endDate}
                    </div>
                    {b.pickupLocation && (
                      <div className="booking-card__location">
                        <MapPin size={13} className="gold-text"/>
                        {b.pickupLocation.name}
                      </div>
                    )}
                  </div>
                  <div className="booking-card__right">
                    <div className="booking-card__price">
                      <CreditCard size={15} className="gold-text"/>
                      {format(b.totalPriceZmw, b.totalPriceUsd)}
                    </div>
                    <span className={`badge ${STATUS_BADGE[b.status] ?? 'badge-grey'}`}>{b.status}</span>
                    <span className={`badge ${PAYMENT_BADGE[b.paymentStatus] ?? 'badge-grey'}`}>{b.paymentStatus}</span>
                    <Link to={`/quote/${b.id}`} className="btn btn-gold btn-sm" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <FileText size={14} />
                      {b.status === 'Pending' || b.status === 'Draft' ? 'View Quote' : 'View Invoice'}
                    </Link>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <style>{`
        .booking-card__body {
          display: flex; justify-content: space-between; align-items: center;
          padding: 20px 24px; gap: 24px; flex-wrap: wrap;
        }
        .booking-card__left { display: flex; flex-direction: column; gap: 8px; }
        .booking-card__header { display: flex; align-items: center; gap: 8px; font-size: 1rem; color: var(--text); }
        .booking-card__dates, .booking-card__location { display: flex; align-items: center; gap: 6px; font-size: 0.83rem; color: var(--text-2); }
        .booking-card__right { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
        .booking-card__price { display: flex; align-items: center; gap: 6px; font-family: var(--font-head); font-size: 1.2rem; color: var(--gold); }
      `}</style>
    </div>
  );
}
