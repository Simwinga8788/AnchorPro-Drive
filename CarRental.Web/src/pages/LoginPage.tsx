import { useState } from 'react';
import { useNavigate, Link, useLocation } from 'react-router-dom';
import { Eye, EyeOff, User, Lock, Mail, Calendar, CreditCard, ArrowRight } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { createProfile } from '../api/client';
import './LoginPage.css';

export default function LoginPage() {
  const [mode, setMode] = useState<'signin' | 'signup'>('signin');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPass, setShowPass] = useState(false);
  
  // Extra signup fields
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [driverLicense, setDriverLicense] = useState('');
  const [dob, setDob] = useState('');

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const { signIn, signUp } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(''); setSuccess(''); setLoading(true);
    if (mode === 'signin') {
      const { error } = await signIn(email, password);
      if (error) setError(error);
      else navigate('/');
    } else {
      const { data, error } = await signUp(email, password, {
        data: {
          first_name: firstName,
          last_name: lastName,
          phone_number: phoneNumber,
          dob: dob,
          driver_license: driverLicense || undefined,
        }
      });
      if (error) {
        setError(error);
      } else {
        // Create the profile on the backend database immediately (using AllowAnonymous endpoint)
        if (data?.user?.id) {
          try {
            await createProfile({
              id: data.user.id,
              email,
              firstName,
              lastName,
              phoneNumber,
              driverLicenseNumber: driverLicense || undefined,
              dateOfBirth: dob ? dob : undefined,
            });
          } catch (apiErr) {
            console.error("Failed to create profile immediately:", apiErr);
          }
        }

        // Save profile details to localStorage as fallback
        localStorage.setItem('pending_profile', JSON.stringify({
          firstName,
          lastName,
          phoneNumber,
          driverLicenseNumber: driverLicense || undefined,
          dateOfBirth: dob ? dob : undefined,
        }));
        setSuccess('Account created! Please sign in below.');
        // Switch to sign-in mode so user can log in immediately
        setTimeout(() => {
          setMode('signin');
          setSuccess('');
        }, 1500);
      }
    }
    setLoading(false);
  };

  return (
    <div className="login-page">
      {/* Logo is positioned outside the card at the top */}
      <Link to="/" className="login-page-logo">
        <img src="/logo.png" alt="Retrix Car Rental" />
      </Link>

      <div className={`login-card ${mode === 'signup' ? 'signup-mode' : ''} animate-slide`}>
        <form onSubmit={handleSubmit} className="login-form">
          {mode === 'signin' ? (
            <>
              <div className="form-group">
                <label className="form-label" htmlFor="email">EMAIL ADDRESS</label>
                <div className="input-with-icon-wrapper">
                  <User size={18} className="input-icon" />
                  <input
                    id="email"
                    type="email"
                    className="form-input"
                    placeholder="yourname@gmail.com"
                    value={email}
                    onChange={e => setEmail(e.target.value)}
                    required
                    autoComplete="email"
                  />
                </div>
              </div>

              <div className="form-group">
                <div className="label-row">
                  <label className="form-label" htmlFor="password">PASSWORD</label>
                  <a href="#" className="forgot-link" onClick={(e) => { e.preventDefault(); alert("Please contact support at simwinga8788@gmail.com to reset your password."); }}>Forgot password?</a>
                </div>
                <div className="input-with-icon-wrapper">
                  <Lock size={18} className="input-icon" />
                  <input
                    id="password"
                    type={showPass ? 'text' : 'password'}
                    className="form-input"
                    placeholder="••••••••"
                    value={password}
                    onChange={e => setPassword(e.target.value)}
                    required
                    autoComplete="current-password"
                    minLength={6}
                  />
                  <button
                    type="button"
                    className="login-eye"
                    onClick={() => setShowPass(p => !p)}
                    tabIndex={-1}
                    id="toggle-password-btn"
                  >
                    {showPass ? <EyeOff size={16}/> : <Eye size={16}/>}
                  </button>
                </div>
              </div>
            </>
          ) : (
            <>
              {/* Sign up form */}
              <div className="form-group">
                <label className="form-label" htmlFor="email">EMAIL ADDRESS</label>
                <div className="input-with-icon-wrapper">
                  <Mail size={18} className="input-icon" />
                  <input
                    id="email"
                    type="email"
                    className="form-input"
                    placeholder="yourname@gmail.com"
                    value={email}
                    onChange={e => setEmail(e.target.value)}
                    required
                    autoComplete="email"
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="password">PASSWORD</label>
                <div className="input-with-icon-wrapper">
                  <Lock size={18} className="input-icon" />
                  <input
                    id="password"
                    type={showPass ? 'text' : 'password'}
                    className="form-input"
                    placeholder="••••••••"
                    value={password}
                    onChange={e => setPassword(e.target.value)}
                    required
                    autoComplete="new-password"
                    minLength={6}
                  />
                  <button
                    type="button"
                    className="login-eye"
                    onClick={() => setShowPass(p => !p)}
                    tabIndex={-1}
                    id="toggle-password-btn"
                  >
                    {showPass ? <EyeOff size={16}/> : <Eye size={16}/>}
                  </button>
                </div>
              </div>

              <div className="signup-grid">
                <div className="form-group">
                  <label className="form-label">FIRST NAME</label>
                  <input className="form-input" required value={firstName} onChange={e => setFirstName(e.target.value)} placeholder="John" />
                </div>
                <div className="form-group">
                  <label className="form-label">LAST NAME</label>
                  <input className="form-input" required value={lastName} onChange={e => setLastName(e.target.value)} placeholder="Doe" />
                </div>
                <div className="form-group">
                  <label className="form-label">PHONE NUMBER</label>
                  <input className="form-input" required type="tel" value={phoneNumber} onChange={e => setPhoneNumber(e.target.value)} placeholder="0972996902" />
                </div>
                <div className="form-group">
                  <label className="form-label">DATE OF BIRTH</label>
                  <input className="form-input" required type="date" value={dob} onChange={e => setDob(e.target.value)} />
                </div>
                <div className="form-group" style={{ gridColumn: '1 / -1' }}>
                  <label className="form-label">DRIVER'S LICENSE NUMBER (OPTIONAL)</label>
                  <input className="form-input" value={driverLicense} onChange={e => setDriverLicense(e.target.value)} placeholder="12345678" />
                </div>
              </div>
            </>
          )}

          {error && <div className="login-error">{error}</div>}
          {success && <div className="login-success">{success}</div>}

          <button
            type="submit"
            className="btn btn-blue login-submit-btn"
            disabled={loading}
            id="auth-submit-btn"
          >
            {loading ? 'Please wait...' : mode === 'signin' ? 'Sign in' : 'Register'}
          </button>
        </form>
      </div>

      {/* Switch mode and footer below the card */}
      <div className="login-footer-area">
        <p className="login-switch">
          {mode === 'signin' ? "No account yet? " : 'Already have an account? '}
          <button
            className="login-switch-btn"
            onClick={() => { setMode(m => m === 'signin' ? 'signup' : 'signin'); setError(''); setSuccess(''); }}
            id="mode-toggle-btn"
          >
            {mode === 'signin' ? 'Create an account' : 'Sign in'} <ArrowRight size={14} style={{ marginLeft: 4, display: 'inline-block', verticalAlign: 'middle' }} />
          </button>
        </p>

        <p style={{ marginTop: 24 }}>
          <Link to="/" className="back-home-link">← Back to Home</Link>
        </p>

        <div className="login-copyright">
          © {new Date().getFullYear()} RETRIX CAR RENTAL
        </div>
      </div>
    </div>
  );
}
