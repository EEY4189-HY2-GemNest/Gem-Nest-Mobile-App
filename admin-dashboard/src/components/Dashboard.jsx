import React, { useState, useEffect } from 'react';
import { BarChart3, Users, Package, TrendingUp } from 'lucide-react';
import { getUserStats, getProductStats } from '../services/adminService';

export default function Dashboard() {
    const [userStats, setUserStats] = useState({ total: 0, active: 0, inactive: 0 });
    const [productStats, setProductStats] = useState({ total: 0, active: 0 });
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchStats = async () => {
            try {
                const [users, products] = await Promise.all([
                    getUserStats(),
                    getProductStats()
                ]);
                setUserStats(users);
                setProductStats(products);
            } catch (error) {
                console.error('Error fetching stats:', error);
            } finally {
                setLoading(false);
            }
        };

        fetchStats();
    }, []);

    const StatCard = ({ icon: Icon, label, value, color }) => (
        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
            <div className="flex items-center justify-between">
                <div>
                    <p className="text-gray-400 text-sm mb-2">{label}</p>
                    <p className="text-3xl font-bold text-white">{value}</p>
                </div>
                <div className={`p-3 rounded-lg ${color}`}>
                    <Icon className="w-8 h-8" />
                </div>
            </div>
        </div>
    );

    if (loading) {
        return <div className="text-center text-gray-400">Loading...</div>;
    }

    return (
        <div className="space-y-6">
            <div>
                <h2 className="text-3xl font-bold text-white mb-2">Dashboard</h2>
                <p className="text-gray-400">Welcome to GemNest Admin Panel</p>
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <StatCard
                    icon={Users}
                    label="Total Users"
                    value={userStats.total}
                    color="bg-blue-900 text-blue-300"
                />
                <StatCard
                    icon={TrendingUp}
                    label="Active Users"
                    value={userStats.active}
                    color="bg-green-900 text-green-300"
                />
                <StatCard
                    icon={Package}
                    label="Total Products"
                    value={productStats.total}
                    color="bg-primary/20 text-primary"
                />
                <StatCard
                    icon={Package}
                    label="Active Listings"
                    value={productStats.active}
                    color="bg-purple-900 text-purple-300"
                />
            </div>

            {/* Info Cards */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
                    <h3 className="text-lg font-bold text-white mb-4">Quick Stats</h3>
                    <ul className="space-y-3">
                        <li className="flex justify-between">
                            <span className="text-gray-400">Inactive Users</span>
                            <span className="text-white font-bold">{userStats.inactive}</span>
                        </li>
                        <li className="flex justify-between border-t border-gray-700 pt-3">
                            <span className="text-gray-400">User Activation Rate</span>
                            <span className="text-white font-bold">
                                {userStats.total > 0 ? ((userStats.active / userStats.total) * 100).toFixed(1) : 0}%
                            </span>
                        </li>
                        <li className="flex justify-between border-t border-gray-700 pt-3">
                            <span className="text-gray-400">Active Products</span>
                            <span className="text-white font-bold">{productStats.active}</span>
                        </li>
                    </ul>
                </div>

                <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
                    <h3 className="text-lg font-bold text-white mb-4">Quick Actions</h3>
                    <p className="text-gray-400 mb-4">Navigate using the sidebar menu to:</p>
                    <ul className="space-y-2 text-sm text-gray-300">
                        <li>✓ Manage user accounts (activate/deactivate)</li>
                        <li>✓ View and remove products</li>
                        <li>✓ Monitor active auctions</li>
                        <li>✓ Review user profiles</li>
                    </ul>
                </div>
            </div>
        </div>
    );
}
