import { useState, useEffect } from 'react';
import { getDamages } from '../../api/client';
import type { Damage } from '../../types';
import './Admin.css';

const SEV_BADGE: Record<string, string> = { Minor:'badge-blue', Moderate:'badge-gold', Severe:'badge-red' };
const REP_BADGE: Record<string, string> = { Pending:'badge-grey', InProgress:'badge-gold', Repaired:'badge-green' };

export default function AdminDamages() {
  const [damages, setDamages] = useState<Damage[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getDamages().then(d => setDamages(d)).catch(() => {}).finally(() => setLoading(false));
  }, []);

  return (
    <div className="admin-page">
      <div className="page-header">
        <h1>Damage <span className="gold-text">Reports</span></h1>
        <p>Vehicle damage tracking and repair status</p>
      </div>

      <div className="admin-section">
        {loading ? <div className="flex-center" style={{padding:48}}><div className="spinner"/></div> : damages.length === 0 ? (
          <p className="muted" style={{padding:'24px 0'}}>No damage reports on record. Great news!</p>
        ) : (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr><th>Vehicle</th><th>Description</th><th>Severity</th><th>Repair Status</th><th>Est. Cost (ZMW)</th><th>Reported</th></tr>
              </thead>
              <tbody>
                {damages.map(d => (
                  <tr key={d.id}>
                    <td><strong>{d.car?.make ?? '—'} {d.car?.model ?? ''}</strong></td>
                    <td style={{maxWidth:240, fontSize:'0.85rem', color:'var(--text-2)'}}>{d.description}</td>
                    <td><span className={`badge ${SEV_BADGE[d.severity]??'badge-grey'}`}>{d.severity}</span></td>
                    <td><span className={`badge ${REP_BADGE[d.repairStatus]??'badge-grey'}`}>{d.repairStatus}</span></td>
                    <td style={{fontFamily:'var(--font-head)', color:'var(--gold)'}}>{d.estimatedCostZmw ? `K${d.estimatedCostZmw.toLocaleString()}` : '—'}</td>
                    <td style={{fontSize:'0.8rem', color:'var(--text-2)'}}>{d.createdAt ? new Date(d.createdAt).toLocaleDateString() : '—'}</td>
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
