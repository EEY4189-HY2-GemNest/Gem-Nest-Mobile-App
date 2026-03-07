import React, { useState, useEffect } from 'react';
import { db, storage } from '../services/firebase';
import { collection, addDoc, deleteDoc, doc, getDocs, query, serverTimestamp } from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL, deleteObject } from 'firebase/storage';
import { Upload, X, Plus, Trash2, Eye, Download, Calendar, AlertCircle } from 'lucide-react';
import ConfirmDialog from './ConfirmDialog';

export default function BannerConfig() {
    const [banners, setBanners] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);
    const [formData, setFormData] = useState({
        imageUrl: '',
        endDate: '',
        useUrlDirectly: true,
    });
    const [imageFile, setImageFile] = useState(null);
    const [imagePreview, setImagePreview] = useState(null);
    const [uploading, setUploading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');
    const [confirmDelete, setConfirmDelete] = useState(null);
    const [deletingId, setDeletingId] = useState(null);

    const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB
    const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

    useEffect(() => {
        fetchBanners();
    }, []);

    const fetchBanners = async () => {
        setLoading(true);
        try {
            const q = query(collection(db, 'banners'));
            const querySnapshot = await getDocs(q);
            const bannersData = querySnapshot.docs.map((doc) => ({
                id: doc.id,
                ...doc.data(),
            }));
            setBanners(bannersData.sort((a, b) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0)));
            setError('');
        } catch (err) {
            console.error('Error fetching banners:', err);
            setError('Failed to load banners');
        }
        setLoading(false);
    };

    const handleImageChange = (e) => {
        const file = e.target.files?.[0];
        if (!file) return;

        // Validate file size
        if (file.size > MAX_IMAGE_SIZE) {
            setError(`Image size must be less than 5MB. Current size: ${(file.size / 1024 / 1024).toFixed(2)}MB`);
            return;
        }

        // Validate file type
        if (!ALLOWED_TYPES.includes(file.type)) {
            setError('Only JPEG, PNG, and WebP images are allowed');
            return;
        }

        setImageFile(file);
        setFormData({ ...formData, useUrlDirectly: false });
        setError('');

        // Preview
        const reader = new FileReader();
        reader.onload = (event) => {
            setImagePreview(event.target?.result);
        };
        reader.readAsDataURL(file);
    };

    const handleUrlInput = (e) => {
        setFormData({ ...formData, imageUrl: e.target.value, useUrlDirectly: true });
        setImageFile(null);
        setImagePreview(null);
    };

    const handleDateChange = (e) => {
        setFormData({ ...formData, endDate: e.target.value });
    };

    const validateForm = () => {
        if (!formData.useUrlDirectly && !imageFile) {
            setError('Please upload an image');
            return false;
        }
        if (formData.useUrlDirectly && !formData.imageUrl.trim()) {
            setError('Please enter an image URL');
            return false;
        }
        if (formData.endDate && new Date(formData.endDate) < new Date()) {
            setError('End date must be in the future');
            return false;
        }
        return true;
    };

    const handleAddBanner = async () => {
        if (!validateForm()) return;

        setUploading(true);
        setError('');
        setSuccess('');

        try {
            let imageUrl = formData.imageUrl;

            // Upload image if file was selected
            if (imageFile) {
                const timestamp = Date.now();
                const fileName = `banners/${timestamp}_${imageFile.name}`;
                const storageRef = ref(storage, fileName);

                await uploadBytes(storageRef, imageFile);
                imageUrl = await getDownloadURL(storageRef);
            }

            // Add banner to Firestore
            const bannerData = {
                imageUrl,
                isActive: true,
                createdAt: serverTimestamp(),
                endDate: formData.endDate ? new Date(formData.endDate) : null,
            };

            await addDoc(collection(db, 'banners'), bannerData);

            setSuccess('Banner added successfully!');
            setFormData({ imageUrl: '', endDate: '', useUrlDirectly: true });
            setImageFile(null);
            setImagePreview(null);
            setShowForm(false);

            // Refresh banners
            setTimeout(() => {
                fetchBanners();
                setSuccess('');
            }, 1500);
        } catch (err) {
            console.error('Error adding banner:', err);
            setError(err.message || 'Failed to add banner');
        } finally {
            setUploading(false);
        }
    };

    const handleDeleteBanner = async (bannerId, imageUrl) => {
        setConfirmDelete({ bannerId, imageUrl });
    };

    const confirmDeleteBanner = async () => {
        if (!confirmDelete) return;

        setDeletingId(confirmDelete.bannerId);
        try {
            // Delete from Firestore
            await deleteDoc(doc(db, 'banners', confirmDelete.bannerId));

            // Delete image from Storage if it's a Firebase Storage URL
            if (confirmDelete.imageUrl.includes('firebasestorage')) {
                try {
                    const storageRef = ref(storage, confirmDelete.imageUrl);
                    await deleteObject(storageRef);
                } catch (err) {
                    console.warn('Could not delete image from storage:', err);
                }
            }

            setSuccess('Banner deleted successfully!');
            setConfirmDelete(null);
            setTimeout(() => {
                fetchBanners();
                setSuccess('');
                setDeletingId(null);
            }, 1500);
        } catch (err) {
            console.error('Error deleting banner:', err);
            setError('Failed to delete banner');
            setDeletingId(null);
        }
    };

    const isExpired = (endDate) => {
        if (!endDate) return false;
        const end = typeof endDate === 'object' && endDate.toDate ? endDate.toDate() : new Date(endDate);
        return end < new Date();
    };

    const formatDate = (date) => {
        if (!date) return 'No expiration';
        const d = typeof date === 'object' && date.toDate ? date.toDate() : new Date(date);
        return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
    };

    return (
        <div className="space-y-6"  >
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold text-white">Banner Configuration</h1>
                    <p className="text-gray-400 mt-1">Manage promotional banners for the mobile app</p>
                </div>
                <button
                    onClick={() => setShowForm(!showForm)}
                    className="flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-primary to-yellow-600 text-gray-950 rounded-xl hover:from-primary/90 hover:to-yellow-700 transition-all shadow-lg shadow-primary/20 font-medium"
                >
                    <Plus className="w-5 h-5" />
                    Add Banner
                </button>
            </div>

            {/* Messages */}
            {error && (
                <div className="p-4 bg-red-900/20 border border-red-500/30 rounded-lg flex items-center gap-3 text-red-400">
                    <AlertCircle className="w-5 h-5 flex-shrink-0" />
                    <span>{error}</span>
                </div>
            )}
            {success && (
                <div className="p-4 bg-green-900/20 border border-green-500/30 rounded-lg flex items-center gap-3 text-green-400">
                    <Download className="w-5 h-5 flex-shrink-0" />
                    <span>{success}</span>
                </div>
            )}

            {/* Add Banner Form */}
            {showForm && (
                <div className="bg-gradient-to-br from-gray-800/40 to-gray-900/40 border border-gray-700/50 rounded-xl p-6 space-y-4">
                    <h2 className="text-xl font-bold text-white flex items-center gap-2">
                        <Plus className="w-5 h-5 text-primary" />
                        Add New Banner
                    </h2>

                    {/* Image Input Method Selection */}
                    <div className="space-y-3">
                        <label className="text-sm font-semibold text-gray-300">Image Source</label>
                        <div className="flex gap-4">
                            <label className="flex items-center gap-2 cursor-pointer text-gray-300 hover:text-white transition">
                                <input
                                    type="radio"
                                    name="imageSource"
                                    checked={formData.useUrlDirectly}
                                    onChange={() => {
                                        setFormData({ ...formData, useUrlDirectly: true });
                                        setImageFile(null);
                                        setImagePreview(null);
                                    }}
                                    className="w-4 h-4"
                                />
                                <span>URL</span>
                            </label>
                            <label className="flex items-center gap-2 cursor-pointer text-gray-300 hover:text-white transition">
                                <input
                                    type="radio"
                                    name="imageSource"
                                    checked={!formData.useUrlDirectly}
                                    onChange={() => setFormData({ ...formData, useUrlDirectly: false })}
                                    className="w-4 h-4"
                                />
                                <span>Upload Image</span>
                            </label>
                        </div>
                    </div>

                    {/* URL Input */}
                    {formData.useUrlDirectly ? (
                        <div>
                            <label className="block text-sm font-semibold text-gray-300 mb-2">Image URL</label>
                            <input
                                type="url"
                                placeholder="https://example.com/banner.jpg"
                                value={formData.imageUrl}
                                onChange={handleUrlInput}
                                className="w-full px-4 py-2.5 bg-gray-900/50 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary transition"
                            />
                        </div>
                    ) : (
                        <div>
                            <label className="block text-sm font-semibold text-gray-300 mb-2">Upload Image</label>
                            <label className="flex items-center justify-center w-full px-4 py-8 border-2 border-dashed border-gray-700 rounded-lg hover:border-primary/50 transition cursor-pointer bg-gray-900/30 group">
                                <div className="text-center">
                                    <Upload className="w-8 h-8 text-gray-500 group-hover:text-primary transition mx-auto mb-2" />
                                    <p className="text-sm font-medium text-gray-300">Click to upload image</p>
                                    <p className="text-xs text-gray-500 mt-1">Max 5MB • JPEG, PNG, WebP</p>
                                </div>
                                <input
                                    type="file"
                                    accept="image/jpeg,image/png,image/webp"
                                    onChange={handleImageChange}
                                    className="hidden"
                                />
                            </label>

                            {/* Image Preview */}
                            {imagePreview && (
                                <div className="mt-4">
                                    <p className="text-xs font-semibold text-gray-400 mb-2">Preview</p>
                                    <img
                                        src={imagePreview}
                                        alt="Preview"
                                        className="w-full h-40 object-cover rounded-lg border border-gray-700"
                                    />
                                </div>
                            )}
                        </div>
                    )}

                    {/* End Date */}
                    <div>
                        <label className="block text-sm font-semibold text-gray-300 mb-2">Expiration Date (Optional)</label>
                        <input
                            type="datetime-local"
                            value={formData.endDate}
                            onChange={handleDateChange}
                            className="w-full px-4 py-2.5 bg-gray-900/50 border border-gray-700 rounded-lg text-white focus:outline-none focus:border-primary transition"
                        />
                        <p className="text-xs text-gray-500 mt-1">Leave empty if the banner never expires</p>
                    </div>

                    {/* Action Buttons */}
                    <div className="flex gap-3 pt-4">
                        <button
                            onClick={handleAddBanner}
                            disabled={uploading}
                            className="flex-1 px-4 py-2.5 bg-gradient-to-r from-primary to-yellow-600 text-gray-950 rounded-lg hover:from-primary/90 hover:to-yellow-700 transition-all shadow-lg disabled:opacity-50 disabled:cursor-not-allowed font-medium"
                        >
                            {uploading ? 'Uploading...' : 'Add Banner'}
                        </button>
                        <button
                            onClick={() => {
                                setShowForm(false);
                                setFormData({ imageUrl: '', endDate: '', useUrlDirectly: true });
                                setImageFile(null);
                                setImagePreview(null);
                            }}
                            className="px-4 py-2.5 bg-gray-800 text-gray-300 rounded-lg hover:bg-gray-700 transition font-medium"
                        >
                            Cancel
                        </button>
                    </div>
                </div>
            )}

            {/* Active Banners */}
            <div className="bg-gradient-to-br from-gray-800/40 to-gray-900/40 border border-gray-700/50 rounded-xl p-6">
                <h2 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
                    <Eye className="w-5 h-5 text-primary" />
                    Active Banners ({banners.length})
                </h2>

                {loading ? (
                    <div className="text-center py-8 text-gray-400">Loading banners...</div>
                ) : banners.length === 0 ? (
                    <div className="text-center py-8 text-gray-400">No banners yet. Add one to get started!</div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                        {banners.map((banner) => (
                            <div
                                key={banner.id}
                                className={`relative group rounded-lg overflow-hidden border transition-all ${isExpired(banner.endDate)
                                    ? 'border-red-500/30 opacity-60'
                                    : 'border-gray-700 hover:border-primary/50'
                                    }`}
                            >
                                {/* Image */}
                                <img
                                    src={banner.imageUrl}
                                    alt="Banner"
                                    className="w-full h-40 object-cover bg-gray-900"
                                />

                                {/* Expired Badge */}
                                {isExpired(banner.endDate) && (
                                    <div className="absolute inset-0 bg-red-900/40 flex items-center justify-center">
                                        <span className="text-red-300 font-semibold text-sm">Expired</span>
                                    </div>
                                )}

                                {/* Hover Overlay */}
                                <div className="absolute inset-0 bg-gradient-to-t from-gray-950 to-transparent opacity-0 group-hover:opacity-100 transition-all flex flex-col justify-end p-3">
                                    {/* End Date */}
                                    {banner.endDate && (
                                        <div className="flex items-center gap-2 text-xs text-gray-300 mb-2">
                                            <Calendar className="w-3 h-3" />
                                            <span>Expires: {formatDate(banner.endDate)}</span>
                                        </div>
                                    )}

                                    {/* Delete Button */}
                                    <button
                                        onClick={() => handleDeleteBanner(banner.id, banner.imageUrl)}
                                        className="w-full flex items-center justify-center gap-2 px-3 py-2 bg-red-900/40 text-red-300 rounded-lg hover:bg-red-900/60 transition text-sm font-medium"
                                    >
                                        <Trash2 className="w-4 h-4" />
                                        Delete
                                    </button>
                                </div>

                                {/* Info at bottom */}
                                <div className="p-3 bg-gray-900/60 border-t border-gray-700/50">
                                    <p className="text-xs text-gray-500">
                                        Added {formatDate(banner.createdAt)}
                                    </p>
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {/* Delete Confirmation Dialog */}
                {confirmDelete && (
                    <ConfirmDialog
                        title="Delete Banner"
                        message="Are you sure you want to delete this banner? This action cannot be undone."
                        action="Delete"
                        isDangerous={true}
                        isLoading={deletingId === confirmDelete.bannerId}
                        onConfirm={confirmDeleteBanner}
                        onCancel={() => setConfirmDelete(null)}
                    />
                )}
            </div>
            );
}
