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

// Get all users with details (combines buyers and sellers)
export const getAllUsers = async () => {
    try {
        const buyersRef = collection(db, 'buyers');
        const sellersRef = collection(db, 'sellers');

        const [buyersSnap, sellersSnap] = await Promise.all([
            getDocs(buyersRef),
            getDocs(sellersRef)
        ]);

        const buyers = buyersSnap.docs.map(doc => ({
            id: doc.id,
            type: 'buyer',
            ...doc.data()
        }));

        const sellers = sellersSnap.docs.map(doc => ({
            id: doc.id,
            type: 'seller',
            ...doc.data()
        }));

        return [...buyers, ...sellers];
    } catch (error) {
        console.error('Error fetching users:', error);
        return [];
    }
};

// Get user by ID with full details (checks both buyers and sellers)
export const getUserById = async (userId) => {
    try {
        // Try buyers first
        const buyerRef = doc(db, 'buyers', userId);
        const buyerSnap = await getDoc(buyerRef);
        if (buyerSnap.exists()) {
            return { id: userId, type: 'buyer', ...buyerSnap.data() };
        }

        // Try sellers
        const sellerRef = doc(db, 'sellers', userId);
        const sellerSnap = await getDoc(sellerRef);
        if (sellerSnap.exists()) {
            return { id: userId, type: 'seller', ...sellerSnap.data() };
        }

        throw new Error('User not found in buyers or sellers collection');
    } catch (error) {
        console.error('Error fetching user:', error);
        throw error;
    }
};

// Deactivate user account (updates buyers or sellers collection)
export const deactivateUserAccount = async (userId) => {
    try {
        // Try to update in buyers collection
        const buyerRef = doc(db, 'buyers', userId);
        const buyerSnap = await getDoc(buyerRef);

        if (buyerSnap.exists()) {
            await updateDoc(buyerRef, {
                isActive: false,
                deactivatedAt: new Date()
            });
            return true;
        }

        // Try sellers collection
        const sellerRef = doc(db, 'sellers', userId);
        await updateDoc(sellerRef, {
            isActive: false,
            deactivatedAt: new Date()
        });
        return true;
    } catch (error) {
        throw error;
    }
};

// Activate user account (updates buyers or sellers collection)
export const activateUserAccount = async (userId) => {
    try {
        // Try to update in buyers collection
        const buyerRef = doc(db, 'buyers', userId);
        const buyerSnap = await getDoc(buyerRef);

        if (buyerSnap.exists()) {
            await updateDoc(buyerRef, {
                isActive: true,
                activatedAt: new Date()
            });
            return true;
        }

        // Try sellers collection
        const sellerRef = doc(db, 'sellers', userId);
        await updateDoc(sellerRef, {
            isActive: true,
            activatedAt: new Date()
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
        console.error('Error fetching products:', error);
        return [];
    }
};

// Get all auctions
export const getAllAuctions = async () => {
    try {
        const auctionsRef = collection(db, 'auctions');
        const snapshot = await getDocs(auctionsRef);
        return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        console.error('Error fetching auctions:', error);
        return [];
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

// Get user statistics (combines buyers and sellers)
export const getUserStats = async () => {
    try {
        const buyersRef = collection(db, 'buyers');
        const sellersRef = collection(db, 'sellers');

        const [buyersSnap, sellersSnap] = await Promise.all([
            getDocs(buyersRef),
            getDocs(sellersRef)
        ]);

        const buyers = buyersSnap.docs;
        const sellers = sellersSnap.docs;

        const activeBuyers = buyers.filter(doc => doc.data().isActive !== false).length;
        const activeSellers = sellers.filter(doc => doc.data().isActive === true).length;

        const total = buyers.length + sellers.length;
        const active = activeBuyers + activeSellers;
        const inactive = total - active;

        return { total, active, inactive };
    } catch (error) {
        console.error('Error getting user stats:', error);
        return { total: 0, active: 0, inactive: 0 };
    }
};

// Get product statistics
export const getProductStats = async () => {
    try {
        const productsRef = collection(db, 'products');
        const snapshot = await getDocs(productsRef);

        const total = snapshot.docs.length;
        const approved = snapshot.docs.filter(doc => doc.data().approvalStatus === 'approved').length;
        const pending = snapshot.docs.filter(doc => doc.data().approvalStatus === 'pending').length;
        const rejected = snapshot.docs.filter(doc => doc.data().approvalStatus === 'rejected').length;

        return { total, approved, pending, rejected };
    } catch (error) {
        console.error('Error getting product stats:', error);
        return { total: 0, approved: 0, pending: 0, rejected: 0 };
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
        console.error('Error fetching revenue analytics:', error);
        return { totalRevenue: 0, completedOrders: 0, pendingOrders: 0 };
    }
};

// Get recent activity
export const getRecentActivity = async (limit = 10) => {
    try {
        const buyersRef = collection(db, 'buyers');
        const sellersRef = collection(db, 'sellers');

        const [buyersSnapshot, sellersSnapshot] = await Promise.all([
            getDocs(buyersRef),
            getDocs(sellersRef)
        ]);

        const buyersActivity = buyersSnapshot.docs.map(doc => ({
            id: doc.id,
            type: 'buyer',
            userType: 'buyer',
            ...doc.data()
        }));

        const sellersActivity = sellersSnapshot.docs.map(doc => ({
            id: doc.id,
            type: 'seller',
            userType: 'seller',
            ...doc.data()
        }));

        const activities = [...buyersActivity, ...sellersActivity]
            .filter(user => user.createdAt || user.timestamp)
            .sort((a, b) => {
                const dateA = (a.createdAt?.toDate?.() || new Date(a.createdAt)) || (a.timestamp?.toDate?.() || new Date(a.timestamp));
                const dateB = (b.createdAt?.toDate?.() || new Date(b.createdAt)) || (b.timestamp?.toDate?.() || new Date(b.timestamp));
                return dateB - dateA;
            })
            .slice(0, limit);

        return activities;
    } catch (error) {
        console.error('Error fetching recent activity:', error);
        return [];
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
        console.error('Error verifying seller:', error);
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
        console.error('Error rejecting seller:', error);
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
        console.error('Error fetching platform stats:', error);
        return {
            totalUsers: 0,
            totalProducts: 0,
            totalAuctions: 0,
            timestamp: new Date()
        };
    }
};