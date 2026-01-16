import React, { useState, useEffect } from 'react';
import { getAllAuctions } from '../services/adminService';
import { AlertCircle, Clock, DollarSign, CheckCircle, XCircle } from 'lucide-react';

export default function AuctionManagement() {
    const [auctions, setAuctions] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [message, setMessage] = useState('');

    useEffect(() => {
        fetchAuctions();
    }, []);

    const fetchAuctions = async () => {
        try {
            setLoading(true);
            const data = await getAllAuctions();
            setAuctions(data);
        } catch (error) {
            setMessage('Error fetching auctions: ' + error.message);
        } finally {
            setLoading(false);
        }
    };

    const filteredAuctions = auctions.filter(auction =>
        auction.title?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const getAuctionStatus = (auction) => {
        const now = new Date();
        const endTime = auction.endTime?.toDate?.() || new Date(auction.endTime);

        if (now > endTime) return 'Ended';
        return 'Active';
    };

    if (loading) {
        return <div className="text-center text-gray-400">Loading auctions...</div>;
    }

    return (
        <div className="space-y-6">
            <div>
                <h2 className="text-4xl font-bold text-white mb-2">Auction Management</h2>
                <p className="text-gray-400 text-lg">Monitor and manage active auctions</p>
            </div>

            {message && (
                <div className="bg-gradient-to-r from-green-900/30 to-green-900/10 border border-green-500 rounded-xl p-4 flex items-center gap-3">
                    <div className="p-2 bg-green-900/40 rounded-lg">
                        <AlertCircle className="w-5 h-5 text-green-400" />
                    </div>
                    <p className="text-green-200">{message}</p>
                </div>
            )}

            <div className="bg-gradient-to-r from-gray-800 to-gray-900 rounded-xl p-4 border border-gray-700 shadow-lg">
                <input
                    type="text"
                    placeholder="Search by product name..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full px-4 py-3 bg-gray-700/50 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all"
                />
            </div>

            <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl border border-gray-700 shadow-lg">
                <div className="space-y-4 p-6">
                    {filteredAuctions.length === 0 ? (
                        <div className="text-center py-12">
                            <AlertCircle className="w-12 h-12 mx-auto mb-3 text-gray-500" />
                            <p className="text-gray-400">No auctions found</p>
                        </div>
                    ) : (
                        filteredAuctions.map((auction) => {
                            const status = getAuctionStatus(auction);
                            const statusColor =
                                status === 'Active'
                                    ? 'bg-green-900/40 text-green-300 border border-green-700'
                                    : 'bg-gray-700/40 text-gray-300 border border-gray-600';

                            return (
                                <div key={auction.id} className="bg-gray-700/30 rounded-lg border border-gray-600/30 p-5 hover:border-gray-500/50 transition">
                                    <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                                        {/* Image & Title */}
                                        <div className="md:col-span-2">
                                            {auction.imagePath && (
                                                <img
                                                    src={auction.imagePath}
                                                    alt={auction.title}
                                                    className="w-full h-40 object-cover rounded-lg mb-3"
                                                />
                                            )}
                                            <div>
                                                <h3 className="text-lg font-bold text-white mb-2">{auction.title || 'Unknown'}</h3>
                                                <div className="flex gap-2">
                                                    <span className={`px-3 py-1 rounded-full text-xs font-bold ${statusColor}`}>
                                                        {status}
                                                    </span>
                                                    {auction.approvalStatus && (
                                                        <span className={`px-3 py-1 rounded-full text-xs font-bold ${auction.approvalStatus === 'approved'
                                                                ? 'bg-blue-900/40 text-blue-300 border border-blue-700'
                                                                : auction.approvalStatus === 'pending'
                                                                    ? 'bg-yellow-900/40 text-yellow-300 border border-yellow-700'
                                                                    : 'bg-red-900/40 text-red-300 border border-red-700'
                                                            }`}>
                                                            {auction.approvalStatus}
                                                        </span>
                                                    )}
                                                </div>
                                            </div>
                                        </div>

                                        {/* Bid Information */}
                                        <div className="space-y-3">
                                            <div>
                                                <p className="text-gray-400 text-sm mb-1">Current Bid</p>
                                                <p className="text-2xl font-bold text-primary flex items-center gap-2">
                                                    <span>Rs</span>
                                                    {auction.currentBid || '0'}
                                                </p>
                                            </div>
                                            <div>
                                                <p className="text-gray-400 text-sm mb-1">Min. Increment</p>
                                                <p className="text-lg font-bold text-white">Rs {auction.minimumIncrement || '0'}</p>
                                            </div>
                                        </div>

                                        {/* Timing & Status */}
                                        <div className="space-y-3">
                                            <div>
                                                <p className="text-gray-400 text-sm mb-1 flex items-center gap-2">
                                                    <Clock className="w-4 h-4" />
                                                    Ends
                                                </p>
                                                <p className="text-white font-semibold text-sm">
                                                    {auction.endTime
                                                        ? new Date(auction.endTime.seconds ? auction.endTime.seconds * 1000 : auction.endTime).toLocaleDateString()
                                                        : 'N/A'
                                                    }
                                                </p>
                                            </div>
                                            {auction.paymentStatus && (
                                                <div>
                                                    <p className="text-gray-400 text-sm mb-1">Payment</p>
                                                    <p className="text-sm font-semibold text-white flex items-center gap-1">
                                                        {auction.paymentStatus === 'paid' ? (
                                                            <>
                                                                <CheckCircle className="w-4 h-4 text-green-400" />
                                                                Paid
                                                            </>
                                                        ) : (
                                                            <>
                                                                <XCircle className="w-4 h-4 text-red-400" />
                                                                Pending
                                                            </>
                                                        )}
                                                    </p>
                                                </div>
                                            )}
                                        </div>
                                    </div>

                                    {/* Additional Details */}
                                    {(auction.winningUserId || auction.lastBidTime || auction.sellerId || auction.deliveryMethods || auction.paymentMethods) && (
                                        <div className="mt-4 pt-4 border-t border-gray-600/30 grid grid-cols-1 md:grid-cols-4 gap-3 text-sm">
                                            {auction.winningUserId && (
                                                <div>
                                                    <p className="text-gray-400 text-xs mb-1">Winner</p>
                                                    <p className="text-white font-medium truncate">{auction.winningUserId}</p>
                                                </div>
                                            )}
                                            {auction.lastBidTime && (
                                                <div>
                                                    <p className="text-gray-400 text-xs mb-1">Last Bid</p>
                                                    <p className="text-white font-medium">
                                                        {new Date(auction.lastBidTime.seconds ? auction.lastBidTime.seconds * 1000 : auction.lastBidTime).toLocaleString()}
                                                    </p>
                                                </div>
                                            )}
                                            {auction.sellerId && (
                                                <div>
                                                    <p className="text-gray-400 text-xs mb-1">Seller</p>
                                                    <p className="text-white font-medium truncate">{auction.sellerId}</p>
                                                </div>
                                            )}
                                            {auction.deliveryMethods && (
                                                <div>
                                                    <p className="text-gray-400 text-xs mb-1">Delivery</p>
                                                    <p className="text-white font-medium">
                                                        {Array.isArray(auction.deliveryMethods)
                                                            ? auction.deliveryMethods.join(', ')
                                                            : auction.deliveryMethods
                                                        }
                                                    </p>
                                                </div>
                                            )}
                                        </div>
                                    )}
                                </div>
                            );
                        })
                    )}
                </div>
            </div>

            <div className="text-gray-400 text-sm font-medium">
                Showing {filteredAuctions.length} auctions
            </div>
        </div>
    );
}
