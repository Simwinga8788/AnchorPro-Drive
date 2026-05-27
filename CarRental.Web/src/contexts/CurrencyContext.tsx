import React, { createContext, useContext, useState } from 'react';
import type { Currency } from '../types';

interface CurrencyContextType {
  currency: Currency;
  toggle: () => void;
  format: (zmw: number, usd?: number) => string;
}

const CurrencyContext = createContext<CurrencyContextType | null>(null);

export const CurrencyProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [currency, setCurrency] = useState<Currency>('ZMW');

  const toggle = () => setCurrency(c => (c === 'ZMW' ? 'USD' : 'ZMW'));

  const format = (zmw: number, usd?: number): string => {
    if (currency === 'USD' && usd != null) {
      return `$${usd.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    }
    return `K${zmw.toLocaleString('en-ZM', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  };

  return (
    <CurrencyContext.Provider value={{ currency, toggle, format }}>
      {children}
    </CurrencyContext.Provider>
  );
};

export const useCurrency = () => {
  const ctx = useContext(CurrencyContext);
  if (!ctx) throw new Error('useCurrency must be used within CurrencyProvider');
  return ctx;
};
