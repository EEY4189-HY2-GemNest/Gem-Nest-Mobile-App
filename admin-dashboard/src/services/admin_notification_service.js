// Admin Notification Service for GemNest Admin Dashboard
// Handles all notification operations for admin users

import { initializeApp } from 'firebase/app';
import {
    getFirestore,
    collection,
    doc,
    getDocs,
    getDoc,
    query,
    where,
    orderBy,
    limit,
    onSnapshot,
    updateDoc,
    deleteDoc,
    writeBatch,
    serverTimestamp,
} from 'firebase/firestore';
import { getMessaging, getToken } from 'firebase/messaging';

// Firebase config - ensure this matches your setup
const firebaseConfig = {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
    storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
    appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const messaging = getMessaging(app);

/**
 * Get admin FCM token for web push notifications
 */
export async function getAdminFCMToken() {
    try {
        const token = await getToken(messaging, {
            vapidKey: import.meta.env.VITE_FIREBASE_VAPID_KEY,
        });
        return token;
    } catch (error) {
        console.error('Error getting FCM token:', error);
        return null;
    }
}

/**
 * Register admin FCM token to Firestore
 */
export async function registerAdminFCMToken(adminId) {
    try {
        const token = await getAdminFCMToken();
        if (!token) {
            console.warn('No FCM token available');
            return;
        }

        const adminRef = doc(db, 'admins', adminId);
        await updateDoc(adminRef, {
            fcmToken: token,
            fcmTokenUpdatedAt: serverTimestamp(),
        });
        console.log('Admin FCM token registered successfully');
    } catch (error) {
        console.error('Error registering admin FCM token:', error);
    }
}

/**
 * Get all pending notifications for admin (approvals)
 */
export async function getPendingNotifications() {
    try {
        // Get products pending approval
        const productsQuery = query(
            collection(db, 'products'),
            where('approvalStatus', '==', 'pending'),
            orderBy('createdAt', 'desc'),
            limit(50)
        );

        // Get auctions pending approval
        const auctionsQuery = query(
            collection(db, 'auctions'),
            where('approvalStatus', '==', 'pending'),
            orderBy('createdAt', 'desc'),
            limit(50)
        );

        const [productsSnapshot, auctionsSnapshot] = await Promise.all([
            getDocs(productsQuery),
            getDocs(auctionsQuery),
        ]);

        const pendingItems = [
            ...productsSnapshot.docs.map((doc) => ({
                id: doc.id,
                type: 'product',
                ...doc.data(),
            })),
            ...auctionsSnapshot.docs.map((doc) => ({
                id: doc.id,
                type: 'auction',
                ...doc.data(),
            })),
        ];

        return pendingItems.sort((a, b) =>
            (b.createdAt?.toDate() || new Date()) -
            (a.createdAt?.toDate() || new Date())
        );
    } catch (error) {
        console.error('Error getting pending notifications:', error);
        return [];
    }
}

/**
 * Get admin notifications stream (real-time)
 */
export function subscribeToAdminNotifications(adminId, callback) {
    try {
        const notificationsRef = collection(
            db,
            'admins',
            adminId,
            'notifications'
        );
        const q = query(
            notificationsRef,
            orderBy('createdAt', 'desc'),
            limit(100)
        );

        const unsubscribe = onSnapshot(
            q,
            (snapshot) => {
                const notifications = snapshot.docs.map((doc) => ({
                    id: doc.id,
                    ...doc.data(),
                }));
                callback(notifications);
            },
            (error) => {
                console.error('Error subscribing to notifications:', error);
            }
        );

        return unsubscribe;
    } catch (error) {
        console.error('Error setting up notifications subscription:', error);
        return () => { };
    }
}

/**
 * Get unread notifications count for admin
 */
export function subscribeToUnreadCount(adminId, callback) {
    try {
        const notificationsRef = collection(
            db,
            'admins',
            adminId,
            'notifications'
        );
        const q = query(notificationsRef, where('isRead', '==', false));

        const unsubscribe = onSnapshot(
            q,
            (snapshot) => {
                callback(snapshot.size);
            },
            (error) => {
                console.error('Error subscribing to unread count:', error);
            }
        );

        return unsubscribe;
    } catch (error) {
        console.error('Error setting up unread count subscription:', error);
        return () => { };
    }
}

/**
 * Mark notification as read
 */
export async function markNotificationAsRead(adminId, notificationId) {
    try {
        const notificationRef = doc(
            db,
            'admins',
            adminId,
            'notifications',
            notificationId
        );
        await updateDoc(notificationRef, {
            isRead: true,
            readAt: serverTimestamp(),
        });
    } catch (error) {
        console.error('Error marking notification as read:', error);
        throw error;
    }
}

/**
 * Mark all notifications as read
 */
export async function markAllNotificationsAsRead(adminId) {
    try {
        const notificationsRef = collection(
            db,
            'admins',
            adminId,
            'notifications'
        );
        const q = query(notificationsRef, where('isRead', '==', false));
        const snapshot = await getDocs(q);

        const batch = writeBatch(db);
        snapshot.forEach((doc) => {
            batch.update(doc.ref, {
                isRead: true,
                readAt: serverTimestamp(),
            });
        });

        await batch.commit();
    } catch (error) {
        console.error('Error marking all notifications as read:', error);
        throw error;
    }
}

/**
 * Delete notification
 */
export async function deleteNotification(adminId, notificationId) {
    try {
        const notificationRef = doc(
            db,
            'admins',
            adminId,
            'notifications',
            notificationId
        );
        await deleteDoc(notificationRef);
    } catch (error) {
        console.error('Error deleting notification:', error);
        throw error;
    }
}

/**
 * Delete all notifications
 */
export async function deleteAllNotifications(adminId) {
    try {
        const notificationsRef = collection(
            db,
            'admins',
            adminId,
            'notifications'
        );
        const snapshot = await getDocs(notificationsRef);

        const batch = writeBatch(db);
        snapshot.forEach((doc) => {
            batch.delete(doc.ref);
        });

        await batch.commit();
    } catch (error) {
        console.error('Error deleting all notifications:', error);
        throw error;
    }
}

/**
 * Get approval statistics
 */
export async function getApprovalStatistics() {
    try {
        const pendingProductsQuery = query(
            collection(db, 'products'),
            where('approvalStatus', '==', 'pending')
        );
        const pendingAuctionsQuery = query(
            collection(db, 'auctions'),
            where('approvalStatus', '==', 'pending')
        );

        const [productsSnapshot, auctionsSnapshot] = await Promise.all([
            getDocs(pendingProductsQuery),
            getDocs(pendingAuctionsQuery),
        ]);

        return {
            pendingProducts: productsSnapshot.size,
            pendingAuctions: auctionsSnapshot.size,
            total: productsSnapshot.size + auctionsSnapshot.size,
        };
    } catch (error) {
        console.error('Error getting approval statistics:', error);
        return {
            pendingProducts: 0,
            pendingAuctions: 0,
            total: 0,
        };
    }
}

/**
 * Get system alerts and critical notifications
 */
export async function getSystemAlerts() {
    try {
        const alertsRef = collection(db, 'system_alerts');
        const q = query(
            alertsRef,
            where('resolved', '==', false),
            orderBy('createdAt', 'desc'),
            limit(20)
        );

        const snapshot = await getDocs(q);
        return snapshot.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
        }));
    } catch (error) {
        console.error('Error getting system alerts:', error);
        return [];
    }
}

/**
 * Subscribe to system alerts in real-time
 */
export function subscribeToSystemAlerts(callback) {
    try {
        const alertsRef = collection(db, 'system_alerts');
        const q = query(
            alertsRef,
            where('resolved', '==', false),
            orderBy('createdAt', 'desc')
        );

        const unsubscribe = onSnapshot(
            q,
            (snapshot) => {
                const alerts = snapshot.docs.map((doc) => ({
                    id: doc.id,
                    ...doc.data(),
                }));
                callback(alerts);
            },
            (error) => {
                console.error('Error subscribing to system alerts:', error);
            }
        );

        return unsubscribe;
    } catch (error) {
        console.error('Error setting up system alerts subscription:', error);
        return () => { };
    }
}

/**
 * Mark system alert as resolved
 */
export async function resolveSystemAlert(alertId) {
    try {
        const alertRef = doc(db, 'system_alerts', alertId);
        await updateDoc(alertRef, {
            resolved: true,
            resolvedAt: serverTimestamp(),
        });
    } catch (error) {
        console.error('Error resolving system alert:', error);
        throw error;
    }
}

/**
 * Send notification to user
 */
export async function sendNotificationToUser(userId, notification) {
    try {
        const userRef = doc(db, 'users', userId);
        const notificationsRef = collection(userRef, 'notifications');

        // Add to user's notifications
        await db.collection('users').doc(userId).collection('notifications').add({
            ...notification,
            createdAt: serverTimestamp(),
            isRead: false,
        });

        return true;
    } catch (error) {
        console.error('Error sending notification:', error);
        throw error;
    }
}

export default {
    getAdminFCMToken,
    registerAdminFCMToken,
    getPendingNotifications,
    subscribeToAdminNotifications,
    subscribeToUnreadCount,
    markNotificationAsRead,
    markAllNotificationsAsRead,
    deleteNotification,
    deleteAllNotifications,
    getApprovalStatistics,
    getSystemAlerts,
    subscribeToSystemAlerts,
    resolveSystemAlert,
    sendNotificationToUser,
};
