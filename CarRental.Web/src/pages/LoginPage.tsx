import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { Car, Eye, EyeOff } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import './LoginPage.css';

export default function LoginPage() {
  const [mode, setMode] = useState<'signin' | 'signup'>('signin');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPass, setShowPass] = useState(false);
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
      const { error } = await signUp(email, password);
      if (error) setError(error);
      else setSuccess('Account created! Check your email to confirm, then sign in.');
    }
    setLoading(false);
  };

  return (
    <div className="login-page">
      {/* Background */}
      <div className="login-bg"
        style={{ backgroundImage: `url('https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=1400&q=85')` }}
      />
      <div className="login-overlay" />

      <div className="login-card animate-slide">
        {/* Logo */}
        <Link to="/" className="login-logo">
          <Car size={24} />
          <span>AnchorPro<em>Drive</em></span>
        </Link>

        <h1 className="login-title">
          {mode === 'signin' ? 'Welcome Back' : 'Create Account'}
        </h1>
        <p className="login-sub muted">
          {mode === 'signin'
            ? 'Sign in to manage your bookings'
            : 'Join Zambia\'s premier car rental platform'}
        </p>

        <form onSubmit={handleSubmit} className="login-form">
          <div className="form-group">
            <label className="form-label" htmlFor="email">Email Address</label>
            <input
              id="email"
              type="email"
              className="form-input"
              placeholder="you@example.com"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
              autoComplete="email"
            />
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="password">Password</label>
            <div className="login-pass-wrap">
              <input
                id="password"
                type={showPass ? 'text' : 'password'}
                className="form-input"
                placeholder="••••••••"
                value={password}
                onChange={e => setPassword(e.target.value)}
                required
                autoComplete={mode === 'signin' ? 'current-password' : 'new-password'}
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

          {error && <div className="login-error">{error}</div>}
          {success && <div className="login-success">{success}</div>}

          <button
            type="submit"
            className="btn btn-gold"
            disabled={loading}
            id="auth-submit-btn"
            style={{ width: '100%', justifyContent:'center' }}
          >
            {loading ? 'Please wait...' : mode === 'signin' ? 'Sign In' : 'Create Account'}
          </button>
        </form>

        <div className="login-divider"><span>or</span></div>

        <p className="login-switch">
          {mode === 'signin' ? "Don't have an account? " : 'Already have an account? '}
          <button
            className="login-switch-btn"
            onClick={() => { setMode(m => m === 'signin' ? 'signup' : 'signin'); setError(''); setSuccess(''); }}
            id="mode-toggle-btn"
          >
            {mode === 'signin' ? 'Create one' : 'Sign in'}
          </button>
        </p>

        <p style={{ textAlign:'center', marginTop: 20 }}>
          <Link to="/" className="muted" style={{ fontSize:'0.8rem' }}>← Back to Home</Link>
        </p>
      </div>
    </div>
  );
}
