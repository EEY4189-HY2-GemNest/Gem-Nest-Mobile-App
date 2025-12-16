import React from 'react';
import { AlertTriangle, X } from 'lucide-react';

export default function ConfirmDialog({ title, message, action, onConfirm, onCancel, isLoading, isDangerous }) {
    return (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-gray-800 rounded-lg border border-gray-700 max-w-md w-full">
                <div className="bg-gray-900 border-b border-gray-700 p-4 flex items-center gap-3">
                    {isDangerous && <AlertTriangle className="w-6 h-6 text-red-500" />}
                    <h2 className="text-lg font-bold text-white">{title}</h2>
                </div>

                <div className="p-6">
                    <p className="text-gray-300 mb-6">{message}</p>

                    <div className="flex gap-3 justify-end">
                        <button
                            onClick={onCancel}
                            disabled={isLoading}
                            className="px-4 py-2 rounded-lg bg-gray-700 hover:bg-gray-600 text-white font-semibold transition disabled:opacity-50"
                        >
                            Cancel
                        </button>
                        <button
                            onClick={onConfirm}
                            disabled={isLoading}
                            className={`px-4 py-2 rounded-lg font-semibold transition disabled:opacity-50 flex items-center gap-2 ${isDangerous
                                    ? 'bg-red-600 hover:bg-red-700 text-white'
                                    : 'bg-green-600 hover:bg-green-700 text-white'
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
