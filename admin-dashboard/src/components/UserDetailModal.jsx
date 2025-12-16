import React, { useState } from 'react';
import { X, Upload, Download, Eye, FileText, Image as ImageIcon, Loader } from 'lucide-react';
import { uploadUserDocument, downloadUserDocument } from '../services/adminService';

export default function UserDetailModal({ user, onClose, onSave }) {
  const [isEditing, setIsEditing] = useState(false);
  const [uploading, setUploading] = useState(null);
  const [documents, setDocuments] = useState({
    brImage: user?.brImage || null,
    brPdf: user?.brPdf || null,
    nicImage: user?.nicImage || null,
    nicPdf: user?.nicPdf || null,
  });
  const [editData, setEditData] = useState({
    name: user?.name || '',
    email: user?.email || '',
    userType: user?.userType || 'buyer',
  });

  const handleFileUpload = async (e, docType) => {
    const file = e.target.files[0];
    if (!file || !user?.id) return;

    try {
      setUploading(docType);
      const downloadUrl = await uploadUserDocument(user.id, file, docType);
      setDocuments(prev => ({ ...prev, [docType]: downloadUrl }));
    } catch (error) {
      alert('Error uploading file: ' + error.message);
    } finally {
      setUploading(null);
    }
  };

  const handleDownload = async (docType) => {
    try {
      if (documents[docType]) {
        window.open(documents[docType], '_blank');
      }
    } catch (error) {
      alert('Error downloading file: ' + error.message);
    }
  };

  const handleSave = () => {
    if (onSave) {
      onSave({
        ...editData,
        ...documents,
      });
    }
    setIsEditing(false);
  };

  const DocumentUploadBox = ({ label, docType, accept }) => (
    <div className="bg-gray-700/30 rounded-lg p-4 border border-gray-600">
      <div className="flex items-center justify-between mb-3">
        <label className="text-sm font-semibold text-gray-300">{label}</label>
        {documents[docType] && (
          <span className="text-xs bg-green-900 text-green-300 px-2 py-1 rounded">
            ✓ Uploaded
          </span>
        )}
      </div>

      <div className="space-y-2">
        <label className="flex items-center justify-center w-full px-4 py-2 bg-gray-600 hover:bg-gray-500 rounded-lg cursor-pointer transition border border-dashed border-gray-500">
          <input
            type="file"
            accept={accept}
            onChange={(e) => handleFileUpload(e, docType)}
            disabled={uploading === docType}
            className="hidden"
          />
          <div className="flex items-center gap-2 text-gray-200">
            {uploading === docType ? (
              <>
                <Loader className="w-4 h-4 animate-spin" />
                <span>Uploading...</span>
              </>
            ) : (
              <>
                <Upload className="w-4 h-4" />
                <span>Click to upload</span>
              </>
            )}
          </div>
        </label>

        {documents[docType] && (
          <button
            onClick={() => handleDownload(docType)}
            className="w-full px-3 py-2 bg-blue-900 hover:bg-blue-800 text-blue-200 rounded text-sm font-semibold flex items-center justify-center gap-2 transition"
          >
            <Download className="w-4 h-4" />
            Download
          </button>
        )}
      </div>
    </div>
  );

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div className="bg-gray-800 rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto border border-gray-700">
        
        {/* Header */}
        <div className="sticky top-0 bg-gray-900 border-b border-gray-700 px-6 py-4 flex items-center justify-between">
          <h2 className="text-xl font-bold text-white">User Details</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-700 rounded-lg transition"
          >
            <X className="w-6 h-6 text-gray-400" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6">
          
          {/* User Info Section */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-white">Personal Information</h3>
            
            {isEditing ? (
              <div className="space-y-3">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">Name</label>
                  <input
                    type="text"
                    value={editData.name}
                    onChange={(e) => setEditData({ ...editData, name: e.target.value })}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">Email</label>
                  <input
                    type="email"
                    value={editData.email}
                    disabled
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded text-gray-400 cursor-not-allowed"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">User Type</label>
                  <select
                    value={editData.userType}
                    onChange={(e) => setEditData({ ...editData, userType: e.target.value })}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                  >
                    <option value="buyer">Buyer</option>
                    <option value="seller">Seller</option>
                  </select>
                </div>
              </div>
            ) : (
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-gray-700/30 rounded-lg p-3">
                  <p className="text-gray-400 text-sm">Name</p>
                  <p className="text-white font-semibold">{user?.name || 'N/A'}</p>
                </div>
                <div className="bg-gray-700/30 rounded-lg p-3">
                  <p className="text-gray-400 text-sm">Email</p>
                  <p className="text-white font-semibold text-sm">{user?.email || 'N/A'}</p>
                </div>
                <div className="bg-gray-700/30 rounded-lg p-3">
                  <p className="text-gray-400 text-sm">User Type</p>
                  <p className="text-white font-semibold">{user?.userType || 'N/A'}</p>
                </div>
                <div className="bg-gray-700/30 rounded-lg p-3">
                  <p className="text-gray-400 text-sm">Status</p>
                  <p className={`font-semibold ${user?.isActive !== false ? 'text-green-400' : 'text-red-400'}`}>
                    {user?.status || (user?.isActive !== false ? 'Active' : 'Inactive')}
                  </p>
                </div>
              </div>
            )}
          </div>

          {/* Document Upload Section */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-white">Documents</h3>
            <p className="text-gray-400 text-sm">Upload Business Registration and National ID Card documents</p>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* BR Section */}
              <div className="space-y-3">
                <div className="bg-gray-700/50 rounded-lg p-3 border border-primary/30">
                  <h4 className="text-primary font-semibold mb-3 flex items-center gap-2">
                    <FileText className="w-4 h-4" />
                    Business Registration
                  </h4>
                  <div className="space-y-2">
                    <DocumentUploadBox
                      label="BR Image/Photo"
                      docType="brImage"
                      accept="image/*"
                    />
                    <DocumentUploadBox
                      label="BR PDF Document"
                      docType="brPdf"
                      accept=".pdf"
                    />
                  </div>
                </div>
              </div>

              {/* NIC Section */}
              <div className="space-y-3">
                <div className="bg-gray-700/50 rounded-lg p-3 border border-primary/30">
                  <h4 className="text-primary font-semibold mb-3 flex items-center gap-2">
                    <ImageIcon className="w-4 h-4" />
                    National ID Card
                  </h4>
                  <div className="space-y-2">
                    <DocumentUploadBox
                      label="NIC Image/Photo"
                      docType="nicImage"
                      accept="image/*"
                    />
                    <DocumentUploadBox
                      label="NIC PDF Document"
                      docType="nicPdf"
                      accept=".pdf"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Document Preview Section */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-white">Uploaded Documents Preview</h3>
            <div className="grid grid-cols-2 gap-4">
              {documents.brImage && (
                <div className="bg-gray-700/30 rounded-lg p-3 border border-gray-600">
                  <p className="text-gray-400 text-xs mb-2">BR Image</p>
                  <button
                    onClick={() => handleDownload('brImage')}
                    className="w-full px-3 py-2 bg-green-900 hover:bg-green-800 text-green-200 rounded text-sm font-semibold flex items-center justify-center gap-2"
                  >
                    <Eye className="w-4 h-4" />
                    View
                  </button>
                </div>
              )}
              {documents.brPdf && (
                <div className="bg-gray-700/30 rounded-lg p-3 border border-gray-600">
                  <p className="text-gray-400 text-xs mb-2">BR PDF</p>
                  <button
                    onClick={() => handleDownload('brPdf')}
                    className="w-full px-3 py-2 bg-green-900 hover:bg-green-800 text-green-200 rounded text-sm font-semibold flex items-center justify-center gap-2"
                  >
                    <Eye className="w-4 h-4" />
                    View
                  </button>
                </div>
              )}
              {documents.nicImage && (
                <div className="bg-gray-700/30 rounded-lg p-3 border border-gray-600">
                  <p className="text-gray-400 text-xs mb-2">NIC Image</p>
                  <button
                    onClick={() => handleDownload('nicImage')}
                    className="w-full px-3 py-2 bg-green-900 hover:bg-green-800 text-green-200 rounded text-sm font-semibold flex items-center justify-center gap-2"
                  >
                    <Eye className="w-4 h-4" />
                    View
                  </button>
                </div>
              )}
              {documents.nicPdf && (
                <div className="bg-gray-700/30 rounded-lg p-3 border border-gray-600">
                  <p className="text-gray-400 text-xs mb-2">NIC PDF</p>
                  <button
                    onClick={() => handleDownload('nicPdf')}
                    className="w-full px-3 py-2 bg-green-900 hover:bg-green-800 text-green-200 rounded text-sm font-semibold flex items-center justify-center gap-2"
                  >
                    <Eye className="w-4 h-4" />
                    View
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="sticky bottom-0 bg-gray-900 border-t border-gray-700 px-6 py-4 flex gap-3 justify-end">
          {isEditing ? (
            <>
              <button
                onClick={() => setIsEditing(false)}
                className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-gray-200 rounded font-semibold transition"
              >
                Cancel
              </button>
              <button
                onClick={handleSave}
                className="px-4 py-2 bg-primary hover:bg-yellow-500 text-dark rounded font-semibold transition"
              >
                Save
              </button>
            </>
          ) : (
            <>
              <button
                onClick={onClose}
                className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-gray-200 rounded font-semibold transition"
              >
                Close
              </button>
              <button
                onClick={() => setIsEditing(true)}
                className="px-4 py-2 bg-primary hover:bg-yellow-500 text-dark rounded font-semibold transition"
              >
                Edit
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
