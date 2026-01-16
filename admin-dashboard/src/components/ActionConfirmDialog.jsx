import React from 'react';
import { X, AlertTriangle, CheckCircle, Trash2 } from 'lucide-react';

export default function ActionConfirmDialog({
    type = 'confirm', // 'confirm', 'warning', 'danger', 'success'
    title,
    message,
    actionText = 'Confirm',
    onConfirm,
    onCancel,
    isLoading = false
}) {
    const getConfig = () => {
        switch (type) {
            case 'danger':
                return {
                    bgColor: 'from-red-900/20 to-red-900/10',
                    borderColor: 'border-red-700/30',
                    iconColor: 'text-red-400',
                    buttonColor: 'bg-red-600 hover:bg-red-700',
                    icon: AlertTriangle
                };
            case 'warning':
                return {
                    bgColor: 'from-yellow-900/20 to-yellow-900/10',
                    borderColor: 'border-yellow-700/30',
                    iconColor: 'text-yellow-400',
                    buttonColor: 'bg-yellow-600 hover:bg-yellow-700',
                    icon: AlertTriangle
                };
            case 'success':
                return {
                    bgColor: 'from-green-900/20 to-green-900/10',
                    borderColor: 'border-green-700/30',
                    iconColor: 'text-green-400',
                    buttonColor: 'bg-green-600 hover:bg-green-700',
                    icon: CheckCircle
                };
            default:
                return {
                    bgColor: 'from-blue-900/20 to-blue-900/10',
                    borderColor: 'border-blue-700/30',
                    iconColor: 'text-blue-400',
                    buttonColor: 'bg-blue-600 hover:bg-blue-700',
                    icon: CheckCircle
                };
        }
    };

    const config = getConfig();
    const Icon = config.icon;

    return (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
            <div className={`bg-gradient-to-br ${config.bgColor} border ${config.borderColor} rounded-2xl shadow-2xl w-full max-w-md mx-4 p-0 overflow-hidden`}>
                {/* Header */}
                <div className={`bg-gradient-to-r ${config.bgColor} border-b ${config.borderColor} px-6 py-4 flex items-center justify-between`}>
                    <div className="flex items-center gap-3">
                        <Icon className={`w-6 h-6 ${config.iconColor}`} />
                        <h2 className="text-xl font-bold text-white">
                            {title}
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
                        {message}
                    </p>

                    {type === 'danger' && (
                        <div className="bg-red-900/20 border border-red-700/30 rounded-lg p-4">
                            <p className="text-red-300 text-sm flex items-center gap-2">
                                <AlertTriangle className="w-4 h-4" />
                                This action cannot be undone
                            </p>
                        </div>
                    )}
                </div>

                {/* Footer */}
                <div className={`bg-gradient-to-r from-gray-900/50 to-gray-800/50 border-t ${config.borderColor} px-6 py-4 flex items-center justify-end gap-3`}>
                    <button
                        onClick={onCancel}
                        disabled={isLoading}
                        className="px-6 py-2 rounded-lg font-semibold text-gray-200 bg-gray-700/40 hover:bg-gray-700/60 border border-gray-600 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        Cancel
                    </button>
                    <button
                        onClick={onConfirm}
                        disabled={isLoading}
                        className={`px-6 py-2 rounded-lg font-semibold text-white ${config.buttonColor} transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2`}
                    >
                        {isLoading ? (
                            <>
                                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                                Processing...
                            </>
                        ) : (
                            actionText
                        )}
                    </button>
                </div>
            </div>
        </div>
    );
}
