/**
 * GemNest Email Service — Cloud Functions Module
 * 
 * Handles all email sending via Nodemailer (SMTP).
 * Works with Gmail, SendGrid, Mailgun, or any SMTP provider.
 * 
 * SETUP:
 * 1. Set environment variables in .env.local:
 *    EMAIL_HOST=smtp.gmail.com
 *    EMAIL_PORT=587
 *    EMAIL_USER=your-email@gmail.com
 *    EMAIL_PASS=your-app-password
 *    EMAIL_FROM="GemNest <noreply@gemnest.com>"
 *    ADMIN_EMAIL=admin@gemnest.com
 * 
 * 2. For Gmail: Enable 2FA and create an App Password
 *    https://myaccount.google.com/apppasswords
 * 
 * 3. Install nodemailer: cd functions && npm install nodemailer
 */

const nodemailer = require('nodemailer');
const admin = require('firebase-admin');
const templates = require('./email_templates');

// ============================================================================
// TRANSPORTER SETUP
// ============================================================================

let transporter = null;

function getTransporter() {
    if (!transporter) {
        const host = process.env.EMAIL_HOST || 'smtp.gmail.com';
        const port = parseInt(process.env.EMAIL_PORT || '587');
        const user = process.env.EMAIL_USER;
        const pass = process.env.EMAIL_PASS;

        if (!user || !pass) {
            console.error('EMAIL_USER or EMAIL_PASS not set. Email sending disabled.');
            return null;
        }

        transporter = nodemailer.createTransport({
            host: host,
            port: port,
            secure: port === 465,
            auth: {
                user: user,
                pass: pass,
            },
            tls: {
                rejectUnauthorized: false,
            },
        });
    }
    return transporter;
}

const FROM_EMAIL = process.env.EMAIL_FROM || '"GemNest" <noreply@gemnest.com>';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@gemnest.com';

// ============================================================================
// CORE SEND FUNCTION
// ============================================================================

/**
 * Send an email with retry logic
 * @param {string} to - Recipient email
 * @param {string} subject - Email subject
 * @param {string} html - HTML content
 * @returns {Promise<boolean>} - Success status
 */
async function sendEmail(to, subject, html) {
    try {
        const transport = getTransporter();
        if (!transport) {
            console.warn('Email transporter not configured. Skipping email to:', to);
            return false;
        }

        const mailOptions = {
            from: FROM_EMAIL,
            to: to,
            subject: subject,
            html: html,
        };

        const info = await transport.sendMail(mailOptions);
        console.log(`✅ Email sent to ${to}: ${info.messageId}`);

        // Log to Firestore for tracking
        await logEmailSent(to, subject, 'sent');

        return true;
    } catch (error) {
        console.error(`❌ Failed to send email to ${to}:`, error.message);
        await logEmailSent(to, subject, 'failed', error.message);
        return false;
    }
}

/**
 * Log email sends to Firestore for auditing
 */
async function logEmailSent(to, subject, status, errorMsg = null) {
    try {
        const db = admin.firestore();
        await db.collection('email_logs').add({
            to: to,
            subject: subject,
            status: status,
            error: errorMsg,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    } catch (err) {
        console.error('Failed to log email:', err.message);
    }
}

// ============================================================================
// HELPER: Get user email from Firestore
// ============================================================================

async function getUserEmail(userId) {
    const db = admin.firestore();

    // Try buyers collection
    const buyerDoc = await db.collection('buyers').doc(userId).get();
    if (buyerDoc.exists && buyerDoc.data().email) {
        return { email: buyerDoc.data().email, name: buyerDoc.data().displayName || buyerDoc.data().name || '' };
    }

    // Try sellers collection
    const sellerDoc = await db.collection('sellers').doc(userId).get();
    if (sellerDoc.exists && sellerDoc.data().email) {
        return { email: sellerDoc.data().email, name: sellerDoc.data().displayName || sellerDoc.data().businessName || '' };
    }

    // Try users collection
    const userDoc = await db.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data().email) {
        return { email: userDoc.data().email, name: userDoc.data().displayName || '' };
    }

    // Try Firebase Auth
    try {
        const userRecord = await admin.auth().getUser(userId);
        return { email: userRecord.email, name: userRecord.displayName || '' };
    } catch (e) {
        console.warn('Could not find email for user:', userId);
        return null;
    }
}

/**
 * Get all admin emails
 */
async function getAdminEmails() {
    const db = admin.firestore();
    const adminsSnapshot = await db.collection('admins').get();
    const emails = [];

    for (const doc of adminsSnapshot.docs) {
        const data = doc.data();
        if (data.email) {
            emails.push(data.email);
        }
    }

    // Also check users collection for admin role
    if (emails.length === 0) {
        const userAdmins = await db.collection('users').where('role', '==', 'admin').get();
        for (const doc of userAdmins.docs) {
            if (doc.data().email) emails.push(doc.data().email);
        }
    }

    // Fallback to env variable
    if (emails.length === 0 && ADMIN_EMAIL) {
        emails.push(ADMIN_EMAIL);
    }

    return emails;
}

// ============================================================================
// EMAIL SENDING FUNCTIONS (Called from notifications.js and triggers)
// ============================================================================

/**
 * 1. Send order confirmation email to buyer (bill/invoice)
 */
async function sendOrderConfirmationEmail(orderData, orderId) {
    try {
        const buyerId = orderData.userId;
        const userInfo = await getUserEmail(buyerId);
        if (!userInfo || !userInfo.email) return false;

        const items = (orderData.items || []).map(item => ({
            name: item.name || item.title || 'Gemstone',
            price: item.price || 0,
            quantity: item.quantity || 1,
            image: item.image || item.imageUrl || null,
        }));

        const html = templates.orderConfirmationTemplate({
            buyerName: orderData.name || userInfo.name || 'Customer',
            orderId: orderId,
            orderDate: orderData.orderDate ? new Date(orderData.orderDate._seconds * 1000).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }) : new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }),
            items: items,
            subtotal: orderData.subtotalBeforeTax || orderData.totalAmount || 0,
            taxPercentage: orderData.taxPercentage || 0,
            taxAmount: orderData.taxAmount || 0,
            serviceChargePercentage: orderData.serviceChargePercentage || 0,
            serviceChargeAmount: orderData.serviceChargeAmount || 0,
            deliveryCharge: orderData.deliveryCharge || 0,
            totalAmount: orderData.totalAmount || 0,
            paymentMethod: orderData.paymentMethod?.name || orderData.paymentMethod || 'N/A',
            deliveryAddress: orderData.address || (orderData.deliveryAddress ? `${orderData.deliveryAddress.street || ''}, ${orderData.deliveryAddress.city || ''} ${orderData.deliveryAddress.postalCode || ''}` : 'N/A'),
            deliveryMethod: orderData.deliveryMethod || orderData.deliveryOption?.name || 'Standard',
            estimatedDelivery: orderData.estimatedDelivery || orderData.deliveryDate || 'TBD',
            specialInstructions: orderData.specialInstructions || '',
        });

        return await sendEmail(
            userInfo.email,
            `Order Confirmed! #${orderId} — GemNest`,
            html
        );
    } catch (error) {
        console.error('Error sending order confirmation email:', error);
        return false;
    }
}

/**
 * 2. Send auction win bill email
 */
async function sendAuctionWinEmail(auctionData, orderData, auctionId) {
    try {
        const winnerId = auctionData.winningUserId || orderData?.userId;
        if (!winnerId) return false;

        const userInfo = await getUserEmail(winnerId);
        if (!userInfo || !userInfo.email) return false;

        const html = templates.auctionWinBillTemplate({
            buyerName: userInfo.name || 'Winner',
            auctionTitle: auctionData.title || 'Auction Item',
            auctionId: auctionId,
            orderId: orderData?.orderId || '',
            winningBid: auctionData.currentBid || orderData?.totalAmount || 0,
            taxPercentage: orderData?.taxPercentage || 0,
            taxAmount: orderData?.taxAmount || 0,
            serviceChargePercentage: orderData?.serviceChargePercentage || 0,
            serviceChargeAmount: orderData?.serviceChargeAmount || 0,
            deliveryCharge: orderData?.deliveryCharge || 0,
            totalAmount: orderData?.totalAmount || auctionData.currentBid || 0,
            paymentMethod: orderData?.paymentMethod || 'N/A',
            deliveryAddress: orderData?.address || '',
            imageUrl: auctionData.imageUrl || auctionData.images?.[0] || '',
        });

        return await sendEmail(
            userInfo.email,
            `🏆 Auction Won! "${auctionData.title}" — GemNest`,
            html
        );
    } catch (error) {
        console.error('Error sending auction win email:', error);
        return false;
    }
}

/**
 * 3. Send seller registration details to admin
 */
async function sendSellerRegistrationToAdmin(sellerData, sellerId) {
    try {
        const adminEmails = await getAdminEmails();
        if (adminEmails.length === 0) return false;

        const html = templates.sellerRegistrationAdminTemplate({
            sellerName: sellerData.displayName || sellerData.name || 'New Seller',
            sellerEmail: sellerData.email || 'N/A',
            phoneNumber: sellerData.phoneNumber || 'N/A',
            businessName: sellerData.businessName || 'N/A',
            brNumber: sellerData.brNumber || 'N/A',
            nicNumber: sellerData.nicNumber || 'N/A',
            address: sellerData.address || '',
            businessRegistrationUrl: sellerData.businessRegistrationUrl || '',
            nicDocumentUrl: sellerData.nicDocumentUrl || '',
            registrationDate: new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }),
        });

        let success = true;
        for (const adminEmail of adminEmails) {
            const result = await sendEmail(
                adminEmail,
                `🆕 New Seller Registration: ${sellerData.businessName || sellerData.displayName} — GemNest`,
                html
            );
            if (!result) success = false;
        }
        return success;
    } catch (error) {
        console.error('Error sending seller registration email to admin:', error);
        return false;
    }
}

/**
 * 4. Send seller approval email
 */
async function sendSellerApprovalEmail(sellerId, sellerData) {
    try {
        const email = sellerData?.email;
        if (!email) {
            const userInfo = await getUserEmail(sellerId);
            if (!userInfo || !userInfo.email) return false;
            sellerData = { ...sellerData, email: userInfo.email };
        }

        const html = templates.sellerApprovalTemplate({
            sellerName: sellerData.displayName || sellerData.businessName || 'Seller',
            businessName: sellerData.businessName || 'Your Business',
        });

        return await sendEmail(
            sellerData.email,
            `🎉 Seller Account Approved — GemNest`,
            html
        );
    } catch (error) {
        console.error('Error sending seller approval email:', error);
        return false;
    }
}

/**
 * 5. Send seller rejection email
 */
async function sendSellerRejectionEmail(sellerId, sellerData, reason) {
    try {
        const email = sellerData?.email;
        if (!email) {
            const userInfo = await getUserEmail(sellerId);
            if (!userInfo || !userInfo.email) return false;
            sellerData = { ...sellerData, email: userInfo.email };
        }

        const html = templates.sellerRejectionTemplate({
            sellerName: sellerData.displayName || sellerData.businessName || 'Seller',
            businessName: sellerData.businessName || 'Your Business',
            rejectionReason: reason || '',
        });

        return await sendEmail(
            sellerData.email,
            `📋 Seller Account Update — GemNest`,
            html
        );
    } catch (error) {
        console.error('Error sending seller rejection email:', error);
        return false;
    }
}

/**
 * 6. Send welcome email to new user
 */
async function sendWelcomeEmail(userId, userData) {
    try {
        const email = userData?.email;
        if (!email) return false;

        const html = templates.welcomeEmailTemplate({
            userName: userData.displayName || userData.name || 'User',
            userEmail: email,
        });

        return await sendEmail(
            email,
            `💎 Welcome to GemNest!`,
            html
        );
    } catch (error) {
        console.error('Error sending welcome email:', error);
        return false;
    }
}

/**
 * 7. Send order status update email
 */
async function sendOrderStatusEmail(orderData, orderId, newStatus) {
    try {
        const buyerId = orderData.userId;
        const userInfo = await getUserEmail(buyerId);
        if (!userInfo || !userInfo.email) return false;

        const html = templates.orderStatusUpdateTemplate({
            buyerName: orderData.name || userInfo.name || 'Customer',
            orderId: orderId,
            newStatus: newStatus,
            items: orderData.items || [],
        });

        const statusLabels = {
            confirmed: 'Confirmed',
            shipped: 'Shipped',
            delivered: 'Delivered',
            cancelled: 'Cancelled',
            refunded: 'Refunded',
        };

        return await sendEmail(
            userInfo.email,
            `Order #${orderId} ${statusLabels[newStatus] || 'Updated'} — GemNest`,
            html
        );
    } catch (error) {
        console.error('Error sending order status email:', error);
        return false;
    }
}

/**
 * 8. Send payment received email to seller
 */
async function sendPaymentReceivedEmail(paymentData, paymentId) {
    try {
        const sellerId = paymentData.sellerId;
        if (!sellerId) return false;

        const userInfo = await getUserEmail(sellerId);
        if (!userInfo || !userInfo.email) return false;

        // Get buyer name
        let buyerName = '';
        if (paymentData.userId) {
            const buyerInfo = await getUserEmail(paymentData.userId);
            buyerName = buyerInfo?.name || '';
        }

        const html = templates.paymentReceivedTemplate({
            sellerName: userInfo.name || 'Seller',
            orderId: paymentData.orderId || paymentId,
            amount: paymentData.totalPrice || paymentData.amount || 0,
            paymentMethod: paymentData.paymentMethod || 'N/A',
            buyerName: buyerName,
        });

        return await sendEmail(
            userInfo.email,
            `💰 Payment Received — Rs. ${paymentData.totalPrice || paymentData.amount || 0} — GemNest`,
            html
        );
    } catch (error) {
        console.error('Error sending payment received email:', error);
        return false;
    }
}

/**
 * 9. Send product/auction approval email to seller
 */
async function sendProductApprovalEmail(sellerId, productData, productId, type, status, rejectionReason) {
    try {
        const userInfo = await getUserEmail(sellerId);
        if (!userInfo || !userInfo.email) return false;

        const html = templates.productApprovalTemplate({
            sellerName: userInfo.name || 'Seller',
            productTitle: productData.title || 'Item',
            productId: productId,
            type: type,
            status: status,
            rejectionReason: rejectionReason || '',
        });

        const typeLabel = type === 'auction' ? 'Auction' : 'Product';
        const statusLabel = status === 'approved' ? 'Approved ✅' : 'Rejected ❌';

        return await sendEmail(
            userInfo.email,
            `${typeLabel} "${productData.title}" ${statusLabel} — GemNest`,
            html
        );
    } catch (error) {
        console.error('Error sending product approval email:', error);
        return false;
    }
}

/**
 * 10. Send outbid notification email
 */
async function sendOutbidEmail(userId, auctionData, auctionId) {
    try {
        const userInfo = await getUserEmail(userId);
        if (!userInfo || !userInfo.email) return false;

        const html = templates.outbidTemplate({
            buyerName: userInfo.name || 'Bidder',
            auctionTitle: auctionData.title || 'Auction',
            currentBid: auctionData.currentBid || 0,
            auctionId: auctionId,
        });

        return await sendEmail(
            userInfo.email,
            `📈 Outbid on "${auctionData.title}" — GemNest`,
            html
        );
    } catch (error) {
        console.error('Error sending outbid email:', error);
        return false;
    }
}

/**
 * 11. Send report status update email
 */
async function sendReportStatusEmail(userId, reportData, reportId, newStatus) {
    try {
        const userInfo = await getUserEmail(userId);
        if (!userInfo || !userInfo.email) return false;

        const html = templates.reportStatusTemplate({
            userName: userInfo.name || 'User',
            reportSubject: reportData.subject || 'Report',
            reportId: reportId,
            newStatus: newStatus,
            adminResponse: reportData.adminResponse || reportData.latestResponse || '',
        });

        return await sendEmail(
            userInfo.email,
            `📋 Report Update: "${reportData.subject}" — GemNest`,
            html
        );
    } catch (error) {
        console.error('Error sending report status email:', error);
        return false;
    }
}

/**
 * 12. Send new product/auction approval needed email to admins
 */
async function sendNewApprovalNeededEmail(itemData, itemId, type) {
    try {
        const adminEmails = await getAdminEmails();
        if (adminEmails.length === 0) return false;

        // Get seller name
        let sellerName = '';
        if (itemData.sellerId) {
            const sellerInfo = await getUserEmail(itemData.sellerId);
            sellerName = sellerInfo?.name || '';
        }

        const typeLabel = type === 'auction' ? 'Auction' : 'Product';

        const html = templates.newApprovalNeededTemplate({
            type: type,
            title: itemData.title || 'Item',
            sellerName: sellerName,
            sellerId: itemData.sellerId || '',
            itemId: itemId,
            category: itemData.category || '',
            price: itemData.price || itemData.startingPrice || 0,
            description: itemData.description || '',
            imageUrl: itemData.imageUrl || (itemData.images && itemData.images[0]) || '',
        });

        let success = true;
        for (const adminEmail of adminEmails) {
            const result = await sendEmail(
                adminEmail,
                `⚠️ New ${typeLabel} Needs Approval: "${itemData.title}" — GemNest`,
                html
            );
            if (!result) success = false;
        }
        return success;
    } catch (error) {
        console.error('Error sending approval needed email:', error);
        return false;
    }
}

module.exports = {
    sendEmail,
    getUserEmail,
    getAdminEmails,
    sendOrderConfirmationEmail,
    sendAuctionWinEmail,
    sendSellerRegistrationToAdmin,
    sendSellerApprovalEmail,
    sendSellerRejectionEmail,
    sendWelcomeEmail,
    sendOrderStatusEmail,
    sendPaymentReceivedEmail,
    sendProductApprovalEmail,
    sendOutbidEmail,
    sendReportStatusEmail,
    sendNewApprovalNeededEmail,
};
