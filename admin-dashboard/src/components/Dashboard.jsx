import React, { useState, useEffect } from 'react';
import { BarChart3, Users, Package, TrendingUp, Activity, AlertCircle } from 'lucide-react';
import { getUserStats, getProductStats } from '../services/adminService';
import { collection, getDocs, query, where } from 'firebase/firestore';
import { db } from '../services/firebase';

export default function Dashboard() {
    const [userStats, setUserStats] = useState({ total: 0, active: 0, inactive: 0, sellers: 0, buyers: 0 });
    const [productStats, setProductStats] = useState({ total: 0, active: 0, inactive: 0 });
    const [auctionStats, setAuctionStats] = useState({ total: 0, active: 0, ended: 0 });
    const [sellerStats, setSellerStats] = useState({ verified: 0, unverified: 0, totalProducts: 0 });
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchStats();
    }, []);

    const fetchStats = async () => {
        try {
            setLoading(true);

            // User stats
            const users = await getUserStats();
            const usersRef = collection(db, 'users');
            const sellerQuery = query(usersRef, where('userType', '==', 'seller'));
            const buyerQuery = query(usersRef, where('userType', '==', 'buyer'));
            const sellerSnap = await getDocs(sellerQuery);
            const buyerSnap = await getDocs(buyerQuery);

            setUserStats({
                ...users,
                sellers: sellerSnap.docs.length,
                buyers: buyerSnap.docs.length
            });

            // Product stats
            const products = await getProductStats();
            const productsRef = collection(db, 'products');
            const inactiveProducts = query(productsRef, where('isActive', '==', false));
            const inactiveSnap = await getDocs(inactiveProducts);

            setProductStats({
                ...products,
                inactive: inactiveSnap.docs.length
            });

            // Auction stats
            const auctionsRef = collection(db, 'auctions');
            const auctionsSnap = await getDocs(auctionsRef);
            const now = new Date();

            let activeCount = 0;
            let endedCount = 0;

            auctionsSnap.docs.forEach(doc => {
                const endTime = doc.data().endTime?.toDate?.() || new Date(doc.data().endTime);
                if (now > endTime) {
                    endedCount++;
                } else {
                    activeCount++;
                }
            });

            setAuctionStats({
                total: auctionsSnap.docs.length,
                active: activeCount,
                ended: endedCount
            });

            // Seller verification stats
            const sellersRef = collection(db, 'sellers');
            const sellersSnap = await getDocs(sellersRef);

            let verified = 0;
            let unverified = 0;

            sellersSnap.docs.forEach(doc => {
                if (doc.data().verified) {
                    verified++;
                } else {
                    unverified++;
                }
            });

            setSellerStats({
                verified,
                unverified,
                totalProducts: products.total
            });
        } catch (error) {
            console.error('Error fetching stats:', error);
        } finally {
            setLoading(false);
        }
    };

    const StatCard = ({ icon: Icon, label, value, color, subtext }) => (
        <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 hover:border-gray-600 transition-all duration-300 hover:shadow-lg hover:shadow-gray-900/50">
            <div className="flex items-center justify-between mb-2">
                <div>
                    <p className="text-gray-400 text-xs font-semibold uppercase tracking-wide mb-2">{label}</p>
                    <p className="text-4xl font-bold text-white">{value}</p>
                    {subtext && <p className="text-gray-500 text-xs mt-2">{subtext}</p>}
                </div>
                <div className={`p-4 rounded-xl ${color} shadow-lg`}>
                    <Icon className="w-6 h-6" />
                </div>
            </div>
        </div>
    );

    if (loading) {
        return <div className="text-center text-gray-400">Loading...</div>;
    }

    return (
        <div className="space-y-8">
            <div>
                <h2 className="text-4xl font-bold text-white mb-2">Dashboard</h2>
                <p className="text-gray-400 text-lg">Welcome to GemNest Admin Panel</p>
            </div>

            {/* Main Stats */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <StatCard
                    icon={Users}
                    label="Total Users"
                    value={userStats.total}
                    color="bg-blue-900 text-blue-300"
                    subtext={`${userStats.active} active, ${userStats.inactive} inactive`}
                />
                <StatCard
                    icon={TrendingUp}
                    label="Sellers"
                    value={userStats.sellers}
                    color="bg-green-900 text-green-300"
                    subtext={`${sellerStats.verified} verified`}
                />
                <StatCard
                    icon={Package}
                    label="Total Products"
                    value={productStats.total}
                    color="bg-primary/20 text-primary"
                    subtext={`${productStats.active} active`}
                />
                <StatCard
                    icon={Activity}
                    label="Active Auctions"
                    value={auctionStats.active}
                    color="bg-purple-900 text-purple-300"
                    subtext={`${auctionStats.total} total`}
                />
            </div>

            {/* Detailed Stats */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Users Breakdown */}
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg">
                    <h3 className="text-lg font-bold text-white mb-5 flex items-center gap-2">
                        <div className="p-2 bg-blue-900/30 rounded-lg">
                            <Users className="w-5 h-5 text-blue-400" />
                        </div>
                        Users Breakdown
                    </h3>
                    <div className="space-y-3">
                        <div className="flex justify-between items-center">
                            <span className="text-gray-400">Total Users</span>
                            <span className="text-white font-bold">{userStats.total}</span>
                        </div>
                        <div className="w-full bg-gray-700 rounded-full h-2">
                            <div
                                className="bg-blue-500 h-2 rounded-full"
                                style={{ width: `${(userStats.active / userStats.total) * 100}%` }}
                            />
                        </div>
                        <div className="flex justify-between text-sm">
                            <span className="text-green-400">Active: {userStats.active}</span>
                            <span className="text-red-400">Inactive: {userStats.inactive}</span>
                        </div>
                        <div className="pt-3 border-t border-gray-700 mt-3 space-y-2">
                            <div className="flex justify-between">
                                <span className="text-gray-400 text-sm">Buyers</span>
                                <span className="text-white font-semibold">{userStats.buyers}</span>
                            </div>
                            <div className="flex justify-between">
                                <span className="text-gray-400 text-sm">Sellers</span>
                                <span className="text-white font-semibold">{userStats.sellers}</span>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Seller Verification */}
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg">
                    <h3 className="text-lg font-bold text-white mb-5 flex items-center gap-2">
                        <div className="p-2 bg-yellow-900/30 rounded-lg">
                            <AlertCircle className="w-5 h-5 text-yellow-400" />
                        </div>
                        Seller Verification
                    </h3>
                    <div className="space-y-4">
                        <div className="text-center">
                            <p className="text-4xl font-bold text-green-400">{sellerStats.verified}</p>
                            <p className="text-gray-400 text-sm">Verified Sellers</p>
                        </div>
                        <div className="w-full bg-gray-700 rounded-full h-3">
                            <div
                                className="bg-green-500 h-3 rounded-full"
                                style={{
                                    width: `${userStats.sellers > 0 ? (sellerStats.verified / userStats.sellers) * 100 : 0}%`
                                }}
                            />
                        </div>
                        <div className="text-center">
                            <p className="text-2xl font-bold text-yellow-400">{sellerStats.unverified}</p>
                            <p className="text-gray-400 text-sm">Pending Verification</p>
                        </div>
                    </div>
                </div>

                {/* Auction Activity */}
                <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
                    <h3 className="text-lg font-bold text-white mb-4 flex items-center gap-2">
                        <BarChart3 className="w-5 h-5 text-purple-400" />
                        Auction Activity
                    </h3>
                    <div className="space-y-3">
                        <div className="flex justify-between items-center">
                            <span className="text-gray-400">Total Auctions</span>
                            <span className="text-white font-bold text-lg">{auctionStats.total}</span>
                        </div>
                        <div className="grid grid-cols-2 gap-2 pt-3 border-t border-gray-700">
                            <div className="bg-gray-700/50 rounded p-3 text-center">
                                <p className="text-2xl font-bold text-green-400">{auctionStats.active}</p>
                                <p className="text-gray-400 text-xs">Active</p>
                            </div>
                            <div className="bg-gray-700/50 rounded p-3 text-center">
                                <p className="text-2xl font-bold text-gray-400">{auctionStats.ended}</p>
                                <p className="text-gray-400 text-xs">Ended</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Summary */}
            <div className="bg-gradient-to-r from-gray-800 to-gray-700 rounded-lg p-6 border border-gray-600">
                <h3 className="text-lg font-bold text-white mb-4">Platform Summary</h3>
                <div className="grid grid-cols-2 md:grid-cols-5 gap-4 text-center">
                    <div>
                        <p className="text-2xl font-bold text-primary">{userStats.total}</p>
                        <p className="text-gray-400 text-xs">Users</p>
                    </div>
                    <div>
                        <p className="text-2xl font-bold text-green-400">{productStats.total}</p>
                        <p className="text-gray-400 text-xs">Products</p>
                    </div>
                    <div>
                        <p className="text-2xl font-bold text-purple-400">{auctionStats.active}</p>
                        <p className="text-gray-400 text-xs">Live Auctions</p>
                    </div>
                    <div>
                        <p className="text-2xl font-bold text-yellow-400">{sellerStats.unverified}</p>
                        <p className="text-gray-400 text-xs">Pending Reviews</p>
                    </div>
                    <div>
                        <p className="text-2xl font-bold text-blue-400">{((userStats.active / userStats.total) * 100).toFixed(1)}%</p>
                        <p className="text-gray-400 text-xs">Active Rate</p>
                    </div>
                </div>
            </div>
        </div >
    );
}
