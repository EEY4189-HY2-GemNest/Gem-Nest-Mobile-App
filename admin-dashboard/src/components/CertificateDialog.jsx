import React, { useState } from 'react';
import { X, AlertTriangle, CheckCircle } from 'lucide-react';

export default function CertificateDialog({ type, productName, onConfirm, onCancel, isLoading }) {
    const [reason, setReason] = useState('');
    const [error, setError] = useState('');

    const handleConfirm = () => {
        if (type === 'reject' && !reason.trim()) {
            setError('Please enter a rejection reason');
            return;
        }
        onConfirm(reason);
    };

    const isVerify = type === 'verify';
    const bgColor = isVerify ? 'from-green-900/20 to-green-900/10' : 'from-red-900/20 to-red-900/10';
    const borderColor = isVerify ? 'border-green-700/30' : 'border-red-700/30';
    const iconColor = isVerify ? 'text-green-400' : 'text-red-400';
    const buttonColor = isVerify 
        ? 'bg-green-600 hover:bg-green-700' 
        : 'bg-red-600 hover:bg-red-700';

    return (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
            <div className={`bg-gradient-to-br ${bgColor} border ${borderColor} rounded-2xl shadow-2xl w-full max-w-md mx-4 p-0 overflow-hidden`}>
                {/* Header */}
                <div className={`bg-gradient-to-r ${bgColor} border-b ${borderColor} px-6 py-4 flex items-center justify-between`}>
                    <div className="flex items-center gap-3">
                        {isVerify ? (
                            <CheckCircle className={`w-6 h-6 ${iconColor}`} />
                        ) : (
                            <AlertTriangle className={`w-6 h-6 ${iconColor}`} />
                        )}
                        <h2 className="text-xl font-bold text-white">
                            {isVerify ? 'Verify Certificate' : 'Reject Certificate'}
                        </h2>
                    </div>
                    <button
                        onClick={onCancel}
                        disabled={isLoading}
                        className="text-gray-400 hover:text-gray-200 transition-colors disabled:opacity-50"
                    >
                        <X className="w-6 h-6" />
                    </button>
                </div>

                {/* Content */}
                <div className="px-6 py-6 space-y-4">
                    <p className="text-gray-300">
                        {isVerify
                            ? `Are you sure you want to verify the certificate for "${productName}"?`
                            : `You are about to reject the certificate for "${productName}".`
                        }
                    </p>

                    {!isVerify && (
                        <div className="space-y-2">
                            <label className="block text-sm font-semibold text-gray-200">
                                Rejection Reason
                            </label>
                            <textarea
                                value={reason}
                                onChange={(e) => {
                                    setReason(e.target.value);
                                    setError('');
                                }}
                                placeholder="Explain why you're rejecting this certificate..."
                                className="w-full px-4 py-3 bg-gray-700/50 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all resize-none"
                                rows="4"
                                disabled={isLoading}
                            />
                            {error && (
                                <p className="text-red-400 text-sm flex items-center gap-2">
                                    <AlertTriangle className="w-4 h-4" />
                                    {error}
                                </p>
                            )}
                        </div>
                    )}

                    {isVerify && (
                        <div className="bg-green-900/20 border border-green-700/30 rounded-lg p-4">
                            <p className="text-green-300 text-sm flex items-center gap-2">
                                <CheckCircle className="w-4 h-4" />
                                This certificate will be marked as verified
                            </p>
                        </div>
                    )}

                    {!isVerify && (
                        <div className="bg-red-900/20 border border-red-700/30 rounded-lg p-4">
                            <p className="text-red-300 text-sm flex items-center gap-2">
                                <AlertTriangle className="w-4 h-4" />
                                The seller will be notified of this rejection
                            </p>
                        </div>
                    )}
                </div>

                {/* Footer */}
                <div className={`bg-gradient-to-r from-gray-900/50 to-gray-800/50 border-t ${borderColor} px-6 py-4 flex items-center justify-end gap-3`}>
                    <button
                        onClick={onCancel}
                        disabled={isLoading}
                        className="px-6 py-2 rounded-lg font-semibold text-gray-200 bg-gray-700/40 hover:bg-gray-700/60 border border-gray-600 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        Cancel
                    </button>
                    <button
                        onClick={handleConfirm}
                        disabled={isLoading}
                        className={`px-6 py-2 rounded-lg font-semibold text-white ${buttonColor} transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2`}
                    >
                        {isLoading ? (
                            <>
                                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                                {isVerify ? 'Verifying...' : 'Rejecting...'}
                            </>
                        ) : (
                            isVerify ? 'Verify Certificate' : 'Reject Certificate'
                        )}
                    </button>
                </div>
            </div>
        </div>
    );
}
