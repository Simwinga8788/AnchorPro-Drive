import { useState, useEffect } from 'react';
import { Car, Calendar, CreditCard, AlertTriangle, TrendingUp, Download, CheckCircle, Clock } from 'lucide-react';
import { getCars, getBookings, getDamages } from '../../api/client';
import { useCurrency } from '../../contexts/CurrencyContext';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts';
import ExcelJS from 'exceljs';
import { saveAs } from 'file-saver';
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
  const [stats, setStats] = useState({ cars: 0, bookings: 0, revenue: 0, damages: 0, available: 0, utilRate: 0, wtd: 0, mtd: 0, ytd: 0, avgDays: 0, repeatRate: 0 });
  const [recentBookings, setRecentBookings] = useState<any[]>([]);
  const [revenueData, setRevenueData] = useState<any[]>([]);
  const [fleetStatusData, setFleetStatusData] = useState<any[]>([]);
  const [topCars, setTopCars] = useState<any[]>([]);
  const [allBookings, setAllBookings] = useState<any[]>([]);
  
  const { format } = useCurrency();

  useEffect(() => {
    Promise.allSettled([getCars(), getBookings(), getDamages()])
      .then(([carsRes, bookingsRes, damagesRes]) => {
        const cars = carsRes.status === 'fulfilled' ? carsRes.value : [];
        const bookings = bookingsRes.status === 'fulfilled' ? bookingsRes.value : [];
        const damages = damagesRes.status === 'fulfilled' ? damagesRes.value : [];
        
        setAllBookings(bookings);

        const now = new Date();
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).getTime();
        const startOfYear = new Date(now.getFullYear(), 0, 1).getTime();
        const startOfWeek = new Date(now);
        startOfWeek.setDate(now.getDate() - (now.getDay() === 0 ? 6 : now.getDay() - 1));
        startOfWeek.setHours(0,0,0,0);

        let totalRev = 0, wtdRev = 0, mtdRev = 0, ytdRev = 0;
        let totalDays = 0, completedCount = 0;
        
        const customerBookingCounts: Record<string, number> = {};

        bookings.forEach((b: any) => {
          if (b.status !== 'Cancelled') {
            const rev = b.totalPriceZmw || 0;
            totalRev += rev;
            
            const bDate = new Date(b.createdAt || b.startDate).getTime();
            if (bDate >= startOfWeek.getTime()) wtdRev += rev;
            if (bDate >= startOfMonth) mtdRev += rev;
            if (bDate >= startOfYear) ytdRev += rev;

            const st = new Date(b.startDate).getTime();
            const ed = new Date(b.endDate).getTime();
            const days = Math.ceil(Math.abs(ed - st) / (1000 * 60 * 60 * 24));
            totalDays += days;
            completedCount++;
            
            customerBookingCounts[b.customerId] = (customerBookingCounts[b.customerId] || 0) + 1;
          }
        });

        const repeatCustomers = Object.values(customerBookingCounts).filter(c => c > 1).length;
        const totalCustomers = Object.keys(customerBookingCounts).length;
        const repeatRate = totalCustomers > 0 ? (repeatCustomers / totalCustomers) * 100 : 0;
        
        const available = cars.filter((c: any) => c.status === 'Available').length;
        const utilRate = cars.length > 0 ? ((cars.length - available) / cars.length) * 100 : 0;

        setStats({
          cars: cars.length,
          bookings: bookings.length,
          revenue: totalRev,
          damages: damages.length,
          available,
          utilRate,
          wtd: wtdRev,
          mtd: mtdRev,
          ytd: ytdRev,
          avgDays: completedCount > 0 ? (totalDays / completedCount) : 0,
          repeatRate
        });
        
        setRecentBookings(bookings.slice(0, 5));

        // 6-Month Revenue Data
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const revMap: Record<string, number> = {};
        for(let i=5; i>=0; i--) {
          const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
          revMap[`${months[d.getMonth()]} ${d.getFullYear()}`] = 0;
        }
        bookings.forEach((b: any) => {
          if (b.status !== 'Cancelled') {
            const d = new Date(b.createdAt || b.startDate);
            const key = `${months[d.getMonth()]} ${d.getFullYear()}`;
            if (revMap[key] !== undefined) {
              revMap[key] += (b.totalPriceZmw || 0);
            }
          }
        });
        setRevenueData(Object.keys(revMap).map(k => ({ name: k, Revenue: revMap[k] })));

        // Fleet Status Data
        const statusCounts: Record<string, number> = { Available: 0, Rented: 0, Maintenance: 0, Unavailable: 0 };
        cars.forEach((c: any) => { if(statusCounts[c.status] !== undefined) statusCounts[c.status]++; });
        setFleetStatusData(Object.keys(statusCounts).map(k => ({ name: k, value: statusCounts[k] })));

        // Top Cars
        const carRevMap: Record<string, { make: string, model: string, rev: number, count: number, dmg: number }> = {};
        cars.forEach((c: any) => {
          carRevMap[c.id] = { make: c.make, model: c.model, rev: 0, count: 0, dmg: 0 };
        });
        bookings.forEach((b: any) => {
          if (b.status !== 'Cancelled' && carRevMap[b.carId]) {
            carRevMap[b.carId].rev += (b.totalPriceZmw || 0);
            carRevMap[b.carId].count++;
          }
        });
        damages.forEach((d: any) => {
          if (carRevMap[d.carId]) {
            carRevMap[d.carId].dmg += (d.actualCostZmw || d.estimatedCostZmw || 0);
          }
        });
        setTopCars(Object.values(carRevMap).sort((a,b) => b.rev - a.rev).slice(0, 5));
      });
  }, []);

  const handleExport = async () => {
    const wb = new ExcelJS.Workbook();
    const ws = wb.addWorksheet('Daily Report');
    
    // Title
    ws.addRow([`Retrix Car Rental - Daily Report (${new Date().toLocaleDateString()})`]);
    ws.getRow(1).font = { bold: true, size: 14 };
    ws.addRow([]);

    // Dashboard Metrics
    ws.addRow(['Dashboard Metrics']);
    ws.getRow(3).font = { bold: true };
    ws.addRow(['Month-to-Date Revenue', format(stats.mtd)]);
    ws.addRow(['Year-to-Date Revenue', format(stats.ytd)]);
    ws.addRow(['Fleet Utilization', `${Math.round(stats.utilRate)}%`]);
    ws.addRow(['Average Rental Duration', `${Math.round(stats.avgDays)} Days`]);
    ws.addRow([]);

    // Top Vehicles
    ws.addRow(['Top Performing Vehicles']);
    const topVehiclesHeaderRow = ws.lastRow!.number;
    ws.getRow(topVehiclesHeaderRow).font = { bold: true };
    ws.addRow(['Vehicle Make', 'Vehicle Model', 'Total Bookings', 'Gross Revenue (ZMW)', 'Maintenance (ZMW)']);
    
    topCars.forEach(c => {
      ws.addRow([c.make, c.model, c.count, c.rev, c.dmg]);
    });
    ws.addRow([]);

    // Booking Records
    ws.addRow(['Booking Records']);
    const bookingsHeaderRow = ws.lastRow!.number;
    ws.getRow(bookingsHeaderRow).font = { bold: true };
    ws.addRow(['ID', 'Booking Date', 'Customer', 'Vehicle', 'Pickup Date', 'Return Date', 'Status', 'Total Price (ZMW)']);
    
    allBookings.forEach(b => {
       ws.addRow([
         b.id,
         new Date(b.createdAt || b.startDate).toLocaleDateString(),
         b.customer ? `${b.customer.firstName} ${b.customer.lastName}` : b.customerId,
         b.car ? `${b.car.make} ${b.car.model}` : 'N/A',
         new Date(b.startDate).toLocaleDateString(),
         new Date(b.endDate).toLocaleDateString(),
         b.status,
         b.totalPriceZmw || 0
       ]);
    });

    // Simple column sizing
    ws.columns.forEach(col => { col.width = 18; });

    // Generate File
    const buffer = await wb.xlsx.writeBuffer();
    saveAs(new Blob([buffer]), `Retrix_Daily_Report_${new Date().toISOString().split('T')[0]}.xlsx`);
  };

  const STATUS_CLASS: Record<string, string> = { Confirmed:'badge-gold', Active:'badge-blue', Completed:'badge-green', Cancelled:'badge-red', Pending: 'badge-grey' };
  const COLORS = ['#10b981', '#f59e0b', '#ef4444', '#94a3b8'];

  return (
    <div className="admin-page">
      <div className="page-header flex-between">
        <div>
          <h1>Analytics Dashboard</h1>
          <p>Comprehensive overview of your fleet and operations</p>
        </div>
        <button className="btn btn-gold btn-sm" onClick={handleExport} id="export-csv-btn">
          <Download size={15}/> Export to Excel
        </button>
      </div>

      <div className="stat-cards-grid" style={{ marginBottom: 24 }}>
        <StatCard icon={CreditCard}    label="Month-to-Date Revenue" value={format(stats.mtd)} sub={`WTD: ${format(stats.wtd)} | YTD: ${format(stats.ytd)}`} color="var(--gold-bg)" iconColor="var(--gold)"  />
        <StatCard icon={Car}           label="Fleet Utilization"     value={`${Math.round(stats.utilRate)}%`} sub={`${stats.cars - stats.available} cars currently booked`} color="#eff6ff" iconColor="var(--blue)"  />
        <StatCard icon={Calendar}      label="Avg. Rental Duration"  value={`${Math.round(stats.avgDays)} Days`} sub={`${Math.round(stats.repeatRate)}% Customer Repeat Rate`} color="#f0fdf4" iconColor="var(--green)" />
        <StatCard icon={AlertTriangle} label="Damage Reports"        value={stats.damages} sub="Requires attention" color="#fff7ed" iconColor="#b45309"      />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 24, marginBottom: 24 }}>
        <div className="admin-section" style={{ margin: 0 }}>
          <h3 className="admin-section__title"><TrendingUp size={16}/> Revenue Trends (Last 6 Months)</h3>
          <div id="revenue-chart" style={{ height: 300, width: '100%', marginTop: 20, background: '#fff' }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={revenueData}>
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: 'var(--text-2)' }} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: 'var(--text-2)' }} width={80} tickFormatter={(v) => `K${(v/1000).toFixed(0)}k`} />
                <Tooltip cursor={{ fill: 'var(--cream)' }} contentStyle={{ borderRadius: 8, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }} formatter={(v: number) => format(v)} />
                <Bar dataKey="Revenue" fill="var(--gold)" radius={[4, 4, 0, 0]} barSize={40} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="admin-section" style={{ margin: 0 }}>
          <h3 className="admin-section__title"><PieChart size={16}/> Fleet Status</h3>
          <div id="fleet-chart" style={{ height: 300, width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#fff' }}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={fleetStatusData} cx="50%" cy="50%" innerRadius={60} outerRadius={100} paddingAngle={2} dataKey="value">
                  {fleetStatusData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip contentStyle={{ borderRadius: 8, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }} />
                <Legend iconType="circle" wrapperStyle={{ fontSize: 12 }} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24, marginBottom: 24 }}>
        <div className="admin-section" style={{ margin: 0 }}>
          <h3 className="admin-section__title"><Car size={16}/> Top Performing Vehicles</h3>
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Vehicle</th>
                  <th>Bookings</th>
                  <th>Revenue</th>
                  <th>Maint. Cost</th>
                </tr>
              </thead>
              <tbody>
                {topCars.map((c, i) => (
                  <tr key={i}>
                    <td><strong>{c.make} {c.model}</strong></td>
                    <td>{c.count}</td>
                    <td style={{ color:'var(--gold)' }}>{format(c.rev)}</td>
                    <td style={{ color: c.dmg > 0 ? 'var(--red)' : 'var(--text-2)' }}>{format(c.dmg)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div className="admin-section" style={{ margin: 0 }}>
          <h3 className="admin-section__title"><Clock size={16}/> Recent Bookings</h3>
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Vehicle</th>
                  <th>Dates</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {recentBookings.map(b => (
                  <tr key={b.id}>
                    <td>{b.car?.make} {b.car?.model}</td>
                    <td style={{ fontSize:'0.82rem', color:'var(--text-2)' }}>{b.startDate.split('T')[0]}</td>
                    <td><span className={`badge ${STATUS_CLASS[b.status] ?? 'badge-grey'}`}>{b.status}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
