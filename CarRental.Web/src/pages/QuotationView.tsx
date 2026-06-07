import { useEffect, useState, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Car, FileText, Download, ArrowLeft } from 'lucide-react';
import { getBooking } from '../api/client';
import type { Booking } from '../types';
import html2pdf from 'html2pdf.js';
import './QuotationView.css';

export default function QuotationView() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [booking, setBooking] = useState<Booking | null>(null);
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);
  const invoiceRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (id) {
      getBooking(id)
        .then(b => setBooking(b))
        .catch(console.error)
        .finally(() => setLoading(false));
    }
  }, [id]);

  const downloadPdf = async () => {
    if (!invoiceRef.current || !booking) return;
    setGenerating(true);
    
    const element = invoiceRef.current;
    const opt = {
      margin:       0.5,
      filename:     `${documentTitle}_${booking.id.slice(0, 8).toUpperCase()}.pdf`,
      image:        { type: 'jpeg', quality: 0.98 },
      html2canvas:  { scale: 2 },
      jsPDF:        { unit: 'in', format: 'letter', orientation: 'portrait' }
    };

    try {
      await html2pdf().set(opt).from(element).save();
    } catch (error) {
      console.error('Failed to generate PDF', error);
      alert('Failed to generate PDF. Please try again.');
    } finally {
      setGenerating(false);
    }
  };

  if (loading) return <div className="flex-center" style={{ height: '100vh' }}><div className="spinner" /></div>;
  if (!booking) return <div className="container" style={{ padding: '100px 0' }}>Booking not found</div>;

  const isQuote = booking.status === 'Pending' || booking.status === 'Draft';
  const documentTitle = isQuote ? 'QUOTATION' : 'INVOICE';
  
  const days = Math.floor((new Date(booking.endDate).getTime() - new Date(booking.startDate).getTime()) / 86400000);
  const rentalDays = days < 1 ? 1 : days;

  // Financial calculations
  const baseRentalPrice = booking.totalPriceZmw;
  const damageFees = booking.payments?.filter(p => p.type === 'Damage Fee') || [];
  const totalDamageFees = damageFees.reduce((sum, p) => sum + p.amountZmw, 0);
  const totalCharges = baseRentalPrice + totalDamageFees;
  const completedPayments = booking.payments?.filter(p => p.status === 'Completed') || [];
  const totalPaid = completedPayments.reduce((sum, p) => sum + p.amountZmw, 0);
  const balanceDue = totalCharges - totalPaid;

  return (
    <div className="quotation-page" style={{ paddingTop: 80, paddingBottom: 80, minHeight: '100vh', background: '#f5f7fa' }}>
      <div className="container">
        <div className="quotation-actions no-print" style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 24 }}>
          <button className="btn btn-ghost btn-sm" onClick={() => navigate(-1)}>
            <ArrowLeft size={16} /> Back
          </button>
          <button className="btn btn-gold" onClick={downloadPdf} disabled={generating}>
            {generating ? <div className="spinner spinner-sm" /> : <Download size={18} />}
            {generating ? 'Generating PDF...' : 'Download PDF'}
          </button>
        </div>

        <div className="invoice-wrapper" ref={invoiceRef}>
          {/* Header */}
          <div className="invoice-header">
            <div className="invoice-brand">
              <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                <img src="/logo.png" alt="Retrix Car Rental" style={{ height: '70px', objectFit: 'contain' }} />
                <div>
                  <h2 style={{ margin: 0, color: '#0f172a', fontSize: '1.5rem', fontWeight: 700 }}>Retrix Car Rental</h2>
                </div>
              </div>
              <p style={{ marginTop: 8, color: '#64748b', fontSize: '0.875rem' }}>
                Lusaka, Zambia<br/>
                <a href="mailto:retrixrentals@gmail.com" style={{ color: 'inherit', textDecoration: 'none' }}>retrixrentals@gmail.com</a><br/>
                Facebook: Retrix Car Rental<br/>
                0979666884
              </p>
            </div>
            <div className="invoice-meta">
              <h1 style={{ fontSize: '2rem', color: 'var(--navy)', marginBottom: 8, textAlign: 'right' }}>{documentTitle}</h1>
              <table className="meta-table">
                <tbody>
                  <tr>
                    <td>Date:</td>
                    <td>{new Date().toLocaleDateString()}</td>
                  </tr>
                  <tr>
                    <td>Ref #:</td>
                    <td>{booking.id.slice(0, 8).toUpperCase()}</td>
                  </tr>
                  <tr>
                    <td>Status:</td>
                    <td style={{ fontWeight: 600, color: isQuote ? '#f59e0b' : '#10b981' }}>{booking.status}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <div className="invoice-divider" />

          {/* Customer & Booking Details */}
          <div className="invoice-details" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 32, marginBottom: 32 }}>
            <div>
              <h3 className="invoice-section-title">Bill To</h3>
              <p>
                <strong>{booking.customer?.firstName || 'Guest'} {booking.customer?.lastName || ''}</strong><br/>
                {booking.customer?.phoneNumber || 'Phone not provided'}<br/>
                Driver's License: {booking.customer?.driverLicenseNumber || 'N/A'}
              </p>
            </div>
            <div>
              <h3 className="invoice-section-title">Rental Information</h3>
              <p>
                <strong>Vehicle:</strong> {booking.car.make} {booking.car.model} ({booking.car.year})<br/>
                <strong>Dates:</strong> {new Date(booking.startDate).toLocaleDateString()} to {new Date(booking.endDate).toLocaleDateString()}<br/>
                <strong>Pickup:</strong> {booking.pickupLocation.name}<br/>
                <strong>Dropoff:</strong> {booking.dropoffLocation.name}
              </p>
            </div>
          </div>

          {/* Line Items */}
          <table className="invoice-table" style={{ width: '100%', borderCollapse: 'collapse', marginBottom: 32 }}>
            <thead>
              <tr style={{ background: 'var(--navy)', color: 'white' }}>
                <th style={{ padding: 12, textAlign: 'left' }}>Description</th>
                <th style={{ padding: 12, textAlign: 'right' }}>Days</th>
                <th style={{ padding: 12, textAlign: 'right' }}>Rate (ZMW)</th>
                <th style={{ padding: 12, textAlign: 'right' }}>Amount (ZMW)</th>
              </tr>
            </thead>
            <tbody>
              <tr style={{ borderBottom: '1px solid #e2e8f0' }}>
                <td style={{ padding: 16 }}>Vehicle Rental - {booking.car.make} {booking.car.model}</td>
                <td style={{ padding: 16, textAlign: 'right' }}>{rentalDays}</td>
                <td style={{ padding: 16, textAlign: 'right' }}>K {booking.car.dailyRateZmw.toLocaleString()}</td>
                <td style={{ padding: 16, textAlign: 'right' }}>K {baseRentalPrice.toLocaleString()}</td>
              </tr>
              {damageFees.map(f => (
                <tr key={f.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
                  <td style={{ padding: 16 }}>
                    Damage Fee - {f.transactionId ? `Ref: ${f.transactionId}` : 'Vehicle Issue'}
                  </td>
                  <td style={{ padding: 16, textAlign: 'right' }}>—</td>
                  <td style={{ padding: 16, textAlign: 'right' }}>—</td>
                  <td style={{ padding: 16, textAlign: 'right' }}>K {f.amountZmw.toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>

          {/* Totals */}
          <div className="invoice-totals" style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <div style={{ width: 320 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0' }}>
                <span>Rental Subtotal</span>
                <span>K {baseRentalPrice.toLocaleString()}</span>
              </div>
              {totalDamageFees > 0 && (
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', color: '#dc2626' }}>
                  <span>Damage Fees</span>
                  <span>K {totalDamageFees.toLocaleString()}</span>
                </div>
              )}
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0' }}>
                <span>Total Charges</span>
                <span style={{ fontWeight: 600 }}>K {totalCharges.toLocaleString()}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', color: '#10b981', borderBottom: '2px solid #e2e8f0' }}>
                <span>Payments Received</span>
                <span>- K {totalPaid.toLocaleString()}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 0', fontSize: '1.25rem', fontWeight: 700, color: balanceDue > 0 ? '#dc2626' : 'var(--navy)' }}>
                <span>Balance Due</span>
                <span>K {balanceDue.toLocaleString()}</span>
              </div>
            </div>
          </div>

          {/* Footer Notes */}
          <div className="invoice-footer" style={{ marginTop: 64, paddingTop: 32, borderTop: '1px solid #e2e8f0', color: '#64748b', fontSize: '0.875rem' }}>
            <p><strong>Terms & Conditions:</strong> Payment is due upon vehicle pickup unless otherwise specified. A security deposit may be required. Valid driver's license must be presented at pickup.</p>
            <p style={{ marginTop: 8, textAlign: 'center' }}>Thank you for choosing Retrix Car Rental!</p>
          </div>
        </div>
      </div>
    </div>
  );
}
