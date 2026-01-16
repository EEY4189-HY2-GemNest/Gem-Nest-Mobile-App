import React, { useState } from 'react';
import { X, Download, Eye, AlertCircle, CheckCircle, Clock, FileText } from 'lucide-react';

export default function SellerDetailsModal({ seller, onClose }) {
    const [selectedImage, setSelectedImage] = useState(null);
    const [downloadingId, setDownloadingId] = useState(null);

    const handleDownload = (url, downloadId) => {
        if (!url) return;
        
        setDownloadingId(downloadId);
        
        try {
            // Ensure the URL has alt=media parameter
            const downloadUrl = url.includes('alt=media') ? url : `${url}?alt=media`;
            
            // Create a temporary anchor element to trigger download
            const link = document.createElement('a');
            link.href = downloadUrl;
            link.style.display = 'none';
            
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            // Success feedback
            setTimeout(() => setDownloadingId(null), 500);
        } catch (error) {
            console.error('Download error:', error);
            // Fallback: open in new tab if direct download fails
            const downloadUrl = url.includes('alt=media') ? url : `${url}?alt=media`;
            window.open(downloadUrl, '_blank');
            setDownloadingId(null);
        }
    };

    const getVerificationStatus = () => {
        if (seller.verified) return { status: 'Verified', color: 'bg-green-900/40 text-green-300 border-green-700' };
        if (seller.verificationStatus === 'rejected') return { status: 'Rejected', color: 'bg-red-900/40 text-red-300 border-red-700' };
        return { status: 'Pending', color: 'bg-yellow-900/40 text-yellow-300 border-yellow-700' };
    };

    const docStatus = getVerificationStatus();

    return (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
            <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-y-auto border border-gray-700">
                {/* Header */}
                <div className="sticky top-0 bg-gradient-to-r from-gray-800 to-gray-900 border-b border-gray-700 px-6 py-4 flex items-center justify-between">
                    <h2 className="text-2xl font-bold text-white">Seller Details</h2>
                    <button
                        onClick={onClose}
                        className="text-gray-400 hover:text-gray-200 transition-colors"
                    >
                        <X className="w-6 h-6" />
                    </button>
                </div>

                {/* Content */}
                <div className="p-6 space-y-6">
                    {/* Basic Info */}
                    <div className="bg-gray-700/30 rounded-xl p-6 border border-gray-600/30 space-y-4">
                        <h3 className="text-lg font-bold text-white flex items-center gap-2">
                            <div className="p-2 bg-blue-900/30 rounded-lg">
                                <FileText className="w-5 h-5 text-blue-400" />
                            </div>
                            Basic Information
                        </h3>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <p className="text-gray-400 text-sm mb-1">Display Name</p>
                                <p className="text-white font-semibold text-lg">{seller.displayName || 'N/A'}</p>
                            </div>
                            <div>
                                <p className="text-gray-400 text-sm mb-1">Email</p>
                                <p className="text-white font-semibold text-lg">{seller.email || 'N/A'}</p>
                            </div>
                            <div>
                                <p className="text-gray-400 text-sm mb-1">Phone Number</p>
                                <p className="text-white font-semibold text-lg">{seller.phoneNumber || 'N/A'}</p>
                            </div>
                            <div>
                                <p className="text-gray-400 text-sm mb-1">Firebase UID</p>
                                <p className="text-white font-mono text-sm break-all">{seller.firebaseUid || 'N/A'}</p>
                            </div>
                        </div>
                    </div>

                    {/* Business Info */}
                    <div className="bg-gray-700/30 rounded-xl p-6 border border-gray-600/30 space-y-4">
                        <h3 className="text-lg font-bold text-white flex items-center gap-2">
                            <div className="p-2 bg-purple-900/30 rounded-lg">
                                <FileText className="w-5 h-5 text-purple-400" />
                            </div>
                            Business Information
                        </h3>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <p className="text-gray-400 text-sm mb-1">Business Name</p>
                                <p className="text-white font-semibold text-lg">{seller.businessName || 'N/A'}</p>
                            </div>
                            <div>
                                <p className="text-gray-400 text-sm mb-1">Business Registration (BR) Number</p>
                                <p className="text-white font-semibold text-lg font-mono">{seller.brNumber || 'N/A'}</p>
                            </div>
                            <div>
                                <p className="text-gray-400 text-sm mb-1">NIC Number</p>
                                <p className="text-white font-semibold text-lg font-mono">{seller.nicNumber || 'N/A'}</p>
                            </div>
                            <div>
                                <p className="text-gray-400 text-sm mb-1">Verification Status</p>
                                <span className={`inline-flex items-center gap-2 px-3 py-1 rounded-full text-sm font-bold border ${docStatus.color}`}>
                                    {docStatus.status === 'Verified' ? (
                                        <CheckCircle className="w-4 h-4" />
                                    ) : docStatus.status === 'Rejected' ? (
                                        <AlertCircle className="w-4 h-4" />
                                    ) : (
                                        <Clock className="w-4 h-4" />
                                    )}
                                    {docStatus.status}
                                </span>
                            </div>
                        </div>
                    </div>

                    {/* NIC Document */}
                    <div className="bg-gray-700/30 rounded-xl p-6 border border-gray-600/30 space-y-4">
                        <h3 className="text-lg font-bold text-white flex items-center gap-2">
                            <div className="p-2 bg-cyan-900/30 rounded-lg">
                                <FileText className="w-5 h-5 text-cyan-400" />
                            </div>
                            NIC (National Identity Card) Document
                        </h3>

                        {seller.nicDocumentUrl ? (
                            <div className="space-y-4">
                                {/* Document Preview */}
                                <div className="bg-gray-800/50 rounded-lg p-4 border border-gray-600/30">
                                    {seller.nicDocumentUrl.match(/\.(jpg|jpeg|png|gif)$/i) ? (
                                        <div>
                                            <p className="text-gray-400 text-sm mb-3">Document Preview:</p>
                                            <img
                                                src={seller.nicDocumentUrl}
                                                alt="NIC Document"
                                                className="w-full max-h-64 object-contain rounded-lg cursor-pointer hover:opacity-90 transition-opacity"
                                                onClick={() => setSelectedImage({ url: seller.nicDocumentUrl, name: 'NIC Document' })}
                                            />
                                        </div>
                                    ) : (
                                        <div className="flex items-center gap-3 p-4 bg-gray-700/40 rounded-lg border border-gray-600/30">
                                            <FileText className="w-8 h-8 text-cyan-400" />
                                            <div className="flex-1">
                                                <p className="text-white font-semibold">NIC Document</p>
                                                <p className="text-gray-400 text-sm">PDF or other document format</p>
                                            </div>
                                        </div>
                                    )}
                                </div>

                                {/* Action Buttons */}
                                <div className="flex gap-2">
                                    <button
                                        onClick={() => window.open(seller.nicDocumentUrl, '_blank')}
                                        className="flex-1 px-4 py-2 bg-cyan-600 hover:bg-cyan-700 text-white rounded-lg font-semibold flex items-center justify-center gap-2 transition-all"
                                    >
                                        <Eye className="w-4 h-4" />
                                        View
                                    </button>
                                    <button
                                        onClick={() => handleDownload(seller.nicDocumentUrl, 'nic')}
                                        disabled={downloadingId === 'nic'}
                                        className="flex-1 px-4 py-2 bg-cyan-600 hover:bg-cyan-700 text-white rounded-lg font-semibold flex items-center justify-center gap-2 transition-all disabled:opacity-50"
                                    >
                                        {downloadingId === 'nic' ? (
                                            <>
                                                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                                                Downloading...
                                            </>
                                        ) : (
                                            <>
                                                <Download className="w-4 h-4" />
                                                Download
                                            </>
                                        )}
                                    </button>
                                </div>
                            </div>
                        ) : (
                            <div className="flex items-center gap-3 p-4 bg-red-900/20 border border-red-700/30 rounded-lg">
                                <AlertCircle className="w-5 h-5 text-red-400 flex-shrink-0" />
                                <p className="text-red-300">No NIC document uploaded</p>
                            </div>
                        )}
                    </div>

                    {/* Business Registration Document */}
                    <div className="bg-gray-700/30 rounded-xl p-6 border border-gray-600/30 space-y-4">
                        <h3 className="text-lg font-bold text-white flex items-center gap-2">
                            <div className="p-2 bg-orange-900/30 rounded-lg">
                                <FileText className="w-5 h-5 text-orange-400" />
                            </div>
                            Business Registration (BR) Document
                        </h3>

                        {seller.businessRegistrationUrl ? (
                            <div className="space-y-4">
                                {/* Document Preview */}
                                <div className="bg-gray-800/50 rounded-lg p-4 border border-gray-600/30">
                                    {seller.businessRegistrationUrl.match(/\.(jpg|jpeg|png|gif)$/i) ? (
                                        <div>
                                            <p className="text-gray-400 text-sm mb-3">Document Preview:</p>
                                            <img
                                                src={seller.businessRegistrationUrl}
                                                alt="Business Registration Document"
                                                className="w-full max-h-64 object-contain rounded-lg cursor-pointer hover:opacity-90 transition-opacity"
                                                onClick={() => setSelectedImage({ url: seller.businessRegistrationUrl, name: 'Business Registration Document' })}
                                            />
                                        </div>
                                    ) : (
                                        <div className="flex items-center gap-3 p-4 bg-gray-700/40 rounded-lg border border-gray-600/30">
                                            <FileText className="w-8 h-8 text-orange-400" />
                                            <div className="flex-1">
                                                <p className="text-white font-semibold">Business Registration Document</p>
                                                <p className="text-gray-400 text-sm">PDF or other document format</p>
                                            </div>
                                        </div>
                                    )}
                                </div>

                                {/* Action Buttons */}
                                <div className="flex gap-2">
                                    <button
                                        onClick={() => window.open(seller.businessRegistrationUrl, '_blank')}
                                        className="flex-1 px-4 py-2 bg-orange-600 hover:bg-orange-700 text-white rounded-lg font-semibold flex items-center justify-center gap-2 transition-all"
                                    >
                                        <Eye className="w-4 h-4" />
                                        View
                                    </button>
                                    <button
                                        onClick={() => handleDownload(seller.businessRegistrationUrl, 'br')}
                                        disabled={downloadingId === 'br'}
                                        className="flex-1 px-4 py-2 bg-orange-600 hover:bg-orange-700 text-white rounded-lg font-semibold flex items-center justify-center gap-2 transition-all disabled:opacity-50"
                                    >
                                        {downloadingId === 'br' ? (
                                            <>
                                                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                                                Downloading...
                                            </>
                                        ) : (
                                            <>
                                                <Download className="w-4 h-4" />
                                                Download
                                            </>
                                        )}
                                    </button>
                                </div>
                            </div>
                        ) : (
                            <div className="flex items-center gap-3 p-4 bg-red-900/20 border border-red-700/30 rounded-lg">
                                <AlertCircle className="w-5 h-5 text-red-400 flex-shrink-0" />
                                <p className="text-red-300">No Business Registration document uploaded</p>
                            </div>
                        )}
                    </div>

                    {/* Rejection Reason (if rejected) */}
                    {seller.rejectionReason && (
                        <div className="bg-red-900/20 rounded-xl p-6 border border-red-700/30 space-y-2">
                            <h3 className="text-lg font-bold text-red-300 flex items-center gap-2">
                                <AlertCircle className="w-5 h-5" />
                                Rejection Reason
                            </h3>
                            <p className="text-red-200">{seller.rejectionReason}</p>
                        </div>
                    )}
                </div>
            </div>

            {/* Image Viewer Modal */}
            {selectedImage && (
                <div
                    className="fixed inset-0 bg-black/80 flex items-center justify-center z-[60] p-4"
                    onClick={() => setSelectedImage(null)}
                >
                    <div className="max-w-4xl w-full" onClick={(e) => e.stopPropagation()}>
                        <div className="relative">
                            <button
                                onClick={() => setSelectedImage(null)}
                                className="absolute -top-12 right-0 text-gray-400 hover:text-gray-200"
                            >
                                <X className="w-8 h-8" />
                            </button>
                            <img
                                src={selectedImage.url}
                                alt={selectedImage.name}
                                className="w-full rounded-lg"
                            />
                            <p className="text-gray-400 text-sm mt-3 text-center">{selectedImage.name}</p>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
