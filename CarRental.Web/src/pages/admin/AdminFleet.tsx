import { useState, useEffect } from 'react';
import { Plus, Pencil, Trash2, X } from 'lucide-react';
import { getCars, createCar, updateCar, deleteCar } from '../../api/client';
import { supabase } from '../../lib/supabase';
import { useCurrency } from '../../contexts/CurrencyContext';
import type { Car } from '../../types';
import './Admin.css';

const EMPTY: Partial<Car> = {
  make:'', model:'', licensePlate:'', vin:'',
  transmission:'Automatic', fuelType:'Diesel', seats:5, dailyRateZmw:1000, dailyRateOutofTownZmw: undefined, status:'Available',
};

export default function AdminFleet() {
  const [cars, setCars] = useState<Car[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState<'add'|'edit'|null>(null);
  const [form, setForm] = useState<Partial<Car>>(EMPTY);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const { format } = useCurrency();

  const load = () => getCars().then(c => setCars(c)).catch(() => {}).finally(() => setLoading(false));
  useEffect(() => { load(); }, []);

  const openAdd  = () => { setForm(EMPTY); setModal('add'); };
  const openEdit = (c: Car) => { setForm(c); setModal('edit'); };
  const close    = () => { setModal(null); setForm({}); };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return;
    setUploading(true);

    try {
      const newUrls: string[] = [];
      for (let i = 0; i < e.target.files.length; i++) {
        const file = e.target.files[i];
        const fileExt = file.name.split('.').pop();
        const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`;
        const filePath = `cars/${fileName}`;

        const { error: uploadError } = await supabase.storage
          .from('fleet-images')
          .upload(filePath, file);

        if (uploadError) throw uploadError;

        const { data } = supabase.storage
          .from('fleet-images')
          .getPublicUrl(filePath);

        if (data?.publicUrl) {
          newUrls.push(data.publicUrl);
        }
      }
      setForm(f => ({ ...f, imageUrls: [...(f.imageUrls || []), ...newUrls] }));
    } catch (error) {
      console.error('Error uploading image:', error);
      alert('Error uploading images. Please check permissions.');
    } finally {
      setUploading(false);
      e.target.value = '';
    }
  };

  const f = (k: keyof Car) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    let val: any = e.target.value;
    if (e.target.type === 'number') {
      val = val === '' ? '' : +val;
    }
    setForm(prev => ({ ...prev, [k]: val }));
  };

  const save = async () => {
    setSaving(true);
    try {
      // Sanitize payload
      const payload = { ...form };
      if (!payload.licensePlate) {
        payload.licensePlate = undefined as any;
      }
      if (!payload.vin) {
        payload.vin = undefined as any;
      }
      if (typeof payload.year === 'string' && payload.year === '') {
        payload.year = undefined as any;
      }
      // Or just forcefully wipe year since we don't use it:
      payload.year = undefined as any;

      if (modal === 'add') await createCar(payload);
      else await updateCar(payload.id!, payload);
      await load();
      close();
    } catch (err: any) {
      alert(`Failed to save vehicle. Error details: ${err.message || 'Unknown error'}`);
    } finally { 
      setSaving(false); 
    }
  };

  const remove = async (id: string) => {
    if (!confirm('Are you sure you want to delete this vehicle?')) return;
    try {
      await deleteCar(id);
      load();
    } catch (err: any) {
      alert(err.message || 'Failed to delete vehicle.');
    }
  };

  const STATUS_BADGE: Record<string, string> = { Available:'badge-green', Rented:'badge-gold', 'In Maintenance':'badge-red', Damaged:'badge-red', Unavailable:'badge-grey' };

  return (
    <div className="admin-page">
      <div className="page-header flex-between">
        <div>
          <h1>Fleet <span className="gold-text">Management</span></h1>
          <p>Manage all vehicles in your rental fleet</p>
        </div>
        <button className="btn btn-gold btn-sm" onClick={openAdd} id="add-car-btn">
          <Plus size={15}/> Add Vehicle
        </button>
      </div>

      <div className="admin-section">
        {loading ? <div className="flex-center" style={{ padding: 48 }}><div className="spinner"/></div> : (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Vehicle</th><th className="hide-mobile">Transmission</th><th className="hide-mobile">Fuel</th>
                  <th className="hide-mobile">Seats</th><th>Daily Rate</th><th>Status</th><th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {cars.map(c => (
                  <tr key={c.id}>
                    <td>
                      <strong>{c.make} {c.model}</strong>
                      {c.isShuttleOnly && <div style={{ fontSize: '0.7rem', color: 'var(--blue)', marginTop: 4, fontWeight: 600 }}>SHUTTLE ONLY</div>}
                    </td>
                    {/* Plate column removed */}
                    <td className="hide-mobile">{c.transmission}</td>
                    <td className="hide-mobile">{c.fuelType}</td>
                    <td className="hide-mobile">{c.seats}</td>
                    <td style={{ color:'var(--gold)', fontFamily:'var(--font-head)' }}>
                      <div>{format(c.dailyRateZmw, c.dailyRateUsd)} <span style={{ fontSize: '0.7rem', color: 'var(--text-3)' }}>local</span></div>
                      {c.dailyRateOutofTownZmw && <div style={{ color: 'var(--blue)', fontSize: '0.85rem' }}>{format(c.dailyRateOutofTownZmw, c.dailyRateOutofTownUsd)} <span style={{ fontSize: '0.7rem', color: 'var(--text-3)' }}>out of town</span></div>}
                    </td>
                    <td><span className={`badge ${STATUS_BADGE[c.status] ?? 'badge-grey'}`}>{c.status}</span></td>
                    <td>
                      <div style={{ display:'flex', gap:8 }}>
                        <button className="btn btn-ghost btn-sm" onClick={() => openEdit(c)} id={`edit-car-${c.id}`}><Pencil size={14}/></button>
                        <button className="btn btn-danger btn-sm" onClick={() => remove(c.id)} id={`del-car-${c.id}`}><Trash2 size={14}/></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {modal && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && close()}>
          <div className="modal-box">
            <div className="modal-header">
              <h2 className="modal-title">{modal === 'add' ? 'Add Vehicle' : 'Edit Vehicle'}</h2>
              <button className="modal-close" onClick={close}><X size={18}/></button>
            </div>
            <div className="admin-form">
              <div className="admin-form-grid">
                <div className="form-group">
                  <label className="form-label">Make</label>
                  <input className="form-input" value={form.make??''} onChange={f('make')} id="car-make" placeholder="Toyota"/>
                </div>
                <div className="form-group">
                  <label className="form-label">Model</label>
                  <input className="form-input" value={form.model??''} onChange={f('model')} id="car-model" placeholder="Land Cruiser"/>
                </div>
                <div className="form-group" style={{ display: 'none' }}>
                  {/* Year hidden entirely */}
                </div>
                <div className="form-group" style={{ display: 'none' }}>
                  {/* License Plate hidden entirely */}
                </div>
                <div className="form-group">
                  <label className="form-label">Transmission</label>
                  <select className="form-input" value={form.transmission??'Automatic'} onChange={f('transmission')} id="car-transmission">
                    <option>Automatic</option><option>Manual</option>
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Fuel Type</label>
                  <select className="form-input" value={form.fuelType??'Diesel'} onChange={f('fuelType')} id="car-fuel">
                    <option>Diesel</option><option>Petrol</option><option>Hybrid</option><option>Electric</option>
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Seats</label>
                  <input className="form-input" type="number" value={form.seats??5} onChange={f('seats')} id="car-seats"/>
                </div>
                <div className="form-group">
                  <label className="form-label">Local Daily Rate (ZMW)</label>
                  <input className="form-input" type="number" value={form.dailyRateZmw??''} onChange={f('dailyRateZmw')} id="car-rate" placeholder="e.g. 500"/>
                </div>
                <div className="form-group">
                  <label className="form-label">Out of Town Daily Rate (ZMW)</label>
                  <input className="form-input" type="number" value={form.dailyRateOutofTownZmw??''} onChange={f('dailyRateOutofTownZmw')} id="car-rate-outoftown" placeholder="e.g. 750 (leave blank if same)"/>
                  <span style={{ fontSize: '0.72rem', color: 'var(--text-3)', marginTop: 4, display: 'block' }}>Leave blank if you don't offer out-of-town trips for this car.</span>
                </div>
                <div className="form-group">
                  <label className="form-label">Status</label>
                  <select className="form-input" value={form.status??'Available'} onChange={f('status')} id="car-status">
                    <option value="Available">Available</option>
                    <option value="Rented">Rented</option>
                    <option value="In Maintenance">In Maintenance</option>
                    <option value="Damaged">Damaged</option>
                    <option value="Unavailable">Unavailable</option>
                  </select>
                </div>
                <div className="form-group" style={{ display: 'none' }}>
                  {/* VIN hidden entirely */}
                </div>
                <div className="form-group" style={{ display: 'flex', alignItems: 'flex-end', paddingBottom: '10px' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', fontSize: '0.9rem', color: 'var(--text-1)' }}>
                    <input 
                      type="checkbox" 
                      checked={!!form.isShuttleOnly} 
                      onChange={e => setForm(prev => ({ ...prev, isShuttleOnly: e.target.checked }))} 
                      style={{ width: '18px', height: '18px', cursor: 'pointer' }}
                    />
                    <strong>Shuttle Service Only</strong>
                  </label>
                </div>
                <div className="form-group" style={{ gridColumn: '1 / -1' }}>
                  <label className="form-label">Images</label>
                  <div style={{ display: 'flex', gap: '10px', marginBottom: '16px' }}>
                    <label className="btn btn-outline-gold btn-sm" style={{ cursor: 'pointer' }}>
                      {uploading ? 'Uploading...' : 'Upload Images'}
                      <input 
                        type="file" 
                        accept="image/*" 
                        multiple
                        style={{ display: 'none' }} 
                        onChange={handleFileUpload} 
                        disabled={uploading}
                      />
                    </label>
                  </div>
                  
                  {(form.imageUrls && form.imageUrls.length > 0) && (
                    <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', marginBottom: '16px', padding: '16px', background: 'var(--cream)', borderRadius: 'var(--radius)' }}>
                      {form.imageUrls.map((url, i) => (
                        <div key={i} style={{ position: 'relative', width: 120, height: 80, borderRadius: 6, overflow: 'hidden', border: i === 0 ? '3px solid var(--gold)' : '1px solid var(--border)', background: '#fff' }}>
                          <img src={url} alt="car" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                          {i === 0 && <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, background: 'var(--gold)', color: '#fff', fontSize: '10px', fontWeight: 700, textAlign: 'center', padding: '2px 0' }}>MAIN COVER</div>}
                          
                          <button 
                            type="button"
                            style={{ position: 'absolute', top: 4, right: 4, background: 'rgba(0,0,0,0.6)', color: '#fff', border: 'none', borderRadius: '50%', width: 20, height: 20, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}
                            onClick={() => {
                              const newUrls = [...(form.imageUrls || [])];
                              newUrls.splice(i, 1);
                              setForm({ ...form, imageUrls: newUrls });
                            }}
                          ><X size={14}/></button>
                          
                          {i !== 0 && (
                            <button 
                              type="button"
                              style={{ position: 'absolute', top: 4, left: 4, background: 'rgba(0,0,0,0.6)', color: '#fff', border: 'none', borderRadius: 4, fontSize: '10px', padding: '3px 6px', cursor: 'pointer' }}
                              onClick={() => {
                                const newUrls = [...(form.imageUrls || [])];
                                const temp = newUrls[0];
                                newUrls[0] = newUrls[i];
                                newUrls[i] = temp;
                                setForm({ ...form, imageUrls: newUrls });
                              }}
                            >Set Main</button>
                          )}
                        </div>
                      ))}
                    </div>
                  )}

                  <label className="form-label" style={{ fontSize: '0.7rem', color: 'var(--muted)' }}>Or Paste URLs manually (One per line, first is Main)</label>
                  <textarea
                    className="form-input"
                    rows={3}
                    value={(form.imageUrls || []).join('\n')}
                    onChange={e => {
                      const lines = e.target.value.split('\n').map(s => s.trim()).filter(s => s);
                      setForm({ ...form, imageUrls: lines });
                    }}
                    placeholder="https://images.unsplash.com/...&#10;https://images.unsplash.com/..."
                  />
                </div>
              </div>
              <div className="admin-form-actions">
                <button className="btn btn-ghost btn-sm" onClick={close}>Cancel</button>
                <button className="btn btn-gold btn-sm" onClick={save} disabled={saving} id="save-car-btn">
                  {saving ? 'Saving...' : modal === 'add' ? 'Add Vehicle' : 'Save Changes'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
