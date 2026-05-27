import { useState, useEffect } from 'react';
import { Plus, Pencil, Trash2, X } from 'lucide-react';
import { getCars, createCar, updateCar, deleteCar } from '../../api/client';
import { supabase } from '../../lib/supabase';
import { useCurrency } from '../../contexts/CurrencyContext';
import type { Car } from '../../types';
import './Admin.css';

const EMPTY: Partial<Car> = {
  make:'', model:'', year: new Date().getFullYear(), licensePlate:'', vin:'',
  transmission:'Automatic', fuelType:'Diesel', seats:5, dailyRateZmw:1000, status:'Available',
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
    const file = e.target.files[0];
    setUploading(true);

    try {
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
        setForm(f => ({ ...f, imageUrls: [...(f.imageUrls || []), data.publicUrl] }));
      }
    } catch (error) {
      console.error('Error uploading image:', error);
      alert('Error uploading image. Please check permissions.');
    } finally {
      setUploading(false);
      e.target.value = '';
    }
  };

  const f = (k: keyof Car) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) =>
    setForm(prev => ({ ...prev, [k]: e.target.type === 'number' ? +e.target.value : e.target.value }));

  const save = async () => {
    setSaving(true);
    try {
      if (modal === 'add') await createCar(form);
      else await updateCar(form.id!, form);
      await load();
      close();
    } catch {} finally { setSaving(false); }
  };

  const remove = async (id: string) => {
    if (!confirm('Delete this car?')) return;
    await deleteCar(id).catch(() => {});
    load();
  };

  const STATUS_BADGE: Record<string, string> = { Available:'badge-green', Rented:'badge-gold', Maintenance:'badge-red', Unavailable:'badge-grey' };

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
                  <th>Vehicle</th><th>Plate</th><th>Transmission</th><th>Fuel</th>
                  <th>Seats</th><th>Daily Rate</th><th>Status</th><th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {cars.map(c => (
                  <tr key={c.id}>
                    <td><strong>{c.make} {c.model}</strong> <span className="muted" style={{fontSize:'0.8rem'}}>({c.year})</span></td>
                    <td style={{ fontFamily:'monospace', fontSize:'0.82rem', color:'var(--text-2)' }}>{c.licensePlate}</td>
                    <td>{c.transmission}</td>
                    <td>{c.fuelType}</td>
                    <td>{c.seats}</td>
                    <td style={{ color:'var(--gold)', fontFamily:'var(--font-head)' }}>{format(c.dailyRateZmw, c.dailyRateUsd)}</td>
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
                <div className="form-group">
                  <label className="form-label">Year</label>
                  <input className="form-input" type="number" value={form.year??''} onChange={f('year')} id="car-year"/>
                </div>
                <div className="form-group">
                  <label className="form-label">License Plate</label>
                  <input className="form-input" value={form.licensePlate??''} onChange={f('licensePlate')} id="car-plate"/>
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
                  <label className="form-label">Daily Rate (ZMW)</label>
                  <input className="form-input" type="number" value={form.dailyRateZmw??''} onChange={f('dailyRateZmw')} id="car-rate"/>
                </div>
                <div className="form-group">
                  <label className="form-label">Status</label>
                  <select className="form-input" value={form.status??'Available'} onChange={f('status')} id="car-status">
                    <option>Available</option><option>Rented</option><option>Maintenance</option><option>Unavailable</option>
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">VIN</label>
                  <input className="form-input" value={form.vin??''} onChange={f('vin')} id="car-vin"/>
                </div>
                <div className="form-group" style={{ gridColumn: '1 / -1' }}>
                  <label className="form-label">Images (Upload or Paste URLs)</label>
                  <div style={{ display: 'flex', gap: '10px', marginBottom: '10px' }}>
                    <label className="btn btn-outline-gold btn-sm" style={{ cursor: 'pointer' }}>
                      {uploading ? 'Uploading...' : 'Upload Image'}
                      <input 
                        type="file" 
                        accept="image/*" 
                        style={{ display: 'none' }} 
                        onChange={handleFileUpload} 
                        disabled={uploading}
                      />
                    </label>
                  </div>
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
