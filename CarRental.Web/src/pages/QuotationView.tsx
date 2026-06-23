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
      margin:       [0.4, 0.4, 0.4, 0.4],
      filename:     `${documentTitle}_${booking.id.slice(0, 8).toUpperCase()}.pdf`,
      image:        { type: 'jpeg', quality: 0.99 },
      html2canvas:  { 
        scale: 2,
        useCORS: true,
        windowWidth: 900,   // ← forces desktop layout — no mobile CSS
        windowHeight: 1200,
        logging: false,
      },
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
  const damageFees = booking.payments?.filter(p => p.type === 'Penalty') || [];
  const totalDamageFees = damageFees.reduce((sum, p) => sum + p.amountZmw, 0);
  const totalCharges = baseRentalPrice + totalDamageFees;
  const completedPayments = booking.payments?.filter(p => p.status === 'Completed') || [];
  const totalPaid = completedPayments.reduce((sum, p) => sum + p.amountZmw, 0);
  const balanceDue = totalCharges - totalPaid;

  return (
    <div className="quotation-page" style={{ paddingTop: 80, paddingBottom: 80, minHeight: '100vh', background: '#f5f7fa' }}>
      <div className="container">
        <div className="quotation-actions no-print" style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 24, gap: 16, flexWrap: 'wrap' }}>
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
              <div className="brand-container">
                <img src="/logo.png" alt="Retrix Car Rental" className="logo-img" />
              </div>
              <p className="brand-info">
                Kitwe, Zambia<br/>
                <a href="mailto:retrixrentals@gmail.com" className="brand-email">retrixrentals@gmail.com</a><br/>
                Facebook: Retrix Car Rental<br/>
                0962431222
              </p>
            </div>
            <div className="invoice-meta">
              <h1 className="invoice-title">{documentTitle}</h1>
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
          <div className="invoice-details">
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
                <strong>Vehicle:</strong> {booking.car.make} {booking.car.model}<br/>
                <strong>Dates:</strong> {new Date(booking.startDate).toLocaleDateString()} to {new Date(booking.endDate).toLocaleDateString()}<br/>
                <strong>Pickup:</strong> {booking.pickupLocation.name}<br/>
                <strong>Dropoff:</strong> {booking.dropoffLocation.name}
              </p>
            </div>
          </div>

          <div className="table-responsive">
            <table className="invoice-table">
              <thead>
                <tr>
                  <th className="align-left">Description</th>
                  <th className="align-right">Days</th>
                  <th className="align-right">Rate (ZMW)</th>
                  <th className="align-right">Amount (ZMW)</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td className="align-left" data-label="Description">Vehicle Rental - {booking.car.make} {booking.car.model}</td>
                  <td className="align-right" data-label="Days">{rentalDays}</td>
                  <td className="align-right" data-label="Rate (ZMW)">K {booking.car.dailyRateZmw.toLocaleString()}</td>
                  <td className="align-right" data-label="Amount (ZMW)">K {baseRentalPrice.toLocaleString()}</td>
                </tr>
                {damageFees.map(f => (
                  <tr key={f.id}>
                    <td className="align-left" data-label="Description">
                      Damage Fee - {f.transactionId ? `Ref: ${f.transactionId}` : 'Vehicle Issue'}
                    </td>
                    <td className="align-right" data-label="Days">—</td>
                    <td className="align-right" data-label="Rate (ZMW)">—</td>
                    <td className="align-right" data-label="Amount (ZMW)">K {f.amountZmw.toLocaleString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Totals */}
          <div className="invoice-totals totals-container">
            <div className="totals-box">
              <div className="totals-row">
                <span>Rental Subtotal</span>
                <span>K {baseRentalPrice.toLocaleString()}</span>
              </div>
              {totalDamageFees > 0 && (
                <div className="totals-row danger">
                  <span>Damage Fees</span>
                  <span>K {totalDamageFees.toLocaleString()}</span>
                </div>
              )}
              <div className="totals-row">
                <span>Total Charges</span>
                <span style={{ fontWeight: 600 }}>K {totalCharges.toLocaleString()}</span>
              </div>
              <div className="totals-row success">
                <span>Payments Received</span>
                <span>- K {totalPaid.toLocaleString()}</span>
              </div>
              <div className="totals-row final" style={{ color: balanceDue > 0 ? '#dc2626' : 'var(--navy)' }}>
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
