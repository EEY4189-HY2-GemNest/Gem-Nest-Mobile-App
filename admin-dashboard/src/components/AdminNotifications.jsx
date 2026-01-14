import React, { useState, useEffect } from 'react';
import {
    subscribeToAdminNotifications,
    subscribeToUnreadCount,
    markNotificationAsRead,
    markAllNotificationsAsRead,
    deleteNotification,
    deleteAllNotifications,
    subscribeToSystemAlerts,
    getPendingNotifications,
} from '../services/admin_notification_service';
import {
    Bell,
    Trash2,
    CheckCheck,
    AlertTriangle,
    X,
} from 'lucide-react';

/**
 * Admin Notification Component - Displays admin notifications
 */
export function AdminNotificationCenter({ adminId }) {
    const [notifications, setNotifications] = useState([]);
    const [unreadCount, setUnreadCount] = useState(0);
    const [isOpen, setIsOpen] = useState(false);
    const [selectedFilter, setSelectedFilter] = useState('all');

    useEffect(() => {
        if (!adminId) return;

        // Subscribe to notifications
        const unsubscribeNotifications = subscribeToAdminNotifications(
            adminId,
            setNotifications
        );

        // Subscribe to unread count
        const unsubscribeUnreadCount = subscribeToUnreadCount(
            adminId,
            setUnreadCount
        );

        return () => {
            unsubscribeNotifications?.();
            unsubscribeUnreadCount?.();
        };
    }, [adminId]);

    const handleMarkAsRead = async (notificationId) => {
        try {
            await markNotificationAsRead(adminId, notificationId);
        } catch (error) {
            console.error('Error marking notification as read:', error);
        }
    };

    const handleMarkAllAsRead = async () => {
        try {
            await markAllNotificationsAsRead(adminId);
        } catch (error) {
            console.error('Error marking all as read:', error);
        }
    };

    const handleDeleteNotification = async (notificationId) => {
        try {
            await deleteNotification(adminId, notificationId);
        } catch (error) {
            console.error('Error deleting notification:', error);
        }
    };

    const filteredNotifications = notifications.filter((notif) => {
        if (selectedFilter === 'unread') return !notif.isRead;
        if (selectedFilter === 'approvals')
            return ['approval', 'rejection'].includes(notif.type);
        return true;
    });

    return (
        <div className="relative">
            {/* Notification Bell Button */}
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="relative p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition"
            >
                <Bell size={20} />
                {unreadCount > 0 && (
                    <span className="absolute top-0 right-0 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white transform translate-x-1/2 -translate-y-1/2 bg-red-600 rounded-full">
                        {unreadCount > 99 ? '99+' : unreadCount}
                    </span>
                )}
            </button>

            {/* Notification Dropdown */}
            {isOpen && (
                <div className="absolute right-0 mt-2 w-96 bg-white rounded-lg shadow-lg z-50">
                    {/* Header */}
                    <div className="flex items-center justify-between p-4 border-b">
                        <h3 className="font-bold">Notifications</h3>
                        <button
                            onClick={() => setIsOpen(false)}
                            className="text-gray-400 hover:text-gray-600"
                        >
                            <X size={18} />
                        </button>
                    </div>

                    {/* Filter Tabs */}
                    <div className="flex gap-2 p-3 border-b overflow-x-auto">
                        {['all', 'unread', 'approvals'].map((filter) => (
                            <button
                                key={filter}
                                onClick={() => setSelectedFilter(filter)}
                                className={`px-3 py-1 rounded-full text-sm whitespace-nowrap transition ${
                                    selectedFilter === filter
                                        ? 'bg-blue-100 text-blue-700'
                                        : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                                }`}
                            >
                                {filter.charAt(0).toUpperCase() +
                                    filter.slice(1)}
                            </button>
                        ))}
                    </div>

                    {/* Notifications List */}
                    <div className="max-h-96 overflow-y-auto">
                        {filteredNotifications.length === 0 ? (
                            <div className="p-8 text-center text-gray-500">
                                <Bell size={32} className="mx-auto mb-2 opacity-50" />
                                <p>No notifications</p>
                            </div>
                        ) : (
                            filteredNotifications.map((notification) => (
                                <AdminNotificationItem
                                    key={notification.id}
                                    notification={notification}
                                    onMarkAsRead={() =>
                                        handleMarkAsRead(notification.id)
                                    }
                                    onDelete={() =>
                                        handleDeleteNotification(notification.id)
                                    }
                                />
                            ))
                        )}
                    </div>

                    {/* Actions Footer */}
                    {notifications.length > 0 && (
                        <div className="flex gap-2 p-3 border-t">
                            <button
                                onClick={handleMarkAllAsRead}
                                disabled={unreadCount === 0}
                                className="flex-1 flex items-center justify-center gap-2 px-3 py-2 bg-blue-50 text-blue-600 rounded hover:bg-blue-100 disabled:opacity-50 disabled:cursor-not-allowed transition"
                            >
                                <CheckCheck size={16} />
                                Mark All Read
                            </button>
                            <button
                                onClick={async () => {
                                    if (confirm('Delete all notifications?')) {
                                        await deleteAllNotifications(adminId);
                                    }
                                }}
                                className="flex-1 flex items-center justify-center gap-2 px-3 py-2 bg-red-50 text-red-600 rounded hover:bg-red-100 transition"
                            >
                                <Trash2 size={16} />
                                Delete All
                            </button>
                        </div>
                    )}
                </div>
            )}
        </div>
    );
}

/**
 * Individual Notification Item
 */
export function AdminNotificationItem({
    notification,
    onMarkAsRead,
    onDelete,
}) {
    const getNotificationColor = (type) => {
        switch (type) {
            case 'approval':
                return 'bg-green-50 border-l-4 border-green-500';
            case 'rejection':
                return 'bg-red-50 border-l-4 border-red-500';
            case 'alert':
                return 'bg-yellow-50 border-l-4 border-yellow-500';
            default:
                return 'bg-blue-50 border-l-4 border-blue-500';
        }
    };

    const getNotificationIcon = (type) => {
        switch (type) {
            case 'approval':
                return '✓';
            case 'rejection':
                return '✗';
            case 'alert':
                return '⚠';
            default:
                return 'ℹ';
        }
    };

    return (
        <div
            className={`p-4 border-b hover:bg-gray-50 transition cursor-pointer ${
                !notification.isRead ? 'bg-blue-50' : ''
            } ${getNotificationColor(notification.type)}`}
            onClick={!notification.isRead ? onMarkAsRead : undefined}
        >
            <div className="flex items-start gap-3">
                {/* Icon */}
                <div className="flex-shrink-0 text-xl">
                    {getNotificationIcon(notification.type)}
                </div>

                {/* Content */}
                <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                        <p
                            className={`font-semibold text-sm truncate ${
                                !notification.isRead
                                    ? 'font-bold'
                                    : 'font-medium'
                            }`}
                        >
                            {notification.title}
                        </p>
                        {!notification.isRead && (
                            <span className="flex-shrink-0 w-2 h-2 bg-blue-500 rounded-full mt-1"></span>
                        )}
                    </div>
                    <p className="text-xs text-gray-600 mt-1">
                        {notification.body}
                    </p>
                    <p className="text-xs text-gray-400 mt-2">
                        {formatTime(notification.createdAt)}
                    </p>
                </div>

                {/* Delete Button */}
                <button
                    onClick={(e) => {
                        e.stopPropagation();
                        onDelete();
                    }}
                    className="flex-shrink-0 text-gray-400 hover:text-red-600 transition"
                >
                    <Trash2 size={14} />
                </button>
            </div>
        </div>
    );
}

/**
 * System Alerts Component - For critical system notifications
 */
export function AdminSystemAlerts() {
    const [alerts, setAlerts] = useState([]);

    useEffect(() => {
        const unsubscribe = subscribeToSystemAlerts(setAlerts);
        return () => unsubscribe?.();
    }, []);

    if (alerts.length === 0) return null;

    return (
        <div className="space-y-2">
            {alerts.map((alert) => (
                <div
                    key={alert.id}
                    className="flex items-start gap-3 p-4 bg-yellow-50 border border-yellow-200 rounded-lg"
                >
                    <AlertTriangle
                        size={20}
                        className="text-yellow-600 flex-shrink-0 mt-0.5"
                    />
                    <div className="flex-1">
                        <h4 className="font-semibold text-yellow-900">
                            {alert.title}
                        </h4>
                        <p className="text-sm text-yellow-800 mt-1">
                            {alert.message}
                        </p>
                    </div>
                </div>
            ))}
        </div>
    );
}

/**
 * Pending Approvals Widget
 */
export function AdminPendingApprovalsWidget() {
    const [pending, setPending] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchPending = async () => {
            try {
                const items = await getPendingNotifications();
                setPending(items);
            } catch (error) {
                console.error('Error fetching pending items:', error);
            } finally {
                setLoading(false);
            }
        };

        fetchPending();
        // Refresh every 30 seconds
        const interval = setInterval(fetchPending, 30000);

        return () => clearInterval(interval);
    }, []);

    if (loading) {
        return <div className="animate-pulse">Loading...</div>;
    }

    if (pending.length === 0) {
        return (
            <div className="p-4 bg-green-50 border border-green-200 rounded-lg text-center">
                <p className="text-green-600 font-semibold">
                    All approvals are up to date ✓
                </p>
            </div>
        );
    }

    return (
        <div className="space-y-2">
            <div className="flex items-center justify-between p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <div>
                    <h3 className="font-bold text-blue-900">
                        Pending Approvals
                    </h3>
                    <p className="text-sm text-blue-700">
                        {pending.length} item(s) awaiting review
                    </p>
                </div>
                <span className="inline-flex items-center justify-center w-8 h-8 bg-blue-500 text-white rounded-full font-bold">
                    {pending.length > 99 ? '99+' : pending.length}
                </span>
            </div>

            {pending.slice(0, 5).map((item) => (
                <div
                    key={item.id}
                    className="p-3 bg-white border rounded hover:shadow-md transition cursor-pointer"
                >
                    <div className="flex items-start justify-between">
                        <div>
                            <p className="font-semibold text-sm">
                                {item.type === 'product'
                                    ? 'Product'
                                    : 'Auction'}{' '}
                                Approval
                            </p>
                            <p className="text-xs text-gray-600 mt-1">
                                {item.title}
                            </p>
                        </div>
                        <span className="text-xs bg-yellow-100 text-yellow-800 px-2 py-1 rounded">
                            Pending
                        </span>
                    </div>
                </div>
            ))}
        </div>
    );
}

// Helper function to format time
function formatTime(timestamp) {
    if (!timestamp) return '';

    let date = timestamp;
    if (timestamp.toDate) {
        date = timestamp.toDate();
    } else if (typeof timestamp === 'string') {
        date = new Date(timestamp);
    }

    const now = new Date();
    const diffMs = now - date;
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;

    return date.toLocaleDateString();
}
