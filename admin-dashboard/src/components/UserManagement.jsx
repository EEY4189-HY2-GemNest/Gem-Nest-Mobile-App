import React, { useState, useEffect } from 'react';
import { getAllUsers, activateUserAccount, deactivateUserAccount, verifySeller, rejectSellerVerification } from '../services/adminService';
import { Check, X, AlertCircle, Loader, Eye, Shield, ShieldAlert } from 'lucide-react';
import UserDetailModal from './UserDetailModal';
import ConfirmDialog from './ConfirmDialog';
import VerificationDialog from './VerificationDialog';

export default function UserManagement() {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [actionLoading, setActionLoading] = useState(null);
    const [message, setMessage] = useState('');
    const [selectedUser, setSelectedUser] = useState(null);
    const [confirmDialog, setConfirmDialog] = useState(null);
    const [verificationDialog, setVerificationDialog] = useState(null);
    const [activeTab, setActiveTab] = useState('sellers');

    useEffect(() => {
        fetchUsers();
    }, []);

    const fetchUsers = async () => {
        try {
            setLoading(true);
            const data = await getAllUsers();
            setUsers(data);
        } catch (error) {
            setMessage('Error fetching users: ' + error.message);
        } finally {
            setLoading(false);
        }
    };

    const handleActivate = async (userId) => {
        setConfirmDialog({
            title: 'Activate Account',
            message: 'Are you sure you want to activate this account?',
            action: 'Activate',
            onConfirm: async () => {
                try {
                    setActionLoading(userId);
                    await activateUserAccount(userId);
                    setUsers(users.map(u => u.id === userId ? { ...u, isActive: true, status: 'active' } : u));
                    setMessage('User account activated');
                    setTimeout(() => setMessage(''), 3000);
                    setConfirmDialog(null);
                } catch (error) {
                    setMessage('Error activating user: ' + error.message);
                    setConfirmDialog(null);
                } finally {
                    setActionLoading(null);
                }
            }
        });
    };

    const handleDeactivate = async (userId) => {
        setConfirmDialog({
            title: 'Deactivate Account',
            message: 'Are you sure you want to deactivate this account? The user will not be able to access the app.',
            action: 'Deactivate',
            isDangerous: true,
            onConfirm: async () => {
                try {
                    setActionLoading(userId);
                    await deactivateUserAccount(userId);
                    setUsers(users.map(u => u.id === userId ? { ...u, isActive: false, status: 'deactivated' } : u));
                    setMessage('User account deactivated');
                    setTimeout(() => setMessage(''), 3000);
                    setConfirmDialog(null);
                } catch (error) {
                    setMessage('Error deactivating user: ' + error.message);
                    setConfirmDialog(null);
                } finally {
                    setActionLoading(null);
                }
            }
        });
    };

    const handleVerifySeller = async (sellerId) => {
        const seller = users.find(u => u.id === sellerId);
        setVerificationDialog({
            type: 'verify',
            userId: sellerId,
            userName: seller?.displayName || seller?.email || 'Seller',
            onConfirm: async () => {
                try {
                    setActionLoading(sellerId);
                    await verifySeller(sellerId);
                    setUsers(users.map(u => u.id === sellerId ? { ...u, verified: true, verificationStatus: 'approved' } : u));
                    setMessage('Seller account verified');
                    setTimeout(() => setMessage(''), 3000);
                    setVerificationDialog(null);
                } catch (error) {
                    setMessage('Error verifying seller: ' + error.message);
                    setVerificationDialog(null);
                } finally {
                    setActionLoading(null);
                }
            }
        });
    };

    const handleRejectSeller = async (sellerId) => {
        const seller = users.find(u => u.id === sellerId);
        setVerificationDialog({
            type: 'reject',
            userId: sellerId,
            userName: seller?.displayName || seller?.email || 'Seller',
            onConfirm: async (reason) => {
                try {
                    setActionLoading(sellerId);
                    await rejectSellerVerification(sellerId, reason);
                    setUsers(users.map(u => u.id === sellerId ? { ...u, verified: false, verificationStatus: 'rejected' } : u));
                    setMessage('Seller verification rejected');
                    setTimeout(() => setMessage(''), 3000);
                    setVerificationDialog(null);
                } catch (error) {
                    setMessage('Error rejecting seller: ' + error.message);
                    setVerificationDialog(null);
                } finally {
                    setActionLoading(null);
                }
            }
        });
    };

    const filteredUsers = users.filter(user =>
        user.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        user.displayName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        user.firebaseUid?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const buyers = filteredUsers.filter(u => u.type === 'buyer' || u.role === 'buyer');
    const sellers = filteredUsers.filter(u => u.type === 'seller' || u.role === 'seller');

    const displayUsers = activeTab === 'buyers' ? buyers : sellers;

    if (loading) {
        return <div className="text-center text-gray-400">Loading users...</div>;
    }

    return (
        <div className="space-y-6">
            <div>
                <h2 className="text-4xl font-bold text-white mb-2">User Management</h2>
                <p className="text-gray-400 text-lg">Manage buyers and verify sellers</p>
            </div>

            {message && (
                <div className="bg-gradient-to-r from-green-900/30 to-green-900/10 border border-green-500 rounded-xl p-4 flex items-center gap-3">
                    <div className="p-2 bg-green-900/40 rounded-lg">
                        <AlertCircle className="w-5 h-5 text-green-400" />
                    </div>
                    <p className="text-green-200">{message}</p>
                </div>
            )}

            {/* Tabs */}
            <div className="flex gap-2 border-b border-gray-700">
                <button
                    onClick={() => setActiveTab('sellers')}
                    className={`px-6 py-3 font-semibold transition-all ${activeTab === 'sellers'
                            ? 'text-primary border-b-2 border-primary'
                            : 'text-gray-400 hover:text-gray-200'
                        }`}
                >
                    <div className="flex items-center gap-2">
                        <ShieldAlert className="w-5 h-5" />
                        Sellers ({sellers.length})
                    </div>
                </button>
                <button
                    onClick={() => setActiveTab('buyers')}
                    className={`px-6 py-3 font-semibold transition-all ${activeTab === 'buyers'
                            ? 'text-primary border-b-2 border-primary'
                            : 'text-gray-400 hover:text-gray-200'
                        }`}
                >
                    <div className="flex items-center gap-2">
                        <Shield className="w-5 h-5" />
                        Buyers ({buyers.length})
                    </div>
                </button>
            </div>

            <div className="bg-gradient-to-r from-gray-800 to-gray-900 rounded-xl p-4 border border-gray-700 shadow-lg">
                <input
                    type="text"
                    placeholder="Search by email or name..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full px-4 py-3 bg-gray-700/50 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all"
                />
            </div>

            <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl border border-gray-700 overflow-hidden shadow-lg">
                <div className="overflow-x-auto">
                    <table className="w-full">
                        <thead className="bg-gray-900/50 border-b border-gray-700">
                            <tr>
                                <th className="px-6 py-4 text-left text-xs font-bold text-gray-300 uppercase tracking-wide">Email</th>
                                <th className="px-6 py-4 text-left text-xs font-bold text-gray-300 uppercase tracking-wide">Name</th>
                                <th className="px-6 py-4 text-left text-xs font-bold text-gray-300 uppercase tracking-wide">Status</th>
                                {activeTab === 'sellers' && (
                                    <th className="px-6 py-4 text-left text-xs font-bold text-gray-300 uppercase tracking-wide">Verification</th>
                                )}
                                <th className="px-6 py-4 text-left text-xs font-bold text-gray-300 uppercase tracking-wide">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {displayUsers.length === 0 ? (
                                <tr>
                                    <td colSpan={activeTab === 'sellers' ? '5' : '4'} className="px-6 py-12 text-center text-gray-400">
                                        <p className="text-lg">No {activeTab} found</p>
                                    </td>
                                </tr>
                            ) : (
                                displayUsers.map((user) => (
                                    <tr key={user.id} className="border-b border-gray-700 hover:bg-gray-700/20 transition-colors">
                                        <td className="px-6 py-4 text-white font-medium">{user.email || 'N/A'}</td>
                                        <td className="px-6 py-4 text-gray-200">{user.displayName || user.name || 'N/A'}</td>
                                        <td className="px-6 py-4">
                                            <span className={`px-3 py-1 rounded-full text-xs font-bold ${user.isActive !== false
                                                ? 'bg-green-900/40 text-green-300 border border-green-700'
                                                : 'bg-red-900/40 text-red-300 border border-red-700'
                                                }`}>
                                                {user.status || (user.isActive !== false ? 'active' : 'inactive')}
                                            </span>
                                        </td>
                                        {activeTab === 'sellers' && (
                                            <td className="px-6 py-4">
                                                <span className={`px-3 py-1 rounded-full text-xs font-bold ${user.verified
                                                        ? 'bg-green-900/40 text-green-300 border border-green-700'
                                                        : 'bg-yellow-900/40 text-yellow-300 border border-yellow-700'
                                                    }`}>
                                                    {user.verified ? 'Verified' : 'Pending'}
                                                </span>
                                            </td>
                                        )}
                                        <td className="px-6 py-4">
                                            <div className="flex gap-2 flex-wrap">
                                                <button
                                                    onClick={() => setSelectedUser(user)}
                                                    className="px-3 py-2 bg-gradient-to-r from-blue-900 to-blue-800 hover:from-blue-800 hover:to-blue-700 text-blue-200 rounded-lg text-xs font-bold flex items-center gap-1 transition-all shadow-lg hover:shadow-blue-900/30"
                                                >
                                                    <Eye className="w-4 h-4" />
                                                    View
                                                </button>
                                                {activeTab === 'sellers' && !user.verified ? (
                                                    <>
                                                        <button
                                                            onClick={() => handleVerifySeller(user.id)}
                                                            disabled={actionLoading === user.id}
                                                            className="px-3 py-2 bg-gradient-to-r from-green-900 to-green-800 hover:from-green-800 hover:to-green-700 text-green-200 rounded-lg text-xs font-bold flex items-center gap-1 disabled:opacity-50 transition-all shadow-lg hover:shadow-green-900/30"
                                                        >
                                                            {actionLoading === user.id ? (
                                                                <Loader className="w-4 h-4 animate-spin" />
                                                            ) : (
                                                                <Check className="w-4 h-4" />
                                                            )}
                                                            Verify
                                                        </button>
                                                        <button
                                                            onClick={() => handleRejectSeller(user.id)}
                                                            disabled={actionLoading === user.id}
                                                            className="px-3 py-2 bg-gradient-to-r from-red-900 to-red-800 hover:from-red-800 hover:to-red-700 text-red-200 rounded-lg text-xs font-bold flex items-center gap-1 disabled:opacity-50 transition-all shadow-lg hover:shadow-red-900/30"
                                                        >
                                                            {actionLoading === user.id ? (
                                                                <Loader className="w-4 h-4 animate-spin" />
                                                            ) : (
                                                                <X className="w-4 h-4" />
                                                            )}
                                                            Reject
                                                        </button>
                                                    </>
                                                ) : (
                                                    <>
                                                        {user.isActive !== false ? (
                                                            <button
                                                                onClick={() => handleDeactivate(user.id)}
                                                                disabled={actionLoading === user.id}
                                                                className="px-3 py-2 bg-gradient-to-r from-red-900 to-red-800 hover:from-red-800 hover:to-red-700 text-red-200 rounded-lg text-xs font-bold flex items-center gap-1 disabled:opacity-50 transition-all shadow-lg hover:shadow-red-900/30"
                                                            >
                                                                {actionLoading === user.id ? (
                                                                    <Loader className="w-4 h-4 animate-spin" />
                                                                ) : (
                                                                    <X className="w-4 h-4" />
                                                                )}
                                                                Deactivate
                                                            </button>
                                                        ) : (
                                                            <button
                                                                onClick={() => handleActivate(user.id)}
                                                                disabled={actionLoading === user.id}
                                                                className="px-3 py-2 bg-gradient-to-r from-green-900 to-green-800 hover:from-green-800 hover:to-green-700 text-green-200 rounded-lg text-xs font-bold flex items-center gap-1 disabled:opacity-50 transition-all shadow-lg hover:shadow-green-900/30"
                                                            >
                                                                {actionLoading === user.id ? (
                                                                    <Loader className="w-4 h-4 animate-spin" />
                                                                ) : (
                                                                    <Check className="w-4 h-4" />
                                                                )}
                                                                Activate
                                                            </button>
                                                        )}
                                                    </>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            <div className="text-gray-400 text-sm font-medium">
                Showing {displayUsers.length} {activeTab}
            </div>

            {/* User Detail Modal */}
            {selectedUser && (
                <UserDetailModal user={selectedUser} onClose={() => setSelectedUser(null)} />
            )}

            {/* Confirm Dialog */}
            {confirmDialog && (
                <ConfirmDialog
                    title={confirmDialog.title}
                    message={confirmDialog.message}
                    action={confirmDialog.action}
                    isDangerous={confirmDialog.isDangerous}
                    isLoading={actionLoading !== null}
                    onConfirm={confirmDialog.onConfirm}
                    onCancel={() => setConfirmDialog(null)}
                />
            )}

            {/* Verification Dialog */}
            {verificationDialog && (
                <VerificationDialog
                    type={verificationDialog.type}
                    userName={verificationDialog.userName}
                    isLoading={actionLoading !== null}
                    onConfirm={verificationDialog.onConfirm}
                    onCancel={() => setVerificationDialog(null)}
                />
            )}
        </div>
    );
}
