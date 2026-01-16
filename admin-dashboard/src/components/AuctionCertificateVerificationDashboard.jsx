import React, { useState, useEffect } from 'react';
import { db } from '../firebase-config';
import { collection, query, where, getDocs, updateDoc, doc, orderBy } from 'firebase/firestore';
import { CheckCircle, XCircle, Clock, Download, Eye, Filter, Gavel } from 'lucide-react';
import CertificateDialog from './CertificateDialog';

export default function AuctionCertificateVerificationDashboard() {
    const [certificates, setCertificates] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('pending');
    const [certDialog, setCertDialog] = useState(null);
    const [actionLoading, setActionLoading] = useState(false);
    const [stats, setStats] = useState({
        pending: 0,
        verified: 0,
        rejected: 0,
        total: 0,
    });

    useEffect(() => {
        fetchCertificates();
    }, [filter]);

    const fetchCertificates = async () => {
        try {
            setLoading(true);
            const auctionsRef = collection(db, 'auctions');

            // Fetch all auctions with certificates
            const q = query(auctionsRef, where('gemCertificates', '!=', null));
            const snapshot = await getDocs(q);
            const certsData = [];

            for (const docSnap of snapshot.docs) {
                const auction = docSnap.data();
                if (auction.gemCertificates && Array.isArray(auction.gemCertificates)) {
                    for (const cert of auction.gemCertificates) {
                        certsData.push({
                            auctionId: docSnap.id,
                            auctionTitle: auction.title,
                            sellerId: auction.sellerId,
                            sellerName: auction.sellerName || 'Unknown',
                            currentBid: auction.currentBid || 0,
                            ...cert,
                            verificationStatus: auction.certificateVerificationStatus || 'pending',
                            rejectionReason: auction.rejectionReason || '',
                        });
                    }
                }
            }

            // Filter in-memory instead of in database query
            let filtered = certsData;
            if (filter !== 'all') {
                filtered = certsData.filter(c => c.verificationStatus === filter);
            }

            // Sort by upload date (newest first)
            filtered.sort((a, b) => new Date(b.uploadedAt) - new Date(a.uploadedAt));
            setCertificates(filtered);

            // Calculate stats
            const pendingCount = filtered.filter(c => c.verificationStatus === 'pending').length;
            const verifiedCount = filtered.filter(c => c.verificationStatus === 'verified').length;
            const rejectedCount = filtered.filter(c => c.verificationStatus === 'rejected').length;

            setStats({
                pending: pendingCount,
                verified: verifiedCount,
                rejected: rejectedCount,
                total: filtered.length,
            });
        } catch (error) {
            console.error('Error fetching auction certificates:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleVerify = async (cert) => {
        try {
            const auctionRef = doc(db, 'auctions', cert.auctionId);
            await updateDoc(auctionRef, {
                certificateVerificationStatus: 'verified',
                rejectionReason: '',
            });

            // Update local state
            setCertificates(certificates.map(c =>
                c.auctionId === cert.auctionId
                    ? { ...c, verificationStatus: 'verified', rejectionReason: '' }
                    : c
            ));
            alert('Auction certificate verified successfully');
        } catch (error) {
            console.error('Error verifying auction certificate:', error);
            alert('Failed to verify auction certificate');
        }
    };

    const handleReject = async () => {
        if (!rejectionReason.trim()) {
            alert('Please provide a rejection reason');
            return;
        }

        try {
            const auctionRef = doc(db, 'auctions', selectedCert.auctionId);
            await updateDoc(auctionRef, {
                certificateVerificationStatus: 'rejected',
                rejectionReason: rejectionReason,
            });

            setCertificates(certificates.map(c =>
                c.auctionId === selectedCert.auctionId
                    ? { ...c, verificationStatus: 'rejected', rejectionReason: rejectionReason }
                    : c
            ));
            setShowRejectModal(false);
            setRejectionReason('');
            setSelectedCert(null);
            alert('Auction certificate rejected successfully');
        } catch (error) {
            console.error('Error rejecting auction certificate:', error);
            alert('Failed to reject auction certificate');
        }
    };

    const getStatusColor = (status) => {
        switch (status) {
            case 'verified':
                return 'bg-green-100 text-green-800 border-green-300';
            case 'rejected':
                return 'bg-red-100 text-red-800 border-red-300';
            default:
                return 'bg-yellow-100 text-yellow-800 border-yellow-300';
        }
    };

    const getStatusIcon = (status) => {
        switch (status) {
            case 'verified':
                return <CheckCircle className="w-5 h-5" />;
            case 'rejected':
                return <XCircle className="w-5 h-5" />;
            default:
                return <Clock className="w-5 h-5" />;
        }
    };

    return (
        <div className="w-full">
            {/* Title */}
            <div className="mb-8">
                <div className="flex items-center gap-3 mb-2">
                    <div className="p-3 bg-purple-900/30 rounded-lg">
                        <Gavel className="w-6 h-6 text-purple-400" />
                    </div>
                    <h2 className="text-2xl font-bold text-white">Auction Certificate Verification</h2>
                </div>
                <p className="text-gray-400 ml-12">Verify and manage gem certificates for auctions</p>
            </div>

            {/* Summary Stats */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
                <div className="bg-gradient-to-br from-yellow-900/20 to-yellow-800/20 rounded-xl p-4 border border-yellow-700/30">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-yellow-300 text-xs font-semibold uppercase">Pending</p>
                            <p className="text-2xl font-bold text-white mt-1">{stats.pending}</p>
                        </div>
                        <Clock className="w-8 h-8 text-yellow-400 opacity-50" />
                    </div>
                </div>
                <div className="bg-gradient-to-br from-green-900/20 to-green-800/20 rounded-xl p-4 border border-green-700/30">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-green-300 text-xs font-semibold uppercase">Verified</p>
                            <p className="text-2xl font-bold text-white mt-1">{stats.verified}</p>
                        </div>
                        <CheckCircle className="w-8 h-8 text-green-400 opacity-50" />
                    </div>
                </div>
                <div className="bg-gradient-to-br from-red-900/20 to-red-800/20 rounded-xl p-4 border border-red-700/30">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-red-300 text-xs font-semibold uppercase">Rejected</p>
                            <p className="text-2xl font-bold text-white mt-1">{stats.rejected}</p>
                        </div>
                        <XCircle className="w-8 h-8 text-red-400 opacity-50" />
                    </div>
                </div>
                <div className="bg-gradient-to-br from-blue-900/20 to-blue-800/20 rounded-xl p-4 border border-blue-700/30">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-blue-300 text-xs font-semibold uppercase">Total</p>
                            <p className="text-2xl font-bold text-white mt-1">{stats.total}</p>
                        </div>
                        <Filter className="w-8 h-8 text-blue-400 opacity-50" />
                    </div>
                </div>
            </div>

            {/* Filter Tabs */}
            <div className="flex gap-3 mb-6 border-b border-gray-700">
                {['pending', 'verified', 'rejected', 'all'].map((status) => (
                    <button
                        key={status}
                        onClick={() => setFilter(status)}
                        className={`px-4 py-2 font-medium text-sm transition-all ${filter === status
                            ? 'text-blue-400 border-b-2 border-blue-400'
                            : 'text-gray-400 hover:text-gray-300'
                            }`}
                    >
                        {status.charAt(0).toUpperCase() + status.slice(1)}
                    </button>
                ))}
            </div>

            {/* Certificates List */}
            <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl border border-gray-700 overflow-hidden">
                {loading ? (
                    <div className="flex items-center justify-center py-12">
                        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-400"></div>
                    </div>
                ) : certificates.length === 0 ? (
                    <div className="text-center py-12">
                        <Gavel className="w-12 h-12 text-gray-500 mx-auto mb-4" />
                        <p className="text-gray-400 text-lg">No auction certificates found</p>
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full">
                            <thead>
                                <tr className="border-b border-gray-700 bg-gray-700/50">
                                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-300">Auction Title</th>
                                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-300">Seller</th>
                                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-300">Current Bid</th>
                                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-300">Certificate</th>
                                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-300">Upload Date</th>
                                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-300">Status</th>
                                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-300">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {certificates.map((cert, index) => (
                                    <tr
                                        key={index}
                                        className="border-b border-gray-700 hover:bg-gray-700/30 transition-colors"
                                    >
                                        <td className="px-6 py-4 text-sm text-white">
                                            <div className="flex items-center gap-2">
                                                <Gavel className="w-4 h-4 text-purple-400" />
                                                {cert.auctionTitle}
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 text-sm text-gray-300">{cert.sellerName}</td>
                                        <td className="px-6 py-4 text-sm text-gray-300">Rs. {cert.currentBid.toFixed(2)}</td>
                                        <td className="px-6 py-4 text-sm text-gray-300">{cert.fileName}</td>
                                        <td className="px-6 py-4 text-sm text-gray-400">
                                            {new Date(cert.uploadedAt).toLocaleDateString()}
                                        </td>
                                        <td className="px-6 py-4 text-sm">
                                            <div className={`inline-flex items-center gap-2 px-3 py-1 rounded-full border ${getStatusColor(cert.verificationStatus)}`}>
                                                {getStatusIcon(cert.verificationStatus)}
                                                {cert.verificationStatus.charAt(0).toUpperCase() + cert.verificationStatus.slice(1)}
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 text-sm">
                                            <div className="flex items-center gap-2">
                                                <button
                                                    onClick={() => window.open(cert.url, '_blank')}
                                                    className="p-2 hover:bg-gray-600 rounded transition-colors"
                                                    title="View Certificate"
                                                >
                                                    <Eye className="w-4 h-4 text-blue-400" />
                                                </button>
                                                {cert.verificationStatus !== 'verified' && (
                                                    <button
                                                        onClick={() => handleVerify(cert)}
                                                        className="px-3 py-1 bg-green-600 hover:bg-green-700 text-white text-xs rounded transition-colors"
                                                        title="Verify"
                                                    >
                                                        Verify
                                                    </button>
                                                )}
                                                {cert.verificationStatus !== 'rejected' && (
                                                    <button
                                                        onClick={() => {
                                                            setSelectedCert(cert);
                                                            setShowRejectModal(true);
                                                        }}
                                                        className="px-3 py-1 bg-red-600 hover:bg-red-700 text-white text-xs rounded transition-colors"
                                                        title="Reject"
                                                    >
                                                        Reject
                                                    </button>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Rejection Modal */}
            {showRejectModal && (
                <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
                    <div className="bg-gray-800 rounded-lg p-6 max-w-md w-full mx-4 border border-gray-700">
                        <h3 className="text-xl font-bold text-white mb-4">Reject Auction Certificate</h3>
                        <div className="mb-4">
                            <p className="text-gray-400 text-sm mb-2">Auction: {selectedCert?.auctionTitle}</p>
                            <label className="block text-gray-300 text-sm font-medium mb-2">Rejection Reason</label>
                            <textarea
                                value={rejectionReason}
                                onChange={(e) => setRejectionReason(e.target.value)}
                                placeholder="Provide a reason for rejection..."
                                className="w-full px-4 py-2 bg-gray-700 text-white rounded border border-gray-600 focus:border-blue-500 focus:outline-none resize-none"
                                rows="4"
                            />
                        </div>
                        <div className="flex gap-3">
                            <button
                                onClick={() => {
                                    setShowRejectModal(false);
                                    setRejectionReason('');
                                    setSelectedCert(null);
                                }}
                                className="flex-1 px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded transition-colors"
                            >
                                Cancel
                            </button>
                            <button
                                onClick={handleReject}
                                className="flex-1 px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded transition-colors font-medium"
                            >
                                Reject
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
