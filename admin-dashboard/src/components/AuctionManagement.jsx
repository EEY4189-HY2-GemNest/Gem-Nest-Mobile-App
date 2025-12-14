import React, { useState, useEffect } from 'react';
import { getAllAuctions } from '../services/adminService';
import { AlertCircle, Clock } from 'lucide-react';

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
        auction.productName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        auction.description?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const getAuctionStatus = (auction) => {
        const now = new Date();
        const endTime = auction.endTime?.toDate?.() || new Date(auction.endTime);

        if (now > endTime) return 'Ended';
        if (now > (auction.startTime?.toDate?.() || new Date(auction.startTime))) return 'Active';
        return 'Upcoming';
    };

    if (loading) {
        return <div className="text-center text-gray-400">Loading auctions...</div>;
    }

    return (
        <div className="space-y-6">
            <div>
                <h2 className="text-3xl font-bold text-white mb-2">Auction Management</h2>
                <p className="text-gray-400">Monitor and manage active auctions</p>
            </div>

            {message && (
                <div className="bg-green-900/20 border border-green-500 rounded-lg p-4 flex items-center gap-2">
                    <AlertCircle className="w-5 h-5 text-green-500" />
                    <p className="text-green-200">{message}</p>
                </div>
            )}

            <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
                <input
                    type="text"
                    placeholder="Search by product name..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:border-primary"
                />
            </div>

            <div className="bg-gray-800 rounded-lg border border-gray-700 overflow-hidden">
                <div className="overflow-x-auto">
                    <table className="w-full">
                        <thead className="bg-gray-900 border-b border-gray-700">
                            <tr>
                                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-300">Product</th>
                                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-300">Starting Price</th>
                                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-300">Current Bid</th>
                                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-300">Bids</th>
                                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-300">Status</th>
                                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-300">Ends</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filteredAuctions.length === 0 ? (
                                <tr>
                                    <td colSpan="6" className="px-6 py-8 text-center text-gray-400">
                                        No auctions found
                                    </td>
                                </tr>
                            ) : (
                                filteredAuctions.map((auction) => {
                                    const status = getAuctionStatus(auction);
                                    const statusColor =
                                        status === 'Active'
                                            ? 'bg-green-900 text-green-300'
                                            : status === 'Ended'
                                                ? 'bg-gray-700 text-gray-300'
                                                : 'bg-blue-900 text-blue-300';

                                    return (
                                        <tr key={auction.id} className="border-b border-gray-700 hover:bg-gray-700/50">
                                            <td className="px-6 py-3 text-white font-medium">
                                                {auction.productName || 'Unknown'}
                                            </td>
                                            <td className="px-6 py-3 text-primary font-semibold">
                                                ${auction.startingPrice || '0'}
                                            </td>
                                            <td className="px-6 py-3 text-white font-semibold">
                                                ${auction.currentBid || auction.startingPrice || '0'}
                                            </td>
                                            <td className="px-6 py-3 text-gray-300">
                                                {auction.totalBids || 0}
                                            </td>
                                            <td className="px-6 py-3">
                                                <span className={`px-3 py-1 rounded-full text-xs font-semibold ${statusColor}`}>
                                                    {status}
                                                </span>
                                            </td>
                                            <td className="px-6 py-3 text-gray-300 text-sm flex items-center gap-2">
                                                <Clock className="w-4 h-4" />
                                                {auction.endTime
                                                    ? new Date(auction.endTime.seconds ? auction.endTime.seconds * 1000 : auction.endTime).toLocaleDateString()
                                                    : 'N/A'
                                                }
                                            </td>
                                        </tr>
                                    );
                                })
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            <div className="text-gray-400 text-sm">
                Total Auctions: {filteredAuctions.length}
            </div>
        </div>
    );
}
