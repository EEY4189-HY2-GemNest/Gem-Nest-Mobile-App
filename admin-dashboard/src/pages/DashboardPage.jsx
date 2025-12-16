import React, { useState, useEffect } from 'react';
import { Users, Package, Gavel, LogOut, Menu, X } from 'lucide-react';
import { logoutAdmin } from '../services/adminService';
import { auth } from '../services/firebase';
import UserManagement from '../components/UserManagement';
import ProductManagement from '../components/ProductManagement';
import AuctionManagement from '../components/AuctionManagement';
import Dashboard from '../components/Dashboard';

export default function DashboardPage() {
    const [currentPage, setCurrentPage] = useState('dashboard');
    const [sidebarOpen, setSidebarOpen] = useState(true);
    const [admin, setAdmin] = useState(null);

    useEffect(() => {
        const unsubscribe = auth.onAuthStateChanged((user) => {
            if (!user) {
                window.location.href = '/login';
            } else {
                setAdmin(user);
            }
        });

        return () => unsubscribe();
    }, []);

    const handleLogout = async () => {
        try {
            await logoutAdmin();
            window.location.href = '/login';
        } catch (error) {
            console.error('Logout error:', error);
        }
    };

    const menuItems = [
        { id: 'dashboard', label: 'Dashboard', icon: Users },
        { id: 'users', label: 'Users', icon: Users },
        { id: 'products', label: 'Products', icon: Package },
        { id: 'auctions', label: 'Auctions', icon: Gavel },
    ];

    return (
        <div className="flex h-screen bg-gray-950">
            {/* Sidebar */}
            <div
                className={`bg-gradient-to-b from-gray-900 to-gray-950 border-r border-gray-800 shadow-2xl transition-all duration-300 ${sidebarOpen ? 'w-64' : 'w-20'
                    }`}
            >
                <div className="p-6 border-b border-gray-800">
                    <div className="flex items-center gap-2">
                        <div className="w-8 h-8 bg-gradient-to-br from-primary to-yellow-600 rounded-lg flex items-center justify-center">
                            <span className="text-dark font-bold text-sm">G</span>
                        </div>
                        {sidebarOpen && <h1 className="text-primary font-bold text-xl tracking-wide">GemNest</h1>}
                    </div>
                </div>

                <nav className="p-3 space-y-1 mt-2">
                    {menuItems.map((item) => {
                        const Icon = item.icon;
                        const isActive = currentPage === item.id;
                        return (
                            <button
                                key={item.id}
                                onClick={() => setCurrentPage(item.id)}
                                className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 font-medium text-sm ${isActive
                                    ? 'bg-gradient-to-r from-primary to-yellow-600 text-gray-950 shadow-lg shadow-primary/20'
                                    : 'text-gray-400 hover:text-gray-200 hover:bg-gray-800/50'
                                    }`}
                            >
                                <Icon className={`w-5 h-5 ${isActive ? '' : ''}`} />
                                {sidebarOpen && <span>{item.label}</span>}
                            </button>
                        );
                    })}
                </nav>

                <div className="absolute bottom-6 w-full px-3">
                    <button
                        onClick={handleLogout}
                        className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-gray-400 hover:text-red-400 hover:bg-red-900/10 transition-all duration-200 font-medium"
                    >
                        <LogOut className="w-5 h-5" />
                        {sidebarOpen && <span>Logout</span>}
                    </button>
                </div>
            </div>

            {/* Main Content */}
            <div className="flex-1 flex flex-col">
                {/* Top Bar */}
                <div className="bg-gradient-to-r from-gray-900 to-gray-950 border-b border-gray-800 shadow-lg px-6 py-4 flex items-center justify-between">
                    <div className="flex items-center gap-4">
                        <button
                            onClick={() => setSidebarOpen(!sidebarOpen)}
                            className="p-2 hover:bg-gray-800 rounded-lg transition-colors duration-200"
                        >
                            {sidebarOpen ? (
                                <X className="w-5 h-5 text-gray-400" />
                            ) : (
                                <Menu className="w-5 h-5 text-gray-400" />
                            )}
                        </button>
                        <div className="h-6 w-px bg-gray-700"></div>
                        <h2 className="text-lg font-semibold text-gray-200">
                            {menuItems.find(item => item.id === currentPage)?.label}
                        </h2>
                    </div>
                    <div className="flex items-center gap-4">
                        <div className="hidden md:flex flex-col items-end">
                            <span className="text-sm font-medium text-gray-200">{admin?.email}</span>
                            <span className="text-xs text-gray-500">Administrator</span>
                        </div>
                        <div className="w-10 h-10 bg-gradient-to-br from-primary to-yellow-600 rounded-lg flex items-center justify-center shadow-lg shadow-primary/20">
                            <span className="text-gray-950 font-bold text-sm">
                                {admin?.email?.[0]?.toUpperCase()}
                            </span>
                        </div>
                    </div>
                </div>

                {/* Content Area */}
                <div className="flex-1 overflow-auto p-6 bg-gray-950">
                    {currentPage === 'dashboard' && <Dashboard />}
                    {currentPage === 'users' && <UserManagement />}
                    {currentPage === 'products' && <ProductManagement />}
                    {currentPage === 'auctions' && <AuctionManagement />}
                </div>
            </div>
        </div>
    );
}
