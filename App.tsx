import React, { useState, useEffect } from 'react';
import { Toaster } from 'react-hot-toast';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { PatientDashboard } from './components/PatientDashboard';
import { DoctorDashboard } from './components/DoctorDashboard';
import { LandingPage } from './components/landing/LandingPage';
import { AuthModal } from './components/auth/AuthModal';
import { DoctorAuthModal } from './components/auth/DoctorAuthModal';
import { Modal, AuthMode } from './types';
import { useAuth } from './hooks/useAuth';

function App() {
  const { user, loading, signOut } = useAuth();
  const [activeModal, setActiveModal] = useState<Modal>(null);
  const [authMode, setAuthMode] = useState<AuthMode>('signin');

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-50">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <Router>
      <Routes>
        <Route path="/doctor-dashboard" element={<DoctorDashboard doctor={{ id: 'DOC001', full_name: 'Dr. James Miller', specialization: 'Cardiologist', years_experience: 15, contact_email: 'jamesmiller@medic.com', contact_phone: '+1-555-0123' }} onSignOut={() => {}} />} />
        <Route path="/" element={
          user ? (
            <>
              <Toaster position="top-right" />
              <PatientDashboard user={user} onSignOut={signOut} />
            </>
          ) : (
            <>
              <Toaster position="top-right" />
              <LandingPage onAuthModalOpen={(mode) => {
                setAuthMode(mode);
                setActiveModal(mode === 'doctor' ? 'doctorAuth' : 'auth');
              }} />
              
              {activeModal === 'auth' && (
                <AuthModal
                  mode={authMode}
                  onClose={() => setActiveModal(null)}
                  onModeSwitch={setAuthMode}
                />
              )}

              {activeModal === 'doctorAuth' && (
                <DoctorAuthModal
                  onClose={() => setActiveModal(null)}
                />
              )}
            </>
          )
        } />
      </Routes>
    </Router>
  );
}

export default App;