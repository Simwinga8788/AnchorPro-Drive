import { useState, useEffect } from 'react';
import { getProfiles, getBookings, toggleAdminProfile, toggleSuspendProfile, deleteProfile, cleanupOrphans } from '../../api/client';
import type { Profile, Booking } from '../../types';
import { User, Calendar, CreditCard, X, Shield, ShieldAlert, Trash2, Search, RefreshCw } from 'lucide-react';
import './Admin.css';
import ResponsiveTable from '../../components/ResponsiveTable';

export default function AdminCustomers() {
  const [customers, setCustomers] = useState<Profile[]>([]);
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCustomer, setSelectedCustomer] = useState<Profile | null>(null);
  const [search, setSearch] = useState('');

  const load = () => {
    Promise.allSettled([getProfiles(), getBookings()])
      .then(([p, b]) => {
        const profiles = (p.status === 'fulfilled' && Array.isArray(p.value)) ? p.value : [];
        const bks = (b.status === 'fulfilled' && Array.isArray(b.value)) ? b.value : [];
        setCustomers(profiles);
        setBookings(bks);
        if (selectedCustomer) {
            const updated = profiles.find(x => x.id === selectedCustomer.id);
            if (updated) setSelectedCustomer(updated);
            else setSelectedCustomer(null);
        }
      })
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
  }, []);

  const getCustomerBookings = (customerId: string) => bookings.filter(b => b.customerId === customerId);
  const filtered = customers.filter(c =>
    `${c.firstName} ${c.lastName} ${c.email} ${c.phoneNumber}`.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="admin-page">
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <h1>Customer <span className="gold-text">Management</span></h1>
          <p>View and manage registered users and their rental history</p>
        </div>
        <button 
          className="btn btn-outline btn-sm" 
          onClick={() => {
            if (confirm("This will permanently remove any authentication accounts that no longer have an associated profile. Proceed?")) {
              cleanupOrphans().then(res => alert(`Cleaned up ${res.deleted} orphaned accounts.`)).catch(e => alert("Error: " + e.message));
            }
          }}
        >
          <RefreshCw size={14} /> Sync Auth
        </button>
      </div>

      <div className="admin-section">
        {/* Search toolbar */}
        <div className="admin-toolbar">
          <div className="admin-search-wrap">
            <Search size={15} />
            <input
              className="admin-search"
              placeholder="Search by name, email or phone…"
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
          </div>
          <span style={{ fontSize: '0.78rem', color: 'var(--text-3)', whiteSpace: 'nowrap' }}>
            {filtered.length} of {customers.length} customers
          </span>
        </div>

        {loading ? (
          <div className="flex-center" style={{ padding: 48 }}><div className="spinner" /></div>
        ) : filtered.length === 0 ? (
          <div className="admin-empty">
            <User size={40} />
            <p>{search ? 'No customers match your search.' : 'No customers registered yet.'}</p>
          </div>
        ) : (
          <>
            <div className="table-wrap hide-mobile">
              <ResponsiveTable>
<table className="data-table">
                <thead>
                  <tr>
                    <th>Customer</th>
                    <th>Phone</th>
                    <th className="hide-mobile">Joined</th>
                    <th>Status</th>
                    <th className="hide-mobile">Bookings</th>
                    <th style={{ textAlign: 'right' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map(c => {
                    const customerBookings = getCustomerBookings(c.id);
                    const initials = `${c.firstName?.[0] ?? ''}${c.lastName?.[0] ?? ''}`.toUpperCase() || '?';
                    const joined = c.createdAt ? new Date(c.createdAt).toLocaleDateString('en-GB', { day:'2-digit', month:'short', year:'numeric' }) : '—';
                    return (
                      <tr key={c.id}>
                        <td>
                          <div className="row-name-cell">
                            <div className="row-avatar">{initials}</div>
                            <div>
                              <strong style={{ display:'block', fontSize:'0.9rem' }}>{c.firstName} {c.lastName}</strong>
                              <span style={{ fontSize:'0.78rem', color:'var(--text-3)' }}>{c.email || '—'}</span>
                            </div>
                          </div>
                        </td>
                        <td style={{ fontSize: '0.875rem' }}>{c.phoneNumber || <span className="muted">—</span>}</td>
                        <td className="hide-mobile" style={{ fontSize: '0.82rem', color: 'var(--text-3)' }}>{joined}</td>
                        <td>
                          <span className={`badge ${c.isSuspended ? 'badge-red' : c.isAdmin ? 'badge-gold' : 'badge-green'}`}>
                            {c.isSuspended ? 'Suspended' : c.isAdmin ? 'Admin' : 'Active'}
                          </span>
                        </td>
                        <td className="hide-mobile" style={{ fontSize: '0.875rem' }}>{customerBookings.length}</td>
                        <td>
                          <div className="action-btn-group" style={{ justifyContent: 'flex-end' }}>
                            <button className="btn-icon btn-icon--blue" title="View Profile" onClick={() => setSelectedCustomer(c)}><User size={15} /></button>
                            <button className="btn-icon btn-icon--gold" title={c.isAdmin ? 'Revoke Admin' : 'Make Admin'} onClick={async () => { await toggleAdminProfile(c.id); load(); }}><Shield size={15} /></button>
                            <button className="btn-icon btn-icon--red" title={c.isSuspended ? 'Unsuspend' : 'Suspend'} onClick={async () => { await toggleSuspendProfile(c.id); load(); }}><ShieldAlert size={15} /></button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
</ResponsiveTable>
            </div>

            <div className="mobile-card-list">
              {customers.map(c => {
                const customerBookings = getCustomerBookings(c.id);
                return (
                  <div key={c.id} className="mobile-data-card">
                    <div className="mobile-data-card__header">
                      <div className="mobile-data-card__title">{c.firstName} {c.lastName}</div>
                      <span className={`badge ${c.isSuspended ? 'badge-red' : c.isAdmin ? 'badge-gold' : 'badge-green'}`}>
                        {c.isSuspended ? 'Suspended' : c.isAdmin ? 'Admin' : 'Active'}
                      </span>
                    </div>
                    
                    <div className="mobile-data-card__body">
                      <div className="mobile-data-card__row">
                        <span className="mobile-data-card__label">Phone</span>
                        <span className="mobile-data-card__value">{c.phoneNumber || 'Not provided'}</span>
                      </div>
                      <div className="mobile-data-card__row">
                        <span className="mobile-data-card__label">Email</span>
                        <span className="mobile-data-card__value" style={{ fontSize: '0.8rem' }}>{c.email || 'Not provided'}</span>
                      </div>
                      <div className="mobile-data-card__row">
                        <span className="mobile-data-card__label">Bookings</span>
                        <span className="mobile-data-card__value">{customerBookings.length} bookings</span>
                      </div>
                    </div>

                    <div className="mobile-data-card__footer">
                      <span style={{ fontSize: '0.75rem', color: 'var(--text-3)' }}>ID: {c.id.slice(0, 8).toUpperCase()}</span>
                      <button className="btn btn-ghost btn-sm" onClick={() => setSelectedCustomer(c)} style={{ padding: '6px 12px' }}>
                        View Profile
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </>
        )}
      </div>

      {selectedCustomer && (
        <CustomerModal
          customer={selectedCustomer}
          bookings={getCustomerBookings(selectedCustomer.id)}
          onClose={() => setSelectedCustomer(null)}
          onUpdate={load}
        />
      )}
    </div>
  );
}

function CustomerModal({ customer, bookings, onClose, onUpdate }: { customer: Profile, bookings: Booking[], onClose: () => void, onUpdate: () => void }) {
  const totalSpent = bookings
    .filter(b => b.status === 'Completed' || b.status === 'Confirmed' || b.status === 'Active')
    .reduce((sum, b) => sum + (b.totalPriceZmw || 0), 0);
  const initials = `${customer.firstName?.[0] ?? ''}${customer.lastName?.[0] ?? ''}`.toUpperCase() || '?';
  const STATUS_CLASS: Record<string, string> = { Confirmed:'badge-gold', Active:'badge-blue', Completed:'badge-green', Cancelled:'badge-red', Pending:'badge-grey' };

  return (
    <div className="modal-overlay">
      <div className="modal-box" style={{ maxWidth: 620, padding: 0, overflow: 'hidden' }}>
        {/* Gradient header */}
        <div style={{ background: 'var(--brand-grad)', padding: '28px 28px 24px', display: 'flex', alignItems: 'center', gap: 16 }}>
          <div style={{ width: 56, height: 56, borderRadius: '50%', background: 'rgba(255,255,255,0.2)', border: '3px solid rgba(255,255,255,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'var(--font-head)', fontSize: '1.3rem', fontWeight: 700, color: '#fff', flexShrink: 0 }}>
            {initials}
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: 'var(--font-head)', fontSize: '1.15rem', fontWeight: 700, color: '#fff' }}>{customer.firstName} {customer.lastName}</div>
            <div style={{ fontSize: '0.8rem', color: 'rgba(255,255,255,0.75)', marginTop: 2 }}>{customer.email}</div>
            <span className={`badge ${customer.isSuspended ? 'badge-red' : customer.isAdmin ? 'badge-gold' : 'badge-green'}`} style={{ marginTop: 8, display: 'inline-flex' }}>
              {customer.isSuspended ? 'Suspended' : customer.isAdmin ? 'Admin' : 'Active'}
            </span>
          </div>
          <button className="modal-close" onClick={onClose} style={{ color: 'rgba(255,255,255,0.8)', alignSelf: 'flex-start' }}><X size={22} /></button>
        </div>

        <div style={{ padding: '24px 28px' }}>
          {/* Stats row */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 24 }}>
            <div style={{ background: 'var(--bg-2)', border: '1px solid var(--border)', borderRadius: 10, padding: '14px 16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--text-3)', fontSize: '0.72rem', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 6 }}><Calendar size={13} /> Total Bookings</div>
              <div style={{ fontFamily: 'var(--font-head)', fontSize: '1.6rem', fontWeight: 800, color: 'var(--text-1)' }}>{bookings.length}</div>
            </div>
            <div style={{ background: 'var(--bg-2)', border: '1px solid var(--border)', borderRadius: 10, padding: '14px 16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--text-3)', fontSize: '0.72rem', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 6 }}><CreditCard size={13} /> Total Spent</div>
              <div style={{ fontFamily: 'var(--font-head)', fontSize: '1.6rem', fontWeight: 800, color: 'var(--blue)' }}>K{totalSpent.toLocaleString()}</div>
            </div>
          </div>

          {/* Detail rows */}
          <div style={{ border: '1px solid var(--border)', borderRadius: 10, overflow: 'hidden', marginBottom: 20 }}>
            {[
              { label: 'Phone Number', value: customer.phoneNumber || '—' },
              { label: 'Date of Birth', value: customer.dateOfBirth ? new Date(customer.dateOfBirth).toLocaleDateString('en-GB') : '—' },
              { label: "Driver's License", value: customer.driverLicenseNumber || '—' },
              { label: 'Address', value: customer.address || '—' },
              { label: 'Member Since', value: customer.createdAt ? new Date(customer.createdAt).toLocaleDateString('en-GB', { day:'2-digit', month:'short', year:'numeric' }) : '—' },
            ].map((row, i) => (
              <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '11px 16px', borderBottom: i < 4 ? '1px solid var(--border)' : 'none', gap: 12 }}>
                <span style={{ fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--text-3)' }}>{row.label}</span>
                <span style={{ fontSize: '0.875rem', color: 'var(--text-1)', fontWeight: 500, textAlign: 'right' }}>{row.value}</span>
              </div>
            ))}
          </div>

          {/* Actions */}
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', paddingTop: 4 }}>
            <button className="btn btn-outline btn-sm" onClick={async () => { await toggleAdminProfile(customer.id); onUpdate(); }}>
              <Shield size={13}/> {customer.isAdmin ? 'Revoke Admin' : 'Make Admin'}
            </button>
            <button className={`btn btn-sm ${customer.isSuspended ? 'btn-gold' : 'btn-outline'}`} onClick={async () => { await toggleSuspendProfile(customer.id); onUpdate(); }}>
              <ShieldAlert size={13}/> {customer.isSuspended ? 'Unsuspend' : 'Suspend'}
            </button>
            <button className="btn btn-sm btn-danger" style={{ marginLeft: 'auto' }} onClick={async () => {
              if (confirm('Delete this user and ALL their history? This cannot be undone.')) {
                await deleteProfile(customer.id); onClose(); onUpdate();
              }
            }}>
              <Trash2 size={13}/> Delete
            </button>
          </div>

          {/* Booking history */}
          {bookings.length > 0 && (
            <>
              <div style={{ fontSize: '0.7rem', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.12em', color: 'var(--text-3)', margin: '24px 0 12px', display: 'flex', alignItems: 'center', gap: 8 }}>
                <Calendar size={13} /> Booking History
              </div>
              <div style={{ maxHeight: 200, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 8 }}>
                {bookings.map(b => (
                  <div key={b.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 14px', background: 'var(--bg-2)', borderRadius: 8, border: '1px solid var(--border)' }}>
                    <div>
                      <strong style={{ fontSize: '0.875rem', color: 'var(--text-1)' }}>{b.car?.make} {b.car?.model}</strong>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-3)', marginTop: 2 }}>
                        {b.startDate ? new Date(b.startDate).toLocaleDateString('en-GB') : '—'} → {b.endDate ? new Date(b.endDate).toLocaleDateString('en-GB') : '—'}
                      </div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontFamily: 'var(--font-head)', fontWeight: 700, color: 'var(--blue)', fontSize: '0.9rem' }}>K{(b.totalPriceZmw || 0).toLocaleString()}</div>
                      <span className={`badge ${STATUS_CLASS[b.status] ?? 'badge-grey'}`} style={{ marginTop: 4 }}>{b.status}</span>
                    </div>
                  </div>
                ))}
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

