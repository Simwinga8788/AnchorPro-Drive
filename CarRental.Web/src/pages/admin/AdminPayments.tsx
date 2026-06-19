import { useState, useEffect } from 'react';
import { getPayments, getBookings } from '../../api/client';
import { useCurrency } from '../../contexts/CurrencyContext';
import type { Payment } from '../../types';
import { Link } from 'react-router-dom';
import './Admin.css';
import ResponsiveTable from '../../components/ResponsiveTable';

const BADGE: Record<string, string> = { Pending:'badge-grey', Completed:'badge-green', Failed:'badge-red', Refunded:'badge-blue' };

export default function AdminPayments() {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'All' | 'Completed' | 'Pending'>('All');
  const { format } = useCurrency();

  useEffect(() => {
    getPayments()
      .then(p => setPayments(p))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  const totalCollected = payments
    .filter(p => p.status === 'Completed')
    .reduce((sum, p) => sum + (p.amountZmw || 0), 0);

  const totalOutstanding = payments
    .filter(p => p.status === 'Pending')
    .reduce((sum, p) => sum + (p.amountZmw || 0), 0);

  const filteredPayments = payments.filter(p => {
    if (filter === 'All') return true;
    return p.status === filter;
  });

  return (
    <div className="admin-page">
      <div className="page-header flex-between" style={{ alignItems: 'flex-start' }}>
        <div>
          <h1>Payments <span className="gold-text">Log</span></h1>
          <p>All financial transactions and outstanding balances</p>
        </div>
        <div style={{ display: 'flex', gap: 24, textAlign: 'right' }}>
          <div>
            <div style={{ fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--text-3)', marginBottom: 4 }}>Total Collected</div>
            <div style={{ fontFamily: 'var(--font-head)', fontSize: '1.6rem', color: '#10b981' }}>{format(totalCollected)}</div>
          </div>
          <div>
            <div style={{ fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--text-3)', marginBottom: 4 }}>Outstanding Due</div>
            <div style={{ fontFamily: 'var(--font-head)', fontSize: '1.6rem', color: '#f59e0b' }}>{format(totalOutstanding)}</div>
          </div>
        </div>
      </div>

      <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
        <button 
          className={`btn btn-sm ${filter === 'All' ? 'btn-gold' : 'btn-outline'}`} 
          onClick={() => setFilter('All')}
        >
          All ({payments.length})
        </button>
        <button 
          className={`btn btn-sm ${filter === 'Completed' ? 'btn-gold' : 'btn-outline'}`} 
          onClick={() => setFilter('Completed')}
          style={{ borderColor: filter === 'Completed' ? 'var(--gold)' : 'rgba(16,185,129,0.3)' }}
        >
          Completed ({payments.filter(p => p.status === 'Completed').length})
        </button>
        <button 
          className={`btn btn-sm ${filter === 'Pending' ? 'btn-gold' : 'btn-outline'}`} 
          onClick={() => setFilter('Pending')}
          style={{ borderColor: filter === 'Pending' ? 'var(--gold)' : 'rgba(245,158,11,0.3)' }}
        >
          Pending / Due ({payments.filter(p => p.status === 'Pending').length})
        </button>
      </div>

      <div className="admin-section">
        {loading ? <div className="flex-center" style={{padding:48}}><div className="spinner"/></div> : filteredPayments.length === 0 ? (
          <p className="muted" style={{padding:'24px 0'}}>No payments match the selected filter.</p>
        ) : (
          <div className="table-wrap">
            <ResponsiveTable>
<table className="data-table">
              <thead>
                <tr>
                  <th>Transaction ID</th>
                  <th>Customer</th>
                  <th>Booking / Type</th>
                  <th>Method</th>
                  <th>Amount</th>
                  <th>Status</th>
                  <th>Date</th>
                </tr>
              </thead>
              <tbody>
                {filteredPayments.map(p => (
                  <tr key={p.id}>
                    <td style={{fontFamily:'monospace', fontSize:'0.8rem', color:'var(--text-2)'}}>{p.transactionId ?? p.id.slice(0,12)+'…'}</td>
                    <td>
                      <strong>{p.profile ? `${p.profile.firstName} ${p.profile.lastName}` : 'Guest'}</strong>
                      {p.profile?.phoneNumber && (
                        <div style={{ fontSize: '0.75rem', color: 'var(--text-3)', marginTop: 2 }}>{p.profile.phoneNumber}</div>
                      )}
                    </td>
                    <td>
                      <Link to={`/quote/${p.bookingId}`} className="gold-text" style={{ fontWeight: 500, textDecoration: 'none' }}>
                        Booking #{p.bookingId.slice(0, 8).toUpperCase()}
                      </Link>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-3)', marginTop: 2 }}>{p.type}</div>
                    </td>
                    <td>{p.paymentMethod}</td>
                    <td style={{color:'var(--gold)', fontFamily:'var(--font-head)'}}>{format(p.amountZmw, p.amountUsd)}</td>
                    <td><span className={`badge ${BADGE[p.status]??'badge-grey'}`}>{p.status}</span></td>
                    <td style={{fontSize:'0.8rem', color:'var(--text-2)'}}>{p.createdAt ? new Date(p.createdAt).toLocaleDateString() : '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
</ResponsiveTable>
          </div>
        )}
      </div>
    </div>
  );
}
