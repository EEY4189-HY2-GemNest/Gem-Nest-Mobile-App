import React from 'react';
import { X, ExternalLink, Tag, Package, Users, Calendar } from 'lucide-react';

export default function ProductDetailsModal({ product, isOpen, onClose }) {
    if (!isOpen || !product) return null;

    const formatDate = (date) => {
        if (!date) return 'N/A';
        try {
            if (typeof date === 'object' && date.toDate) {
                return date.toDate().toLocaleDateString();
            } else if (date instanceof Date) {
                return date.toLocaleDateString();
            }
            return new Date(date).toLocaleDateString();
        } catch {
            return 'N/A';
        }
    };

    return (
        <div className="fixed inset-0 bg-black/70 z-50 flex items-center justify-center p-4">
            <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto border border-gray-700">
                {/* Header */}
                <div className="sticky top-0 bg-gradient-to-r from-gray-900 to-gray-800 border-b border-gray-700 flex items-center justify-between p-6">
                    <h2 className="text-2xl font-bold text-white">Product Details</h2>
                    <button
                        onClick={onClose}
                        className="p-2 hover:bg-gray-700 rounded-lg transition-colors"
                    >
                        <X className="w-6 h-6 text-gray-400" />
                    </button>
                </div>

                {/* Content */}
                <div className="p-6 space-y-6">
                    {/* Image Section */}
                    {product.imageUrl && (
                        <div className="relative rounded-xl overflow-hidden bg-gray-700/50">
                            <img
                                src={product.imageUrl}
                                alt={product.title}
                                className="w-full h-80 object-cover"
                            />
                        </div>
                    )}

                    {/* Title and Description */}
                    <div className="space-y-3">
                        <h3 className="text-3xl font-bold text-white">{product.title || 'Untitled Product'}</h3>
                        <p className="text-gray-300 text-base leading-relaxed">
                            {product.description || 'No description provided'}
                        </p>
                    </div>

                    {/* Price and Status Section */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="bg-gradient-to-br from-blue-900/30 to-blue-900/10 border border-blue-700/30 rounded-xl p-4">
                            <p className="text-gray-400 text-xs uppercase tracking-wide font-semibold mb-2">Total Price</p>
                            <p className="text-3xl font-bold text-blue-400">
                                Rs {product.pricing ? product.pricing.toLocaleString() : 'N/A'}
                            </p>
                        </div>
                        <div className="bg-gradient-to-br from-green-900/30 to-green-900/10 border border-green-700/30 rounded-xl p-4">
                            <p className="text-gray-400 text-xs uppercase tracking-wide font-semibold mb-2">Status</p>
                            <span className={`inline-flex items-center px-3 py-2 rounded-lg font-bold ${
                                product.isActive !== false 
                                    ? 'bg-green-900/40 text-green-300 border border-green-700/50' 
                                    : 'bg-red-900/40 text-red-300 border border-red-700/50'
                            }`}>
                                {product.isActive !== false ? 'Active' : 'Inactive'}
                            </span>
                        </div>
                    </div>

                    {/* Product Details Grid */}
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                        {/* Gem Type */}
                        {product.gemType && (
                            <div className="bg-gray-700/30 rounded-lg border border-gray-600/50 p-4">
                                <p className="text-gray-400 text-xs uppercase tracking-wide font-semibold mb-2 flex items-center gap-2">
                                    <Tag className="w-4 h-4" /> Gem Type
                                </p>
                                <p className="text-white font-medium">{product.gemType}</p>
                            </div>
                        )}

                        {/* Weight */}
                        {product.weight && (
                            <div className="bg-gray-700/30 rounded-lg border border-gray-600/50 p-4">
                                <p className="text-gray-400 text-xs uppercase tracking-wide font-semibold mb-2 flex items-center gap-2">
                                    <Package className="w-4 h-4" /> Weight
                                </p>
                                <p className="text-white font-medium">{product.weight} carat</p>
                            </div>
                        )}

                        {/* Color */}
                        {product.color && (
                            <div className="bg-gray-700/30 rounded-lg border border-gray-600/50 p-4">
                                <p className="text-gray-400 text-xs uppercase tracking-wide font-semibold mb-2">Color</p>
                                <p className="text-white font-medium">{product.color}</p>
                            </div>
                        )}

                        {/* Clarity */}
                        {product.clarity && (
                            <div className="bg-gray-700/30 rounded-lg border border-gray-600/50 p-4">
                                <p className="text-gray-400 text-xs uppercase tracking-wide font-semibold mb-2">Clarity</p>
                                <p className="text-white font-medium">{product.clarity}</p>
                            </div>
                        )}

                        {/* Cut */}
                        {product.cut && (
                            <div className="bg-gray-700/30 rounded-lg border border-gray-600/50 p-4">
                                <p className="text-gray-400 text-xs uppercase tracking-wide font-semibold mb-2">Cut</p>
                                <p className="text-white font-medium">{product.cut}</p>
                            </div>
                        )}

                        {/* Certification */}
                        {product.certification && (
                            <div className="bg-gray-700/30 rounded-lg border border-gray-600/50 p-4">
                                <p className="text-gray-400 text-xs uppercase tracking-wide font-semibold mb-2">Certification</p>
                                <p className="text-white font-medium">{product.certification}</p>
                            </div>
                        )}
                    </div>

                    {/* Seller and Dates */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {/* Seller ID */}
                        <div className="bg-gray-700/30 rounded-lg border border-gray-600/50 p-4">
                            <p className="text-gray-400 text-xs uppercase tracking-wide font-semibold mb-2 flex items-center gap-2">
                                <Users className="w-4 h-4" /> Seller ID
                            </p>
                            <p className="text-white font-mono text-sm break-all">{product.sellerId || 'Unknown'}</p>
                        </div>

                        {/* Listed Date */}
                        {product.createdAt && (
                            <div className="bg-gray-700/30 rounded-lg border border-gray-600/50 p-4">
                                <p className="text-gray-400 text-xs uppercase tracking-wide font-semibold mb-2 flex items-center gap-2">
                                    <Calendar className="w-4 h-4" /> Listed Date
                                </p>
                                <p className="text-white font-medium">{formatDate(product.createdAt)}</p>
                            </div>
                        )}
                    </div>

                    {/* Certificate URL */}
                    {product.certificateUrl && (
                        <div className="bg-teal-900/20 border border-teal-700/50 rounded-xl p-4">
                            <p className="text-gray-400 text-xs uppercase tracking-wide font-semibold mb-3 flex items-center gap-2">
                                <ExternalLink className="w-4 h-4" /> Certificate Information
                            </p>
                            <a
                                href={product.certificateUrl}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="text-teal-400 hover:text-teal-300 text-sm break-all transition-colors flex items-center gap-2"
                            >
                                <ExternalLink className="w-4 h-4 flex-shrink-0" />
                                View Certificate
                            </a>
                        </div>
                    )}

                    {/* Additional Fields */}
                    {product.size && (
                        <div className="bg-gray-700/30 rounded-lg border border-gray-600/50 p-4">
                            <p className="text-gray-400 text-xs uppercase tracking-wide font-semibold mb-2">Size</p>
                            <p className="text-white font-medium">{product.size}</p>
                        </div>
                    )}

                    {/* Approval Status */}
                    {product.approvalStatus && (
                        <div className="bg-gray-700/30 rounded-lg border border-gray-600/50 p-4">
                            <p className="text-gray-400 text-xs uppercase tracking-wide font-semibold mb-2">Approval Status</p>
                            <span className={`inline-flex px-3 py-1 rounded-full text-sm font-bold ${
                                product.approvalStatus === 'approved' 
                                    ? 'bg-green-900/40 text-green-300' 
                                    : product.approvalStatus === 'rejected'
                                    ? 'bg-red-900/40 text-red-300'
                                    : 'bg-yellow-900/40 text-yellow-300'
                            }`}>
                                {product.approvalStatus.charAt(0).toUpperCase() + product.approvalStatus.slice(1)}
                            </span>
                        </div>
                    )}
                </div>

                {/* Footer */}
                <div className="sticky bottom-0 bg-gradient-to-r from-gray-900 to-gray-800 border-t border-gray-700 p-6 flex justify-end gap-3">
                    <button
                        onClick={onClose}
                        className="px-6 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg font-bold transition-colors"
                    >
                        Close
                    </button>
                </div>
            </div>
        </div>
    );
}
