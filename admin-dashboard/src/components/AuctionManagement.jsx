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

            <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl border border-gray-700 overflow-hidden shadow-lg">
                <div className="overflow-x-auto">
                    <table className="w-full">
                        <thead className="bg-gray-900/50 border-b border-gray-700">
                            <tr>
                                <th className="px-6 py-4 text-left text-xs font-bold text-gray-300 uppercase tracking-wide">Title</th>
                                <th className="px-6 py-4 text-left text-xs font-bold text-gray-300 uppercase tracking-wide">Current Bid</th>
                                <th className="px-6 py-4 text-left text-xs font-bold text-gray-300 uppercase tracking-wide">Minimum Increment</th>
                                <th className="px-6 py-4 text-left text-xs font-bold text-gray-300 uppercase tracking-wide">Status</th>
                                <th className="px-6 py-4 text-left text-xs font-bold text-gray-300 uppercase tracking-wide">Ends</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filteredAuctions.length === 0 ? (
                                <tr>
                                    <td colSpan="6" className="px-6 py-12 text-center text-gray-400">
                                        No auctions found
                                    </td>
                                </tr>
                            ) : (
                                filteredAuctions.map((auction) => {
                                    const status = getAuctionStatus(auction);
                                    const statusColor =
                                        status === 'Active'
                                            ? 'bg-green-900/40 text-green-300 border border-green-700'
                                            : status === 'Ended'
                                                ? 'bg-gray-700/40 text-gray-300 border border-gray-600'
                                                : 'bg-blue-900/40 text-blue-300 border border-blue-700';

                                    return (
                                        <tr key={auction.id} className="border-b border-gray-700 hover:bg-gray-700/20 transition-colors">
                                            <td className="px-6 py-4 text-white font-medium">
                                                {auction.title || 'Unknown'}
                                            </td>
                                            <td className="px-6 py-4 text-primary font-bold">
                                                ${auction.currentBid || '0'}
                                            </td>
                                            <td className="px-6 py-4 text-white font-bold">
                                                ${auction.minimumIncrement || '0'}
                                            </td>
                                            <td className="px-6 py-4">
                                                <span className={`px-3 py-1 rounded-full text-xs font-bold ${statusColor}`}>
                                                    {status}
                                                </span>
                                            </td>
                                            <td className="px-6 py-4 text-gray-300 text-sm flex items-center gap-2">
                                                <Clock className="w-4 h-4 text-gray-400" />
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

            <div className="text-gray-400 text-sm font-medium">
                Showing {filteredAuctions.length} auctions
            </div>
        </div>
    );
}
