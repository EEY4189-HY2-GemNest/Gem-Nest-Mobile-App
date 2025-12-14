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
        <div className="flex h-screen bg-dark">
            {/* Sidebar */}
            <div
                className={`bg-gray-900 border-r border-gray-700 transition-all duration-300 ${sidebarOpen ? 'w-64' : 'w-20'
                    }`}
            >
                <div className="p-6 border-b border-gray-700">
                    <h1 className="text-primary font-bold text-xl">
                        {sidebarOpen ? 'GemNest' : 'GN'}
                    </h1>
                </div>

                <nav className="p-4 space-y-2">
                    {menuItems.map((item) => {
                        const Icon = item.icon;
                        return (
                            <button
                                key={item.id}
                                onClick={() => setCurrentPage(item.id)}
                                className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition ${currentPage === item.id
                                        ? 'bg-primary text-dark'
                                        : 'text-gray-300 hover:bg-gray-800'
                                    }`}
                            >
                                <Icon className="w-5 h-5" />
                                {sidebarOpen && <span>{item.label}</span>}
                            </button>
                        );
                    })}
                </nav>

                <div className="absolute bottom-6 w-full px-4">
                    <button
                        onClick={handleLogout}
                        className="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-gray-300 hover:bg-gray-800 transition"
                    >
                        <LogOut className="w-5 h-5" />
                        {sidebarOpen && <span>Logout</span>}
                    </button>
                </div>
            </div>

            {/* Main Content */}
            <div className="flex-1 flex flex-col">
                {/* Top Bar */}
                <div className="bg-gray-900 border-b border-gray-700 px-6 py-4 flex items-center justify-between">
                    <button
                        onClick={() => setSidebarOpen(!sidebarOpen)}
                        className="p-2 hover:bg-gray-800 rounded-lg"
                    >
                        {sidebarOpen ? (
                            <X className="w-5 h-5 text-gray-300" />
                        ) : (
                            <Menu className="w-5 h-5 text-gray-300" />
                        )}
                    </button>
                    <div className="flex items-center gap-4">
                        <span className="text-gray-300 text-sm">{admin?.email}</span>
                        <div className="w-10 h-10 bg-primary rounded-full flex items-center justify-center">
                            <span className="text-dark font-bold">
                                {admin?.email?.[0]?.toUpperCase()}
                            </span>
                        </div>
                    </div>
                </div>

                {/* Content Area */}
                <div className="flex-1 overflow-auto p-6">
                    {currentPage === 'dashboard' && <Dashboard />}
                    {currentPage === 'users' && <UserManagement />}
                    {currentPage === 'products' && <ProductManagement />}
                    {currentPage === 'auctions' && <AuctionManagement />}
                </div>
            </div>
        </div>
    );
}
