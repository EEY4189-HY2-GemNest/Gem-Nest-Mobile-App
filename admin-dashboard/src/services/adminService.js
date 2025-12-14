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

// Get all users
export const getAllUsers = async () => {
  try {
    const usersRef = collection(db, 'users');
    const snapshot = await getDocs(usersRef);
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
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
      isActive: true
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

// Remove product
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
