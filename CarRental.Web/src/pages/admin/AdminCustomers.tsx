import { useState, useEffect } from 'react';
import { getProfiles, getBookings } from '../../api/client';
import type { Profile, Booking } from '../../types';
import { User, Calendar, CreditCard, X } from 'lucide-react';
import './Admin.css';

export default function AdminCustomers() {
  const [customers, setCustomers] = useState<Profile[]>([]);
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCustomer, setSelectedCustomer] = useState<Profile | null>(null);

  useEffect(() => {
    Promise.all([getProfiles(), getBookings()])
      .then(([p, b]) => {
        setCustomers(p);
        setBookings(b);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  const getCustomerBookings = (customerId: string) => bookings.filter(b => b.customerId === customerId);

  return (
    <div className="admin-page">
      <div className="page-header">
        <h1>Customer <span className="gold-text">Management</span></h1>
        <p>View and manage registered users and their rental history</p>
      </div>

      <div className="admin-section">
        {loading ? (
          <div className="flex-center" style={{ padding: 48 }}><div className="spinner" /></div>
        ) : customers.length === 0 ? (
          <p className="muted" style={{ padding: '24px 0' }}>No customers registered yet.</p>
        ) : (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Contact</th>
                  <th>License Status</th>
                  <th>Total Bookings</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {customers.map(c => {
                  const customerBookings = getCustomerBookings(c.id);
                  const isVerified = !!c.driverLicenseNumber;
                  return (
                    <tr key={c.id}>
                      <td>
                        <strong>{c.firstName} {c.lastName}</strong>
                      </td>
                      <td style={{ fontSize: '0.85rem', color: 'var(--text-2)' }}>
                        {c.phoneNumber || 'No phone'}
                      </td>
                      <td>
                        <span className={`badge ${isVerified ? 'badge-green' : 'badge-grey'}`}>
                          {isVerified ? 'Verified' : 'Unverified'}
                        </span>
                      </td>
                      <td>{customerBookings.length} bookings</td>
                      <td>
                        <button className="btn btn-sm" onClick={() => setSelectedCustomer(c)}>
                          View Profile
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {selectedCustomer && (
        <CustomerModal
          customer={selectedCustomer}
          bookings={getCustomerBookings(selectedCustomer.id)}
          onClose={() => setSelectedCustomer(null)}
        />
      )}
    </div>
  );
}

function CustomerModal({ customer, bookings, onClose }: { customer: Profile, bookings: Booking[], onClose: () => void }) {
  const totalSpent = bookings
    .filter(b => b.status === 'Completed' || b.status === 'Confirmed' || b.status === 'Active')
    .reduce((sum, b) => sum + (b.totalPriceZmw || 0), 0);

  return (
    <div className="modal-overlay">
      <div className="modal-box" style={{ maxWidth: 600 }}>
        <div className="modal-header">
          <h2 className="modal-title">Customer <span className="gold-text">Profile</span></h2>
          <button className="modal-close" onClick={onClose}><X size={24} /></button>
        </div>

        <div style={{ display: 'flex', gap: 24, marginTop: 24, flexWrap: 'wrap' }}>
          <div style={{ flex: '1 1 250px', display: 'flex', flexDirection: 'column', gap: 16 }}>
            <div>
              <label className="muted" style={{ fontSize: '0.8rem' }}>Full Name</label>
              <div><strong>{customer.firstName} {customer.lastName}</strong></div>
            </div>
            <div>
              <label className="muted" style={{ fontSize: '0.8rem' }}>Phone Number</label>
              <div>{customer.phoneNumber || 'Not provided'}</div>
            </div>
            <div>
              <label className="muted" style={{ fontSize: '0.8rem' }}>Address</label>
              <div>{customer.address || 'Not provided'}</div>
            </div>
            <div>
              <label className="muted" style={{ fontSize: '0.8rem' }}>Driver's License</label>
              <div>{customer.driverLicenseNumber || <span className="muted">Not provided</span>}</div>
            </div>
          </div>
          
          <div style={{ flex: '1 1 250px', background: 'var(--surface-2)', padding: 16, borderRadius: 8, display: 'flex', flexDirection: 'column', gap: 16 }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, color: 'var(--text-2)', marginBottom: 4 }}>
                <Calendar size={16} /> Total Bookings
              </div>
              <div style={{ fontSize: '1.5rem', fontFamily: 'var(--font-head)' }}>{bookings.length}</div>
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, color: 'var(--text-2)', marginBottom: 4 }}>
                <CreditCard size={16} /> Total Spent
              </div>
              <div style={{ fontSize: '1.5rem', fontFamily: 'var(--font-head)', color: 'var(--gold)' }}>
                K{totalSpent.toLocaleString()}
              </div>
            </div>
          </div>
        </div>

        <h3 style={{ marginTop: 32, marginBottom: 16 }}>Booking History</h3>
        {bookings.length === 0 ? (
          <p className="muted">No bookings yet.</p>
        ) : (
          <div style={{ maxHeight: 200, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 8 }}>
            {bookings.map(b => (
              <div key={b.id} style={{ display: 'flex', justifyContent: 'space-between', padding: 12, background: 'var(--surface-2)', borderRadius: 6 }}>
                <div>
                  <strong>{b.car?.make} {b.car?.model}</strong>
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-2)' }}>{b.startDate} to {b.endDate}</div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ color: 'var(--gold)', fontFamily: 'var(--font-head)' }}>K{b.totalPriceZmw?.toLocaleString()}</div>
                  <span className={`badge badge-grey`} style={{ fontSize: '0.7rem', padding: '2px 6px' }}>{b.status}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
