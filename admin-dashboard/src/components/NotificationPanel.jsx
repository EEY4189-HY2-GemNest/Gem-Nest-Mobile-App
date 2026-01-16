import React, { useState, useEffect, useRef } from 'react';
import { Bell, X, CheckCircle, AlertCircle, Info, Trash2 } from 'lucide-react';
import { collection, query, where, orderBy, limit, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase-config';

export default function NotificationPanel() {
    const [notifications, setNotifications] = useState([]);
    const [isOpen, setIsOpen] = useState(false);
    const [loading, setLoading] = useState(true);
    const dropdownRef = useRef(null);

    useEffect(() => {
        // Subscribe to notifications
        const notificationsRef = collection(db, 'notifications');
        const q = query(
            notificationsRef,
            orderBy('timestamp', 'desc'),
            limit(10)
        );

        const unsubscribe = onSnapshot(q, (snapshot) => {
            const notifs = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
            setNotifications(notifs);
            setLoading(false);
        }, (error) => {
            console.error('Error fetching notifications:', error);
            setLoading(false);
        });

        return () => unsubscribe();
    }, []);

    // Close dropdown when clicking outside
    useEffect(() => {
        const handleClickOutside = (event) => {
            if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
                setIsOpen(false);
            }
        };

        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    const unreadCount = notifications.filter(n => !n.read).length;

    const getNotificationIcon = (type) => {
        switch (type) {
            case 'success':
                return <CheckCircle className="w-5 h-5 text-green-400" />;
            case 'warning':
                return <AlertCircle className="w-5 h-5 text-yellow-400" />;
            case 'error':
                return <AlertCircle className="w-5 h-5 text-red-400" />;
            case 'info':
            default:
                return <Info className="w-5 h-5 text-blue-400" />;
        }
    };

    const getNotificationBgColor = (type) => {
        switch (type) {
            case 'success':
                return 'bg-green-900/20 border-green-700/30';
            case 'warning':
                return 'bg-yellow-900/20 border-yellow-700/30';
            case 'error':
                return 'bg-red-900/20 border-red-700/30';
            case 'info':
            default:
                return 'bg-blue-900/20 border-blue-700/30';
        }
    };

    const formatTime = (timestamp) => {
        if (!timestamp) return '';
        try {
            const date = timestamp.seconds ? new Date(timestamp.seconds * 1000) : new Date(timestamp);
            const now = new Date();
            const diffMs = now - date;
            const diffMins = Math.floor(diffMs / 60000);
            const diffHours = Math.floor(diffMs / 3600000);
            const diffDays = Math.floor(diffMs / 86400000);

            if (diffMins < 1) return 'Just now';
            if (diffMins < 60) return `${diffMins}m ago`;
            if (diffHours < 24) return `${diffHours}h ago`;
            if (diffDays < 7) return `${diffDays}d ago`;
            return date.toLocaleDateString();
        } catch {
            return '';
        }
    };

    return (
        <div className="relative" ref={dropdownRef}>
            {/* Notification Bell Icon */}
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="relative p-2 text-gray-400 hover:text-gray-200 transition-colors"
            >
                <Bell className="w-6 h-6" />
                {unreadCount > 0 && (
                    <span className="absolute top-1 right-1 bg-red-500 text-white text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center">
                        {unreadCount > 9 ? '9+' : unreadCount}
                    </span>
                )}
            </button>

            {/* Notification Dropdown */}
            {isOpen && (
                <div className="absolute right-0 mt-2 w-96 bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl border border-gray-700 shadow-2xl z-50 overflow-hidden">
                    {/* Header */}
                    <div className="bg-gradient-to-r from-gray-800 to-gray-900 border-b border-gray-700 px-4 py-3 flex items-center justify-between">
                        <h3 className="text-white font-bold flex items-center gap-2">
                            <Bell className="w-5 h-5 text-blue-400" />
                            Notifications
                        </h3>
                        <button
                            onClick={() => setIsOpen(false)}
                            className="text-gray-400 hover:text-gray-200"
                        >
                            <X className="w-5 h-5" />
                        </button>
                    </div>

                    {/* Notifications List */}
                    <div className="max-h-96 overflow-y-auto">
                        {loading ? (
                            <div className="p-8 text-center">
                                <div className="w-8 h-8 border-4 border-gray-700 border-t-blue-400 rounded-full animate-spin mx-auto mb-3"></div>
                                <p className="text-gray-400 text-sm">Loading notifications...</p>
                            </div>
                        ) : notifications.length > 0 ? (
                            <div className="divide-y divide-gray-700">
                                {notifications.map((notification) => (
                                    <div
                                        key={notification.id}
                                        className={`p-4 border-l-4 border-l-transparent hover:bg-gray-700/20 transition-all cursor-pointer ${
                                            getNotificationBgColor(notification.type)
                                        } ${!notification.read ? 'bg-gray-700/40' : ''}`}
                                    >
                                        <div className="flex items-start gap-3">
                                            {getNotificationIcon(notification.type)}
                                            <div className="flex-1">
                                                <p className="text-white font-semibold text-sm">
                                                    {notification.title}
                                                </p>
                                                <p className="text-gray-400 text-xs mt-1">
                                                    {notification.message}
                                                </p>
                                                <p className="text-gray-500 text-xs mt-2">
                                                    {formatTime(notification.timestamp)}
                                                </p>
                                            </div>
                                            {!notification.read && (
                                                <div className="w-2 h-2 bg-blue-400 rounded-full mt-2 flex-shrink-0"></div>
                                            )}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        ) : (
                            <div className="p-8 text-center">
                                <Bell className="w-8 h-8 mx-auto mb-3 text-gray-600" />
                                <p className="text-gray-400 text-sm">No notifications yet</p>
                            </div>
                        )}
                    </div>

                    {/* Footer */}
                    {notifications.length > 0 && (
                        <div className="border-t border-gray-700 px-4 py-3 bg-gray-900/50">
                            <button className="w-full text-xs text-gray-400 hover:text-gray-200 transition-colors">
                                View all notifications
                            </button>
                        </div>
                    )}
                </div>
            )}
        </div>
    );
}
