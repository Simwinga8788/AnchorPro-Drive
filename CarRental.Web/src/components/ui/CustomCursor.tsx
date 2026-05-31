import { useEffect, useRef, useState } from 'react';
import './CustomCursor.css';

export default function CustomCursor() {
  const dotRef = useRef<HTMLDivElement>(null);
  const ringRef = useRef<HTMLDivElement>(null);
  const [text, setText] = useState('');
  const [hovered, setHovered] = useState(false);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    // Do not show on touch devices
    if (window.matchMedia('(pointer: coarse)').matches) return;

    const move = (e: MouseEvent) => {
      if (!visible) setVisible(true);
      
      if (dotRef.current) {
        dotRef.current.style.transform = `translate3d(${e.clientX}px, ${e.clientY}px, 0)`;
      }
      if (ringRef.current) {
        ringRef.current.style.transform = `translate3d(${e.clientX}px, ${e.clientY}px, 0)`;
      }
    };

    const handleMouseOver = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      
      // Expand and show "VIEW" on images/cards
      if (target.closest('.featured__card, .car-card, .car-main-image')) {
        setHovered(true);
        setText('VIEW');
      }
      // Expand and show "DRAG" on slideshow
      else if (target.closest('.hiw-slideshow')) {
        setHovered(true);
        setText('DRAG');
      }
      // Expand with no text for links/buttons
      else if (target.closest('a, button, select, input[type="range"]')) {
        setHovered(true);
        setText('');
      }
      // Reset
      else {
        setHovered(false);
        setText('');
      }
    };

    const handleMouseLeave = () => {
      setVisible(false);
    };

    window.addEventListener('mousemove', move);
    window.addEventListener('mouseover', handleMouseOver);
    document.addEventListener('mouseleave', handleMouseLeave);

    return () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseover', handleMouseOver);
      document.removeEventListener('mouseleave', handleMouseLeave);
    };
  }, [visible]);

  // If touch device, return nothing
  if (typeof window !== 'undefined' && window.matchMedia('(pointer: coarse)').matches) {
    return null;
  }

  return (
    <>
      <div 
        ref={dotRef}
        className={`custom-cursor-dot ${hovered ? 'hovered' : ''} ${text ? 'has-text' : ''}`}
        style={{ opacity: visible ? 1 : 0 }}
      >
        {text && <span className="custom-cursor-text">{text}</span>}
      </div>
      <div 
        ref={ringRef} 
        className={`custom-cursor-ring ${hovered ? 'hovered' : ''}`} 
        style={{ opacity: visible ? 1 : 0 }}
      />
    </>
  );
}
