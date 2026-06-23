import { useState, useEffect } from 'react';
import { Car, Calendar, CreditCard, AlertTriangle, TrendingUp, Download, Users } from 'lucide-react';
import { getCars, getBookings, getDamages, getProfiles } from '../../api/client';
import { useCurrency } from '../../contexts/CurrencyContext';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend, AreaChart, Area } from 'recharts';
import ExcelJS from 'exceljs';
import { saveAs } from 'file-saver';
import './Admin.css';
import ResponsiveTable from '../../components/ResponsiveTable';

function StatCard({ icon: Icon, label, value, sub, color, iconColor }: { icon: any; label: string; value: string | number; sub?: string; color: string; iconColor?: string }) {
  return (
    <div className="stat-card" style={{ padding: '32px', display: 'flex', flexDirection: 'column', gap: '16px', alignItems: 'flex-start' }}>
      <div className="stat-card__icon" style={{ background: color, width: '56px', height: '56px', borderRadius: '14px' }}>
        <Icon size={28} color={iconColor ?? '#fff'}/>
      </div>
      <div className="stat-card__body" style={{ marginTop: '8px', width: '100%' }}>
        <div className="stat-card__value" style={{ fontSize: '2.5rem', fontWeight: 800 }}>{value}</div>
        <div className="stat-card__label" style={{ fontSize: '0.95rem', color: 'var(--text-2)', marginTop: '8px', fontWeight: 600 }}>{label}</div>
        {sub && <div className="stat-card__sub" style={{ fontSize: '0.85rem', marginTop: '12px', fontWeight: 500, padding: '6px 10px', background: 'var(--bg-2)', borderRadius: '6px', display: 'inline-block' }}>{sub}</div>}
      </div>
    </div>
  );
}

export default function AdminDashboard() {
  const [stats, setStats] = useState({ cars: 0, bookings: 0, revenue: 0, damages: 0, available: 0, utilRate: 0, wtd: 0, mtd: 0, ytd: 0, avgDays: 0, repeatRate: 0, customers: 0 });
  const [recentBookings, setRecentBookings] = useState<any[]>([]);
  const [revenueData, setRevenueData] = useState<any[]>([]);
  const [fleetStatusData, setFleetStatusData] = useState<any[]>([]);
  const [topCars, setTopCars] = useState<any[]>([]);
  const [allBookings, setAllBookings] = useState<any[]>([]);
  
  const { format } = useCurrency();

  useEffect(() => {
    Promise.allSettled([getCars(), getBookings(), getDamages(), getProfiles()])
      .then(([carsRes, bookingsRes, damagesRes, profilesRes]) => {
        const cars = (carsRes.status === 'fulfilled' && Array.isArray(carsRes.value)) ? carsRes.value : [];
        const bookings = (bookingsRes.status === 'fulfilled' && Array.isArray(bookingsRes.value)) ? bookingsRes.value : [];
        const damages = (damagesRes.status === 'fulfilled' && Array.isArray(damagesRes.value)) ? damagesRes.value : [];
        const profiles = (profilesRes.status === 'fulfilled' && Array.isArray(profilesRes.value)) ? profilesRes.value : [];
        const customerCount = profiles.filter((p: any) => !p.isAdmin).length;
        
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
          repeatRate,
          customers: customerCount,
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
        const statusCounts: Record<string, number> = { Available: 0, Rented: 0, 'In Maintenance': 0, Damaged: 0, Unavailable: 0 };
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
    ws.addRow(['Total Earnings (Gross)', format(stats.revenue)]);
    ws.addRow(['Current Month Earnings', format(stats.mtd)]);
    ws.addRow(['Current Week Earnings', format(stats.wtd)]);
    ws.addRow(['Fleet Utilization', `${Math.round(stats.utilRate)}%`]);
    ws.addRow(['Active Vehicles Status', `${stats.cars - stats.available} / ${stats.cars} Active`]);
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
        <StatCard 
          icon={CreditCard} 
          label="Total Earnings" 
          value={format(stats.revenue)} 
          sub={`This Month: ${format(stats.mtd)} | This Week: ${format(stats.wtd)}`} 
          color="var(--gold-bg)" 
          iconColor="var(--gold)"  
        />
        <StatCard 
          icon={Car} 
          label="Fleet Status" 
          value={`${stats.cars - stats.available} / ${stats.cars} Active`} 
          sub={`${Math.round(stats.utilRate)}% utilization rate`} 
          color="#eff6ff" 
          iconColor="var(--blue)"  
        />
        <StatCard 
          icon={Calendar} 
          label="Booking Volume" 
          value={`${stats.bookings} Bookings`} 
          sub={`Avg. Duration: ${Math.round(stats.avgDays)} days`} 
          color="#f0fdf4" 
          iconColor="var(--green)" 
        />
        <StatCard 
          icon={AlertTriangle} 
          label="Fleet Health" 
          value={`${stats.damages} Incidents`} 
          sub={`${Math.round(stats.repeatRate)}% customer repeat rate`} 
          color="#fff7ed" 
          iconColor="#b45309"      
        />
        <StatCard 
          icon={Users} 
          label="Total Customers" 
          value={stats.customers} 
          sub={`${Math.round(stats.repeatRate)}% repeat booking rate`} 
          color="#f0f9ff" 
          iconColor="#0284c7"      
        />
      </div>

      <div className="dashboard-chart-grid">
        <div className="admin-section" style={{ margin: 0 }}>
          <h3 className="admin-section__title"><TrendingUp size={16}/> Revenue Trends (Last 6 Months)</h3>
          <div id="revenue-chart" style={{ height: 320, width: '100%', marginTop: 20, background: '#fff' }}>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={revenueData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 14, fill: '#64748b', fontWeight: 500 }} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 14, fill: '#64748b', fontWeight: 500 }} tickFormatter={(v) => `K${(v/1000).toFixed(0)}k`} />
                <Tooltip 
                  contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 8px 24px rgba(0,0,0,0.12)', padding: '16px', fontWeight: 600 }} 
                  itemStyle={{ color: '#0f172a', fontSize: '1.2rem', fontWeight: 700 }}
                  formatter={(v: number) => [format(v), 'Revenue']} 
                />
                <Area type="monotone" dataKey="Revenue" stroke="#10b981" strokeWidth={4} fillOpacity={1} fill="url(#colorRevenue)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="admin-section" style={{ margin: 0 }}>
          <h3 className="admin-section__title"><PieChart size={16}/> Fleet Status</h3>
          <div id="fleet-chart" style={{ height: 320, width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#fff' }}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={fleetStatusData} cx="50%" cy="50%" innerRadius={65} outerRadius={110} paddingAngle={4} dataKey="value" stroke="none">
                  {fleetStatusData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#94a3b8'][index % 5]} />
                  ))}
                </Pie>
                <Tooltip 
                  contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 8px 24px rgba(0,0,0,0.12)', padding: '12px 16px', fontWeight: 600 }} 
                  itemStyle={{ color: '#0f172a', fontSize: '1.1rem' }} 
                />
                <Legend iconType="circle" wrapperStyle={{ fontSize: 14, fontWeight: 500 }} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      <div className="dashboard-table-grid">
        <div className="admin-section" style={{ margin: 0 }}>
          <h3 className="admin-section__title"><Car size={16}/> Top Performing Vehicles</h3>
          <div className="table-wrap">
            <ResponsiveTable>
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
</ResponsiveTable>
          </div>
        </div>

        <div className="admin-section" style={{ margin: 0 }}>
          <h3 className="admin-section__title"><Clock size={16}/> Recent Bookings</h3>
          <div className="table-wrap">
            <ResponsiveTable>
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
</ResponsiveTable>
          </div>
        </div>
      </div>
    </div>
  );
}
