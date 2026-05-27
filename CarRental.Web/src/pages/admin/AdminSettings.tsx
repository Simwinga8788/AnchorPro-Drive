import { useState, useEffect } from 'react';
import { getHeroImages, updateHeroImages } from '../../api/client';
import { supabase } from '../../lib/supabase';
import { Plus, Trash2, Save, Upload } from 'lucide-react';
import './Admin.css';

export default function AdminSettings() {
  const [heroImages, setHeroImages] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [message, setMessage] = useState<{type: 'success'|'error', text: string} | null>(null);

  useEffect(() => {
    getHeroImages()
      .then(imgs => setHeroImages(imgs))
      .catch(() => setMessage({ type: 'error', text: 'Failed to load settings.' }))
      .finally(() => setLoading(false));
  }, []);

  const handleAdd = () => {
    setHeroImages([...heroImages, '']);
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return;
    const file = e.target.files[0];
    setUploading(true);

    try {
      const fileExt = file.name.split('.').pop();
      const fileName = `hero-${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`;
      const filePath = `hero/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from('fleet-images')
        .upload(filePath, file);

      if (uploadError) throw uploadError;

      const { data } = supabase.storage
        .from('fleet-images')
        .getPublicUrl(filePath);

      if (data?.publicUrl) {
        setHeroImages(prev => [...prev, data.publicUrl]);
      }
    } catch (error) {
      console.error('Error uploading image:', error);
      alert('Error uploading image. Please check permissions.');
    } finally {
      setUploading(false);
      e.target.value = '';
    }
  };

  const handleChange = (index: number, value: string) => {
    const next = [...heroImages];
    next[index] = value;
    setHeroImages(next);
  };

  const handleRemove = (index: number) => {
    const next = heroImages.filter((_, i) => i !== index);
    setHeroImages(next);
  };

  const handleSave = async () => {
    setSaving(true);
    setMessage(null);
    try {
      // filter out empty strings
      const cleaned = heroImages.filter(url => url.trim() !== '');
      await updateHeroImages(cleaned);
      setHeroImages(cleaned);
      setMessage({ type: 'success', text: 'Hero images saved successfully.' });
    } catch (e: any) {
      setMessage({ type: 'error', text: 'Failed to save settings.' });
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="admin-page">
      <div className="page-header flex-between">
        <div>
          <h1>Site <span className="gold-text">Settings</span></h1>
          <p>Manage site-wide configurations like homepage hero images</p>
        </div>
        <button className="btn btn-gold btn-sm" onClick={handleSave} disabled={saving}>
          <Save size={15}/> {saving ? 'Saving...' : 'Save Settings'}
        </button>
      </div>

      {message && (
        <div className={`toast toast-${message.type}`} style={{ position: 'relative', top: 0, right: 0, marginBottom: 20 }}>
          {message.text}
        </div>
      )}

      <div className="admin-section" style={{ padding: 24 }}>
        <h3 className="admin-section__title" style={{ padding: 0, border: 'none', background: 'transparent', marginBottom: 16 }}>
          Landing Page Hero Images
        </h3>
        <p className="muted" style={{ fontSize: '0.875rem', marginBottom: 24 }}>
          Provide Unsplash URLs or any other image links. These will be used for the hero section background on the landing page.
        </p>

        {loading ? <div className="spinner" /> : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16, maxWidth: 800 }}>
            {heroImages.map((img, idx) => (
              <div key={idx} style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                <div style={{ width: 80, height: 50, borderRadius: 4, overflow: 'hidden', background: 'var(--cream)', flexShrink: 0 }}>
                  {img && <img src={img} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />}
                </div>
                <input
                  className="form-input"
                  value={img}
                  onChange={e => handleChange(idx, e.target.value)}
                  placeholder="https://..."
                />
                <button className="btn btn-danger btn-sm" onClick={() => handleRemove(idx)}>
                  <Trash2 size={15} />
                </button>
              </div>
            ))}
            <div style={{ display: 'flex', gap: '12px' }}>
              <button className="btn btn-outline btn-sm" onClick={handleAdd}>
                <Plus size={15} /> Add URL
              </button>
              <label className="btn btn-outline-gold btn-sm" style={{ cursor: 'pointer', margin: 0 }}>
                <Upload size={15} style={{ marginRight: 6 }}/>
                {uploading ? 'Uploading...' : 'Upload from Device'}
                <input 
                  type="file" 
                  accept="image/*" 
                  style={{ display: 'none' }} 
                  onChange={handleFileUpload} 
                  disabled={uploading}
                />
              </label>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
