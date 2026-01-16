import React, { useState, useEffect } from 'react';
import { db } from '../firebase-config';
import { collection, query, where, getDocs, updateDoc, doc, orderBy } from 'firebase/firestore';
import { CheckCircle, XCircle, Clock, Download, Eye, Filter } from 'lucide-react';
import CertificateDialog from './CertificateDialog';

export default function CertificateVerificationDashboard() {
    const [certificates, setCertificates] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('pending');
    const [selectedCert, setSelectedCert] = useState(null);
    const [certDialog, setCertDialog] = useState(null);
    const [actionLoading, setActionLoading] = useState(false);

    useEffect(() => {
        fetchCertificates();
    }, [filter]);

    const fetchCertificates = async () => {
        try {
            setLoading(true);
            const productsRef = collection(db, 'products');

            // Fetch all products with certificates (no compound where needed)
            const q = query(productsRef, where('gemCertificates', '!=', null));
            const snapshot = await getDocs(q);
            const certsData = [];

            for (const docSnap of snapshot.docs) {
                const product = docSnap.data();
                if (product.gemCertificates && Array.isArray(product.gemCertificates)) {
                    for (const cert of product.gemCertificates) {
                        certsData.push({
                            productId: docSnap.id,
                            productName: product.title,
                            sellerId: product.sellerId,
                            sellerName: product.sellerName || 'Unknown',
                            ...cert,
                            verificationStatus: product.certificateVerificationStatus || 'pending',
                            rejectionReason: product.rejectionReason || '',
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
        } catch (error) {
            console.error('Error fetching certificates:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleVerify = (cert) => {
        setCertDialog({
            type: 'verify',
            cert,
            onConfirm: async () => {
                try {
                    setActionLoading(true);
                    const productRef = doc(db, 'products', cert.productId);
                    await updateDoc(productRef, {
                        certificateVerificationStatus: 'verified',
                        rejectionReason: '',
                    });

                    setCertificates(certificates.map(c =>
                        c.productId === cert.productId
                            ? { ...c, verificationStatus: 'verified', rejectionReason: '' }
                            : c
                    ));
                    setCertDialog(null);
                } catch (error) {
                    console.error('Error verifying certificate:', error);
                } finally {
                    setActionLoading(false);
                }
            }
        });
    };

    const handleReject = (cert) => {
        setCertDialog({
            type: 'reject',
            cert,
            onConfirm: async (reason) => {
                try {
                    setActionLoading(true);
                    const productRef = doc(db, 'products', cert.productId);
                    await updateDoc(productRef, {
                        certificateVerificationStatus: 'rejected',
                        rejectionReason: reason,
                    });

                    setCertificates(certificates.map(c =>
                        c.productId === cert.productId
                            ? { ...c, verificationStatus: 'rejected', rejectionReason: reason }
                            : c
                    ));
                    setCertDialog(null);
                } catch (error) {
                    console.error('Error rejecting certificate:', error);
                } finally {
                    setActionLoading(false);
                }
            }
        });
    };

    const getStatusIcon = (status) => {
        switch (status) {
            case 'verified':
                return <CheckCircle className="w-5 h-5 text-green-400" />;
            case 'rejected':
                return <XCircle className="w-5 h-5 text-red-400" />;
            default:
                return <Clock className="w-5 h-5 text-orange-400" />;
        }
    };

    const getStatusColor = (status) => {
        switch (status) {
            case 'verified':
                return 'bg-green-900/20 border-green-700';
            case 'rejected':
                return 'bg-red-900/20 border-red-700';
            default:
                return 'bg-orange-900/20 border-orange-700';
        }
    };

    const filteredCerts = filter === 'all'
        ? certificates
        : certificates.filter(c => c.verificationStatus === filter);

    return (
        <div className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-xl p-8 border border-gray-700">
            <div className="mb-6">
                <h2 className="text-3xl font-bold text-white mb-4 flex items-center gap-2">
                    <div className="p-2 bg-purple-900/30 rounded-lg">
                        <CheckCircle className="w-6 h-6 text-purple-400" />
                    </div>
                    Certificate Verification Management
                </h2>

                {/* Filter Buttons */}
                <div className="flex gap-2 mb-6">
                    {['pending', 'verified', 'rejected', 'all'].map((status) => (
                        <button
                            key={status}
                            onClick={() => setFilter(status)}
                            className={`px-4 py-2 rounded-lg font-medium transition-colors ${filter === status
                                ? 'bg-purple-600 text-white'
                                : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
                                }`}
                        >
                            {status.charAt(0).toUpperCase() + status.slice(1)}
                            <span className="ml-2 text-sm opacity-75">
                                ({certificates.filter(c => c.verificationStatus === status || status === 'all').length})
                            </span>
                        </button>
                    ))}
                </div>
            </div>

            {loading ? (
                <div className="text-center py-12">
                    <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-purple-400"></div>
                    <p className="text-gray-400 mt-4">Loading certificates...</p>
                </div>
            ) : filteredCerts.length === 0 ? (
                <div className="text-center py-12">
                    <Filter className="w-12 h-12 text-gray-600 mx-auto mb-4" />
                    <p className="text-gray-400">No certificates found for this filter</p>
                </div>
            ) : (
                <div className="overflow-x-auto">
                    <table className="w-full">
                        <thead>
                            <tr className="border-b border-gray-700">
                                <th className="text-left py-3 px-4 text-gray-300 font-semibold">Product</th>
                                <th className="text-left py-3 px-4 text-gray-300 font-semibold">Seller</th>
                                <th className="text-left py-3 px-4 text-gray-300 font-semibold">Certificate</th>
                                <th className="text-left py-3 px-4 text-gray-300 font-semibold">Type</th>
                                <th className="text-left py-3 px-4 text-gray-300 font-semibold">Uploaded</th>
                                <th className="text-left py-3 px-4 text-gray-300 font-semibold">Status</th>
                                <th className="text-left py-3 px-4 text-gray-300 font-semibold">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filteredCerts.map((cert, idx) => (
                                <tr key={idx} className="border-b border-gray-700 hover:bg-gray-800/50 transition-colors">
                                    <td className="py-4 px-4">
                                        <p className="text-white font-medium">{cert.productName}</p>
                                    </td>
                                    <td className="py-4 px-4">
                                        <p className="text-gray-300">{cert.sellerName}</p>
                                    </td>
                                    <td className="py-4 px-4">
                                        <p className="text-gray-300 text-sm max-w-xs truncate">{cert.fileName}</p>
                                    </td>
                                    <td className="py-4 px-4">
                                        <span className="text-gray-400 text-sm uppercase">{cert.type}</span>
                                    </td>
                                    <td className="py-4 px-4">
                                        <p className="text-gray-400 text-sm">
                                            {new Date(cert.uploadedAt).toLocaleDateString()}
                                        </p>
                                    </td>
                                    <td className="py-4 px-4">
                                        <div className={`flex items-center gap-2 px-3 py-1 rounded-lg border ${getStatusColor(cert.verificationStatus)} w-fit`}>
                                            {getStatusIcon(cert.verificationStatus)}
                                            <span className="text-sm font-medium text-white">
                                                {cert.verificationStatus.charAt(0).toUpperCase() + cert.verificationStatus.slice(1)}
                                            </span>
                                        </div>
                                    </td>
                                    <td className="py-4 px-4">
                                        <div className="flex gap-2">
                                            <button
                                                onClick={() => {
                                                    const fileUrl = cert.url;
                                                    window.open(fileUrl, '_blank');
                                                }}
                                                className="p-2 hover:bg-blue-900/30 rounded-lg text-blue-400 transition-colors"
                                                title="View"
                                            >
                                                <Eye className="w-5 h-5" />
                                            </button>
                                            {cert.verificationStatus === 'pending' && (
                                                <>
                                                    <button
                                                        onClick={() => handleVerify(cert)}
                                                        className="p-2 hover:bg-green-900/30 rounded-lg text-green-400 transition-colors"
                                                        title="Verify"
                                                    >
                                                        <CheckCircle className="w-5 h-5" />
                                                    </button>
                                                    <button
                                                        onClick={() => {
                                                            setSelectedCert(cert);
                                                            setShowRejectModal(true);
                                                        }}
                                                        className="p-2 hover:bg-red-900/30 rounded-lg text-red-400 transition-colors"
                                                        title="Reject"
                                                    >
                                                        <XCircle className="w-5 h-5" />
                                                    </button>
                                                </>
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}

            {/* Rejection Modal */}
            {showRejectModal && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
                    <div className="bg-gray-900 border border-gray-700 rounded-xl p-6 max-w-md w-full mx-4">
                        <h3 className="text-xl font-bold text-white mb-4">Reject Certificate</h3>
                        <p className="text-gray-400 mb-4">
                            Product: <span className="text-white font-medium">{selectedCert?.productName}</span>
                        </p>

                        <textarea
                            value={rejectionReason}
                            onChange={(e) => setRejectionReason(e.target.value)}
                            placeholder="Enter rejection reason..."
                            className="w-full bg-gray-800 border border-gray-700 rounded-lg p-3 text-white placeholder-gray-500 mb-4 focus:outline-none focus:border-red-500"
                            rows="4"
                        />

                        <div className="flex gap-3">
                            <button
                                onClick={() => {
                                    setShowRejectModal(false);
                                    setRejectionReason('');
                                    setSelectedCert(null);
                                }}
                                className="flex-1 bg-gray-700 hover:bg-gray-600 text-white font-medium py-2 rounded-lg transition-colors"
                            >
                                Cancel
                            </button>
                            <button
                                onClick={handleReject}
                                className="flex-1 bg-red-600 hover:bg-red-700 text-white font-medium py-2 rounded-lg transition-colors"
                            >
                                Reject
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Summary Stats */}
            <div className="grid grid-cols-3 gap-4 mt-8">
                <div className="bg-green-900/20 border border-green-700 rounded-lg p-4 text-center">
                    <p className="text-green-400 text-2xl font-bold">
                        {certificates.filter(c => c.verificationStatus === 'verified').length}
                    </p>
                    <p className="text-green-400 text-sm mt-1">Verified</p>
                </div>
                <div className="bg-orange-900/20 border border-orange-700 rounded-lg p-4 text-center">
                    <p className="text-orange-400 text-2xl font-bold">
                        {certificates.filter(c => c.verificationStatus === 'pending').length}
                    </p>
                    <p className="text-orange-400 text-sm mt-1">Pending</p>
                </div>
                <div className="bg-red-900/20 border border-red-700 rounded-lg p-4 text-center">
                    <p className="text-red-400 text-2xl font-bold">
                        {certificates.filter(c => c.verificationStatus === 'rejected').length}
                    </p>
                    <p className="text-red-400 text-sm mt-1">Rejected</p>
                </div>
            </div>
        </div>
    );
}
