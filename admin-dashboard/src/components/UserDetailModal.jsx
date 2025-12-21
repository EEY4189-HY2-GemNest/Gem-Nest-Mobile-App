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
            <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
                <div className="bg-gray-800 rounded-lg p-8 border border-gray-700 text-center">
                    <p className="text-gray-300">Loading...</p>
                </div>
            </div>
        );
    }

    return (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-gray-800 rounded-lg border border-gray-700 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
                {/* Header */}
                <div className="sticky top-0 bg-gray-900 border-b border-gray-700 p-6 flex items-center justify-between">
                    <h2 className="text-2xl font-bold text-white">User Details</h2>
                    <button
                        onClick={onClose}
                        className="p-2 hover:bg-gray-700 rounded-lg transition"
                    >
                        <X className="w-6 h-6 text-gray-300" />
                    </button>
                </div>

                {/* Content */}
                <div className="p-6 space-y-6">
                    {/* Basic Info */}
                    <div className="bg-gray-700/50 rounded-lg p-4">
                        <h3 className="text-lg font-bold text-primary mb-4">Basic Information</h3>
                        <div className="grid grid-cols-2 gap-4">
                            <div>
                                <p className="text-gray-400 text-sm">Email</p>
                                <p className="text-white font-semibold">{user.email || 'N/A'}</p>
                            </div>
                            <div>
                                <p className="text-gray-400 text-sm">Name</p>
                                <p className="text-white font-semibold">{user.name || 'N/A'}</p>
                            </div>
                            <div>
                                <p className="text-gray-400 text-sm">User Type</p>
                                <p className="text-white font-semibold capitalize">{user.userType || 'Unknown'}</p>
                            </div>
                            <div>
                                <p className="text-gray-400 text-sm">Status</p>
                                <span className={`px-3 py-1 rounded-full text-xs font-semibold ${user.isActive !== false
                                        ? 'bg-green-900 text-green-300'
                                        : 'bg-red-900 text-red-300'
                                    }`}>
                                    {user.status || (user.isActive !== false ? 'Active' : 'Inactive')}
                                </span>
                            </div>
                        </div>
                    </div>

                    {/* Seller Details */}
                    {user.userType === 'seller' && sellerDetails && (
                        <>
                            <div className="bg-gray-700/50 rounded-lg p-4">
                                <h3 className="text-lg font-bold text-primary mb-4">Seller Information</h3>
                                <div className="grid grid-cols-2 gap-4 text-sm">
                                    <div>
                                        <p className="text-gray-400">Business Name</p>
                                        <p className="text-white font-semibold">{sellerDetails.businessName || 'N/A'}</p>
                                    </div>
                                    <div>
                                        <p className="text-gray-400">Phone</p>
                                        <p className="text-white font-semibold">{sellerDetails.phoneNumber || 'N/A'}</p>
                                    </div>
                                    <div>
                                        <p className="text-gray-400">Address</p>
                                        <p className="text-white font-semibold">{sellerDetails.address || 'N/A'}</p>
                                    </div>
                                    <div>
                                        <p className="text-gray-400">Verified</p>
                                        <span className={`px-2 py-1 rounded text-xs font-semibold ${sellerDetails.verified ? 'bg-green-900 text-green-300' : 'bg-yellow-900 text-yellow-300'
                                            }`}>
                                            {sellerDetails.verified ? 'Verified' : 'Pending'}
                                        </span>
                                    </div>
                                </div>
                            </div>

                            {/* Seller Stats */}
                            <div className="bg-gray-700/50 rounded-lg p-4">
                                <h3 className="text-lg font-bold text-primary mb-4">Seller Statistics</h3>
                                <div className="grid grid-cols-3 gap-4">
                                    <div className="text-center">
                                        <p className="text-3xl font-bold text-primary">{productCount}</p>
                                        <p className="text-gray-400 text-sm">Products Listed</p>
                                    </div>
                                    <div className="text-center">
                                        <p className="text-3xl font-bold text-primary">{auctionCount}</p>
                                        <p className="text-gray-400 text-sm">Auctions Listed</p>
                                    </div>
                                    <div className="text-center">
                                        <p className="text-3xl font-bold text-primary">{sellerDetails.rating || 0}</p>
                                        <p className="text-gray-400 text-sm">Rating</p>
                                    </div>
                                </div>
                            </div>

                            {/* Verification Documents */}
                            <div className="bg-gray-700/50 rounded-lg p-4">
                                <h3 className="text-lg font-bold text-primary mb-4">Verification Documents</h3>
                                <div className="space-y-3">
                                    {/* NIC Document */}
                                    {sellerDetails.nicUrl && (
                                        <div className="bg-gray-600/50 rounded-lg p-3 flex items-center justify-between">
                                            <div className="flex items-center gap-3">
                                                {getFileType(sellerDetails.nicUrl) === 'pdf' ? (
                                                    <FileText className="w-6 h-6 text-red-400" />
                                                ) : (
                                                    <ImageIcon className="w-6 h-6 text-blue-400" />
                                                )}
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
                                                    className="p-2 hover:bg-gray-700 rounded text-blue-400"
                                                    title="View"
                                                >
                                                    <Eye className="w-5 h-5" />
                                                </button>
                                                <button
                                                    onClick={() => handleDownloadFile(sellerDetails.nicUrl, 'NIC_Document')}
                                                    className="p-2 hover:bg-gray-700 rounded text-green-400"
                                                    title="Download"
                                                >
                                                    <Download className="w-5 h-5" />
                                                </button>
                                            </div>
                                        </div>
                                    )}

                                    {/* BR Document */}
                                    {sellerDetails.brUrl && (
                                        <div className="bg-gray-600/50 rounded-lg p-3 flex items-center justify-between">
                                            <div className="flex items-center gap-3">
                                                {getFileType(sellerDetails.brUrl) === 'pdf' ? (
                                                    <FileText className="w-6 h-6 text-red-400" />
                                                ) : (
                                                    <ImageIcon className="w-6 h-6 text-blue-400" />
                                                )}
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
                                                    className="p-2 hover:bg-gray-700 rounded text-blue-400"
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
