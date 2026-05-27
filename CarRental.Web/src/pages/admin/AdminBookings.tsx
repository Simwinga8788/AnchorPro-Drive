import { useState, useEffect } from 'react';
import { getBookings, updateBooking, deleteBooking } from '../../api/client';
import { useCurrency } from '../../contexts/CurrencyContext';
import type { Booking } from '../../types';
import { Trash2, Pencil, X } from 'lucide-react';
import './Admin.css';

const STATUS_OPTS = ['Confirmed','Active','Completed','Cancelled'];
const PAYMENT_OPTS = ['Pending','Paid','Refunded'];
const BADGE: Record<string, string> = { Confirmed:'badge-gold', Active:'badge-blue', Completed:'badge-green', Cancelled:'badge-red', Pending:'badge-grey', Paid:'badge-green', Refunded:'badge-blue' };

export default function AdminBookings() {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Booking | null>(null);
  const [saving, setSaving] = useState(false);
  const { format } = useCurrency();

  const load = () => getBookings().then(b => setBookings(b)).catch(() => {}).finally(() => setLoading(false));
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
    await deleteBooking(id).catch(() => {});
    load();
  };

  return (
    <div className="admin-page">
      <div className="page-header">
        <h1>Bookings <span className="gold-text">Management</span></h1>
        <p>View and manage all customer reservations</p>
      </div>

      <div className="admin-section">
        {loading ? <div className="flex-center" style={{padding:48}}><div className="spinner"/></div> : (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr><th>Customer</th><th>Vehicle</th><th>Dates</th><th>Total</th><th>Status</th><th>Payment</th><th>Actions</th></tr>
              </thead>
              <tbody>
                {bookings.map(b => (
                  <tr key={b.id}>
                    <td style={{fontSize:'0.8rem', color:'var(--text-2)', fontFamily:'monospace'}}>{b.customerId.slice(0,8)}…</td>
                    <td><strong>{b.car?.make} {b.car?.model}</strong></td>
                    <td style={{fontSize:'0.82rem', color:'var(--text-2)'}}>{b.startDate} → {b.endDate}</td>
                    <td style={{color:'var(--gold)', fontFamily:'var(--font-head)'}}>{format(b.totalPriceZmw, b.totalPriceUsd)}</td>
                    <td><span className={`badge ${BADGE[b.status]??'badge-grey'}`}>{b.status}</span></td>
                    <td><span className={`badge ${BADGE[b.paymentStatus]??'badge-grey'}`}>{b.paymentStatus}</span></td>
                    <td>
                      <div style={{display:'flex', gap:8}}>
                        <button className="btn btn-ghost btn-sm" onClick={() => setEditing(b)} id={`edit-booking-${b.id}`}><Pencil size={14}/></button>
                        <button className="btn btn-danger btn-sm" onClick={() => remove(b.id)} id={`del-booking-${b.id}`}><Trash2 size={14}/></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
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
    </div>
  );
}
