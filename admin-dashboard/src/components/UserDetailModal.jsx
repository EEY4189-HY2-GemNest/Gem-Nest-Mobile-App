import React, { useState, useEffect } from 'react';
import { X, Download, Eye, FileText, Image as ImageIcon } from 'lucide-react';
import { doc, getDoc } from 'firebase/firestore';
import { db } from '../services/firebase';

export default function UserDetailModal({ user, onClose }) {
    const [sellerDetails, setSellerDetails] = useState(null);
    const [productCount, setProductCount] = useState(0);
    const [auctionCount, setAuctionCount] = useState(0);
    const [loading, setLoading] = useState(true);
    const [previewFile, setPreviewFile] = useState(null);

    useEffect(() => {
        fetchUserDetails();
    }, [user.id]);

    const fetchUserDetails = async () => {
        try {
            setLoading(true);

            // Fetch seller details if user is a seller
            if (user.userType === 'seller') {
                const sellerRef = doc(db, 'sellers', user.id);
                const sellerSnap = await getDoc(sellerRef);
                if (sellerSnap.exists()) {
                    setSellerDetails(sellerSnap.data());
                }
            }

            // Count products
            const productsRef = collection(db, 'products');
            const productQuery = query(productsRef, where('sellerId', '==', user.id));
            const productSnap = await getDocs(productQuery);
            setProductCount(productSnap.docs.length);

            // Count auctions
            const auctionsRef = collection(db, 'auctions');
            const auctionQuery = query(auctionsRef, where('sellerId', '==', user.id));
            const auctionSnap = await getDocs(auctionQuery);
            setAuctionCount(auctionSnap.docs.length);
        } catch (error) {
            console.error('Error fetching user details:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleDownloadFile = (fileUrl, fileName) => {
        if (fileUrl) {
            const link = document.createElement('a');
            link.href = fileUrl;
            link.download = fileName;
            link.click();
        }
    };

    const getFileType = (url) => {
        if (!url) return 'unknown';
        if (url.toLowerCase().endsWith('.pdf')) return 'pdf';
        if (url.match(/\.(jpg|jpeg|png|gif)$/i)) return 'image';
        return 'file';
    };

    if (loading) {
        return (
            <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 backdrop-blur-sm">
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-8 border border-gray-700 text-center shadow-2xl">
                    <div className="w-12 h-12 border-4 border-gray-700 border-t-primary rounded-full animate-spin mx-auto mb-4"></div>
                    <p className="text-gray-300">Loading user details...</p>
                </div>
            </div>
        );
    }

    return (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
            <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl border border-gray-700 max-w-2xl w-full max-h-[90vh] overflow-y-auto shadow-2xl">
                {/* Header */}
                <div className="sticky top-0 bg-gradient-to-r from-gray-900 to-gray-800 border-b border-gray-700 p-6 flex items-center justify-between">
                    <h2 className="text-2xl font-bold text-white">User Details</h2>
                    <button
                        onClick={onClose}
                        className="p-2 hover:bg-gray-700 rounded-lg transition-colors duration-200"
                    >
                        <X className="w-6 h-6 text-gray-300 hover:text-white" />
                    </button>
                </div>

                {/* Content */}
                <div className="p-6 space-y-6">
                    {/* Basic Info */}
                    <div className="bg-gradient-to-br from-gray-700/50 to-gray-800/50 rounded-xl p-6 border border-gray-700">
                        <h3 className="text-lg font-bold text-primary mb-5 flex items-center gap-2">
                            <div className="w-1 h-6 bg-gradient-to-b from-primary to-yellow-600 rounded"></div>
                            Basic Information
                        </h3>
                        <div className="grid grid-cols-2 gap-5">
                            <div>
                                <p className="text-gray-400 text-xs uppercase tracking-wide mb-2">Email</p>
                                <p className="text-white font-semibold text-lg">{user.email || 'N/A'}</p>
                            </div>
                            <div>
                                <p className="text-gray-400 text-xs uppercase tracking-wide mb-2">Name</p>
                                <p className="text-white font-semibold text-lg">{user.name || 'N/A'}</p>
                            </div>
                            <div>
                                <p className="text-gray-400 text-xs uppercase tracking-wide mb-2">User Type</p>
                                <p className="text-white font-semibold capitalize text-lg">{user.userType || 'Unknown'}</p>
                            </div>
                            <div>
                                <p className="text-gray-400 text-xs uppercase tracking-wide mb-2">Status</p>
                                <span className={`px-3 py-2 rounded-lg text-xs font-bold inline-block border ${user.isActive !== false
                                    ? 'bg-green-900/40 text-green-300 border-green-700'
                                    : 'bg-red-900/40 text-red-300 border-red-700'
                                    }`}>
                                    {user.status || (user.isActive !== false ? 'Active' : 'Inactive')}
                                </span>
                            </div>
                        </div>
                    </div>

                    {/* Seller Details */}
                    {user.userType === 'seller' && sellerDetails && (
                        <>
                            <div className="bg-gradient-to-br from-gray-700/50 to-gray-800/50 rounded-xl p-6 border border-gray-700">
                                <h3 className="text-lg font-bold text-primary mb-5 flex items-center gap-2">
                                    <div className="w-1 h-6 bg-gradient-to-b from-primary to-yellow-600 rounded"></div>
                                    Seller Information
                                </h3>
                                <div className="grid grid-cols-2 gap-5 text-sm">
                                    <div>
                                        <p className="text-gray-400 text-xs uppercase tracking-wide mb-2">Business Name</p>
                                        <p className="text-white font-semibold">{sellerDetails.businessName || 'N/A'}</p>
                                    </div>
                                    <div>
                                        <p className="text-gray-400 text-xs uppercase tracking-wide mb-2">Phone</p>
                                        <p className="text-white font-semibold">{sellerDetails.phoneNumber || 'N/A'}</p>
                                    </div>
                                    <div>
                                        <p className="text-gray-400 text-xs uppercase tracking-wide mb-2">Address</p>
                                        <p className="text-white font-semibold">{sellerDetails.address || 'N/A'}</p>
                                    </div>
                                    <div>
                                        <p className="text-gray-400 text-xs uppercase tracking-wide mb-2">Verified</p>
                                        <span className={`px-3 py-1 rounded-lg text-xs font-bold border inline-block ${sellerDetails.verified ? 'bg-green-900/40 text-green-300 border-green-700' : 'bg-yellow-900/40 text-yellow-300 border-yellow-700'
                                            }`}>
                                            {sellerDetails.verified ? 'Verified' : 'Pending'}
                                        </span>
                                    </div>
                                </div>
                            </div>

                            {/* Seller Stats */}
                            <div className="bg-gradient-to-br from-gray-700/50 to-gray-800/50 rounded-xl p-6 border border-gray-700">
                                <h3 className="text-lg font-bold text-primary mb-5 flex items-center gap-2">
                                    <div className="w-1 h-6 bg-gradient-to-b from-primary to-yellow-600 rounded"></div>
                                    Seller Statistics
                                </h3>
                                <div className="grid grid-cols-3 gap-5">
                                    <div className="bg-gradient-to-br from-blue-900/30 to-blue-800/30 rounded-lg p-4 border border-blue-700/30 text-center">
                                        <p className="text-4xl font-bold text-blue-400 mb-1">{productCount}</p>
                                        <p className="text-gray-300 text-sm font-medium">Products Listed</p>
                                    </div>
                                    <div className="bg-gradient-to-br from-purple-900/30 to-purple-800/30 rounded-lg p-4 border border-purple-700/30 text-center">
                                        <p className="text-4xl font-bold text-purple-400 mb-1">{auctionCount}</p>
                                        <p className="text-gray-300 text-sm font-medium">Auctions Listed</p>
                                    </div>
                                    <div className="bg-gradient-to-br from-pink-900/30 to-pink-800/30 rounded-lg p-4 border border-pink-700/30 text-center">
                                        <p className="text-4xl font-bold text-pink-400 mb-1">{sellerDetails.rating || 0}</p>
                                        <p className="text-gray-300 text-sm font-medium">Rating</p>
                                    </div>
                                </div>
                            </div>

                            {/* Verification Documents */}
                            <div className="bg-gradient-to-br from-gray-700/50 to-gray-800/50 rounded-xl p-6 border border-gray-700">
                                <h3 className="text-lg font-bold text-primary mb-5 flex items-center gap-2">
                                    <div className="w-1 h-6 bg-gradient-to-b from-primary to-yellow-600 rounded"></div>
                                    Verification Documents
                                </h3>
                                <div className="space-y-4">
                                    {/* NIC Document */}
                                    {sellerDetails.nicUrl && (
                                        <div className="bg-gray-700/50 rounded-lg p-4 flex items-center justify-between border border-gray-600 hover:border-gray-500 transition">
                                            <div className="flex items-center gap-4">
                                                <div className="p-3 bg-red-900/30 rounded-lg">
                                                    {getFileType(sellerDetails.nicUrl) === 'pdf' ? (
                                                        <FileText className="w-6 h-6 text-red-400" />
                                                    ) : (
                                                        <ImageIcon className="w-6 h-6 text-blue-400" />
                                                    )}
                                                </div>
                                                <div>
                                                    <p className="text-white font-semibold">NIC Document</p>
                                                    <p className="text-gray-400 text-xs">
                                                        {getFileType(sellerDetails.nicUrl).toUpperCase()}
                                                    </p>
                                                </div>
                                            </div>
                                            <div className="flex gap-2">
                                                <button
                                                    onClick={() => setPreviewFile({
                                                        url: sellerDetails.nicUrl,
                                                        type: getFileType(sellerDetails.nicUrl),
                                                        name: 'NIC Document'
                                                    })}
                                                    className="p-2 hover:bg-blue-900/30 rounded-lg text-blue-400 transition-colors"
                                                    title="View"
                                                >
                                                    <Eye className="w-5 h-5" />
                                                </button>
                                                <button
                                                    onClick={() => handleDownloadFile(sellerDetails.nicUrl, 'NIC_Document')}
                                                    className="p-2 hover:bg-green-900/30 rounded-lg text-green-400 transition-colors"
                                                    title="Download"
                                                >
                                                    <Download className="w-5 h-5" />
                                                </button>
                                            </div>
                                        </div>
                                    )}

                                    {/* BR Document */}
                                    {sellerDetails.brUrl && (
                                        <div className="bg-gray-700/50 rounded-lg p-4 flex items-center justify-between border border-gray-600 hover:border-gray-500 transition">
                                            <div className="flex items-center gap-4">
                                                <div className="p-3 bg-orange-900/30 rounded-lg">
                                                    {getFileType(sellerDetails.brUrl) === 'pdf' ? (
                                                        <FileText className="w-6 h-6 text-orange-400" />
                                                    ) : (
                                                        <ImageIcon className="w-6 h-6 text-blue-400" />
                                                    )}
                                                </div>
                                                <div>
                                                    <p className="text-white font-semibold">Business Registration (BR)</p>
                                                    <p className="text-gray-400 text-xs">
                                                        {getFileType(sellerDetails.brUrl).toUpperCase()}
                                                    </p>
                                                </div>
                                            </div>
                                            <div className="flex gap-2">
                                                <button
                                                    onClick={() => setPreviewFile({
                                                        url: sellerDetails.brUrl,
                                                        type: getFileType(sellerDetails.brUrl),
                                                        name: 'BR Document'
                                                    })}
                                                    className="p-2 hover:bg-blue-900/30 rounded-lg text-blue-400 transition-colors"
                                                    title="View"
                                                >
                                                    <Eye className="w-5 h-5" />
                                                </button>
                                                <button
                                                    onClick={() => handleDownloadFile(sellerDetails.brUrl, 'BR_Document')}
                                                    className="p-2 hover:bg-gray-700 rounded text-green-400"
                                                    title="Download"
                                                >
                                                    <Download className="w-5 h-5" />
                                                </button>
                                            </div>
                                        </div>
                                    )}

                                    {!sellerDetails.nicUrl && !sellerDetails.brUrl && (
                                        <p className="text-gray-400 text-sm">No verification documents uploaded</p>
                                    )}
                                </div>
                            </div>
                        </>
                    )}

                    {/* Buyer Details */}
                    {user.userType === 'buyer' && (
                        <div className="bg-gray-700/50 rounded-lg p-4">
                            <h3 className="text-lg font-bold text-primary mb-4">Buyer Information</h3>
                            <div className="grid grid-cols-2 gap-4 text-sm">
                                <div>
                                    <p className="text-gray-400">Phone</p>
                                    <p className="text-white font-semibold">{user.phoneNumber || 'N/A'}</p>
                                </div>
                                <div>
                                    <p className="text-gray-400">Address</p>
                                    <p className="text-white font-semibold">{user.address || 'N/A'}</p>
                                </div>
                            </div>
                        </div>
                    )}
                </div>
            </div>

            {/* File Preview Modal */}
            {previewFile && (
                <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-[60] p-4">
                    <div className="bg-gray-800 rounded-lg border border-gray-700 max-w-3xl w-full max-h-[80vh] overflow-y-auto">
                        <div className="bg-gray-900 border-b border-gray-700 p-4 flex items-center justify-between">
                            <h3 className="text-lg font-bold text-white">{previewFile.name}</h3>
                            <button
                                onClick={() => setPreviewFile(null)}
                                className="p-2 hover:bg-gray-700 rounded"
                            >
                                <X className="w-5 h-5 text-gray-300" />
                            </button>
                        </div>
                        <div className="p-4">
                            {previewFile.type === 'pdf' ? (
                                <iframe
                                    src={previewFile.url}
                                    className="w-full h-[60vh] rounded border border-gray-700"
                                    title={previewFile.name}
                                />
                            ) : (
                                <img
                                    src={previewFile.url}
                                    alt={previewFile.name}
                                    className="w-full h-auto max-h-[60vh] object-contain rounded border border-gray-700"
                                />
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

import { collection, query, where, getDocs } from 'firebase/firestore';
