const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// Helper function to get user's FCM tokens
async function getUserFCMTokens(userId) {
    try {
        const userDoc = await db.collection('users').doc(userId).get();
        const tokens = [];

        if (userDoc.exists) {
            const fcmToken = userDoc.data().fcmToken;
            if (fcmToken) tokens.push(fcmToken);
        }

        return tokens;
    } catch (error) {
        console.error('Error getting FCM tokens:', error);
        return [];
    }
}

// Helper function to save notification to database
async function saveNotification(userId, notification) {
    try {
        const notificationDoc = {
            ...notification,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
        };

        await db
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add(notificationDoc);
    } catch (error) {
        console.error('Error saving notification:', error);
    }
}

// Helper function to send notification
async function sendNotification(tokens, notification) {
    if (tokens.length === 0) return;

    try {
        const message = {
            notification: {
                title: notification.title,
                body: notification.body,
            },
            data: notification.data || {},
            android: {
                ttl: 86400,
                priority: 'high',
            },
            apns: {
                headers: {
                    'apns-priority': '10',
                },
            },
        };

        const response = await messaging.sendMulticast({
            ...message,
            tokens: tokens,
        });

        console.log(`Sent notification to ${response.successCount} devices`);
        return response;
    } catch (error) {
        console.error('Error sending notification:', error);
    }
}

// ============================================================================
// PRODUCT APPROVAL NOTIFICATIONS
// ============================================================================

/**
 * Send notification when product is approved
 * Triggered by admin update on products collection
 */
exports.onProductApproved = functions.firestore
    .document('products/{productId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        // Check if approval status changed to approved
        if (before.approvalStatus !== 'approved' && after.approvalStatus === 'approved') {
            const sellerId = after.sellerId;
            const tokens = await getUserFCMTokens(sellerId);

            const notification = {
                title: '✓ Product Approved!',
                body: `Your product "${after.title}" has been approved and is now visible to customers.`,
                type: 'productApproved',
                data: {
                    userId: sellerId,
                    productId: context.params.productId,
                    type: 'productApproved',
                    actionUrl: `product/${context.params.productId}`,
                },
            };

            await sendNotification(tokens, notification);
            await saveNotification(sellerId, notification);
        }
    });

/**
 * Send notification when product is rejected
 */
exports.onProductRejected = functions.firestore
    .document('products/{productId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        if (before.approvalStatus !== 'rejected' && after.approvalStatus === 'rejected') {
            const sellerId = after.sellerId;
            const tokens = await getUserFCMTokens(sellerId);

            const notification = {
                title: '✗ Product Rejected',
                body: `Your product "${after.title}" was rejected. Check the details for more information.`,
                type: 'productRejected',
                data: {
                    userId: sellerId,
                    productId: context.params.productId,
                    type: 'productRejected',
                    actionUrl: `product/${context.params.productId}/details`,
                },
            };

            await sendNotification(tokens, notification);
            await saveNotification(sellerId, notification);
        }
    });

// ============================================================================
// AUCTION APPROVAL NOTIFICATIONS
// ============================================================================

/**
 * Send notification when auction is approved
 */
exports.onAuctionApproved = functions.firestore
    .document('auctions/{auctionId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        if (before.approvalStatus !== 'approved' && after.approvalStatus === 'approved') {
            const sellerId = after.sellerId;
            const tokens = await getUserFCMTokens(sellerId);

            const notification = {
                title: '✓ Auction Approved!',
                body: `Your auction "${after.title}" has been approved and is now live!`,
                type: 'auctionApproved',
                data: {
                    userId: sellerId,
                    auctionId: context.params.auctionId,
                    type: 'auctionApproved',
                    actionUrl: `auction/${context.params.auctionId}`,
                },
            };

            await sendNotification(tokens, notification);
            await saveNotification(sellerId, notification);
        }
    });

/**
 * Send notification when auction is rejected
 */
exports.onAuctionRejected = functions.firestore
    .document('auctions/{auctionId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        if (before.approvalStatus !== 'rejected' && after.approvalStatus === 'rejected') {
            const sellerId = after.sellerId;
            const tokens = await getUserFCMTokens(sellerId);

            const notification = {
                title: '✗ Auction Rejected',
                body: `Your auction "${after.title}" was rejected. Please review and resubmit.`,
                type: 'auctionRejected',
                data: {
                    userId: sellerId,
                    auctionId: context.params.auctionId,
                    type: 'auctionRejected',
                    actionUrl: `auction/${context.params.auctionId}/details`,
                },
            };

            await sendNotification(tokens, notification);
            await saveNotification(sellerId, notification);
        }
    });

// ============================================================================
// BID NOTIFICATIONS
// ============================================================================

/**
 * Send notification when a new bid is placed on an auction
 */
exports.onNewBid = functions.firestore
    .document('auctions/{auctionId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        // Check if current bid changed (new bid placed)
        if (after.currentBid > before.currentBid) {
            const auctionId = context.params.auctionId;
            const newBid = after.currentBid;
            const winningUserId = after.winningUserId;
            const sellerId = after.sellerId;
            const auctionTitle = after.title;

            // Notify seller about new bid
            const sellerTokens = await getUserFCMTokens(sellerId);
            const sellerNotification = {
                title: '🔨 New Bid!',
                body: `Your auction "${auctionTitle}" received a new bid of Rs. ${newBid}`,
                type: 'newBidOnAuction',
                data: {
                    userId: sellerId,
                    auctionId: auctionId,
                    bidAmount: newBid,
                    type: 'newBidOnAuction',
                    actionUrl: `auction/${auctionId}`,
                },
            };
            await sendNotification(sellerTokens, sellerNotification);
            await saveNotification(sellerId, sellerNotification);

            // Notify previous highest bidder they were outbid
            if (before.winningUserId && before.winningUserId !== winningUserId) {
                const previousBidderTokens = await getUserFCMTokens(before.winningUserId);
                const outbidNotification = {
                    title: '📈 You were outbid!',
                    body: `Someone placed a higher bid on "${auctionTitle}". Current bid: Rs. ${newBid}`,
                    type: 'outbid',
                    data: {
                        userId: before.winningUserId,
                        auctionId: auctionId,
                        bidAmount: newBid,
                        type: 'outbid',
                        actionUrl: `auction/${auctionId}`,
                    },
                };
                await sendNotification(previousBidderTokens, outbidNotification);
                await saveNotification(before.winningUserId, outbidNotification);
            }
        }
    });

// ============================================================================
// AUCTION ENDED NOTIFICATIONS
// ============================================================================

/**
 * Send notification when auction ends
 * Triggered by scheduled function or manual trigger
 */
exports.notifyAuctionEnded = functions.https.onRequest(async (req, res) => {
    try {
        const now = admin.firestore.Timestamp.now();
        const endedAuctions = await db
            .collection('auctions')
            .where('endTime', '<', now.toDate().toISOString())
            .where('notifiedEnded', '==', false)
            .get();

        for (const doc of endedAuctions.docs) {
            const auctionData = doc.data();
            const sellerId = auctionData.sellerId;
            const winnerId = auctionData.winningUserId;

            // Notify seller
            const sellerTokens = await getUserFCMTokens(sellerId);
            const sellerNotification = {
                title: '🏁 Your Auction Ended',
                body: `Auction "${auctionData.title}" has ended. Final bid: Rs. ${auctionData.currentBid}`,
                type: 'auctionEnded',
                data: {
                    userId: sellerId,
                    auctionId: doc.id,
                    type: 'auctionEnded',
                    actionUrl: `auction/${doc.id}/results`,
                },
            };
            await sendNotification(sellerTokens, sellerNotification);
            await saveNotification(sellerId, sellerNotification);

            // Notify winner
            if (winnerId) {
                const winnerTokens = await getUserFCMTokens(winnerId);
                const winnerNotification = {
                    title: '🎉 Congratulations! You won!',
                    body: `You won the auction for "${auctionData.title}" with a bid of Rs. ${auctionData.currentBid}`,
                    type: 'auctionWon',
                    data: {
                        userId: winnerId,
                        auctionId: doc.id,
                        type: 'auctionWon',
                        actionUrl: `auction/${doc.id}/payment`,
                    },
                };
                await sendNotification(winnerTokens, winnerNotification);
                await saveNotification(winnerId, winnerNotification);
            }

            // Mark as notified
            await db.collection('auctions').doc(doc.id).update({
                notifiedEnded: true,
            });
        }

        res.json({ success: true, processed: endedAuctions.size });
    } catch (error) {
        console.error('Error notifying auction ended:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================================
// ORDER NOTIFICATIONS
// ============================================================================

/**
 * Send notification when order is created
 */
exports.onOrderCreated = functions.firestore
    .document('orders/{orderId}')
    .onCreate(async (snap, context) => {
        const orderData = snap.data();
        const buyerId = orderData.userId;
        const sellerId = orderData.sellerId;

        // Notify buyer
        const buyerTokens = await getUserFCMTokens(buyerId);
        const buyerNotification = {
            title: '📦 Order Confirmed!',
            body: `Your order has been placed. Order ID: ${context.params.orderId}`,
            type: 'orderCreated',
            data: {
                userId: buyerId,
                orderId: context.params.orderId,
                type: 'orderCreated',
                actionUrl: `order/${context.params.orderId}`,
            },
        };
        await sendNotification(buyerTokens, buyerNotification);
        await saveNotification(buyerId, buyerNotification);

        // Notify seller
        if (sellerId) {
            const sellerTokens = await getUserFCMTokens(sellerId);
            const sellerNotification = {
                title: '🛍️ New Order!',
                body: `You received a new order. Order ID: ${context.params.orderId}`,
                type: 'orderCreated',
                data: {
                    userId: sellerId,
                    orderId: context.params.orderId,
                    type: 'orderCreated',
                    actionUrl: `order/${context.params.orderId}`,
                },
            };
            await sendNotification(sellerTokens, sellerNotification);
            await saveNotification(sellerId, sellerNotification);
        }
    });

/**
 * Send notification when order status changes
 */
exports.onOrderStatusChanged = functions.firestore
    .document('orders/{orderId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        if (before.status !== after.status) {
            const buyerId = after.userId;
            const tokens = await getUserFCMTokens(buyerId);

            let title = 'Order Update';
            let body = 'Your order status has been updated.';
            let type = 'orderConfirmed';

            switch (after.status) {
                case 'confirmed':
                    title = '✓ Order Confirmed';
                    body = 'Your order has been confirmed by the seller.';
                    type = 'orderConfirmed';
                    break;
                case 'shipped':
                    title = '📦 Order Shipped!';
                    body = 'Your order has been shipped. Track your package.';
                    type = 'orderShipped';
                    break;
                case 'delivered':
                    title = '✓ Order Delivered!';
                    body = 'Your order has been delivered.';
                    type = 'orderDelivered';
                    break;
                case 'cancelled':
                    title = '✗ Order Cancelled';
                    body = 'Your order has been cancelled.';
                    type = 'orderCancelled';
                    break;
            }

            const notification = {
                title: title,
                body: body,
                type: type,
                data: {
                    userId: buyerId,
                    orderId: context.params.orderId,
                    status: after.status,
                    type: type,
                    actionUrl: `order/${context.params.orderId}`,
                },
            };

            await sendNotification(tokens, notification);
            await saveNotification(buyerId, notification);
        }
    });

/**
 * Send notification when payment is received
 */
exports.onPaymentReceived = functions.firestore
    .document('payments/{paymentId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        if (before.paymentStatus !== 'completed' && after.paymentStatus === 'completed') {
            const sellerId = after.sellerId;
            const tokens = await getUserFCMTokens(sellerId);

            const notification = {
                title: '💰 Payment Received!',
                body: `Payment of Rs. ${after.totalPrice} has been received for order ${after.orderId}`,
                type: 'paymentReceived',
                data: {
                    userId: sellerId,
                    paymentId: context.params.paymentId,
                    amount: after.totalPrice,
                    type: 'paymentReceived',
                    actionUrl: `payment/${context.params.paymentId}`,
                },
            };

            await sendNotification(tokens, notification);
            await saveNotification(sellerId, notification);
        }
    });

// ============================================================================
// PRODUCT APPROVAL BROADCAST NOTIFICATIONS
// ============================================================================

/**
 * Send notification to all users when a new product in their interest category is approved
 */
exports.broadcastProductApprovedByCategory = functions.firestore
    .document('products/{productId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        if (before.approvalStatus !== 'approved' && after.approvalStatus === 'approved') {
            const category = after.category;
            const productId = context.params.productId;

            // Get all users interested in this category
            const usersSnapshot = await db
                .collection('users')
                .where('interests', 'array-contains', category)
                .get();

            for (const userDoc of usersSnapshot.docs) {
                const tokens = await getUserFCMTokens(userDoc.id);
                const notification = {
                    title: f'✨ New ${category} Available!',
                    body: `"${after.title}" is now available. Check it out!`,
                    type: 'itemApprovedNotification',
                    data: {
                        userId: userDoc.id,
                        productId: productId,
                        category: category,
                        type: 'itemApprovedNotification',
                        actionUrl: `product/${productId}`,
                    },
                };

                await sendNotification(tokens, notification);
                await saveNotification(userDoc.id, notification);
            }
        }
    });

// ============================================================================
// AUCTION EXPIRING NOTIFICATIONS
// ============================================================================

/**
 * Notify bidders when auction is ending soon (30 minutes)
 */
exports.notifyAuctionEndingSoon = functions.https.onRequest(async (req, res) => {
    try {
        const now = new Date();
        const thirtyMinutesLater = new Date(now.getTime() + 30 * 60000);

        const endingSoonAuctions = await db
            .collection('auctions')
            .where('endTime', '>', now.toISOString())
            .where('endTime', '<', thirtyMinutesLater.toISOString())
            .where('notifiedEnding', '==', false)
            .get();

        for (const doc of endingSoonAuctions.docs) {
            const auctionData = doc.data();

            // Notify current highest bidder
            if (auctionData.winningUserId) {
                const tokens = await getUserFCMTokens(auctionData.winningUserId);
                const notification = {
                    title: '⏰ Auction Ending Soon!',
                    body: `"${auctionData.title}" ends in 30 minutes. Current bid: Rs. ${auctionData.currentBid}`,
                    type: 'auctionEndingoon',
                    data: {
                        userId: auctionData.winningUserId,
                        auctionId: doc.id,
                        type: 'auctionEndingsoon',
                        actionUrl: `auction/${doc.id}`,
                    },
                };

                await sendNotification(tokens, notification);
                await saveNotification(auctionData.winningUserId, notification);
            }

            // Mark as notified
            await db.collection('auctions').doc(doc.id).update({
                notifiedEnding: true,
            });
        }

        res.json({ success: true, processed: endingSoonAuctions.size });
    } catch (error) {
        console.error('Error notifying auction ending soon:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================================
// ADMIN NOTIFICATION
// ============================================================================

/**
 * Notify all admins when new product/auction needs approval
 */
exports.notifyAdminsNewApprovalNeeded = functions.firestore
    .document('products/{productId}')
    .onCreate(async (snap, context) => {
        try {
            const productData = snap.data();

            // Get all admins
            const adminsSnapshot = await db
                .collection('users')
                .where('role', '==', 'admin')
                .get();

            for (const adminDoc of adminsSnapshot.docs) {
                const tokens = await getUserFCMTokens(adminDoc.id);
                const notification = {
                    title: '⚠️ Product Needs Approval',
                    body: `New product "${productData.title}" awaits your review.`,
                    type: 'systemMessage',
                    data: {
                        userId: adminDoc.id,
                        productId: context.params.productId,
                        type: 'systemMessage',
                        actionUrl: `admin/approvals/products`,
                    },
                };

                await sendNotification(tokens, notification);
                await saveNotification(adminDoc.id, notification);
            }
        } catch (error) {
            console.error('Error notifying admins:', error);
        }
    });

console.log('All notification functions deployed successfully!');
