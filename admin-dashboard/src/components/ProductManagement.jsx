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
                <h2 className="text-3xl font-bold text-white mb-2">Product Management</h2>
                <p className="text-gray-400">Manage listed products and auctions</p>
            </div>

            {message && (
                <div className="bg-green-900/20 border border-green-500 rounded-lg p-4 flex items-center gap-2">
                    <AlertCircle className="w-5 h-5 text-green-500" />
                    <p className="text-green-200">{message}</p>
                </div>
            )}

            <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
                <input
                    type="text"
                    placeholder="Search by product name..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:border-primary"
                />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {filteredProducts.length === 0 ? (
                    <div className="col-span-full text-center text-gray-400 py-8">
                        No products found
                    </div>
                ) : (
                    filteredProducts.map((product) => (
                        <div
                            key={product.id}
                            className="bg-gray-800 rounded-lg border border-gray-700 overflow-hidden hover:border-gray-600 transition"
                        >
                            {product.imageUrl && (
                                <img
                                    src={product.imageUrl}
                                    alt={product.name}
                                    className="w-full h-48 object-cover"
                                />
                            )}

                            <div className="p-4 space-y-3">
                                <h3 className="font-bold text-white line-clamp-2">{product.name}</h3>

                                <p className="text-gray-400 text-sm line-clamp-2">
                                    {product.description || 'No description'}
                                </p>

                                <div className="grid grid-cols-2 gap-2 text-sm">
                                    <div>
                                        <p className="text-gray-400">Price</p>
                                        <p className="text-primary font-bold">
                                            ${product.price || 'N/A'}
                                        </p>
                                    </div>
                                    <div>
                                        <p className="text-gray-400">Status</p>
                                        <p className={`font-semibold ${product.isActive !== false ? 'text-green-400' : 'text-red-400'
                                            }`}>
                                            {product.isActive !== false ? 'Active' : 'Inactive'}
                                        </p>
                                    </div>
                                </div>

                                <div className="pt-2 border-t border-gray-700">
                                    <p className="text-gray-500 text-xs mb-2">
                                        Seller: {product.sellerId || 'Unknown'}
                                    </p>
                                </div>

                                {product.isActive !== false && (
                                    <button
                                        onClick={() => handleRemove(product.id)}
                                        disabled={actionLoading === product.id}
                                        className="w-full px-4 py-2 bg-red-900 hover:bg-red-800 text-red-200 rounded font-semibold flex items-center justify-center gap-2 disabled:opacity-50 transition"
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

            <div className="text-gray-400 text-sm">
                Total Products: {filteredProducts.length}
            </div>
        </div>
    );
}
