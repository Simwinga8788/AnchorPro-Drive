import { useState, useEffect } from 'react';
import { getPayments } from '../../api/client';
import { useCurrency } from '../../contexts/CurrencyContext';
import type { Payment } from '../../types';
import './Admin.css';

const BADGE: Record<string, string> = { Pending:'badge-grey', Completed:'badge-green', Failed:'badge-red', Refunded:'badge-blue' };

export default function AdminPayments() {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);
  const { format } = useCurrency();

  useEffect(() => {
    getPayments().then(p => setPayments(p)).catch(() => {}).finally(() => setLoading(false));
  }, []);

  const total = payments.filter(p => p.status === 'Completed').reduce((s, p) => s + p.amountZmw, 0);

  return (
    <div className="admin-page">
      <div className="page-header flex-between">
        <div>
          <h1>Payments <span className="gold-text">Log</span></h1>
          <p>All financial transactions</p>
        </div>
        <div style={{ textAlign:'right' }}>
          <div style={{ fontSize:'0.75rem', textTransform:'uppercase', letterSpacing:'0.08em', color:'var(--text-3)', marginBottom:4 }}>Total Collected</div>
          <div style={{ fontFamily:'var(--font-head)', fontSize:'1.8rem', color:'var(--gold)' }}>{format(total)}</div>
        </div>
      </div>

      <div className="admin-section">
        {loading ? <div className="flex-center" style={{padding:48}}><div className="spinner"/></div> : payments.length === 0 ? (
          <p className="muted" style={{padding:'24px 0'}}>No payment records yet.</p>
        ) : (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr><th>Transaction ID</th><th>Method</th><th>Amount</th><th>Type</th><th>Status</th><th>Date</th></tr>
              </thead>
              <tbody>
                {payments.map(p => (
                  <tr key={p.id}>
                    <td style={{fontFamily:'monospace', fontSize:'0.8rem', color:'var(--text-2)'}}>{p.transactionId ?? p.id.slice(0,12)+'…'}</td>
                    <td>{p.paymentMethod}</td>
                    <td style={{color:'var(--gold)', fontFamily:'var(--font-head)'}}>{format(p.amountZmw, p.amountUsd)}</td>
                    <td>{p.type}</td>
                    <td><span className={`badge ${BADGE[p.status]??'badge-grey'}`}>{p.status}</span></td>
                    <td style={{fontSize:'0.8rem', color:'var(--text-2)'}}>{p.createdAt ? new Date(p.createdAt).toLocaleDateString() : '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
