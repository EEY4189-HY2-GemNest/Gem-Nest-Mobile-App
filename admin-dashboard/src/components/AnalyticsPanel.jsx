import React, { useState, useEffect } from 'react';
import { TrendingUp, DollarSign, ShoppingCart, Clock, AlertCircle, Users, Zap, CheckCircle } from 'lucide-react';
import { getRevenueAnalytics, getRecentActivity } from '../services/adminService';

export default function AnalyticsPanel() {
    const [revenue, setRevenue] = useState({ totalRevenue: 0, completedOrders: 0, pendingOrders: 0 });
    const [recentActivity, setRecentActivity] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchAnalytics();
        // Refresh analytics every 30 seconds
        const interval = setInterval(fetchAnalytics, 30000);
        return () => clearInterval(interval);
    }, []);

    const fetchAnalytics = async () => {
        try {
            setLoading(true);
            const [revenueData, activityData] = await Promise.all([
                getRevenueAnalytics(),
                getRecentActivity(8)
            ]);
            setRevenue(revenueData);
            setRecentActivity(activityData);
        } catch (error) {
            console.error('Error fetching analytics:', error);
        } finally {
            setLoading(false);
        }
    };

    // Calculate additional metrics
    const totalOrders = revenue.completedOrders + revenue.pendingOrders;
    const completionRate = totalOrders > 0 ? Math.round((revenue.completedOrders / totalOrders) * 100) : 0;
    const avgOrderValue = revenue.completedOrders > 0 ? Math.round(revenue.totalRevenue / revenue.completedOrders) : 0;
    const activeUsers = recentActivity.filter(a => a.isActive !== false).length;

    if (loading) {
        return (
            <div className="flex items-center justify-center h-96">
                <div className="text-center">
                    <div className="w-12 h-12 border-4 border-gray-700 border-t-blue-400 rounded-full animate-spin mx-auto mb-4"></div>
                    <p className="text-gray-400">Loading analytics...</p>
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div>
                <h2 className="text-4xl font-bold text-white mb-2">Analytics</h2>
                <p className="text-gray-400 text-lg">Platform performance and real-time metrics</p>
            </div>

            {/* Primary Metrics */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg hover:border-green-700/50 transition-all">
                    <div className="flex items-center justify-between mb-4">
                        <h3 className="text-gray-300 font-semibold text-sm uppercase tracking-wider">Total Revenue</h3>
                        <div className="p-3 bg-green-900/30 rounded-lg">
                            <DollarSign className="w-5 h-5 text-green-400" />
                        </div>
                    </div>
                    <p className="text-3xl font-bold text-green-400 mb-2">${revenue.totalRevenue.toLocaleString()}</p>
                    <p className="text-gray-400 text-xs">From completed orders</p>
                </div>

                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg hover:border-blue-700/50 transition-all">
                    <div className="flex items-center justify-between mb-4">
                        <h3 className="text-gray-300 font-semibold text-sm uppercase tracking-wider">Completed Orders</h3>
                        <div className="p-3 bg-blue-900/30 rounded-lg">
                            <CheckCircle className="w-5 h-5 text-blue-400" />
                        </div>
                    </div>
                    <p className="text-3xl font-bold text-blue-400 mb-2">{revenue.completedOrders}</p>
                    <p className="text-gray-400 text-xs">{completionRate}% completion rate</p>
                </div>

                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg hover:border-yellow-700/50 transition-all">
                    <div className="flex items-center justify-between mb-4">
                        <h3 className="text-gray-300 font-semibold text-sm uppercase tracking-wider">Pending Orders</h3>
                        <div className="p-3 bg-yellow-900/30 rounded-lg">
                            <Clock className="w-5 h-5 text-yellow-400" />
                        </div>
                    </div>
                    <p className="text-3xl font-bold text-yellow-400 mb-2">{revenue.pendingOrders}</p>
                    <p className="text-gray-400 text-xs">In progress</p>
                </div>

                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg hover:border-purple-700/50 transition-all">
                    <div className="flex items-center justify-between mb-4">
                        <h3 className="text-gray-300 font-semibold text-sm uppercase tracking-wider">Avg Order Value</h3>
                        <div className="p-3 bg-purple-900/30 rounded-lg">
                            <Zap className="w-5 h-5 text-purple-400" />
                        </div>
                    </div>
                    <p className="text-3xl font-bold text-purple-400 mb-2">${avgOrderValue}</p>
                    <p className="text-gray-400 text-xs">Per transaction</p>
                </div>
            </div>

            {/* Secondary Metrics Row */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Performance Overview */}
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg">
                    <h3 className="text-lg font-bold text-white mb-5 flex items-center gap-2">
                        <div className="p-2 bg-cyan-900/30 rounded-lg">
                            <TrendingUp className="w-5 h-5 text-cyan-400" />
                        </div>
                        Performance Summary
                    </h3>
                    <div className="space-y-4">
                        <div>
                            <div className="flex items-center justify-between mb-2">
                                <p className="text-gray-300 text-sm">Orders Completed</p>
                                <p className="text-cyan-400 font-bold">{completionRate}%</p>
                            </div>
                            <div className="w-full bg-gray-700 rounded-full h-2">
                                <div className="bg-gradient-to-r from-cyan-500 to-cyan-400 h-2 rounded-full" style={{ width: `${completionRate}%` }}></div>
                            </div>
                        </div>
                        <div className="grid grid-cols-2 gap-4 mt-6">
                            <div className="bg-gray-700/30 rounded-lg p-3 border border-gray-600/30">
                                <p className="text-gray-400 text-xs uppercase tracking-wider mb-1">Total Orders</p>
                                <p className="text-2xl font-bold text-white">{totalOrders}</p>
                            </div>
                            <div className="bg-gray-700/30 rounded-lg p-3 border border-gray-600/30">
                                <p className="text-gray-400 text-xs uppercase tracking-wider mb-1">Active Users</p>
                                <p className="text-2xl font-bold text-white">{activeUsers}</p>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Quick Stats */}
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg">
                    <h3 className="text-lg font-bold text-white mb-5 flex items-center gap-2">
                        <div className="p-2 bg-orange-900/30 rounded-lg">
                            <Users className="w-5 h-5 text-orange-400" />
                        </div>
                        Quick Stats
                    </h3>
                    <div className="space-y-3">
                        <div className="flex items-center justify-between p-3 bg-gray-700/30 rounded-lg border border-gray-600/30">
                            <p className="text-gray-300">Revenue/Order</p>
                            <p className="text-orange-400 font-bold text-lg">${avgOrderValue}</p>
                        </div>
                        <div className="flex items-center justify-between p-3 bg-gray-700/30 rounded-lg border border-gray-600/30">
                            <p className="text-gray-300">Pending Orders</p>
                            <p className="text-yellow-400 font-bold text-lg">{revenue.pendingOrders}</p>
                        </div>
                        <div className="flex items-center justify-between p-3 bg-gray-700/30 rounded-lg border border-gray-600/30">
                            <p className="text-gray-300">Completion Rate</p>
                            <p className="text-cyan-400 font-bold text-lg">{completionRate}%</p>
                        </div>
                        <div className="flex items-center justify-between p-3 bg-gray-700/30 rounded-lg border border-gray-600/30">
                            <p className="text-gray-300">Active Users</p>
                            <p className="text-green-400 font-bold text-lg">{activeUsers}</p>
                        </div>
                    </div>
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

                <div className="space-y-2">
                    {recentActivity.length > 0 ? (
                        recentActivity.map((activity, index) => (
                            <div key={index} className="bg-gray-700/30 rounded-lg p-4 border border-gray-600/30 hover:border-gray-500/50 transition-all group">
                                <div className="flex items-center justify-between gap-4">
                                    <div className="flex-1">
                                        <div className="flex items-center gap-2 mb-1">
                                            <p className="text-white font-semibold">{activity.displayName || activity.name || activity.email}</p>
                                            <span className={`px-2 py-1 rounded text-xs font-bold ${activity.userType === 'seller'
                                                ? 'bg-purple-900/40 text-purple-300'
                                                : 'bg-blue-900/40 text-blue-300'
                                                }`}>
                                                {activity.userType === 'seller' ? '🏪 Seller' : '👤 Buyer'}
                                            </span>
                                        </div>
                                        <p className="text-gray-400 text-xs">{activity.email}</p>
                                    </div>
                                    <div className="text-right">
                                        <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-bold border ${activity.isActive !== false
                                            ? 'bg-green-900/40 text-green-300 border-green-700'
                                            : 'bg-red-900/40 text-red-300 border-red-700'
                                            }`}>
                                            {activity.isActive !== false ? '● Active' : '● Inactive'}
                                        </span>
                                    </div>
                                </div>
                                {(activity.createdAt || activity.timestamp) && (
                                    <p className="text-gray-500 text-xs mt-3 pl-4 border-l border-gray-600/30">
                                        {new Date(activity.createdAt?.seconds ? activity.createdAt.seconds * 1000 : activity.createdAt || activity.timestamp?.seconds ? activity.timestamp.seconds * 1000 : activity.timestamp).toLocaleString()}
                                    </p>
                                )}
                            </div>
                        ))
                    ) : (
                        <div className="text-center py-12 text-gray-400">
                            <AlertCircle className="w-8 h-8 mx-auto mb-3 opacity-40" />
                            <p className="text-sm">No recent activity</p>
                        </div>
                    )}
                </div>

                {recentActivity.length > 0 && (
                    <div className="mt-6 pt-6 border-t border-gray-600/30">
                        <p className="text-gray-400 text-xs text-center">Showing {recentActivity.length} most recent users</p>
                    </div>
                )}
            </div>
        </div>
    );
}