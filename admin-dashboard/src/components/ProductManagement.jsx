import React, { useState, useEffect } from 'react';
import { getAllProducts, removeProduct } from '../services/adminService';
import { Trash2, AlertCircle, Loader } from 'lucide-react';

export default function ProductManagement() {
    const [products, setProducts] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [actionLoading, setActionLoading] = useState(null);
    const [message, setMessage] = useState('');

    useEffect(() => {
        fetchProducts();
    }, []);

    const fetchProducts = async () => {
        try {
            setLoading(true);
            const data = await getAllProducts();
            setProducts(data);
        } catch (error) {
            setMessage('Error fetching products: ' + error.message);
        } finally {
            setLoading(false);
        }
    };

    const handleRemove = async (productId) => {
        if (!window.confirm('Are you sure you want to remove this product?')) return;

        try {
            setActionLoading(productId);
            await removeProduct(productId);
            setProducts(products.map(p => p.id === productId ? { ...p, isActive: false } : p));
            setMessage('Product removed');
            setTimeout(() => setMessage(''), 3000);
        } catch (error) {
            setMessage('Error removing product: ' + error.message);
        } finally {
            setActionLoading(null);
        }
    };

    const filteredProducts = products.filter(product =>
        product.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        product.description?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    if (loading) {
        return <div className="text-center text-gray-400">Loading products...</div>;
    }

    return (
        <div className="space-y-6">
            <div>
                <h2 className="text-4xl font-bold text-white mb-2">Product Management</h2>
                <p className="text-gray-400 text-lg">Manage listed products and auctions</p>
            </div>

            {message && (
                <div className="bg-gradient-to-r from-green-900/30 to-green-900/10 border border-green-500 rounded-xl p-4 flex items-center gap-3">
                    <div className="p-2 bg-green-900/40 rounded-lg">
                        <AlertCircle className="w-5 h-5 text-green-400" />
                    </div>
                    <p className="text-green-200">{message}</p>
                </div>
            )}

            <div className="bg-gradient-to-r from-gray-800 to-gray-900 rounded-xl p-4 border border-gray-700 shadow-lg">
                <input
                    type="text"
                    placeholder="Search by product name..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full px-4 py-3 bg-gray-700/50 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all"
                />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {filteredProducts.length === 0 ? (
                    <div className="col-span-full text-center text-gray-400 py-12">
                        <p className="text-lg">No products found</p>
                    </div>
                ) : (
                    filteredProducts.map((product) => (
                        <div
                            key={product.id}
                            className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl border border-gray-700 overflow-hidden hover:border-gray-600 transition-all duration-300 shadow-lg hover:shadow-xl hover:shadow-gray-900/50"
                        >
                            {product.imageUrl && (
                                <img
                                    src={product.imageUrl}
                                    alt={product.name}
                                    className="w-full h-48 object-cover"
                                />
                            )}

                            <div className="p-5 space-y-4">
                                <h3 className="font-bold text-white line-clamp-2 text-lg">{product.name}</h3>

                                <p className="text-gray-400 text-sm line-clamp-2">
                                    {product.description || 'No description'}
                                </p>

                                <div className="grid grid-cols-2 gap-3 text-sm">
                                    <div>
                                        <p className="text-gray-400 text-xs uppercase tracking-wide mb-1">Price</p>
                                        <p className="text-primary font-bold text-lg">
                                            ${product.price || 'N/A'}
                                        </p>
                                    </div>
                                    <div>
                                        <p className="text-gray-400 text-xs uppercase tracking-wide mb-1">Status</p>
                                        <p className={`font-bold ${product.isActive !== false ? 'text-green-400' : 'text-red-400'
                                            }`}>
                                            {product.isActive !== false ? 'Active' : 'Inactive'}
                                        </p>
                                    </div>
                                </div>

                                <div className="pt-3 border-t border-gray-700">
                                    <p className="text-gray-500 text-xs">
                                        Seller: {product.sellerId || 'Unknown'}
                                    </p>
                                </div>

                                {product.isActive !== false && (
                                    <button
                                        onClick={() => handleRemove(product.id)}
                                        disabled={actionLoading === product.id}
                                        className="w-full px-4 py-2 bg-gradient-to-r from-red-900 to-red-800 hover:from-red-800 hover:to-red-700 text-red-200 rounded-lg font-bold flex items-center justify-center gap-2 disabled:opacity-50 transition-all shadow-lg hover:shadow-red-900/30"
                                    >
                                        {actionLoading === product.id ? (
                                            <Loader className="w-4 h-4 animate-spin" />
                                        ) : (
                                            <Trash2 className="w-4 h-4" />
                                        )}
                                        Remove
                                    </button>
                                )}
                            </div>
                        </div>
                    ))
                )}
            </div>

            <div className="text-gray-400 text-sm font-medium">
                Showing {filteredProducts.length} products
            </div>
        </div>
    );
}
