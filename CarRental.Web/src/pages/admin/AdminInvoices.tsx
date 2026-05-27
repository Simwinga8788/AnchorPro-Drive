import { useState, useEffect } from 'react';
import { getInvoices } from '../../api/client';
import { useCurrency } from '../../contexts/CurrencyContext';
import type { ZraInvoice } from '../../types';
import './Admin.css';

const BADGE: Record<string, string> = { Pending:'badge-grey', Submitted:'badge-blue', Accepted:'badge-green', Rejected:'badge-red' };

export default function AdminInvoices() {
  const [invoices, setInvoices] = useState<ZraInvoice[]>([]);
  const [loading, setLoading] = useState(true);
  const { format } = useCurrency();

  useEffect(() => {
    getInvoices().then(i => setInvoices(i)).catch(() => {}).finally(() => setLoading(false));
  }, []);

  return (
    <div className="admin-page">
      <div className="page-header">
        <h1>ZRA <span className="gold-text">Invoices</span></h1>
        <p>Tax compliance — Zambia Revenue Authority invoice submissions</p>
      </div>

      <div className="admin-section">
        {loading ? <div className="flex-center" style={{padding:48}}><div className="spinner"/></div> : invoices.length === 0 ? (
          <p className="muted" style={{padding:'24px 0'}}>No ZRA invoices generated yet.</p>
        ) : (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr><th>Invoice No.</th><th>Booking</th><th>Tax (ZMW)</th><th>Total (ZMW)</th><th>Submission Status</th><th>Submitted</th></tr>
              </thead>
              <tbody>
                {invoices.map(i => (
                  <tr key={i.id}>
                    <td style={{fontFamily:'monospace', color:'var(--gold)'}}>{i.invoiceNumber}</td>
                    <td style={{fontSize:'0.8rem', fontFamily:'monospace', color:'var(--text-2)'}}>{i.bookingId.slice(0,12)}…</td>
                    <td>{i.taxAmountZmw ? format(i.taxAmountZmw) : '—'}</td>
                    <td style={{fontFamily:'var(--font-head)', color:'var(--gold)'}}>{i.totalAmountZmw ? format(i.totalAmountZmw) : '—'}</td>
                    <td><span className={`badge ${BADGE[i.submissionStatus]??'badge-grey'}`}>{i.submissionStatus}</span></td>
                    <td style={{fontSize:'0.8rem', color:'var(--text-2)'}}>{i.submittedAt ? new Date(i.submittedAt).toLocaleDateString() : '—'}</td>
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
