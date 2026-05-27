import { useState, useEffect } from 'react';
import { Car, Calendar, CreditCard, AlertTriangle, FileText, TrendingUp } from 'lucide-react';
import { getCars, getBookings, getPayments, getDamages } from '../../api/client';
import { useCurrency } from '../../contexts/CurrencyContext';
import './Admin.css';

function StatCard({ icon: Icon, label, value, sub, color, iconColor }: { icon: any; label: string; value: string | number; sub?: string; color: string; iconColor?: string }) {
  return (
    <div className="stat-card">
      <div className="stat-card__icon" style={{ background: color }}><Icon size={18} color={iconColor ?? '#fff'}/></div>
      <div className="stat-card__body">
        <div className="stat-card__value">{value}</div>
        <div className="stat-card__label">{label}</div>
        {sub && <div className="stat-card__sub">{sub}</div>}
      </div>
    </div>
  );
}

export default function AdminDashboard() {
  const [stats, setStats] = useState({ cars: 0, bookings: 0, revenue: 0, damages: 0, available: 0 });
  const [recentBookings, setRecentBookings] = useState<any[]>([]);
  const { format } = useCurrency();

  useEffect(() => {
    Promise.allSettled([getCars(), getBookings(), getPayments(), getDamages()])
      .then(([cars, bookings, payments, damages]) => {
        const c = cars.status === 'fulfilled' ? cars.value : [];
        const b = bookings.status === 'fulfilled' ? bookings.value : [];
        const p = payments.status === 'fulfilled' ? payments.value : [];
        const d = damages.status === 'fulfilled' ? damages.value : [];
        const revenue = p.reduce((sum: number, pay: any) => sum + (pay.amountZmw ?? 0), 0);
        setStats({
          cars: c.length,
          bookings: b.length,
          revenue,
          damages: d.length,
          available: c.filter((x: any) => x.status === 'Available').length,
        });
        setRecentBookings(b.slice(0, 5));
      });
  }, []);

  const STATUS_CLASS: Record<string, string> = {
    Confirmed:'badge-gold', Active:'badge-blue', Completed:'badge-green', Cancelled:'badge-red',
  };

  return (
    <div className="admin-page">
      <div className="page-header">
        <h1>Dashboard</h1>
        <p>Overview of your fleet and operations</p>
      </div>

      <div className="stat-cards-grid">
        <StatCard icon={Car}           label="Total Vehicles"     value={stats.cars}      sub={`${stats.available} available`} color="var(--gold-bg)"     iconColor="var(--gold)"  />
        <StatCard icon={Calendar}      label="Total Bookings"     value={stats.bookings}                                       color="#eff6ff"            iconColor="var(--blue)"  />
        <StatCard icon={CreditCard}    label="Total Revenue"      value={format(stats.revenue)}                                color="#f0fdf4"            iconColor="var(--green)" />
        <StatCard icon={AlertTriangle} label="Damage Reports"     value={stats.damages}                                        color="#fff7ed"            iconColor="#b45309"      />
      </div>

      <div className="admin-section">
        <h3 className="admin-section__title"><TrendingUp size={16}/> Recent Bookings</h3>
        {recentBookings.length === 0 ? (
          <p className="muted" style={{ padding: '24px 0' }}>No bookings data available yet.</p>
        ) : (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Vehicle</th>
                  <th>Dates</th>
                  <th>Total</th>
                  <th>Status</th>
                  <th>Payment</th>
                </tr>
              </thead>
              <tbody>
                {recentBookings.map(b => (
                  <tr key={b.id}>
                    <td>{b.car?.make} {b.car?.model}</td>
                    <td style={{ fontSize:'0.82rem', color:'var(--text-2)' }}>{b.startDate} → {b.endDate}</td>
                    <td style={{ color:'var(--gold)', fontFamily:'var(--font-head)' }}>{format(b.totalPriceZmw, b.totalPriceUsd)}</td>
                    <td><span className={`badge ${STATUS_CLASS[b.status] ?? 'badge-grey'}`}>{b.status}</span></td>
                    <td><span className={`badge ${b.paymentStatus === 'Paid' ? 'badge-green' : 'badge-grey'}`}>{b.paymentStatus}</span></td>
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
