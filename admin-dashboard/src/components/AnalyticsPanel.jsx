import React, { useState, useEffect } from 'react';
import { TrendingUp, DollarSign, ShoppingCart, Clock, AlertCircle } from 'lucide-react';
import { getRevenueAnalytics, getRecentActivity } from '../services/adminService';

export default function AnalyticsPanel() {
    const [revenue, setRevenue] = useState({ totalRevenue: 0, completedOrders: 0, pendingOrders: 0 });
    const [recentActivity, setRecentActivity] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchAnalytics();
    }, []);

    const fetchAnalytics = async () => {
        try {
            setLoading(true);
            const [revenueData, activityData] = await Promise.all([
                getRevenueAnalytics(),
                getRecentActivity(5)
            ]);
            setRevenue(revenueData);
            setRecentActivity(activityData);
        } catch (error) {
            console.error('Error fetching analytics:', error);
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return <div className="text-center text-gray-400">Loading analytics...</div>;
    }

    return (
        <div className="space-y-6">
            <div>
                <h2 className="text-4xl font-bold text-white mb-2">Analytics</h2>
                <p className="text-gray-400 text-lg">Platform performance and activity</p>
            </div>

            {/* Revenue Section */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg">
                    <div className="flex items-center justify-between mb-4">
                        <h3 className="text-gray-300 font-semibold">Total Revenue</h3>
                        <div className="p-3 bg-green-900/30 rounded-lg">
                            <DollarSign className="w-6 h-6 text-green-400" />
                        </div>
                    </div>
                    <p className="text-4xl font-bold text-primary mb-2">${revenue.totalRevenue.toLocaleString()}</p>
                    <p className="text-gray-400 text-sm">From {revenue.completedOrders} completed orders</p>
                </div>

                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg">
                    <div className="flex items-center justify-between mb-4">
                        <h3 className="text-gray-300 font-semibold">Completed Orders</h3>
                        <div className="p-3 bg-green-900/30 rounded-lg">
                            <ShoppingCart className="w-6 h-6 text-green-400" />
                        </div>
                    </div>
                    <p className="text-4xl font-bold text-green-400 mb-2">{revenue.completedOrders}</p>
                    <p className="text-gray-400 text-sm">Successfully processed</p>
                </div>

                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg">
                    <div className="flex items-center justify-between mb-4">
                        <h3 className="text-gray-300 font-semibold">Pending Orders</h3>
                        <div className="p-3 bg-yellow-900/30 rounded-lg">
                            <Clock className="w-6 h-6 text-yellow-400" />
                        </div>
                    </div>
                    <p className="text-4xl font-bold text-yellow-400 mb-2">{revenue.pendingOrders}</p>
                    <p className="text-gray-400 text-sm">Awaiting completion</p>
                </div>
            </div>

            {/* Recent Activity */}
            <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg">
                <h3 className="text-lg font-bold text-white mb-5 flex items-center gap-2">
                    <div className="p-2 bg-blue-900/30 rounded-lg">
                        <TrendingUp className="w-5 h-5 text-blue-400" />
                    </div>
                    Recent User Activity
                </h3>

                <div className="space-y-3">
                    {recentActivity.length > 0 ? (
                        recentActivity.map((activity, index) => (
                            <div key={index} className="bg-gray-700/30 rounded-lg p-4 border border-gray-600/30 hover:border-gray-500/50 transition">
                                <div className="flex items-start justify-between">
                                    <div className="flex-1">
                                        <p className="text-white font-semibold">{activity.displayName || activity.name || activity.email}</p>
                                        <p className="text-gray-400 text-sm mt-1">
                                            Joined as {activity.userType === 'seller' ? '🏪 Seller' : '👤 Buyer'}
                                        </p>
                                    </div>
                                    <span className={`px-3 py-1 rounded-full text-xs font-bold border ${activity.isActive !== false
                                            ? 'bg-green-900/40 text-green-300 border-green-700'
                                            : 'bg-red-900/40 text-red-300 border-red-700'
                                        }`}>
                                        {activity.isActive !== false ? 'Active' : 'Inactive'}
                                    </span>
                                </div>
                                {(activity.createdAt || activity.timestamp) && (
                                    <p className="text-gray-500 text-xs mt-2">
                                        {new Date(activity.createdAt?.seconds ? activity.createdAt.seconds * 1000 : activity.createdAt || activity.timestamp?.seconds ? activity.timestamp.seconds * 1000 : activity.timestamp).toLocaleDateString()}
                                    </p>
                                )}
                            </div>
                        ))
                    ) : (
                        <div className="text-center py-8 text-gray-400">
                            <AlertCircle className="w-8 h-8 mx-auto mb-2 opacity-50" />
                            <p>No recent activity</p>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}
