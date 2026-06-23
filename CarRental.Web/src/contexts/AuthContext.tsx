import React, { createContext, useContext, useEffect, useState } from 'react';
import type { Session, User } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';

import { getMe, updateProfile } from '../api/client';

interface AuthContextType {
  session: Session | null;
  user: User | null;
  isAdmin: boolean;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<{ error: string | null }>;
  signUp: (email: string, password: string) => Promise<{ data: any, error: string | null }>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [session, setSession] = useState<Session | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;
    
    const initializeAuth = async (currentSession: Session | null) => {
      setSession(currentSession);
      setUser(currentSession?.user ?? null);
      
      if (currentSession?.user) {
        try {
          const profile = await getMe();
          if (mounted) setIsAdmin(profile?.isAdmin === true);

          // Flush any pending profile data saved during signup
          const pending = localStorage.getItem('pending_profile');
          if (pending) {
            try {
              const pendingData = JSON.parse(pending);
              await updateProfile(profile.id, pendingData);
            } catch (_) {}
            localStorage.removeItem('pending_profile');
          }
        } catch (e) {
          if (mounted) setIsAdmin(false);
        }
      } else {
        if (mounted) setIsAdmin(false);
      }
      
      if (mounted) setLoading(false);
    };

    supabase.auth.getSession().then(({ data: { session } }) => {
      initializeAuth(session);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      initializeAuth(session);
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    return { error: error?.message ?? null };
  };

  const signUp = async (email: string, password: string) => {
    const { data, error } = await supabase.auth.signUp({ email, password });
    // Auto-create profile on the backend for new users
    if (data?.session) {
      try { await getMe(); } catch (_) {}
    }
    return { data, error: error?.message ?? null };
  };

  const signOut = async () => {
    await supabase.auth.signOut();
  };

  return (
    <AuthContext.Provider value={{ session, user, isAdmin, loading, signIn, signUp, signOut }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
};
