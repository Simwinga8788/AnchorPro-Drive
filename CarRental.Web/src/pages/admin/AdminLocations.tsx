import { useState, useEffect } from 'react';
import { Plus, Pencil, Trash2, X, MapPin } from 'lucide-react';
import { getLocations, createLocation, updateLocation, deleteLocation } from '../../api/client';
import type { Location } from '../../types';
import './Admin.css';
import ResponsiveTable from '../../components/ResponsiveTable';

export default function AdminLocations() {
  const [locations, setLocations] = useState<Location[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState<'add' | 'edit' | null>(null);
  const [form, setForm] = useState<Partial<Location>>({});
  const [saving, setSaving] = useState(false);

  const load = () => getLocations().then(l => setLocations(Array.isArray(l) ? l : [])).catch(() => {}).finally(() => setLoading(false));
  useEffect(() => { load(); }, []);

  const openAdd = () => { setForm({}); setModal('add'); };
  const openEdit = (loc: Location) => { setForm(loc); setModal('edit'); };
  const close = () => { setModal(null); setForm({}); };

  const handleInput = (k: keyof Location) => (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm(prev => ({ ...prev, [k]: e.target.value }));
  };

  const save = async () => {
    setSaving(true);
    try {
      if (modal === 'add') await createLocation(form);
      else await updateLocation(form.id!, form);
      await load();
      close();
    } catch (e: any) {
      alert(e.message || 'Error saving location');
    } finally {
      setSaving(false);
    }
  };

  const remove = async (id: string) => {
    if (!confirm('Are you sure you want to delete this location?')) return;
    try {
      await deleteLocation(id);
      load();
    } catch (e: any) {
      alert('Cannot delete location because it is likely being used by existing bookings.');
    }
  };

  return (
    <div className="admin-page">
      <div className="page-header flex-between">
        <div>
          <h1>Locations <span className="gold-text">Management</span></h1>
          <p>Manage pickup and dropoff locations</p>
        </div>
        <button className="btn btn-gold btn-sm" onClick={openAdd}>
          <Plus size={15}/> Add Location
        </button>
      </div>

      <div className="admin-section">
        {loading ? <div className="flex-center" style={{ padding: 48 }}><div className="spinner"/></div> : (
          <div className="table-wrap">
            <ResponsiveTable>
<table className="data-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th className="hide-mobile">Address</th>
                  <th className="hide-mobile">Contact Phone</th>
                  <th style={{ width: 100 }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {locations.length === 0 ? (
                  <tr><td colSpan={4} style={{ textAlign: 'center', padding: '32px' }}>No locations added yet.</td></tr>
                ) : locations.map(loc => (
                  <tr key={loc.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontWeight: 600 }}>
                        <MapPin size={16} className="gold-text" /> {loc.name}
                      </div>
                      <div className="show-mobile" style={{ fontSize: '0.78rem', color: 'var(--text-3)', paddingLeft: 24, marginTop: 4 }}>
                        <div>{loc.address}</div>
                        {loc.contactPhone && <div style={{ marginTop: 2 }}>Phone: {loc.contactPhone}</div>}
                      </div>
                    </td>
                    <td className="hide-mobile">{loc.address}</td>
                    <td className="hide-mobile">{loc.contactPhone || '—'}</td>
                    <td>
                      <div style={{ display: 'flex', gap: 8 }}>
                        <button className="btn btn-ghost btn-sm" onClick={() => openEdit(loc)}><Pencil size={14}/></button>
                        <button className="btn btn-danger btn-sm" onClick={() => remove(loc.id)}><Trash2 size={14}/></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
</ResponsiveTable>
          </div>
        )}
      </div>

      {modal && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && close()}>
          <div className="modal-box" style={{ maxWidth: 500 }}>
            <div className="modal-header">
              <h2 className="modal-title">{modal === 'add' ? 'Add Location' : 'Edit Location'}</h2>
              <button className="modal-close" onClick={close}><X size={18}/></button>
            </div>
            <div className="admin-form">
              <div className="form-group">
                <label className="form-label">Location Name</label>
                <input className="form-input" value={form.name || ''} onChange={handleInput('name')} placeholder="e.g. Lusaka Airport Branch" />
              </div>
              <div className="form-group">
                <label className="form-label">Full Address</label>
                <input className="form-input" value={form.address || ''} onChange={handleInput('address')} placeholder="e.g. Kenneth Kaunda International Airport" />
              </div>
              <div className="form-group">
                <label className="form-label">Contact Phone (Optional)</label>
                <input className="form-input" value={form.contactPhone || ''} onChange={handleInput('contactPhone')} placeholder="+260..." />
              </div>
              <div className="admin-form-actions">
                <button className="btn btn-ghost btn-sm" onClick={close}>Cancel</button>
                <button className="btn btn-gold btn-sm" onClick={save} disabled={saving}>
                  {saving ? 'Saving...' : modal === 'add' ? 'Add Location' : 'Save Changes'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
