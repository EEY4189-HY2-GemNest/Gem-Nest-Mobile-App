import React from 'react';
import { AlertTriangle, X } from 'lucide-react';

export default function ConfirmDialog({ title, message, action, onConfirm, onCancel, isLoading, isDangerous }) {
    return (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
            <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl border border-gray-700 max-w-md w-full shadow-2xl">
                <div className="bg-gradient-to-r from-gray-900 to-gray-800 border-b border-gray-700 p-6 flex items-center gap-3">
                    {isDangerous && (
                        <div className="p-2 bg-red-900/30 rounded-lg">
                            <AlertTriangle className="w-6 h-6 text-red-400" />
                        </div>
                    )}
                    <h2 className="text-xl font-bold text-white">{title}</h2>
                </div>

                <div className="p-6 space-y-4">
                    <p className="text-gray-300 leading-relaxed">{message}</p>

                    <div className="flex gap-3 justify-end pt-4">
                        <button
                            onClick={onCancel}
                            disabled={isLoading}
                            className="px-5 py-2 rounded-lg bg-gray-700 hover:bg-gray-600 text-white font-semibold transition-all duration-200 disabled:opacity-50"
                        >
                            Cancel
                        </button>
                        <button
                            onClick={onConfirm}
                            disabled={isLoading}
                            className={`px-5 py-2 rounded-lg font-semibold transition-all duration-200 disabled:opacity-50 flex items-center gap-2 ${isDangerous
                                ? 'bg-gradient-to-r from-red-600 to-red-700 hover:from-red-700 hover:to-red-800 text-white shadow-lg hover:shadow-red-900/30'
                                : 'bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800 text-white shadow-lg hover:shadow-green-900/30'
                                }`}
                        >
                            {isLoading ? (
                                <>
                                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                                    Processing...
                                </>
                            ) : (
                                action
                            )}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
