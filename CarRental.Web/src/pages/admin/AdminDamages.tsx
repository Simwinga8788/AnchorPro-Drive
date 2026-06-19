import React, { useState, useEffect } from 'react';
import { getDamages, getCars, getBookings, createDamage, updateDamage, deleteDamage, createPayment } from '../../api/client';
import type { Damage, Car, Booking } from '../../types';
import { supabase } from '../../lib/supabase';
import { AlertTriangle, Plus, X, Upload } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { Link } from 'react-router-dom';
import './Admin.css';
import ResponsiveTable from '../../components/ResponsiveTable';

const SEV_BADGE: Record<string, string> = { Minor:'badge-blue', Moderate:'badge-gold', Major:'badge-red' };
const REP_BADGE: Record<string, string> = { Pending:'badge-grey', 'In Progress':'badge-gold', Completed:'badge-green' };

export default function AdminDamages() {
  const [damages, setDamages] = useState<Damage[]>([]);
  const [cars, setCars] = useState<Car[]>([]);
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingDamage, setEditingDamage] = useState<Damage | null>(null);

  const fetchAll = async () => {
    setLoading(true);
    try {
      const [d, c, b] = await Promise.all([getDamages(), getCars(), getBookings()]);
      setDamages(d);
      setCars(c);
      setBookings(b);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAll();
  }, []);

  const handleEdit = (d: Damage) => {
    setEditingDamage(d);
    setIsModalOpen(true);
  };

  const handleDelete = async (d: Damage) => {
    if (!window.confirm('Are you sure you want to delete this damage report?')) return;
    try {
      await deleteDamage(d.id);
      setDamages(damages.filter(x => x.id !== d.id));
    } catch (err) {
      console.error(err);
      alert('Failed to delete damage report');
    }
  };

  return (
    <div className="admin-page">
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <h1>Damage <span className="gold-text">Reports</span></h1>
          <p>Vehicle damage tracking and repair status</p>
        </div>
        <button className="btn btn-gold" onClick={() => { setEditingDamage(null); setIsModalOpen(true); }}>
          <Plus size={18} /> Report Damage
        </button>
      </div>

      <div className="admin-section">
        {loading ? <div className="flex-center" style={{padding:48}}><div className="spinner"/></div> : damages.length === 0 ? (
          <p className="muted" style={{padding:'24px 0'}}>No damage reports on record. Great news!</p>
        ) : (
          <>
            <div className="table-wrap hide-mobile">
              <ResponsiveTable>
<table className="data-table">
                <thead>
                  <tr>
                    <th>Vehicle</th>
                    <th className="hide-mobile">Customer / Booking</th>
                    <th className="hide-mobile">Description</th>
                    <th>Severity</th>
                    <th>Repair Status</th>
                    <th>Est. Cost (ZMW)</th>
                    <th className="hide-mobile">Reported</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {damages.map(d => (
                    <tr key={d.id}>
                      <td>
                        <strong>{d.car?.make ?? '—'} {d.car?.model ?? ''}</strong>
                        <div className="show-mobile" style={{ fontSize: '0.75rem', color: 'var(--text-3)', marginTop: 4 }}>
                          {d.booking ? (
                            <>
                              #{d.booking.id.slice(0, 8).toUpperCase()}
                              {d.booking.customer && ` - ${d.booking.customer.firstName.slice(0, 1)}. ${d.booking.customer.lastName}`}
                            </>
                          ) : (
                            'General Maint.'
                          )}
                        </div>
                      </td>
                      <td className="hide-mobile">
                        {d.booking ? (
                          <div>
                            <Link to={`/quote/${d.booking.id}`} className="gold-text" style={{ fontWeight: 500, textDecoration: 'none' }}>
                              Booking #{d.booking.id.slice(0, 8).toUpperCase()}
                            </Link>
                            {d.booking.customer && (
                              <div style={{ fontSize: '0.78rem', color: 'var(--text-2)', marginTop: 2 }}>
                                {d.booking.customer.firstName} {d.booking.customer.lastName}
                              </div>
                            )}
                          </div>
                        ) : (
                          <span className="muted" style={{ fontSize: '0.8rem' }}>General / Maintenance</span>
                        )}
                      </td>
                      <td className="hide-mobile" style={{maxWidth:240, fontSize:'0.85rem', color:'var(--text-2)'}}>{d.description}</td>
                      <td><span className={`badge ${SEV_BADGE[d.severity]??'badge-grey'}`}>{d.severity}</span></td>
                      <td><span className={`badge ${REP_BADGE[d.repairStatus]??'badge-grey'}`}>{d.repairStatus}</span></td>
                      <td style={{fontFamily:'var(--font-head)', color:'var(--gold)'}}>{d.repairCostEstimate ? `K${d.repairCostEstimate.toLocaleString()}` : '—'}</td>
                      <td className="hide-mobile" style={{fontSize:'0.8rem', color:'var(--text-2)'}}>{d.createdAt ? new Date(d.createdAt).toLocaleDateString() : '—'}</td>
                      <td>
                        <div style={{ display: 'flex', gap: 8 }}>
                          <button className="btn btn-sm" onClick={() => handleEdit(d)}>Edit</button>
                          <button className="btn btn-sm btn-ghost" style={{ color: 'var(--red)' }} onClick={() => handleDelete(d)}>Delete</button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
</ResponsiveTable>
            </div>

            <div className="mobile-card-list">
              {damages.map(d => (
                <div key={d.id} className="mobile-data-card">
                  <div className="mobile-data-card__header">
                    <div>
                      <div className="mobile-data-card__title">
                        {d.car?.make ?? '—'} {d.car?.model ?? 'Vehicle'}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-3)', marginTop: 4 }}>
                        {d.booking ? `Booking: #${d.booking.id.slice(0, 8).toUpperCase()}` : 'General / Maintenance'}
                      </div>
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'flex-end' }}>
                      <span className={`badge ${SEV_BADGE[d.severity]??'badge-grey'}`}>{d.severity}</span>
                      <span className={`badge ${REP_BADGE[d.repairStatus]??'badge-grey'}`}>{d.repairStatus}</span>
                    </div>
                  </div>
                  
                  <div className="mobile-data-card__body">
                    {d.booking?.customer && (
                      <div className="mobile-data-card__row">
                        <span className="mobile-data-card__label">Customer</span>
                        <span className="mobile-data-card__value">
                          {d.booking.customer.firstName} {d.booking.customer.lastName}
                        </span>
                      </div>
                    )}
                    <div className="mobile-data-card__row" style={{ alignItems: 'flex-start' }}>
                      <span className="mobile-data-card__label">Description</span>
                      <span className="mobile-data-card__value" style={{ textAlign: 'right', maxWidth: '70%', fontSize: '0.8rem' }}>
                        {d.description}
                      </span>
                    </div>
                    <div className="mobile-data-card__row">
                      <span className="mobile-data-card__label">Est. Cost</span>
                      <span className="mobile-data-card__value" style={{ color: 'var(--gold)', fontFamily: 'var(--font-head)', fontWeight: 700 }}>
                        {d.repairCostEstimate ? `K${d.repairCostEstimate.toLocaleString()}` : '—'}
                      </span>
                    </div>
                  </div>

                  <div className="mobile-data-card__footer">
                    <span style={{ fontSize: '0.75rem', color: 'var(--text-3)' }}>
                      Reported: {d.createdAt ? new Date(d.createdAt).toLocaleDateString() : '—'}
                    </span>
                    <div style={{ display: 'flex', gap: 8 }}>
                      <button className="btn btn-ghost btn-sm" onClick={() => handleEdit(d)} style={{ padding: '6px 12px' }}>
                        Edit
                      </button>
                      <button className="btn btn-ghost btn-sm" onClick={() => handleDelete(d)} style={{ padding: '6px 12px', color: 'var(--red)' }}>
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {isModalOpen && (
        <DamageModal 
          damage={editingDamage}
          cars={cars}
          bookings={bookings}
          onClose={() => setIsModalOpen(false)}
          onSaved={() => { setIsModalOpen(false); fetchAll(); }}
        />
      )}
    </div>
  );
}

interface DamageModalProps {
  damage: Damage | null;
  cars: Car[];
  bookings: Booking[];
  onClose: () => void;
  onSaved: () => void;
}

function DamageModal({ damage, cars, bookings, onClose, onSaved }: DamageModalProps) {
  const { user } = useAuth();
  const [formData, setFormData] = useState<Partial<Damage>>(damage || {
    severity: 'Minor',
    repairStatus: 'Pending',
    description: '',
    carId: cars[0]?.id || '',
    repairCostEstimate: 0,
    imageUrls: [],
    bookingId: undefined
  });
  
  const [chargeStatus, setChargeStatus] = useState<'none' | 'pending' | 'paid'>('none');
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      const submissionData = {
        ...formData,
        reportedByProfileId: damage?.reportedByProfileId || user?.id || undefined
      };

      let dRecord: Damage;
      if (damage?.id) {
        await updateDamage(damage.id, submissionData);
        dRecord = { ...damage, ...submissionData } as Damage;
      } else {
        dRecord = await createDamage(submissionData);
      }

      // Automatically charge customer if requested and booking/cost are valid
      if (chargeStatus !== 'none' && submissionData.bookingId && (submissionData.repairCostEstimate || 0) > 0) {
        const selectedBooking = bookings.find(b => b.id === submissionData.bookingId);
        if (selectedBooking) {
          await createPayment({
            bookingId: submissionData.bookingId,
            profileId: selectedBooking.customerId,
            amountZmw: submissionData.repairCostEstimate,
            currency: 'ZMW',
            paymentMethod: 'Bank Transfer',
            status: chargeStatus === 'paid' ? 'Completed' : 'Pending',
            type: 'Penalty',
            transactionId: `DMG-${dRecord.id.slice(0, 8).toUpperCase()}`,
          });
        }
      }

      onSaved();
    } catch (err) {
      console.error(err);
      alert('Failed to save damage report');
    } finally {
      setSaving(false);
    }
  };

  const handlePhotoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return;
    setUploading(true);
    try {
      const newUrls = [...(formData.imageUrls || [])];
      for (const file of Array.from(e.target.files)) {
        const fileExt = file.name.split('.').pop();
        const fileName = `${Math.random()}.${fileExt}`;
        const filePath = `damages/${fileName}`;
        
        const { error } = await supabase.storage.from('cars').upload(filePath, file);
        if (error) throw error;
        
        const { data } = supabase.storage.from('cars').getPublicUrl(filePath);
        newUrls.push(data.publicUrl);
      }
      setFormData({ ...formData, imageUrls: newUrls });
    } catch (err) {
      console.error(err);
      alert('Failed to upload image');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-box" style={{ maxWidth: 500 }}>
        <div className="modal-header">
          <h2 className="modal-title">{damage ? 'Edit' : 'Report'} <span className="gold-text">Damage</span></h2>
          <button className="modal-close" onClick={onClose}><X size={24} /></button>
        </div>

        <form onSubmit={handleSave} style={{ display: 'flex', flexDirection: 'column', gap: 16, marginTop: 24 }}>
          <div className="form-group">
            <label>Vehicle</label>
            <select 
              value={formData.carId} 
              onChange={e => {
                const newCarId = e.target.value;
                setFormData({...formData, carId: newCarId, bookingId: undefined});
                setChargeStatus('none');
              }}
              required
              disabled={!!damage}
            >
              <option value="">Select a vehicle...</option>
              {cars.map(c => <option key={c.id} value={c.id}>{c.make} {c.model}</option>)}
            </select>
          </div>

          {formData.carId && (
            <div className="form-group">
              <label>Associated Booking (Customer / Rental)</label>
              <select 
                value={formData.bookingId || ''} 
                onChange={e => {
                  const bId = e.target.value || undefined;
                  setFormData({...formData, bookingId: bId});
                  if (!bId) setChargeStatus('none');
                }}
              >
                <option value="">-- No Associated Booking (General Maintenance) --</option>
                {bookings
                  .filter(b => b.carId === formData.carId)
                  .map(b => (
                    <option key={b.id} value={b.id}>
                      Booking #{b.id.slice(0,8).toUpperCase()} - {b.customer ? `${b.customer.firstName} ${b.customer.lastName}` : 'Unknown'} ({b.startDate} to {b.endDate})
                    </option>
                  ))}
              </select>
            </div>
          )}

          <div className="form-group">
            <label>Severity</label>
            <select 
              value={formData.severity} 
              onChange={e => setFormData({...formData, severity: e.target.value as any})}
            >
              <option value="Minor">Minor</option>
              <option value="Moderate">Moderate</option>
              <option value="Major">Major</option>
            </select>
          </div>

          <div className="form-group">
            <label>Repair Status</label>
            <select 
              value={formData.repairStatus} 
              onChange={e => setFormData({...formData, repairStatus: e.target.value as any})}
            >
              <option value="Pending">Pending</option>
              <option value="In Progress">In Progress</option>
              <option value="Completed">Completed</option>
            </select>
          </div>

          <div className="form-group">
            <label>Description</label>
            <textarea 
              value={formData.description} 
              onChange={e => setFormData({...formData, description: e.target.value})}
              required
              rows={3}
              placeholder="Describe the damage..."
            />
          </div>

          <div className="form-group">
            <label>Estimated Repair Cost (ZMW)</label>
            <input 
              type="number" 
              value={formData.repairCostEstimate || ''} 
              onChange={e => setFormData({...formData, repairCostEstimate: parseFloat(e.target.value) || 0})}
            />
          </div>

          {/* Charge customer flow */}
          {formData.bookingId && (formData.repairCostEstimate || 0) > 0 && (
            <div className="form-group" style={{ padding: 12, background: 'rgba(255,255,255,0.03)', borderRadius: 8, border: '1px solid var(--border)', marginTop: 8 }}>
              <label style={{ display: 'block', marginBottom: 8, fontWeight: 600, fontSize: '0.85rem' }}>Damage Charge to Customer</label>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', fontSize: '0.85rem' }}>
                  <input 
                    type="radio" 
                    name="chargeStatus" 
                    value="none" 
                    checked={chargeStatus === 'none'} 
                    onChange={() => setChargeStatus('none')} 
                  />
                  Do not charge customer
                </label>
                <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', fontSize: '0.85rem' }}>
                  <input 
                    type="radio" 
                    name="chargeStatus" 
                    value="pending" 
                    checked={chargeStatus === 'pending'} 
                    onChange={() => setChargeStatus('pending')} 
                  />
                  Charge customer (Pending payment: K{(formData.repairCostEstimate || 0).toLocaleString()})
                </label>
                <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', fontSize: '0.85rem' }}>
                  <input 
                    type="radio" 
                    name="chargeStatus" 
                    value="paid" 
                    checked={chargeStatus === 'paid'} 
                    onChange={() => setChargeStatus('paid')} 
                  />
                  Charge customer (Paid on the spot: K{(formData.repairCostEstimate || 0).toLocaleString()})
                </label>
              </div>
            </div>
          )}

          <div className="form-group">
            <label>Photos</label>
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 8 }}>
              {formData.imageUrls?.map((url, i) => (
                <div key={i} style={{ position: 'relative', width: 80, height: 80 }}>
                  <img src={url} alt="Damage" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: 4 }} />
                  <button type="button" 
                    onClick={() => setFormData({...formData, imageUrls: formData.imageUrls?.filter((_, index) => index !== i)})}
                    style={{ position: 'absolute', top: -6, right: -6, background: 'red', color: 'white', border: 'none', borderRadius: '50%', width: 20, height: 20, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
                    <X size={12} />
                  </button>
                </div>
              ))}
            </div>
            <label className="btn btn-outline" style={{ display: 'inline-flex', gap: 8, alignItems: 'center', cursor: 'pointer' }}>
              <Upload size={16} /> {uploading ? 'Uploading...' : 'Upload Photos'}
              <input type="file" multiple accept="image/*" onChange={handlePhotoUpload} style={{ display: 'none' }} disabled={uploading} />
            </label>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 12, marginTop: 16 }}>
            <button type="button" className="btn btn-outline" onClick={onClose}>Cancel</button>
            <button type="submit" className="btn btn-gold" disabled={saving || uploading}>
              {saving ? 'Saving...' : 'Save Report'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
