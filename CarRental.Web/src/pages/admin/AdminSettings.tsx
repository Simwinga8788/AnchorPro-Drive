import { useState, useEffect, useRef } from 'react';
import { getHeroImages, updateHeroImages, getHeroVideo, updateHeroVideo, deleteHeroVideo, getEmailConfig, saveEmailConfig, sendTestEmail } from '../../api/client';
import { supabase } from '../../lib/supabase';
import { Plus, Trash2, Save, Upload, Video, X, Mail, Send, Eye, EyeOff } from 'lucide-react';
import './Admin.css';

export default function AdminSettings() {
  const [heroImages, setHeroImages] = useState<string[]>([]);
  const [heroVideoUrl, setHeroVideoUrl] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadingVideo, setUploadingVideo] = useState(false);
  const [message, setMessage] = useState<{type: 'success'|'error', text: string} | null>(null);
  const videoRef = useRef<HTMLVideoElement>(null);

  // Email config state
  const [emailConfig, setEmailConfig] = useState({ smtpHost: 'smtp.gmail.com', smtpPort: '587', senderEmail: '', senderName: 'Retrix Car Rental', appPassword: '', adminEmail: '' });
  const [emailSaving, setEmailSaving] = useState(false);
  const [emailTesting, setEmailTesting] = useState(false);
  const [emailMessage, setEmailMessage] = useState<{type: 'success'|'error', text: string} | null>(null);
  const [showPassword, setShowPassword] = useState(false);
  const [testEmailAddr, setTestEmailAddr] = useState('');

  useEffect(() => {
    Promise.all([
      getHeroImages().catch(() => [] as string[]),
      getHeroVideo().catch(() => ({ url: '' })),
      getEmailConfig().catch(() => null),
    ]).then(([imgs, vid, emailCfg]) => {
      setHeroImages(imgs);
      setHeroVideoUrl(vid.url || '');
      if (emailCfg) setEmailConfig(prev => ({ ...prev, ...emailCfg }));
    }).catch(() => setMessage({ type: 'error', text: 'Failed to load settings.' }))
      .finally(() => setLoading(false));
  }, []);

  // ── Images ────────────────────────────────────────────────────────────────

  const handleAdd = () => setHeroImages([...heroImages, '']);

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return;
    const file = e.target.files[0];
    setUploading(true);
    try {
      const fileExt = file.name.split('.').pop();
      const fileName = `hero-${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`;
      const filePath = `hero/${fileName}`;
      const { error: uploadError } = await supabase.storage.from('fleet-images').upload(filePath, file);
      if (uploadError) throw uploadError;
      const { data } = supabase.storage.from('fleet-images').getPublicUrl(filePath);
      if (data?.publicUrl) setHeroImages(prev => [...prev, data.publicUrl]);
    } catch (error) {
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

  const handleRemove = (index: number) => setHeroImages(heroImages.filter((_, i) => i !== index));

  // ── Video ─────────────────────────────────────────────────────────────────

  const handleVideoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return;
    const file = e.target.files[0];
    setUploadingVideo(true);
    try {
      const fileExt = file.name.split('.').pop();
      const fileName = `hero-video-${Date.now()}.${fileExt}`;
      const filePath = `hero/${fileName}`;
      const { error: uploadError } = await supabase.storage.from('fleet-images').upload(filePath, file, {
        contentType: file.type,
        upsert: false,
      });
      if (uploadError) throw uploadError;
      const { data } = supabase.storage.from('fleet-images').getPublicUrl(filePath);
      if (data?.publicUrl) {
        setHeroVideoUrl(data.publicUrl);
        await updateHeroVideo(data.publicUrl);
        setMessage({ type: 'success', text: 'Hero video uploaded and saved!' });
      }
    } catch (error) {
      console.error(error);
      alert('Error uploading video. Please check permissions or file size.');
    } finally {
      setUploadingVideo(false);
      e.target.value = '';
    }
  };

  const handleRemoveVideo = async () => {
    if (!confirm('Remove the hero video?')) return;
    await deleteHeroVideo().catch(() => {});
    setHeroVideoUrl('');
    setMessage({ type: 'success', text: 'Hero video removed.' });
  };

  const handleSaveVideoUrl = async () => {
    await updateHeroVideo(heroVideoUrl).catch(() => {});
    setMessage({ type: 'success', text: 'Hero video URL saved.' });
  };

  // ── Save All ──────────────────────────────────────────────────────────────

  const handleSave = async () => {
    setSaving(true);
    setMessage(null);
    try {
      const cleaned = heroImages.filter(url => url.trim() !== '');
      await updateHeroImages(cleaned);
      setHeroImages(cleaned);
      setMessage({ type: 'success', text: 'Settings saved successfully.' });
    } catch {
      setMessage({ type: 'error', text: 'Failed to save settings.' });
    } finally {
      setSaving(false);
    }
  };

  // ── Email Config ───────────────────────────────────────────────────────────

  const handleEmailSave = async () => {
    setEmailSaving(true); setEmailMessage(null);
    try {
      await saveEmailConfig(emailConfig);
      setEmailMessage({ type: 'success', text: 'Email settings saved successfully!' });
    } catch (e: any) {
      setEmailMessage({ type: 'error', text: e.message || 'Failed to save email settings.' });
    } finally { setEmailSaving(false); }
  };

  const handleTestEmail = async () => {
    if (!testEmailAddr) { setEmailMessage({ type: 'error', text: 'Enter a test email address.' }); return; }
    setEmailTesting(true); setEmailMessage(null);
    try {
      const res = await sendTestEmail(testEmailAddr);
      setEmailMessage({ type: 'success', text: res.message });
    } catch (e: any) {
      setEmailMessage({ type: 'error', text: e.message || 'Test failed. Check your SMTP settings.' });
    } finally { setEmailTesting(false); }
  };

  return (
    <div className="admin-page">
      <div className="page-header flex-between">
        <div>
          <h1>Site <span className="gold-text">Settings</span></h1>
          <p>Manage site-wide configurations like homepage hero images and video</p>
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

      {loading ? <div className="spinner" /> : (
        <>
          {/* ── Hero Video ──────────────────────────────────────────────── */}
          <div className="admin-section" style={{ padding: 24, marginBottom: 24 }}>
            <h3 className="admin-section__title" style={{ padding: 0, border: 'none', background: 'transparent', marginBottom: 8, display: 'flex', alignItems: 'center', gap: 8 }}>
              <Video size={18} /> Hero Video <span style={{ fontSize: '0.75rem', fontWeight: 400, color: 'var(--text-2)', marginLeft: 8 }}>Optional — overrides the static image on the right side of the hero</span>
            </h3>
            <p className="muted" style={{ fontSize: '0.875rem', marginBottom: 20 }}>
              Upload an MP4 video to play as the hero background. It will loop silently and autoplay. Leave empty to use the static image instead.
            </p>

            {heroVideoUrl ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16, maxWidth: 600 }}>
                {/* Preview */}
                <div style={{ position: 'relative', borderRadius: 10, overflow: 'hidden', background: '#000', aspectRatio: '16/9' }}>
                  <video
                    ref={videoRef}
                    src={heroVideoUrl}
                    autoPlay muted loop playsInline
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  />
                  <button
                    onClick={handleRemoveVideo}
                    className="btn btn-danger btn-sm"
                    style={{ position: 'absolute', top: 10, right: 10, zIndex: 2 }}
                  >
                    <X size={14} style={{marginRight: 6}}/> Remove Video
                  </button>
                </div>
                <input
                  className="form-input"
                  value={heroVideoUrl}
                  onChange={e => setHeroVideoUrl(e.target.value)}
                  placeholder="https://... video URL"
                />
                <button className="btn btn-outline btn-sm" style={{ width: 'fit-content' }} onClick={handleSaveVideoUrl}>
                  <Save size={14} style={{marginRight: 6}}/> Save URL
                </button>
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16, maxWidth: 600 }}>
                <div style={{ border: '2px dashed var(--border)', borderRadius: 10, padding: '40px 24px', textAlign: 'center', color: 'var(--text-2)' }}>
                  <Video size={36} style={{ marginBottom: 12, opacity: 0.4 }} />
                  <p style={{ marginBottom: 16, fontSize: '0.9rem' }}>No hero video set. Upload an MP4 or paste a URL below.</p>
                  <label className="btn btn-gold btn-sm" style={{ cursor: 'pointer', display: 'inline-flex' }}>
                    <Upload size={15} style={{ marginRight: 6 }} />
                    {uploadingVideo ? 'Uploading...' : 'Upload MP4 Video'}
                    <input
                      type="file"
                      accept="video/mp4,video/webm,video/ogg"
                      style={{ display: 'none' }}
                      onChange={handleVideoUpload}
                      disabled={uploadingVideo}
                    />
                  </label>
                </div>
                <div style={{ display: 'flex', gap: 8 }}>
                  <input
                    className="form-input"
                    value={heroVideoUrl}
                    onChange={e => setHeroVideoUrl(e.target.value)}
                    placeholder="Or paste a video URL (MP4)..."
                  />
                  <button className="btn btn-outline btn-sm" onClick={handleSaveVideoUrl} style={{ whiteSpace: 'nowrap' }}>
                    <Save size={14} style={{marginRight: 6}}/> Save URL
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* ── Hero Images ─────────────────────────────────────────────── */}
          <div className="admin-section" style={{ padding: 24 }}>
            <h3 className="admin-section__title" style={{ padding: 0, border: 'none', background: 'transparent', marginBottom: 8 }}>
              Landing Page Hero Images
            </h3>
            <p className="muted" style={{ fontSize: '0.875rem', marginBottom: 24 }}>
              Used as the hero background when no video is set. Provide Unsplash URLs or upload from device.
            </p>

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
                    <Trash2 size={15} style={{marginRight: 6}}/> Delete
                  </button>
                </div>
              ))}
              <div style={{ display: 'flex', gap: '12px' }}>
                <button className="btn btn-outline btn-sm" onClick={handleAdd}>
                  <Plus size={15} style={{marginRight: 6}}/> Add URL
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
          </div>

          {/* ── Email Settings ───────────────────────────────────────────── */}
          <div className="admin-section" style={{ padding: 24, marginTop: 24 }}>
            <h3 className="admin-section__title" style={{ padding: 0, border: 'none', background: 'transparent', marginBottom: 4, display: 'flex', alignItems: 'center', gap: 8 }}>
              <Mail size={18} /> Email Notifications
            </h3>
            <p className="muted" style={{ fontSize: '0.875rem', marginBottom: 24 }}>
              Configure your SMTP credentials to send automated emails for bookings, status changes, and more.
            </p>

            {emailMessage && (
              <div className={`toast toast-${emailMessage.type}`} style={{ position: 'relative', top: 0, right: 0, marginBottom: 20 }}>
                {emailMessage.text}
              </div>
            )}

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, maxWidth: 720 }}>
              <div className="form-group">
                <label className="form-label">SMTP Host</label>
                <input className="form-input" value={emailConfig.smtpHost} onChange={e => setEmailConfig(p => ({...p, smtpHost: e.target.value}))} placeholder="smtp.gmail.com" />
              </div>
              <div className="form-group">
                <label className="form-label">SMTP Port</label>
                <input className="form-input" value={emailConfig.smtpPort} onChange={e => setEmailConfig(p => ({...p, smtpPort: e.target.value}))} placeholder="587" />
              </div>
              <div className="form-group">
                <label className="form-label">Sender Email (Gmail Address)</label>
                <input className="form-input" type="email" value={emailConfig.senderEmail} onChange={e => setEmailConfig(p => ({...p, senderEmail: e.target.value}))} placeholder="yourname@gmail.com" />
              </div>
              <div className="form-group">
                <label className="form-label">Sender Name</label>
                <input className="form-input" value={emailConfig.senderName} onChange={e => setEmailConfig(p => ({...p, senderName: e.target.value}))} placeholder="Retrix Car Rental" />
              </div>
              <div className="form-group" style={{ position: 'relative' }}>
                <label className="form-label">App Password <span style={{ fontWeight: 400, color: 'var(--text-3)', fontSize: '0.75rem' }}>(from Google Account → Security → App Passwords)</span></label>
                <div style={{ position: 'relative' }}>
                  <input
                    className="form-input"
                    type={showPassword ? 'text' : 'password'}
                    value={emailConfig.appPassword}
                    onChange={e => setEmailConfig(p => ({...p, appPassword: e.target.value}))}
                    placeholder="xxxx xxxx xxxx xxxx"
                    style={{ paddingRight: 40 }}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(p => !p)}
                    style={{ position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-3)', padding: 4 }}
                  >
                    {showPassword ? <EyeOff size={16}/> : <Eye size={16}/>}
                  </button>
                </div>
              </div>
              <div className="form-group">
                <label className="form-label">Admin Alert Email</label>
                <input className="form-input" type="email" value={emailConfig.adminEmail} onChange={e => setEmailConfig(p => ({...p, adminEmail: e.target.value}))} placeholder="admin@yourdomain.com" />
              </div>
            </div>

            <div style={{ display: 'flex', gap: 12, alignItems: 'center', marginTop: 20, flexWrap: 'wrap' }}>
              <button className="btn btn-gold btn-sm" onClick={handleEmailSave} disabled={emailSaving}>
                <Save size={15}/> {emailSaving ? 'Saving...' : 'Save Email Settings'}
              </button>

              <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginLeft: 'auto', flexWrap: 'wrap' }}>
                <input
                  className="form-input"
                  type="email"
                  value={testEmailAddr}
                  onChange={e => setTestEmailAddr(e.target.value)}
                  placeholder="Send test to..."
                  style={{ width: 220 }}
                />
                <button className="btn btn-outline btn-sm" onClick={handleTestEmail} disabled={emailTesting}>
                  <Send size={14}/> {emailTesting ? 'Sending...' : 'Send Test Email'}
                </button>
              </div>
            </div>

            <div style={{ marginTop: 20, padding: '12px 16px', background: 'var(--bg-2)', borderRadius: 8, border: '1px solid var(--border)', fontSize: '0.8rem', color: 'var(--text-3)', lineHeight: 1.7 }}>
              <strong style={{ color: 'var(--text-2)' }}>📋 How to get a Gmail App Password:</strong><br/>
              1. Go to <strong>myaccount.google.com</strong> → Security → Enable 2-Step Verification<br/>
              2. Then go to <strong>myaccount.google.com/apppasswords</strong><br/>
              3. Create a new App Password named "Retrix" — copy the 16-character code<br/>
              4. Paste it above (spaces are ignored automatically)
            </div>
          </div>
        </>
      )}
    </div>
  );
}
