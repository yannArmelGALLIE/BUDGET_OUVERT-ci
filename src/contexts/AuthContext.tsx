import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import type { Session } from '@supabase/supabase-js';

interface UserRole {
  id: string;
  name: string;
  description: string | null;
}

interface AuthContextType {
  session: Session | null;
  user: { id: string; email: string; role: UserRole | null; full_name: string | null } | null;
  loading: boolean;
  signUp: (email: string, password: string, fullName: string, roleId: string) => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [session, setSession] = useState<Session | null>(null);
  const [user, setUser] = useState<AuthContextType['user']>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const initializeAuth = async () => {
      const { data } = await supabase.auth.getSession();
      setSession(data.session);

      if (data.session?.user.id) {
        const { data: userData } = await supabase
          .from('users_extended')
          .select('id, email, full_name, user_roles(id, name, description)')
          .eq('id', data.session.user.id)
          .maybeSingle();

        if (userData) {
          setUser({
            id: userData.id,
            email: userData.email,
            full_name: userData.full_name,
            role: userData.user_roles as UserRole | null,
          });
        }
      }
      setLoading(false);
    };

    initializeAuth();

    const { data: authListener } = supabase.auth.onAuthStateChange(
      async (event, newSession) => {
        setSession(newSession);

        if (event === 'SIGNED_IN' && newSession?.user.id) {
          const { data: userData } = await supabase
            .from('users_extended')
            .select('id, email, full_name, user_roles(id, name, description)')
            .eq('id', newSession.user.id)
            .maybeSingle();

          if (userData) {
            setUser({
              id: userData.id,
              email: userData.email,
              full_name: userData.full_name,
              role: userData.user_roles as UserRole | null,
            });
          }
        } else if (event === 'SIGNED_OUT') {
          setUser(null);
        }
      }
    );

    return () => authListener?.subscription.unsubscribe();
  }, []);

  const signUp = async (email: string, password: string, fullName: string, roleId: string) => {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
    });

    if (error) throw error;
    if (!data.user) throw new Error('Sign up failed');

    const { error: profileError } = await supabase
      .from('users_extended')
      .insert({
        id: data.user.id,
        email,
        full_name: fullName,
        role_id: roleId,
      });

    if (profileError) throw profileError;
  };

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) throw error;
  };

  const signOut = async () => {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ session, user, loading, signUp, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};
