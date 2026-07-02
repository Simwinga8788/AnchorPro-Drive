import { useState, useEffect } from 'react';
import { Outlet, NavLink, useNavigate, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, Car, Calendar, CreditCard, MapPin,
  AlertTriangle, FileText, ChevronLeft, ChevronRight, Settings, LogOut, Menu, Bell, Check, PieChart, Users
} from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { getAdminNotifications, getAdminUnreadCount, markNotificationRead, markAllNotificationsRead, getMe } from '../../api/client';
import type { Profile } from '../../types';
import './AdminLayout.css';

const sidebarGroups = [
  {
    title: 'RENTAL OPERATIONS',
    items: [
      { to: '/admin',          label: 'Dashboard', icon: LayoutDashboard, exact: true },
      { to: '/admin/fleet',    label: 'Fleet',      icon: Car              },
      { to: '/admin/bookings', label: 'Bookings',   icon: Calendar         },
    ]
  },
  {
    title: 'CUSTOMER RELATIONS',
    items: [
      { to: '/admin/customers',label: 'Customers',  icon: Users            },
      { to: '/admin/locations',label: 'Locations',  icon: MapPin           },
    ]
  },
  {
    title: 'FINANCIALS',
    items: [
      { to: '/admin/payments', label: 'Payments',   icon: CreditCard       },
      { to: '/admin/damages',  label: 'Damages',    icon: AlertTriangle    },
    ]
  },
  {
    title: 'CONFIGURATION',
    items: [
      { to: '/admin/settings', label: 'Settings',   icon: Settings         },
    ]
  }
];

export default function AdminLayout() {
  const [collapsed, setCollapsed] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [notifications, setNotifications] = useState<any[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [showNotifications, setShowNotifications] = useState(false);
  const [profile, setProfile] = useState<Profile | null>(null);
  const { signOut } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    getMe().then(setProfile).catch(() => {});
  }, []);

  useEffect(() => {
    setMobileMenuOpen(false);
  }, [location.pathname]);

  // Polling for notifications (every 30s)
  const fetchNotifications = async () => {
    try {
      const [nots, count] = await Promise.all([getAdminNotifications(), getAdminUnreadCount()]);
      setNotifications(Array.isArray(nots) ? nots : []);
      setUnreadCount(count?.count || 0);
    } catch (e) { console.error('Failed to fetch notifications'); }
  };
  
  useEffect(() => {
    fetchNotifications();
    const interval = setInterval(fetchNotifications, 30000);
    return () => clearInterval(interval);
  }, []);

  const handleSignOut = async () => { await signOut(); navigate('/'); };
  const handleMarkAsRead = async (id: string) => {
    await markNotificationRead(id);
    await fetchNotifications();
  };
  const handleMarkAllAsRead = async () => {
    await markAllNotificationsRead();
    await fetchNotifications();
  };

  return (
    <div className={`admin-layout ${collapsed ? 'admin-layout--collapsed' : ''} ${mobileMenuOpen ? 'admin-layout--mobile-open' : ''}`}>
      {/* Mobile Sidebar Backdrop */}
      {mobileMenuOpen && (
        <div className="admin-sidebar-backdrop" onClick={() => setMobileMenuOpen(false)} />
      )}

      {/* Sidebar */}
      <aside className={`admin-sidebar ${mobileMenuOpen ? 'admin-sidebar--mobile-open' : ''}`}>
        <div className="admin-sidebar__top">
          <div className="admin-sidebar__logo">
            <img src="/logo.png" alt="Retrix" style={{ height: '48px', objectFit: 'contain', maxWidth: collapsed ? '40px' : '100%' }} />
          </div>
          <button
            className="admin-sidebar__collapse"
            onClick={() => setCollapsed(c => !c)}
            title={collapsed ? 'Expand' : 'Collapse'}
            id="sidebar-collapse-btn"
          >
            {collapsed ? <ChevronRight size={16}/> : <ChevronLeft size={16}/>}
          </button>
        </div>

        <nav className="admin-sidebar__nav">
          {sidebarGroups.map((group, gIdx) => (
            <div key={gIdx} className="admin-sidebar__group">
              {!collapsed && (
                <div className="admin-sidebar__section-label">{group.title}</div>
              )}
              <div className="admin-sidebar__group-items">
                {group.items.map(item => (
                  <NavLink
                    key={item.to}
                    to={item.to}
                    end={item.exact}
                    className={({ isActive }) =>
                      `admin-sidebar__link ${isActive ? 'admin-sidebar__link--active' : ''}`
                    }
                    title={collapsed ? item.label : undefined}
                  >
                    <item.icon size={18} />
                    {!collapsed && <span>{item.label}</span>}
                  </NavLink>
                ))}
              </div>
            </div>
          ))}
        </nav>

        <div className="admin-sidebar__footer">
          <button
            className="admin-sidebar__link admin-sidebar__signout"
            onClick={handleSignOut}
            id="admin-sign-out-btn"
          >
            <LogOut size={18} />
            {!collapsed && <span>Sign Out</span>}
          </button>
        </div>
      </aside>

      {/* Main */}
      <main className="admin-main">
        {/* Admin Header with search, notifications, and profile dropdown */}
        <header className="admin-header">
          <button 
            className="admin-header__hamburger" 
            onClick={() => setMobileMenuOpen(true)}
            title="Open Menu"
            id="admin-hamburger-btn"
          >
            <Menu size={20} />
          </button>
          
          <div className="admin-header__search">
            <input 
              type="text" 
              placeholder="Search bookings, customers, vehicles..." 
              className="header-search-input"
            />
          </div>

          <div className="admin-header__spacer" />

          <div className="admin-header__actions">
            <div className="notification-wrapper">
              <button 
                className="notification-btn" 
                onClick={() => setShowNotifications(!showNotifications)}
              >
                <Bell size={20} />
                {unreadCount > 0 && <span className="notification-badge">{unreadCount}</span>}
              </button>
              
              {showNotifications && (
                <div className="notification-dropdown">
                  <div className="notification-dropdown__header">
                    <h4>Notifications</h4>
                    {unreadCount > 0 && (
                      <button onClick={handleMarkAllAsRead} className="text-btn">Mark all read</button>
                    )}
                  </div>
                  <div className="notification-dropdown__list">
                    {notifications.length === 0 ? (
                      <div className="notification-empty">No notifications</div>
                    ) : (
                      notifications.map(n => (
                        <div key={n.id} className={`notification-item ${!n.isRead ? 'unread' : ''}`}>
                          <div className="notification-item__content">
                            <strong>{n.title}</strong>
                            <p>{n.message}</p>
                            <span className="time">{new Date(n.createdAt).toLocaleTimeString()}</span>
                          </div>
                          {!n.isRead && (
                            <button title="Mark as read" onClick={() => handleMarkAsRead(n.id)}>
                              <Check size={16} />
                            </button>
                          )}
                        </div>
                      ))
                    )}
                  </div>
                </div>
              )}
            </div>

            {/* Profile Dropdown */}
            <div className="header-profile">
              <div className="header-profile__avatar">
                {profile?.firstName?.[0]?.toUpperCase() || 'A'}
              </div>
              <span className="header-profile__name hide-mobile">
                {profile ? `${profile.firstName} ${profile.lastName}` : 'Admin'}
              </span>
            </div>
          </div>
        </header>

        <div className="admin-main__inner">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
