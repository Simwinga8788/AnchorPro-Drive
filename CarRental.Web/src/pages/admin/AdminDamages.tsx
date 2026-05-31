import React, { useState, useEffect } from 'react';
import { getDamages, getCars, createDamage, updateDamage } from '../../api/client';
import type { Damage, Car } from '../../types';
import { supabase } from '../../lib/supabase';
import { AlertTriangle, Plus, X, Upload } from 'lucide-react';
import './Admin.css';

const SEV_BADGE: Record<string, string> = { Minor:'badge-blue', Moderate:'badge-gold', Severe:'badge-red' };
const REP_BADGE: Record<string, string> = { Pending:'badge-grey', InProgress:'badge-gold', Repaired:'badge-green' };

export default function AdminDamages() {
  const [damages, setDamages] = useState<Damage[]>([]);
  const [cars, setCars] = useState<Car[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingDamage, setEditingDamage] = useState<Damage | null>(null);

  const fetchAll = async () => {
    setLoading(true);
    try {
      const [d, c] = await Promise.all([getDamages(), getCars()]);
      setDamages(d);
      setCars(c);
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
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr><th>Vehicle</th><th>Description</th><th>Severity</th><th>Repair Status</th><th>Est. Cost (ZMW)</th><th>Reported</th><th>Actions</th></tr>
              </thead>
              <tbody>
                {damages.map(d => (
                  <tr key={d.id}>
                    <td><strong>{d.car?.make ?? '—'} {d.car?.model ?? ''}</strong></td>
                    <td style={{maxWidth:240, fontSize:'0.85rem', color:'var(--text-2)'}}>{d.description}</td>
                    <td><span className={`badge ${SEV_BADGE[d.severity]??'badge-grey'}`}>{d.severity}</span></td>
                    <td><span className={`badge ${REP_BADGE[d.repairStatus]??'badge-grey'}`}>{d.repairStatus}</span></td>
                    <td style={{fontFamily:'var(--font-head)', color:'var(--gold)'}}>{d.repairCostEstimate ? `K${d.repairCostEstimate.toLocaleString()}` : '—'}</td>
                    <td style={{fontSize:'0.8rem', color:'var(--text-2)'}}>{d.createdAt ? new Date(d.createdAt).toLocaleDateString() : '—'}</td>
                    <td>
                      <button className="btn btn-sm" onClick={() => handleEdit(d)}>Edit</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {isModalOpen && (
        <DamageModal 
          damage={editingDamage}
          cars={cars}
          onClose={() => setIsModalOpen(false)}
          onSaved={() => { setIsModalOpen(false); fetchAll(); }}
        />
      )}
    </div>
  );
}

function DamageModal({ damage, cars, onClose, onSaved }: { damage: Damage | null, cars: Car[], onClose: () => void, onSaved: () => void }) {
  const [formData, setFormData] = useState<Partial<Damage>>(damage || {
    severity: 'Minor',
    repairStatus: 'Pending',
    description: '',
    carId: cars[0]?.id || '',
    repairCostEstimate: 0,
    imageUrls: []
  });
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      if (damage?.id) {
        await updateDamage(damage.id, formData);
      } else {
        await createDamage(formData);
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
              onChange={e => setFormData({...formData, carId: e.target.value})}
              required
              disabled={!!damage}
            >
              <option value="">Select a vehicle...</option>
              {cars.map(c => <option key={c.id} value={c.id}>{c.make} {c.model} ({c.licensePlate})</option>)}
            </select>
          </div>

          <div className="form-group">
            <label>Severity</label>
            <select 
              value={formData.severity} 
              onChange={e => setFormData({...formData, severity: e.target.value as any})}
            >
              <option value="Minor">Minor</option>
              <option value="Moderate">Moderate</option>
              <option value="Severe">Severe</option>
            </select>
          </div>

          <div className="form-group">
            <label>Repair Status</label>
            <select 
              value={formData.repairStatus} 
              onChange={e => setFormData({...formData, repairStatus: e.target.value as any})}
            >
              <option value="Pending">Pending</option>
              <option value="InProgress">In Progress</option>
              <option value="Repaired">Repaired</option>
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
              onChange={e => setFormData({...formData, repairCostEstimate: parseFloat(e.target.value)})}
            />
          </div>

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
