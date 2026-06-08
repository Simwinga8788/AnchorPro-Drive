import { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { getMe, updateProfile } from '../api/client';
import type { Profile } from '../types';
import { Save } from 'lucide-react';
import './ProfilePage.css';

export default function ProfilePage() {
  const { user } = useAuth();
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Form fields
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [driverLicense, setDriverLicense] = useState('');
  const [dob, setDob] = useState('');

  useEffect(() => {
    loadProfile();
  }, [user]);

  const loadProfile = async () => {
    if (!user) return;
    try {
      const data = await getMe();
      setProfile(data);
      setFirstName(data.firstName || '');
      setLastName(data.lastName || '');
      setPhoneNumber(data.phoneNumber || '');
      setDriverLicense(data.driverLicenseNumber || '');
      setDob(data.dateOfBirth ? data.dateOfBirth.split('T')[0] : '');
    } catch (err) {
      console.error('Failed to load profile:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!profile) return;
    
    setSaving(true);
    setError('');
    setSuccess('');
    
    try {
      await updateProfile(profile.id, {
        firstName,
        lastName,
        phoneNumber,
        driverLicenseNumber: driverLicense || undefined,
        dateOfBirth: dob ? dob : undefined,
      });
      setSuccess('Profile updated successfully!');
      setTimeout(() => setSuccess(''), 3000);
    } catch (err: any) {
      setError(err.message || 'Failed to update profile.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="profile-page flex-center">
        <div className="spinner" />
      </div>
    );
  }

  return (
    <div className="profile-page">
      <div className="container profile-container">
        <div className="profile-card animate-slide">
          <div className="profile-header">
            <h2>My <span className="gold-text">Profile</span></h2>
            <p>View and update your personal information.</p>
          </div>

          <form onSubmit={handleSave} className="profile-form">
            <div className="profile-form-grid">
              <div className="form-group">
                <label className="form-label">First Name</label>
                <input 
                  className="form-input" 
                  required 
                  value={firstName} 
                  onChange={e => setFirstName(e.target.value)} 
                />
              </div>
              <div className="form-group">
                <label className="form-label">Last Name</label>
                <input 
                  className="form-input" 
                  required 
                  value={lastName} 
                  onChange={e => setLastName(e.target.value)} 
                />
              </div>
              
              <div className="form-group">
                <label className="form-label">Phone Number</label>
                <input 
                  className="form-input" 
                  required 
                  type="tel" 
                  value={phoneNumber} 
                  onChange={e => setPhoneNumber(e.target.value)} 
                />
              </div>
              
              <div className="form-group">
                <label className="form-label">Date of Birth</label>
                <input 
                  className="form-input" 
                  required 
                  type="date" 
                  value={dob} 
                  onChange={e => setDob(e.target.value)} 
                />
              </div>

              <div className="form-group" style={{ gridColumn: '1 / -1' }}>
                <label className="form-label">Driver's License Number (Optional)</label>
                <input 
                  className="form-input" 
                  value={driverLicense} 
                  onChange={e => setDriverLicense(e.target.value)} 
                />
              </div>
            </div>

            {error && <div className="error-message" style={{ color: 'var(--red)', marginTop: 10 }}>{error}</div>}
            {success && <div className="success-message" style={{ color: 'var(--green)', marginTop: 10 }}>{success}</div>}

            <div className="profile-actions">
              <button 
                type="submit" 
                className="btn btn-gold" 
                disabled={saving}
                style={{ display: 'flex', alignItems: 'center', gap: 8 }}
              >
                {saving ? 'Saving...' : <><Save size={16} /> Save Changes</>}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
