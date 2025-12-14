import './App.css'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { auth } from './services/firebase'
import { useState, useEffect } from 'react'
import LoginPage from './pages/LoginPage'
import DashboardPage from './pages/DashboardPage'

function ProtectedRoute({ children }) {
    const [isAuthenticated, setIsAuthenticated] = useState(null)

    useEffect(() => {
        const unsubscribe = auth.onAuthStateChanged((user) => {
            setIsAuthenticated(!!user)
        })
        return () => unsubscribe()
    }, [])

    if (isAuthenticated === null) {
        return <div className="flex items-center justify-center h-screen bg-dark text-white">Loading...</div>
    }

    return isAuthenticated ? children : <Navigate to="/login" />
}

function App() {
    return (
        <BrowserRouter>
            <Routes>
                <Route path="/login" element={<LoginPage />} />
                <Route
                    path="/dashboard"
                    element={
                        <ProtectedRoute>
                            <DashboardPage />
                        </ProtectedRoute>
                    }
                />
                <Route path="/" element={<Navigate to="/dashboard" />} />
            </Routes>
        </BrowserRouter>
    )
}

export default App
