import { useState, useEffect } from 'react';
import { getBookings, getCars, getDamages } from '../../api/client';
import { useCurrency } from '../../contexts/CurrencyContext';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';
import ExcelJS from 'exceljs';
import { saveAs } from 'file-saver';
import { Download, Calendar as CalendarIcon, TrendingUp, Car } from 'lucide-react';
import './Admin.css';

export default function AdminReports() {
  const { format } = useCurrency();
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState({
    start: new Date(new Date().setMonth(new Date().getMonth() - 1)).toISOString().split('T')[0],
    end: new Date().toISOString().split('T')[0]
  });

  const [data, setData] = useState({
    totalRevenue: 0,
    totalBookings: 0,
    completedBookings: 0,
    revenueByDay: [] as any[],
    vehiclePerformance: [] as any[],
  });

  useEffect(() => {
    fetchReportData();
  }, [dateRange]);

  const fetchReportData = async () => {
    setLoading(true);
    try {
      const [bRes, cRes] = await Promise.all([getBookings(), getCars()]);
      const bookings = Array.isArray(bRes) ? bRes : [];
      const cars = Array.isArray(cRes) ? cRes : [];
      
      const start = new Date(dateRange.start).getTime();
      const end = new Date(dateRange.end).getTime() + 86400000; // include end day
      
      let totalRev = 0;
      let completedCount = 0;
      let totalCount = 0;
      
      const dailyRev: Record<string, number> = {};
      const vehicleStats: Record<string, { make: string, model: string, rev: number, count: number }> = {};
      
      cars.forEach(c => {
        vehicleStats[c.id] = { make: c.make, model: c.model, rev: 0, count: 0 };
      });

      bookings.forEach(b => {
        const bDate = new Date(b.createdAt).getTime();
        if (bDate >= start && bDate < end) {
          totalCount++;
          if (b.status !== 'Cancelled') {
            const rev = b.totalPriceZmw || 0;
            totalRev += rev;
            if (b.status === 'Completed') completedCount++;
            
            const dayKey = b.createdAt.split('T')[0];
            dailyRev[dayKey] = (dailyRev[dayKey] || 0) + rev;
            
            if (vehicleStats[b.carId]) {
              vehicleStats[b.carId].rev += rev;
              vehicleStats[b.carId].count++;
            }
          }
        }
      });

      const revenueByDay = Object.keys(dailyRev).sort().map(date => ({
        date,
        Revenue: dailyRev[date]
      }));

      const vehiclePerformance = Object.values(vehicleStats)
        .filter(v => v.count > 0)
        .sort((a, b) => b.rev - a.rev);

      setData({
        totalRevenue: totalRev,
        totalBookings: totalCount,
        completedBookings: completedCount,
        revenueByDay,
        vehiclePerformance
      });

    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleExport = async () => {
    const wb = new ExcelJS.Workbook();
    const ws = wb.addWorksheet('Custom Report');
    
    ws.addRow([`Retrix Car Rental - Custom Report`]);
    ws.addRow([`Period: ${dateRange.start} to ${dateRange.end}`]);
    ws.addRow([]);
    
    ws.addRow(['Summary Metrics']);
    ws.addRow(['Total Revenue (ZMW)', data.totalRevenue]);
    ws.addRow(['Total Bookings', data.totalBookings]);
    ws.addRow(['Completed Bookings', data.completedBookings]);
    ws.addRow([]);
    
    ws.addRow(['Vehicle Performance']);
    ws.addRow(['Vehicle', 'Bookings', 'Revenue Generated']);
    data.vehiclePerformance.forEach(v => {
      ws.addRow([`${v.make} ${v.model}`, v.count, v.rev]);
    });
    
    const buf = await wb.xlsx.writeBuffer();
    saveAs(new Blob([buf]), `Retrix_Report_${dateRange.start}_${dateRange.end}.xlsx`);
  };

  return (
    <div className="admin-page">
      <div className="admin-page__header">
        <h1 className="admin-page__title">Custom Reports</h1>
        <button className="btn btn-primary" onClick={handleExport} disabled={loading}>
          <Download size={18} /> Export Excel
        </button>
      </div>

      <div className="reports-filters" style={{ display: 'flex', gap: 16, marginBottom: 32, background: 'white', padding: 24, borderRadius: 12, border: '1px solid var(--border-color)', alignItems: 'flex-end' }}>
        <div style={{ flex: 1 }}>
          <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: 600, color: 'var(--navy)', marginBottom: 8 }}>Start Date</label>
          <input 
            type="date" 
            className="input" 
            value={dateRange.start} 
            onChange={e => setDateRange({...dateRange, start: e.target.value})}
          />
        </div>
        <div style={{ flex: 1 }}>
          <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: 600, color: 'var(--navy)', marginBottom: 8 }}>End Date</label>
          <input 
            type="date" 
            className="input" 
            value={dateRange.end} 
            onChange={e => setDateRange({...dateRange, end: e.target.value})}
          />
        </div>
      </div>

      {loading ? (
        <div style={{ padding: 40, textAlign: 'center' }}>Loading report data...</div>
      ) : (
        <>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '16px', marginBottom: '32px' }}>
            <div className="stat-card">
              <div className="stat-card__icon" style={{ background: '#eff6ff' }}>
                <TrendingUp size={24} color="#3b82f6"/>
              </div>
              <div className="stat-card__value" style={{ marginTop: 12 }}>{format(data.totalRevenue)}</div>
              <div className="stat-card__label" style={{ marginTop: 4 }}>Total Revenue</div>
            </div>
            <div className="stat-card">
              <div className="stat-card__icon" style={{ background: '#f8fafc' }}>
                <CalendarIcon size={24} color="#0f172a"/>
              </div>
              <div className="stat-card__value" style={{ marginTop: 12 }}>{data.totalBookings}</div>
              <div className="stat-card__label" style={{ marginTop: 4 }}>Total Bookings</div>
            </div>
            <div className="stat-card">
              <div className="stat-card__icon" style={{ background: '#ecfdf5' }}>
                <Car size={24} color="#10b981"/>
              </div>
              <div className="stat-card__value" style={{ marginTop: 12 }}>{data.completedBookings}</div>
              <div className="stat-card__label" style={{ marginTop: 4 }}>Completed Rentals</div>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 24 }}>
            <div className="admin-card">
              <h2 className="admin-card__title">Revenue Over Time</h2>
              <div style={{ height: 320, marginTop: 24 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={data.revenueByDay} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                    <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 14, fontWeight: 500}} dy={10} />
                    <YAxis axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 14, fontWeight: 500}} tickFormatter={(val) => `K${val/1000}k`} />
                    <Tooltip 
                      cursor={{fill: '#f1f5f9'}} 
                      contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 8px 24px rgba(0,0,0,0.12)', padding: '16px', fontWeight: 600 }}
                      itemStyle={{ color: '#0f172a', fontSize: '1.2rem', fontWeight: 700 }}
                      formatter={(v: number) => [format(v), 'Revenue']}
                    />
                    <Bar dataKey="Revenue" fill="#3b82f6" radius={[6,6,0,0]} barSize={40} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>

            <div className="admin-card">
              <h2 className="admin-card__title">Top Vehicles</h2>
              <div style={{ marginTop: 24 }}>
                {data.vehiclePerformance.length === 0 ? (
                  <p style={{ color: '#64748b', fontSize: '0.875rem' }}>No data for this period.</p>
                ) : (
                  data.vehiclePerformance.slice(0, 5).map((v, i) => (
                    <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 0', borderBottom: '1px solid #e2e8f0' }}>
                      <div>
                        <div style={{ fontWeight: 600, color: 'var(--navy)', fontSize: '0.875rem' }}>{v.make} {v.model}</div>
                        <div style={{ fontSize: '0.75rem', color: '#64748b', marginTop: 4 }}>{v.count} bookings</div>
                      </div>
                      <div style={{ fontWeight: 700, color: '#10b981' }}>{format(v.rev)}</div>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
