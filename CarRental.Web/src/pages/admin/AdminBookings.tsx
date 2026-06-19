import { useState, useEffect } from 'react';
import { getBookings, updateBooking, deleteBooking, createBooking, getProfiles, getCars, getLocations } from '../../api/client';
import { useCurrency } from '../../contexts/CurrencyContext';
import type { Booking, Profile, Car, Location } from '../../types';
import { Trash2, Pencil, X, FileText, Plus } from 'lucide-react';
import { Link } from 'react-router-dom';
import './Admin.css';
import ResponsiveTable from '../../components/ResponsiveTable';

const STATUS_OPTS = ['Confirmed','Active','Completed','Cancelled'];
const PAYMENT_OPTS = ['Pending','Paid','Refunded'];
const BADGE: Record<string, string> = { Confirmed:'badge-gold', Active:'badge-blue', Completed:'badge-green', Cancelled:'badge-red', Pending:'badge-grey', Paid:'badge-green', Refunded:'badge-blue' };

export default function AdminBookings() {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [cars, setCars] = useState<Car[]>([]);
  const [locations, setLocations] = useState<Location[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Booking | null>(null);
  
  // Create Modal State
  const [creating, setCreating] = useState(false);
  const [newBooking, setNewBooking] = useState<Partial<Booking>>({
    bookingType: 'Standard', status: 'Pending', paymentStatus: 'Pending'
  });

  const [saving, setSaving] = useState(false);
  const { format } = useCurrency();

  const load = () => {
    Promise.allSettled([getBookings(), getProfiles(), getCars(), getLocations()])
      .then(([b, p, c, l]) => {
        if (b.status === 'fulfilled') setBookings(b.value);
        if (p.status === 'fulfilled') setProfiles(p.value);
        if (c.status === 'fulfilled') setCars(c.value);
        if (l.status === 'fulfilled') setLocations(l.value);
      })
      .finally(() => setLoading(false));
  };
  useEffect(() => { load(); }, []);

  const save = async () => {
    if (!editing) return;
    setSaving(true);
    await updateBooking(editing.id, editing).catch(() => {});
    await load();
    setEditing(null);
    setSaving(false);
  };

  const remove = async (id: string) => {
    if (!confirm('Cancel this booking?')) return;
    try {
      await deleteBooking(id);
      load();
    } catch (err: any) {
      alert(`Failed to delete booking: ${err.message || 'Unknown error'}`);
    }
  };

  return (
    <div className="admin-page">
      <div className="page-header flex-between">
        <div>
          <h1>Bookings <span className="gold-text">Management</span></h1>
          <p>View and manage all customer reservations</p>
        </div>
        <button className="btn btn-gold" onClick={() => setCreating(true)} style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <Plus size={16}/> New Booking
        </button>
      </div>

      <div className="admin-section">
        {loading ? <div className="flex-center" style={{padding:48}}><div className="spinner"/></div> : (
          <>
            <div className="table-wrap hide-mobile">
              <ResponsiveTable>
<table className="data-table">
                <thead>
                  <tr><th>Customer</th><th>Vehicle</th><th className="hide-mobile">Dates</th><th>Total</th><th>Status</th><th className="hide-mobile">Payment</th><th>Actions</th></tr>
                </thead>
                <tbody>
                  {bookings.map(b => (
                    <tr key={b.id}>
                      <td>
                        <strong>{b.customer ? `${b.customer.firstName} ${b.customer.lastName}` : `${b.customerId.slice(0, 8)}…`}</strong>
                        <div className="show-mobile" style={{ fontSize: '0.75rem', color: 'var(--text-3)', marginTop: 4 }}>{b.startDate} → {b.endDate}</div>
                      </td>
                      <td><strong>{b.car?.make} {b.car?.model}</strong><br/><span style={{fontSize:'0.75rem', color:'var(--text-3)'}}>{b.bookingType || 'Standard'}</span></td>
                      <td className="hide-mobile" style={{fontSize:'0.82rem', color:'var(--text-2)'}}>{b.startDate} → {b.endDate}</td>
                      <td style={{color:'var(--gold)', fontFamily:'var(--font-head)'}}>{format(b.totalPriceZmw, b.totalPriceUsd)}</td>
                      <td>
                        <span className={`badge ${BADGE[b.status]??'badge-grey'}`}>{b.status}</span>
                        <span className={`badge ${BADGE[b.paymentStatus]??'badge-grey'} show-mobile`} style={{ marginTop: 4 }}>{b.paymentStatus}</span>
                      </td>
                      <td className="hide-mobile"><span className={`badge ${BADGE[b.paymentStatus]??'badge-grey'}`}>{b.paymentStatus}</span></td>
                      <td>
                        <div style={{display:'flex', gap:8}}>
                          <Link to={`/quote/${b.id}`} className="btn btn-ghost btn-sm" title="View Quotation"><FileText size={14}/></Link>
                          <button className="btn btn-ghost btn-sm" onClick={() => setEditing(b)} id={`edit-booking-${b.id}`}><Pencil size={14}/></button>
                          <button className="btn btn-danger btn-sm" onClick={() => remove(b.id)} id={`del-booking-${b.id}`}><Trash2 size={14}/></button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
</ResponsiveTable>
            </div>

            <div className="mobile-card-list">
              {bookings.map(b => (
                <div key={b.id} className="mobile-data-card">
                  <div className="mobile-data-card__header">
                    <div>
                      <div className="mobile-data-card__title">
                        {b.customer ? `${b.customer.firstName} ${b.customer.lastName}` : `Customer #${b.customerId.slice(0, 6).toUpperCase()}`}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-3)', marginTop: 4 }}>
                        {b.startDate} → {b.endDate}
                      </div>
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'flex-end' }}>
                      <span className={`badge ${BADGE[b.status]??'badge-grey'}`}>{b.status}</span>
                      <span className={`badge ${BADGE[b.paymentStatus]??'badge-grey'}`}>{b.paymentStatus}</span>
                    </div>
                  </div>
                  
                  <div className="mobile-data-card__body">
                    <div className="mobile-data-card__row">
                      <span className="mobile-data-card__label">Vehicle</span>
                      <span className="mobile-data-card__value" style={{ fontWeight: 600 }}>{b.car?.make} {b.car?.model}</span>
                    </div>
                    <div className="mobile-data-card__row">
                      <span className="mobile-data-card__label">Type</span>
                      <span className="mobile-data-card__value">{b.bookingType || 'Standard'}</span>
                    </div>
                    <div className="mobile-data-card__row">
                      <span className="mobile-data-card__label">Total Price</span>
                      <span className="mobile-data-card__value" style={{ color: 'var(--gold)', fontFamily: 'var(--font-head)', fontWeight: 700 }}>
                        {format(b.totalPriceZmw, b.totalPriceUsd)}
                      </span>
                    </div>
                  </div>

                  <div className="mobile-data-card__footer">
                    <span style={{ fontSize: '0.75rem', color: 'var(--text-3)' }}>ID: {b.id.slice(0, 8).toUpperCase()}</span>
                    <div style={{ display: 'flex', gap: 12 }}>
                      <Link to={`/quote/${b.id}`} className="btn btn-ghost btn-sm" title="View Quotation" style={{ padding: '6px 12px' }}><FileText size={14}/></Link>
                      <button className="btn btn-ghost btn-sm" onClick={() => setEditing(b)} id={`edit-booking-mob-${b.id}`} style={{ padding: '6px 12px' }}><Pencil size={14}/></button>
                      <button className="btn btn-danger btn-sm" onClick={() => remove(b.id)} id={`del-booking-mob-${b.id}`} style={{ padding: '6px 12px' }}><Trash2 size={14}/></button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {editing && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setEditing(null)}>
          <div className="modal-box">
            <div className="modal-header">
              <h2 className="modal-title">Edit Booking</h2>
              <button className="modal-close" onClick={() => setEditing(null)}><X size={18}/></button>
            </div>
            <div className="admin-form">
              <div className="admin-form-grid">
                <div className="form-group">
                  <label className="form-label">Status</label>
                  <select className="form-input" value={editing.status}
                    onChange={e => setEditing({...editing, status: e.target.value as any})} id="edit-status">
                    {STATUS_OPTS.map(o => <option key={o}>{o}</option>)}
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Payment Status</label>
                  <select className="form-input" value={editing.paymentStatus}
                    onChange={e => setEditing({...editing, paymentStatus: e.target.value as any})} id="edit-payment">
                    {PAYMENT_OPTS.map(o => <option key={o}>{o}</option>)}
                  </select>
                </div>
              </div>
              <div className="admin-form-actions">
                <button className="btn btn-ghost btn-sm" onClick={() => setEditing(null)}>Cancel</button>
                <button className="btn btn-gold btn-sm" onClick={save} disabled={saving} id="save-booking-btn">
                  {saving ? 'Saving...' : 'Save Changes'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {creating && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setCreating(false)}>
          <div className="modal-box" style={{ maxWidth: 600 }}>
            <div className="modal-header">
              <h2 className="modal-title">Create Custom Booking</h2>
              <button className="modal-close" onClick={() => setCreating(false)}><X size={18}/></button>
            </div>
            <div className="admin-form">
              <div className="admin-form-grid" style={{ gridTemplateColumns: '1fr 1fr' }}>
                <div className="form-group">
                  <label className="form-label">Booking Type</label>
                  <select className="form-input" value={newBooking.bookingType} onChange={e => setNewBooking({...newBooking, bookingType: e.target.value})}>
                    <option>Standard</option>
                    <option>Airport Transfer</option>
                    <option>Wedding</option>
                    <option>Chauffeur</option>
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Customer</label>
                  <select className="form-input" value={newBooking.customerId || ''} onChange={e => setNewBooking({...newBooking, customerId: e.target.value})}>
                    <option value="">-- Select Customer --</option>
                    {profiles.map(p => <option key={p.id} value={p.id}>{p.firstName} {p.lastName} ({p.phoneNumber || p.id.slice(0,6)})</option>)}
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Vehicle</label>
                  <select className="form-input" value={newBooking.carId || ''} onChange={e => setNewBooking({...newBooking, carId: e.target.value})}>
                    <option value="">-- Select Vehicle --</option>
                    {cars.map(c => <option key={c.id} value={c.id}>{c.make} {c.model}</option>)}
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Custom Price (ZMW)</label>
                  <input type="number" className="form-input" value={newBooking.totalPriceZmw || 0} onChange={e => setNewBooking({...newBooking, totalPriceZmw: parseFloat(e.target.value)})} />
                </div>
                <div className="form-group">
                  <label className="form-label">Start Date</label>
                  <input type="date" className="form-input" value={newBooking.startDate || ''} onChange={e => setNewBooking({...newBooking, startDate: e.target.value})} />
                </div>
                <div className="form-group">
                  <label className="form-label">End Date</label>
                  <input type="date" className="form-input" value={newBooking.endDate || ''} onChange={e => setNewBooking({...newBooking, endDate: e.target.value})} />
                </div>
                <div className="form-group">
                  <label className="form-label">Status (Quotation vs Invoice)</label>
                  <select className="form-input" value={newBooking.status} onChange={e => setNewBooking({...newBooking, status: e.target.value as any})}>
                    <option value="Pending">Pending (Quotation)</option>
                    <option value="Confirmed">Confirmed (Invoice)</option>
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Payment Status</label>
                  <select className="form-input" value={newBooking.paymentStatus} onChange={e => setNewBooking({...newBooking, paymentStatus: e.target.value as any})}>
                    <option value="Pending">Pending</option>
                    <option value="Paid">Paid</option>
                  </select>
                </div>
              </div>
              <div className="form-group" style={{ marginTop: 16 }}>
                <label className="form-label">Special Notes / Requirements</label>
                <textarea className="form-input" rows={3} value={newBooking.notes || ''} onChange={e => setNewBooking({...newBooking, notes: e.target.value})} placeholder="E.g., Flight EK713 landing at 14:00, needs child seat..." />
              </div>
              <div className="admin-form-actions" style={{ marginTop: 24 }}>
                <button className="btn btn-ghost btn-sm" onClick={() => setCreating(false)}>Cancel</button>
                <button className="btn btn-gold btn-sm" disabled={saving || !newBooking.customerId || !newBooking.carId} onClick={async () => {
                  setSaving(true);
                  if (!newBooking.pickupLocationId) newBooking.pickupLocationId = locations[0]?.id;
                  if (!newBooking.dropoffLocationId) newBooking.dropoffLocationId = locations[0]?.id;
                  await createBooking(newBooking).catch(() => {});
                  await load();
                  setCreating(false);
                  setSaving(false);
                }}>
                  {saving ? 'Creating...' : 'Create Booking'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
