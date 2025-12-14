import React, { useState } from 'react';
import { loginAdmin } from '../services/adminService';
import { LogIn, AlertCircle } from 'lucide-react';

export default function LoginPage() {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleLogin = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            await loginAdmin(email, password);
            window.location.href = '/dashboard';
        } catch (err) {
            setError(err.message || 'Login failed');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-gradient-to-br from-dark to-gray-900 flex items-center justify-center p-4">
            <div className="w-full max-w-md">
                <div className="bg-gray-800 rounded-lg shadow-xl p-8">
                    <h1 className="text-3xl font-bold text-primary mb-2">GemNest</h1>
                    <p className="text-gray-400 mb-8">Admin Dashboard</p>

                    {error && (
                        <div className="bg-red-900/20 border border-red-500 rounded-lg p-3 mb-6 flex items-gap-2">
                            <AlertCircle className="w-5 h-5 text-red-500 flex-shrink-0" />
                            <p className="text-red-200 text-sm">{error}</p>
                        </div>
                    )}

                    <form onSubmit={handleLogin} className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-300 mb-2">
                                Email Address
                            </label>
                            <input
                                type="email"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:border-primary"
                                placeholder="admin@gemnest.com"
                                required
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-gray-300 mb-2">
                                Password
                            </label>
                            <input
                                type="password"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:border-primary"
                                placeholder="••••••••"
                                required
                            />
                        </div>

                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full bg-primary hover:bg-yellow-500 text-dark font-bold py-2 px-4 rounded-lg transition disabled:opacity-50 flex items-center justify-center gap-2"
                        >
                            <LogIn className="w-5 h-5" />
                            {loading ? 'Logging in...' : 'Login'}
                        </button>
                    </form>

                    <p className="text-gray-400 text-xs mt-8 pt-8 border-t border-gray-700">
                        Use your admin credentials to access the dashboard
                    </p>
                </div>
            </div>
        </div>
    );
}
