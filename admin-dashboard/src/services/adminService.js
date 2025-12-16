import {
    signInWithEmailAndPassword,
    signOut,
    onAuthStateChanged,
    createUserWithEmailAndPassword
} from 'firebase/auth';
import {
    doc,
    getDoc,
    setDoc,
    query,
    collection,
    where,
    getDocs,
    updateDoc
} from 'firebase/firestore';
import { auth, db } from './firebase';

// Admin Login
export const loginAdmin = async (email, password) => {
    try {
        const userCredential = await signInWithEmailAndPassword(auth, email, password);
        const user = userCredential.user;

        // Check if user is admin
        const adminRef = doc(db, 'admins', user.uid);
        const adminSnap = await getDoc(adminRef);

        if (!adminSnap.exists()) {
            await signOut(auth);
            throw new Error('Not authorized as admin');
        }

        return user;
    } catch (error) {
        throw error;
    }
};

// Logout
export const logoutAdmin = async () => {
    try {
        await signOut(auth);
    } catch (error) {
        throw error;
    }
};

// Get current admin user
export const getCurrentAdmin = (callback) => {
    return onAuthStateChanged(auth, async (user) => {
        if (user) {
            const adminRef = doc(db, 'admins', user.uid);
            const adminSnap = await getDoc(adminRef);
            callback(adminSnap.exists() ? { id: user.uid, ...adminSnap.data() } : null);
        } else {
            callback(null);
        }
    });
};

// Get all users with details
export const getAllUsers = async () => {
    try {
        const usersRef = collection(db, 'users');
        const snapshot = await getDocs(usersRef);
        return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        throw error;
    }
};

// Get user by ID with full details
export const getUserById = async (userId) => {
    try {
        const userRef = doc(db, 'users', userId);
        const userSnap = await getDoc(userRef);

        if (!userSnap.exists()) {
            throw new Error('User not found');
        }

        return { id: userId, ...userSnap.data() };
    } catch (error) {
        throw error;
    }
};

// Deactivate user account
export const deactivateUserAccount = async (userId) => {
    try {
        const userRef = doc(db, 'users', userId);
        await updateDoc(userRef, {
            status: 'deactivated',
            deactivatedAt: new Date(),
            isActive: false
        });
        return true;
    } catch (error) {
        throw error;
    }
};

// Activate user account
export const activateUserAccount = async (userId) => {
    try {
        const userRef = doc(db, 'users', userId);
        await updateDoc(userRef, {
            status: 'active',
            isActive: true,
            deactivatedAt: null
        });
        return true;
    } catch (error) {
        throw error;
    }
};

// Get all products
export const getAllProducts = async () => {
    try {
        const productsRef = collection(db, 'products');
        const snapshot = await getDocs(productsRef);
        return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        throw error;
    }
};

// Get all auctions
export const getAllAuctions = async () => {
    try {
        const auctionsRef = collection(db, 'auctions');
        const snapshot = await getDocs(auctionsRef);
        return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        throw error;
    }
};

// Remove/deactivate product
export const removeProduct = async (productId) => {
    try {
        const productRef = doc(db, 'products', productId);
        await updateDoc(productRef, { isActive: false });
        return true;
    } catch (error) {
        throw error;
    }
};

// Get user statistics
export const getUserStats = async () => {
    try {
        const usersRef = collection(db, 'users');
        const snapshot = await getDocs(usersRef);

        const total = snapshot.docs.length;
        const active = snapshot.docs.filter(doc => doc.data().isActive !== false).length;
        const inactive = total - active;

        return { total, active, inactive };
    } catch (error) {
        throw error;
    }
};

// Get product statistics
export const getProductStats = async () => {
    try {
        const productsRef = collection(db, 'products');
        const snapshot = await getDocs(productsRef);

        const total = snapshot.docs.length;
        const active = snapshot.docs.filter(doc => doc.data().isActive !== false).length;

        return { total, active };
    } catch (error) {
        throw error;
    }
};

// Get seller details
export const getSellerDetails = async (sellerId) => {
    try {
        const sellerRef = doc(db, 'sellers', sellerId);
        const sellerSnap = await getDoc(sellerRef);

        if (!sellerSnap.exists()) {
            throw new Error('Seller not found');
        }

        return { id: sellerId, ...sellerSnap.data() };
    } catch (error) {
        throw error;
    }
};

// Get seller products
export const getSellerProducts = async (sellerId) => {
    try {
        const productsRef = collection(db, 'products');
        const q = query(productsRef, where('sellerId', '==', sellerId));
        const snapshot = await getDocs(q);

        return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        throw error;
    }
};

// Get seller auctions
export const getSellerAuctions = async (sellerId) => {
    try {
        const auctionsRef = collection(db, 'auctions');
        const q = query(auctionsRef, where('sellerId', '==', sellerId));
        const snapshot = await getDocs(q);

        return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        throw error;
    }
};

// Get revenue analytics
export const getRevenueAnalytics = async () => {
    try {
        const ordersRef = collection(db, 'orders');
        const snapshot = await getDocs(ordersRef);
        
        let totalRevenue = 0;
        let completedOrders = 0;
        let pendingOrders = 0;

        snapshot.docs.forEach(doc => {
            const data = doc.data();
            if (data.status === 'completed') {
                totalRevenue += data.amount || 0;
                completedOrders++;
            } else if (data.status === 'pending') {
                pendingOrders++;
            }
        });

        return { totalRevenue, completedOrders, pendingOrders };
    } catch (error) {
        throw error;
    }
};

// Get recent activity
export const getRecentActivity = async (limit = 10) => {
    try {
        const usersRef = collection(db, 'users');
        const snapshot = await getDocs(usersRef);
        
        const activities = snapshot.docs
            .map(doc => ({ id: doc.id, ...doc.data() }))
            .filter(user => user.createdAt)
            .sort((a, b) => (b.createdAt?.toDate?.() || b.createdAt) - (a.createdAt?.toDate?.() || a.createdAt))
            .slice(0, limit);

        return activities;
    } catch (error) {
        throw error;
    }
};

// Verify seller
export const verifySeller = async (sellerId) => {
    try {
        const sellerRef = doc(db, 'sellers', sellerId);
        await updateDoc(sellerRef, {
            verified: true,
            verifiedAt: new Date(),
            verificationStatus: 'approved'
        });
    } catch (error) {
        throw error;
    }
};

// Reject seller verification
export const rejectSellerVerification = async (sellerId, reason) => {
    try {
        const sellerRef = doc(db, 'sellers', sellerId);
        await updateDoc(sellerRef, {
            verified: false,
            verificationStatus: 'rejected',
            rejectionReason: reason,
            rejectedAt: new Date()
        });
    } catch (error) {
        throw error;
    }
};

// Get platform statistics
export const getPlatformStats = async () => {
    try {
        const usersRef = collection(db, 'users');
        const productsRef = collection(db, 'products');
        const auctionsRef = collection(db, 'auctions');
        
        const [usersSnap, productsSnap, auctionsSnap] = await Promise.all([
            getDocs(usersRef),
            getDocs(productsRef),
            getDocs(auctionsRef)
        ]);

        return {
            totalUsers: usersSnap.size,
            totalProducts: productsSnap.size,
            totalAuctions: auctionsSnap.size,
            timestamp: new Date()
        };
    } catch (error) {
        throw error;
    }
};