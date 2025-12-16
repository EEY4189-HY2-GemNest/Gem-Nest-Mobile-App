import React, { useState, useEffect } from 'react';
import { getAllUsers, activateUserAccount, deactivateUserAccount } from '../services/adminService';
import { Check, X, AlertCircle, Loader, Eye } from 'lucide-react';
import UserDetailModal from './UserDetailModal';
import ConfirmDialog from './ConfirmDialog';

export default function UserManagement() {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [actionLoading, setActionLoading] = useState(null);
    const [message, setMessage] = useState('');
    const [selectedUser, setSelectedUser] = useState(null);
    const [confirmDialog, setConfirmDialog] = useState(null);

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

    const filteredUsers = users.filter(user =>
        user.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        user.name?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    if (loading) {
        return <div className="text-center text-gray-400">Loading users...</div>;
    }

    return (
        <div className="space-y-6">
            <div>
                <h2 className="text-3xl font-bold text-white mb-2">User Management</h2>
                <p className="text-gray-400">Manage user accounts and status</p>
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
                    placeholder="Search by email or name..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:border-primary"
                />
            </div>

            <div className="bg-gray-800 rounded-lg border border-gray-700 overflow-hidden">
                <div className="overflow-x-auto">
                    <table className="w-full">
                        <thead className="bg-gray-900 border-b border-gray-700">
                            <tr>
                                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-300">Email</th>
                                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-300">Name</th>
                                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-300">Status</th>
                                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-300">User Type</th>
                                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-300">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filteredUsers.length === 0 ? (
                                <tr>
                                    <td colSpan="5" className="px-6 py-8 text-center text-gray-400">
                                        No users found
                                    </td>
                                </tr>
                            ) : (
                                filteredUsers.map((user) => (
                                    <tr key={user.id} className="border-b border-gray-700 hover:bg-gray-700/50">
                                        <td className="px-6 py-3 text-white">{user.email || 'N/A'}</td>
                                        <td className="px-6 py-3 text-white">{user.name || 'N/A'}</td>
                                        <td className="px-6 py-3">
                                            <span className={`px-3 py-1 rounded-full text-xs font-semibold ${user.isActive !== false
                                                ? 'bg-green-900 text-green-300'
                                                : 'bg-red-900 text-red-300'
                                                }`}>
                                                {user.status || (user.isActive !== false ? 'active' : 'inactive')}
                                            </span>
                                        </td>
                                        <td className="px-6 py-3 text-gray-300">{user.userType || 'buyer'}</td>
                                        <td className="px-6 py-3">
                                            <div className="flex gap-2">
                                                <button
                                                    onClick={() => setSelectedUser(user)}
                                                    className="px-3 py-1 bg-blue-900 hover:bg-blue-800 text-blue-200 rounded text-xs font-semibold flex items-center gap-1 transition"
                                                >
                                                    <Eye className="w-4 h-4" />
                                                    View
                                                </button>
                                                {user.isActive !== false ? (
                                                    <button
                                                        onClick={() => handleDeactivate(user.id)}
                                                        disabled={actionLoading === user.id}
                                                        className="px-3 py-1 bg-red-900 hover:bg-red-800 text-red-200 rounded text-xs font-semibold flex items-center gap-1 disabled:opacity-50"
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
                                                        className="px-3 py-1 bg-green-900 hover:bg-green-800 text-green-200 rounded text-xs font-semibold flex items-center gap-1 disabled:opacity-50"
                                                    >
                                                        {actionLoading === user.id ? (
                                                            <Loader className="w-4 h-4 animate-spin" />
                                                        ) : (
                                                            <Check className="w-4 h-4" />
                                                        )}
                                                        Activate
                                                    </button>
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

            <div className="text-gray-400 text-sm">
                Total Users: {filteredUsers.length}
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
        </div>
    );
}
