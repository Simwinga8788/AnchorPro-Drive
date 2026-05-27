import { useState } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard, Car, Calendar, CreditCard,
  AlertTriangle, FileText, ChevronLeft, ChevronRight, Settings, LogOut, Menu
} from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { useCurrency } from '../../contexts/CurrencyContext';
import './AdminLayout.css';

const navItems = [
  { to: '/admin',          label: 'Dashboard', icon: LayoutDashboard, exact: true },
  { to: '/admin/fleet',    label: 'Fleet',      icon: Car              },
  { to: '/admin/bookings', label: 'Bookings',   icon: Calendar         },
  { to: '/admin/payments', label: 'Payments',   icon: CreditCard       },
  { to: '/admin/damages',  label: 'Damages',    icon: AlertTriangle    },
  { to: '/admin/invoices', label: 'ZRA Invoices',icon: FileText        },
];

export default function AdminLayout() {
  const [collapsed, setCollapsed] = useState(false);
  const { signOut } = useAuth();
  const { currency, toggle } = useCurrency();
  const navigate = useNavigate();

  const handleSignOut = async () => { await signOut(); navigate('/'); };

  return (
    <div className={`admin-layout ${collapsed ? 'admin-layout--collapsed' : ''}`}>
      {/* Sidebar */}
      <aside className="admin-sidebar">
        <div className="admin-sidebar__top">
          <div className="admin-sidebar__logo">
            <Car size={20} />
            {!collapsed && <span>Prestige<em>Drive</em></span>}
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

        {!collapsed && <div className="admin-sidebar__section-label">Navigation</div>}

        <nav className="admin-sidebar__nav">
          {navItems.map(item => (
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
          <NavLink 
            to="/admin/settings" 
            className={({isActive}) => `admin-sidebar__link ${isActive ? 'admin-sidebar__link--active' : ''}`}
            title={collapsed ? 'Settings' : undefined}
          >
            <Settings size={18}/>
            {!collapsed && <span>Settings</span>}
          </NavLink>
        </nav>

        <div className="admin-sidebar__footer">
          {!collapsed && (
            <button
              id="currency-toggle-admin"
              className="currency-toggle"
              onClick={toggle}
              style={{ width: '100%', justifyContent: 'center', marginBottom: 12 }}
            >
              <span className={currency === 'ZMW' ? 'active' : ''}>ZMW</span>
              <span className="sep">|</span>
              <span className={currency === 'USD' ? 'active' : ''}>USD</span>
            </button>
          )}
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
        <div className="admin-main__inner">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
