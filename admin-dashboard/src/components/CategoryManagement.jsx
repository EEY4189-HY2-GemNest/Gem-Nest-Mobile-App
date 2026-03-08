import React, { useState, useEffect } from 'react';
import { collection, getDocs, addDoc, updateDoc, deleteDoc, doc } from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL, deleteObject } from 'firebase/storage';
import { db, storage } from '../services/firebase';
import { Plus, Trash2, Edit2, Upload, X, AlertCircle, Check } from 'lucide-react';

export default function CategoryManagement() {
    const [categories, setCategories] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [success, setSuccess] = useState(null);

    const [showModal, setShowModal] = useState(false);
    const [editingId, setEditingId] = useState(null);
    const [imageFile, setImageFile] = useState(null);
    const [imagePreview, setImagePreview] = useState(null);
    const [uploading, setUploading] = useState(false);

    const [formData, setFormData] = useState({
        categoryName: '',
        categoryImage: '',
    });

    // Fetch categories
    const fetchCategories = async () => {
        try {
            setLoading(true);
            const querySnapshot = await getDocs(collection(db, 'categories'));
            const data = querySnapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data(),
            }));
            setCategories(data);
        } catch (err) {
            console.error('Error fetching categories:', err);
            setError('Failed to load categories');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchCategories();
    }, []);

    // Handle image selection
    const handleImageChange = (e) => {
        const file = e.target.files?.[0];
        if (file) {
            setImageFile(file);
            const reader = new FileReader();
            reader.onloadend = () => {
                setImagePreview(reader.result);
            };
            reader.readAsDataURL(file);
        }
    };

    // Upload image to Firebase Storage
    const uploadCategoryImage = async (file) => {
        try {
            const storageRef = ref(storage, `categories/${Date.now()}_${file.name}`);
            await uploadBytes(storageRef, file);
            const url = await getDownloadURL(storageRef);
            return url;
        } catch (err) {
            console.error('Error uploading image:', err);
            throw new Error('Failed to upload image');
        }
    };

    // Handle save (add or update)
    const handleSave = async (e) => {
        e.preventDefault();

        if (!formData.categoryName.trim()) {
            setError('Category name is required');
            return;
        }

        try {
            setUploading(true);
            let imageUrl = formData.categoryImage;

            // Upload image if a new one was selected
            if (imageFile && imagePreview) {
                imageUrl = await uploadCategoryImage(imageFile);
            }

            const categoryData = {
                categoryName: formData.categoryName.trim(),
                categoryImage: imageUrl,
                updatedAt: new Date(),
            };

            if (editingId) {
                // Update existing
                await updateDoc(doc(db, 'categories', editingId), categoryData);
                setSuccess('Category updated successfully!');
            } else {
                // Add new
                await addDoc(collection(db, 'categories'), {
                    ...categoryData,
                    createdAt: new Date(),
                });
                setSuccess('Category added successfully!');
            }

            setFormData({ categoryName: '', categoryImage: '' });
            setImageFile(null);
            setImagePreview(null);
            setEditingId(null);
            setShowModal(false);
            await fetchCategories();
        } catch (err) {
            console.error('Error saving category:', err);
            setError(err.message || 'Failed to save category');
        } finally {
            setUploading(false);
        }
    };

    // Handle edit
    const handleEdit = (category) => {
        setFormData({
            categoryName: category.categoryName,
            categoryImage: category.categoryImage,
        });
        setImagePreview(category.categoryImage);
        setEditingId(category.id);
        setImageFile(null);
        setShowModal(true);
    };

    // Handle delete
    const handleDelete = async (id, imageUrl) => {
        if (!window.confirm('Are you sure you want to delete this category?')) return;

        try {
            setUploading(true);

            // Delete image from storage if it exists
            if (imageUrl) {
                try {
                    const imageRef = ref(storage, imageUrl);
                    await deleteObject(imageRef);
                } catch (err) {
                    console.warn('Error deleting image:', err);
                }
            }

            // Delete category document
            await deleteDoc(doc(db, 'categories', id));
            setSuccess('Category deleted successfully!');
            await fetchCategories();
        } catch (err) {
            console.error('Error deleting category:', err);
            setError('Failed to delete category');
        } finally {
            setUploading(false);
        }
    };

    // Reset modal
    const handleCloseModal = () => {
        setShowModal(false);
        setFormData({ categoryName: '', categoryImage: '' });
        setImageFile(null);
        setImagePreview(null);
        setEditingId(null);
        setError(null);
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-white">Gem Categories</h2>
                    <p className="text-gray-400 text-sm mt-1">Manage and configure gem categories for buyers</p>
                </div>
                <button
                    onClick={() => setShowModal(true)}
                    className="flex items-center gap-2 bg-gradient-to-r from-primary to-primary/80 text-white px-4 py-2 rounded-lg hover:shadow-lg transition-all"
                >
                    <Plus className="w-5 h-5" />
                    Add Category
                </button>
            </div>

            {/* Alert Messages */}
            {error && (
                <div className="flex items-center gap-3 bg-red-900/20 border border-red-700/50 rounded-lg p-4">
                    <AlertCircle className="w-5 h-5 text-red-400 flex-shrink-0" />
                    <p className="text-red-300 text-sm">{error}</p>
                </div>
            )}
            {success && (
                <div className="flex items-center gap-3 bg-green-900/20 border border-green-700/50 rounded-lg p-4">
                    <Check className="w-5 h-5 text-green-400 flex-shrink-0" />
                    <p className="text-green-300 text-sm">{success}</p>
                </div>
            )}

            {/* Categories Grid */}
            {loading ? (
                <div className="flex justify-center items-center h-40">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
                </div>
            ) : categories.length === 0 ? (
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl border border-gray-700 p-12 text-center">
                    <p className="text-gray-400 mb-3">No categories added yet</p>
                    <button
                        onClick={() => setShowModal(true)}
                        className="inline-flex items-center gap-2 bg-primary text-white px-4 py-2 rounded-lg hover:shadow-lg transition-all"
                    >
                        <Plus className="w-4 h-4" />
                        Create First Category
                    </button>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {categories.map((category) => (
                        <div
                            key={category.id}
                            className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-lg border border-gray-700 overflow-hidden hover:border-gray-600 transition-all"
                        >
                            {/* Image */}
                            {category.categoryImage && (
                                <div className="h-40 bg-gray-700 overflow-hidden">
                                    <img
                                        src={category.categoryImage}
                                        alt={category.categoryName}
                                        className="w-full h-full object-cover hover:scale-105 transition-transform duration-300"
                                    />
                                </div>
                            )}

                            {/* Content */}
                            <div className="p-4">
                                <h3 className="text-white font-semibold mb-1 truncate">
                                    {category.categoryName}
                                </h3>
                                <p className="text-gray-500 text-xs mb-4">
                                    ID: {category.id}
                                </p>

                                {/* Actions */}
                                <div className="flex gap-2">
                                    <button
                                        onClick={() => handleEdit(category)}
                                        disabled={uploading}
                                        className="flex-1 flex items-center justify-center gap-1 bg-blue-600/20 text-blue-400 hover:bg-blue-600/40 px-3 py-2 rounded transition-all disabled:opacity-50"
                                    >
                                        <Edit2 className="w-4 h-4" />
                                        Edit
                                    </button>
                                    <button
                                        onClick={() => handleDelete(category.id, category.categoryImage)}
                                        disabled={uploading}
                                        className="flex-1 flex items-center justify-center gap-1 bg-red-600/20 text-red-400 hover:bg-red-600/40 px-3 py-2 rounded transition-all disabled:opacity-50"
                                    >
                                        <Trash2 className="w-4 h-4" />
                                        Delete
                                    </button>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Modal */}
            {showModal && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
                    <div className="bg-gray-900 rounded-xl border border-gray-700 w-full max-w-md shadow-xl">
                        {/* Modal Header */}
                        <div className="flex items-center justify-between p-6 border-b border-gray-700">
                            <h3 className="text-xl font-bold text-white">
                                {editingId ? 'Edit Category' : 'Add New Category'}
                            </h3>
                            <button
                                onClick={handleCloseModal}
                                className="text-gray-400 hover:text-white transition-colors"
                            >
                                <X className="w-6 h-6" />
                            </button>
                        </div>

                        {/* Modal Body */}
                        <form onSubmit={handleSave} className="p-6 space-y-5">
                            {/* Category Name */}
                            <div>
                                <label className="block text-sm font-medium text-gray-300 mb-2">
                                    Category Name *
                                </label>
                                <input
                                    type="text"
                                    value={formData.categoryName}
                                    onChange={(e) => setFormData({ ...formData, categoryName: e.target.value })}
                                    placeholder="e.g., Blue Sapphires"
                                    className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
                                />
                            </div>

                            {/* Image Upload */}
                            <div>
                                <label className="block text-sm font-medium text-gray-300 mb-2">
                                    Category Image *
                                </label>

                                {imagePreview && (
                                    <div className="mb-3 relative rounded-lg overflow-hidden border border-gray-700">
                                        <img
                                            src={imagePreview}
                                            alt="Preview"
                                            className="w-full h-40 object-cover"
                                        />
                                        <button
                                            type="button"
                                            onClick={() => {
                                                setImagePreview(null);
                                                setImageFile(null);
                                                if (!editingId) {
                                                    setFormData({ ...formData, categoryImage: '' });
                                                }
                                            }}
                                            className="absolute top-2 right-2 bg-red-600 text-white p-1 rounded hover:bg-red-700 transition-colors"
                                        >
                                            <X className="w-4 h-4" />
                                        </button>
                                    </div>
                                )}

                                <label className="flex items-center justify-center gap-2 px-4 py-3 border-2 border-dashed border-gray-700 rounded-lg cursor-pointer hover:border-primary/50 transition-colors">
                                    <Upload className="w-4 h-4 text-gray-400" />
                                    <span className="text-sm text-gray-300">
                                        {imageFile ? 'Change Image' : 'Upload Image'}
                                    </span>
                                    <input
                                        type="file"
                                        accept="image/*"
                                        onChange={handleImageChange}
                                        className="hidden"
                                    />
                                </label>
                                <p className="text-xs text-gray-500 mt-1">
                                    Recommended: 500x400px or larger
                                </p>
                            </div>

                            {/* Current Image Info */}
                            {editingId && formData.categoryImage && !imageFile && (
                                <p className="text-xs text-gray-500">Current image: {formData.categoryImage}</p>
                            )}

                            {/* Actions */}
                            <div className="flex gap-3 pt-4">
                                <button
                                    type="button"
                                    onClick={handleCloseModal}
                                    disabled={uploading}
                                    className="flex-1 px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-600 transition-all disabled:opacity-50"
                                >
                                    Cancel
                                </button>
                                <button
                                    type="submit"
                                    disabled={uploading || !formData.categoryName.trim()}
                                    className="flex-1 px-4 py-2 bg-gradient-to-r from-primary to-primary/80 text-white rounded-lg hover:shadow-lg transition-all disabled:opacity-50 flex items-center justify-center gap-2"
                                >
                                    {uploading ? (
                                        <>
                                            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                                            Saving...
                                        </>
                                    ) : (
                                        'Save Category'
                                    )}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
