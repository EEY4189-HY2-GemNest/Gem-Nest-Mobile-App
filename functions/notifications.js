const functions = require('firebase-functions');
const admin = require('firebase-admin');
const emailService = require('./email_service');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');

// NOTE: Do NOT call admin.initializeApp() here!
// It's already called in index.js which imports this module.

function getDb() {
    return admin.firestore();
}

function getMessaging() {
    return admin.messaging();
}

// Helper function to get user's FCM tokens from all collections
async function getUserFCMTokens(userId) {
    const db = getDb();
    try {
        const tokens = [];

        // Check users collection
        const userDoc = await db.collection('users').doc(userId).get();
        if (userDoc.exists && userDoc.data().fcmToken) {
            tokens.push(userDoc.data().fcmToken);
        }

        // Check buyers collection if not found
        if (tokens.length === 0) {
            const buyerDoc = await db.collection('buyers').doc(userId).get();
            if (buyerDoc.exists && buyerDoc.data().fcmToken) {
                tokens.push(buyerDoc.data().fcmToken);
            }
        }

        // Check sellers collection if not found
        if (tokens.length === 0) {
            const sellerDoc = await db.collection('sellers').doc(userId).get();
            if (sellerDoc.exists && sellerDoc.data().fcmToken) {
                tokens.push(sellerDoc.data().fcmToken);
            }
        }

        return tokens;
    } catch (error) {
        console.error('Error getting FCM tokens:', error);
        return [];
    }
}

// Helper function to save notification to database
async function saveNotification(userId, notification) {
    const db = getDb();
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

// Helper function to send notification via FCM
async function sendNotification(tokens, notification) {
    if (tokens.length === 0) return;

    const messaging = getMessaging();
    try {
        const message = {
            notification: {
                title: notification.title,
                body: notification.body,
            },
            data: {
                ...(notification.data || {}),
                // Ensure all values are strings for FCM data payload
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
                ttl: 86400000,
                priority: 'high',
                notification: {
                    channelId: 'gemnest_channel',
                    priority: 'high',
                    defaultSound: true,
                    defaultVibrateTimings: true,
                },
            },
            apns: {
                headers: {
                    'apns-priority': '10',
                },
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                    },
                },
            },
        };

        // Send to each token individually (sendEachForMulticast is the newer API)
        const response = await messaging.sendEachForMulticast({
            ...message,
            tokens: tokens,
        });

        console.log(`Sent notification to ${response.successCount}/${tokens.length} devices`);

        // Clean up invalid tokens
        response.responses.forEach((resp, idx) => {
            if (!resp.success) {
                console.error(`Failed to send to token ${idx}:`, resp.error?.message);
            }
        });

        return response;
    } catch (error) {
        console.error('Error sending notification:', error);
    }
}

// ============================================================================
// REGISTRATION NOTIFICATIONS (Cloud Function triggered by notification_triggers)
// ============================================================================

/**
 * Process notification triggers written by the Flutter app
 * This handles: registration, report notifications, bid reminders, etc.
 */
exports.onNotificationTrigger = onDocumentCreated(
    'notification_triggers/{triggerId}',
    async (event) => {
        const snap = event.data;
        const context = { params: event.params };
        const db = getDb();
        const triggerData = snap.data();
        const triggerType = triggerData.type;

        try {
            switch (triggerType) {
                case 'welcomeRegistration': {
                    const userId = triggerData.userId;
                    const tokens = await getUserFCMTokens(userId);
                    await sendNotification(tokens, {
                        title: '🎉 Welcome to GemNest!',
                        body: 'Your account has been created. Start exploring our gemstone collection!',
                        data: {
                            type: 'welcomeRegistration',
                            userId: userId,
                        },
                    });

                    // Send welcome email
                    await emailService.sendWelcomeEmail(userId, {
                        email: triggerData.email,
                        displayName: triggerData.displayName || triggerData.name,
                    });
                    break;
                }
                case 'sellerRegistrationPending': {
                    const userId = triggerData.userId;
                    const tokens = await getUserFCMTokens(userId);
                    await sendNotification(tokens, {
                        title: '📋 Account Under Review',
                        body: `Your seller account for "${triggerData.businessName}" is under review.`,
                        data: {
                            type: 'sellerRegistrationPending',
                            userId: userId,
                        },
                    });

                    // Also send FCM to admins AND save notifications to Firestore
                    const adminsSnapshot = await db
                        .collection('users')
                        .where('role', '==', 'admin')
                        .get();

                    for (const adminDoc of adminsSnapshot.docs) {
                        const adminTokens = await getUserFCMTokens(adminDoc.id);
                        const adminNotification = {
                            title: '👤 New Seller Registration',
                            body: `New seller "${triggerData.businessName}" needs verification.`,
                            type: 'newSellerRegistration',
                            data: {
                                type: 'newSellerRegistration',
                                sellerId: userId,
                                sellerEmail: triggerData.email,
                                businessName: triggerData.businessName,
                            },
                        };

                        // Send FCM notification
                        await sendNotification(adminTokens, adminNotification);

                        // Save notification to Firestore for offline access
                        await saveNotification(adminDoc.id, adminNotification);
                    }

                    // Send seller registration details email to admin
                    await emailService.sendSellerRegistrationToAdmin({
                        displayName: triggerData.displayName || triggerData.name,
                        email: triggerData.email,
                        phoneNumber: triggerData.phoneNumber,
                        businessName: triggerData.businessName,
                        brNumber: triggerData.brNumber,
                        nicNumber: triggerData.nicNumber,
                        address: triggerData.address,
                        businessRegistrationUrl: triggerData.businessRegistrationUrl,
                        nicDocumentUrl: triggerData.nicDocumentUrl,
                    }, userId);
                    break;
                }
                case 'seller_activated': {
                    const userId = triggerData.userId;
                    const tokens = await getUserFCMTokens(userId);

                    if (triggerData.status === 'rejected') {
                        // Seller was rejected
                        await sendNotification(tokens, {
                            title: '❌ Account Verification Rejected',
                            body: `Your seller account verification has been rejected.${triggerData.rejectionReason ? ' Reason: ' + triggerData.rejectionReason : ''}`,
                            data: {
                                type: 'sellerAccountRejected',
                                userId: userId,
                            },
                        });
                        await saveNotification(userId, {
                            title: '❌ Account Verification Rejected',
                            body: `Your seller account verification has been rejected.${triggerData.rejectionReason ? ' Reason: ' + triggerData.rejectionReason : ''}`,
                            type: 'sellerAccountRejected',
                        });

                        // Send seller rejection email
                        await emailService.sendSellerRejectionEmail(userId, {
                            email: triggerData.email,
                            displayName: triggerData.displayName,
                            businessName: triggerData.businessName,
                        }, triggerData.rejectionReason);
                    } else {
                        // Seller was approved
                        await sendNotification(tokens, {
                            title: '🎉 Account Activated!',
                            body: `Congratulations! Your seller account "${triggerData.businessName}" has been verified and activated.`,
                            data: {
                                type: 'sellerAccountActivated',
                                userId: userId,
                            },
                        });
                        await saveNotification(userId, {
                            title: '🎉 Account Activated!',
                            body: `Congratulations! Your seller account "${triggerData.businessName}" has been verified and activated.`,
                            type: 'sellerAccountActivated',
                        });

                        // Send seller approval email
                        await emailService.sendSellerApprovalEmail(userId, {
                            email: triggerData.email,
                            displayName: triggerData.displayName,
                            businessName: triggerData.businessName,
                        });
                    }
                    break;
                }
                case 'sellerAccountActivated': {
                    const userId = triggerData.userId;
                    const tokens = await getUserFCMTokens(userId);
                    await sendNotification(tokens, {
                        title: '🎉 Account Activated!',
                        body: `Congratulations ${triggerData.displayName}! Your seller account is now active.`,
                        data: {
                            type: 'sellerAccountActivated',
                            userId: userId,
                        },
                    });

                    // Send seller approval email
                    await emailService.sendSellerApprovalEmail(userId, {
                        email: triggerData.email,
                        displayName: triggerData.displayName,
                        businessName: triggerData.businessName,
                    });
                    break;
                }
                case 'reportSubmitted': {
                    // Send FCM to admins about new report
                    const adminsSnapshot = await db
                        .collection('users')
                        .where('role', '==', 'admin')
                        .get();

                    for (const adminDoc of adminsSnapshot.docs) {
                        const adminTokens = await getUserFCMTokens(adminDoc.id);
                        await sendNotification(adminTokens, {
                            title: '🚨 New Report Submitted',
                            body: `New report: "${triggerData.subject}" needs review.`,
                            data: {
                                type: 'newReportAdmin',
                                reportId: triggerData.reportId,
                            },
                        });
                    }
                    break;
                }
                case 'reportStatusChanged': {
                    const userId = triggerData.userId;
                    const tokens = await getUserFCMTokens(userId);
                    let title = '📋 Report Updated';
                    let body = `Your report "${triggerData.subject}" status changed to ${triggerData.newStatus}.`;

                    switch (triggerData.newStatus) {
                        case 'review':
                            title = '🔍 Report Under Review';
                            body = `Your report "${triggerData.subject}" is now being reviewed.`;
                            break;
                        case 'inProgress':
                            title = '⚙️ Report In Progress';
                            body = `Your report "${triggerData.subject}" is being processed.`;
                            break;
                        case 'done':
                            title = '✅ Report Resolved';
                            body = `Your report "${triggerData.subject}" has been resolved.`;
                            break;
                        case 'rejected':
                            title = '❌ Report Closed';
                            body = `Your report "${triggerData.subject}" has been closed.`;
                            break;
                    }

                    await sendNotification(tokens, {
                        title: title,
                        body: body,
                        data: {
                            type: 'reportStatusChanged',
                            reportId: triggerData.reportId,
                            newStatus: triggerData.newStatus,
                        },
                    });
                    break;
                }
                case 'reportResponseAdded': {
                    const userId = triggerData.userId;
                    const tokens = await getUserFCMTokens(userId);
                    await sendNotification(tokens, {
                        title: '💬 Admin Response',
                        body: `${triggerData.adminName} responded to your report "${triggerData.subject}".`,
                        data: {
                            type: 'reportResponseAdded',
                            reportId: triggerData.reportId,
                        },
                    });
                    break;
                }
                default:
                    console.log(`Unknown notification trigger type: ${triggerType}`);
            }

            // Mark trigger as processed
            await snap.ref.update({ processed: true });
        } catch (error) {
            console.error(`Error processing notification trigger ${triggerType}:`, error);
            await snap.ref.update({ processed: false, error: error.message });
        }
    }
);

// ============================================================================
// PRODUCT APPROVAL NOTIFICATIONS
// ============================================================================

/**
 * Send notification when product is approved/rejected
 */
exports.onProductApprovalChanged = onDocumentUpdated(
    'products/{productId}',
    async (event) => {
        const change = { before: event.data.before(), after: event.data.after() };
        const context = { params: event.params };
        const before = change.before.data();
        const after = change.after.data();

        if (before.approvalStatus === after.approvalStatus) return;

        const sellerId = after.sellerId;
        const tokens = await getUserFCMTokens(sellerId);

        if (after.approvalStatus === 'approved') {
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

            // Send product approval email
            await emailService.sendProductApprovalEmail(sellerId, after, context.params.productId, 'product', 'approved');
        } else if (after.approvalStatus === 'rejected') {
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

            // Send product rejection email
            await emailService.sendProductApprovalEmail(sellerId, after, context.params.productId, 'product', 'rejected', after.rejectionReason);
        }
    }
);

// ============================================================================
// AUCTION APPROVAL NOTIFICATIONS
// ============================================================================

/**
 * Send notification when auction is approved/rejected
 */
exports.onAuctionApprovalChanged = onDocumentUpdated(
    'auctions/{auctionId}',
    async (event) => {
        const change = { before: event.data.before(), after: event.data.after() };
        const context = { params: event.params };
        const before = change.before.data();
        const after = change.after.data();

        if (before.approvalStatus === after.approvalStatus) return;

        const sellerId = after.sellerId;
        const tokens = await getUserFCMTokens(sellerId);

        if (after.approvalStatus === 'approved') {
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

            // Send auction approval email
            await emailService.sendProductApprovalEmail(sellerId, after, context.params.auctionId, 'auction', 'approved');
        } else if (after.approvalStatus === 'rejected') {
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

            // Send auction rejection email
            await emailService.sendProductApprovalEmail(sellerId, after, context.params.auctionId, 'auction', 'rejected', after.rejectionReason);
        }
    }
);

// ============================================================================
// BID NOTIFICATIONS
// ============================================================================

/**
 * Send notification when a new bid is placed on an auction
 */
exports.onNewBid = onDocumentUpdated(
    'auctions/{auctionId}',
    async (event) => {
        const change = { before: event.data.before(), after: event.data.after() };
        const context = { params: event.params };
        const before = change.before.data();
        const after = change.after.data();

        // Only process if currentBid changed (new bid placed)
        if (after.currentBid <= before.currentBid) return;

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
                bidAmount: String(newBid),
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
                    bidAmount: String(newBid),
                    type: 'outbid',
                    actionUrl: `auction/${auctionId}`,
                },
            };
            await sendNotification(previousBidderTokens, outbidNotification);
            await saveNotification(before.winningUserId, outbidNotification);

            // Send outbid email
            await emailService.sendOutbidEmail(before.winningUserId, after, auctionId);
        }
    }
);

// ============================================================================
// AUCTION ENDED NOTIFICATIONS
// ============================================================================

/**
 * Send notification when auction ends
 * Called by a scheduled Cloud Function or HTTP trigger
 */
exports.notifyAuctionEnded = functions.https.onRequest(async (req, res) => {
    const db = getDb();
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

                // Send auction win email to winner
                await emailService.sendAuctionWinEmail(auctionData, null, doc.id);
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
// BID REMINDER NOTIFICATIONS (5 minutes before auction ends)
// ============================================================================

/**
 * Process bid reminders - scheduled via Cloud Scheduler or HTTP trigger
 * Checks bid_reminders collection for reminders that need to be sent
 */
exports.processBidReminders = functions.https.onRequest(async (req, res) => {
    const db = getDb();
    try {
        const now = new Date();
        const fiveMinutesLater = new Date(now.getTime() + 5 * 60000);

        // Get auctions ending within 5 minutes that haven't been reminded
        const remindersSnapshot = await db
            .collection('bid_reminders')
            .where('processed', '==', false)
            .where('reminderTime', '<=', admin.firestore.Timestamp.fromDate(fiveMinutesLater))
            .get();

        let processedCount = 0;

        for (const reminderDoc of remindersSnapshot.docs) {
            const reminderData = reminderDoc.data();
            const auctionId = reminderData.auctionId;

            // Get auction data
            const auctionDoc = await db.collection('auctions').doc(auctionId).get();
            if (!auctionDoc.exists) continue;

            const auctionData = auctionDoc.data();

            // Notify current highest bidder
            if (auctionData.winningUserId) {
                const tokens = await getUserFCMTokens(auctionData.winningUserId);
                const notification = {
                    title: '⏰ Auction Ending in 5 Minutes!',
                    body: `"${auctionData.title}" ends soon! Your current bid: Rs. ${auctionData.currentBid}`,
                    type: 'bidReminder',
                    data: {
                        userId: auctionData.winningUserId,
                        auctionId: auctionId,
                        type: 'bidReminder',
                        actionUrl: `auction/${auctionId}`,
                    },
                };
                await sendNotification(tokens, notification);
                await saveNotification(auctionData.winningUserId, notification);
            }

            // Also notify the seller
            if (auctionData.sellerId) {
                const sellerTokens = await getUserFCMTokens(auctionData.sellerId);
                const sellerNotification = {
                    title: '⏰ Your Auction Ending Soon!',
                    body: `"${auctionData.title}" ends in 5 minutes. Current bid: Rs. ${auctionData.currentBid}`,
                    type: 'bidReminder',
                    data: {
                        userId: auctionData.sellerId,
                        auctionId: auctionId,
                        type: 'bidReminder',
                        actionUrl: `auction/${auctionId}`,
                    },
                };
                await sendNotification(sellerTokens, sellerNotification);
                await saveNotification(auctionData.sellerId, sellerNotification);
            }

            // Mark reminder as processed
            await reminderDoc.ref.update({ processed: true });
            processedCount++;
        }

        res.json({ success: true, processed: processedCount });
    } catch (error) {
        console.error('Error processing bid reminders:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Scheduled function to run every minute to check for bid reminders and ended auctions
 * This runs every minute and checks:
 * 1. Bid reminders (5 min before end)
 * 2. Auctions that have ended
 */
exports.scheduledAuctionCheck = onSchedule('every 1 minutes', async (context) => {
    const db = getDb();
    const now = new Date();

    try {
        // --- Process bid reminders (5 min before end) ---
        const fiveMinutesLater = new Date(now.getTime() + 5 * 60000);

        const remindersSnapshot = await db
            .collection('bid_reminders')
            .where('processed', '==', false)
            .where('reminderTime', '<=', admin.firestore.Timestamp.fromDate(fiveMinutesLater))
            .get();

        for (const reminderDoc of remindersSnapshot.docs) {
            const reminderData = reminderDoc.data();
            const auctionId = reminderData.auctionId;
            const auctionDoc = await db.collection('auctions').doc(auctionId).get();

            if (!auctionDoc.exists) {
                await reminderDoc.ref.update({ processed: true });
                continue;
            }

            const auctionData = auctionDoc.data();

            // Notify highest bidder
            if (auctionData.winningUserId) {
                const tokens = await getUserFCMTokens(auctionData.winningUserId);
                await sendNotification(tokens, {
                    title: '⏰ Auction Ending in 5 Minutes!',
                    body: `"${auctionData.title}" ends soon! Current bid: Rs. ${auctionData.currentBid}`,
                    data: {
                        type: 'bidReminder',
                        auctionId: auctionId,
                    },
                });
                await saveNotification(auctionData.winningUserId, {
                    title: '⏰ Auction Ending in 5 Minutes!',
                    body: `"${auctionData.title}" ends soon! Current bid: Rs. ${auctionData.currentBid}`,
                    type: 'bidReminder',
                    data: { auctionId: auctionId, type: 'bidReminder' },
                });
            }

            // Notify seller
            if (auctionData.sellerId) {
                const sellerTokens = await getUserFCMTokens(auctionData.sellerId);
                await sendNotification(sellerTokens, {
                    title: '⏰ Your Auction Ending Soon!',
                    body: `"${auctionData.title}" ends in 5 minutes. Current bid: Rs. ${auctionData.currentBid}`,
                    data: {
                        type: 'bidReminder',
                        auctionId: auctionId,
                    },
                });
                await saveNotification(auctionData.sellerId, {
                    title: '⏰ Your Auction Ending Soon!',
                    body: `"${auctionData.title}" ends in 5 minutes. Current bid: Rs. ${auctionData.currentBid}`,
                    type: 'bidReminder',
                    data: { auctionId: auctionId, type: 'bidReminder' },
                });
            }

            await reminderDoc.ref.update({ processed: true });
        }

        // --- Process ended auctions ---
        const nowTimestamp = admin.firestore.Timestamp.now();
        const endedAuctions = await db
            .collection('auctions')
            .where('endTime', '<', nowTimestamp.toDate().toISOString())
            .where('notifiedEnded', '==', false)
            .get();

        for (const doc of endedAuctions.docs) {
            const auctionData = doc.data();
            const sellerId = auctionData.sellerId;
            const winnerId = auctionData.winningUserId;

            // Notify seller
            const sellerTokens = await getUserFCMTokens(sellerId);
            await sendNotification(sellerTokens, {
                title: '🏁 Your Auction Ended',
                body: `Auction "${auctionData.title}" has ended. Final bid: Rs. ${auctionData.currentBid}`,
                data: { type: 'auctionEnded', auctionId: doc.id },
            });
            await saveNotification(sellerId, {
                title: '🏁 Your Auction Ended',
                body: `Auction "${auctionData.title}" has ended. Final bid: Rs. ${auctionData.currentBid}`,
                type: 'auctionEnded',
                data: { type: 'auctionEnded', auctionId: doc.id },
            });

            // Notify winner
            if (winnerId) {
                const winnerTokens = await getUserFCMTokens(winnerId);
                await sendNotification(winnerTokens, {
                    title: '🎉 Congratulations! You won!',
                    body: `You won "${auctionData.title}" with Rs. ${auctionData.currentBid}`,
                    data: { type: 'auctionWon', auctionId: doc.id },
                });
                await saveNotification(winnerId, {
                    title: '🎉 Congratulations! You won!',
                    body: `You won "${auctionData.title}" with Rs. ${auctionData.currentBid}`,
                    type: 'auctionWon',
                    data: { type: 'auctionWon', auctionId: doc.id },
                });

                // Send auction win email
                await emailService.sendAuctionWinEmail(auctionData, null, doc.id);
            }

            await db.collection('auctions').doc(doc.id).update({ notifiedEnded: true });
        }

        console.log(`Scheduled check: ${remindersSnapshot.size} reminders, ${endedAuctions.size} ended auctions`);
    } catch (error) {
        console.error('Error in scheduled auction check:', error);
    }

    return null;
}
);

// ============================================================================
// ORDER NOTIFICATIONS
// ============================================================================

/**
 * Send notification when order is created
 */
exports.onOrderCreated = onDocumentCreated(
    'orders/{orderId}',
    async (event) => {
        const snap = event.data;
        const context = { params: event.params };
        const orderData = snap.data();
        const buyerId = orderData.userId;
        const sellerId = orderData.sellerId;

        // Notify buyer
        const buyerTokens = await getUserFCMTokens(buyerId);
        const buyerNotification = {
            title: '📦 Order Confirmed!',
            body: `Your order has been placed successfully. Order ID: ${context.params.orderId}`,
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

        // Send order confirmation email (bill) to buyer
        await emailService.sendOrderConfirmationEmail(orderData, context.params.orderId);

        // Notify seller
        if (sellerId) {
            const sellerTokens = await getUserFCMTokens(sellerId);
            const sellerNotification = {
                title: '🛍️ New Order Received!',
                body: `You have a new order. Order ID: ${context.params.orderId}`,
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
    }
);

/**
 * Send notification when order status changes
 */
exports.onOrderStatusChanged = onDocumentUpdated(
    'orders/{orderId}',
    async (event) => {
        const change = { before: event.data.before(), after: event.data.after() };
        const context = { params: event.params };
        const before = change.before.data();
        const after = change.after.data();

        if (before.status === after.status) return;

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
                body = 'Your order has been delivered successfully.';
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

        // Send order status update email
        await emailService.sendOrderStatusEmail(after, context.params.orderId, after.status);
    }
);

/**
 * Send notification when payment is received
 */
exports.onPaymentReceived = onDocumentUpdated(
    'payments/{paymentId}',
    async (event) => {
        const change = { before: event.data.before(), after: event.data.after() };
        const context = { params: event.params };
        const before = change.before.data();
        const after = change.after.data();

        if (before.paymentStatus === 'completed' || after.paymentStatus !== 'completed') return;

        const sellerId = after.sellerId;
        const tokens = await getUserFCMTokens(sellerId);

        const notification = {
            title: '💰 Payment Received!',
            body: `Payment of Rs. ${after.totalPrice} received for order ${after.orderId}`,
            type: 'paymentReceived',
            data: {
                userId: sellerId,
                paymentId: context.params.paymentId,
                amount: String(after.totalPrice),
                type: 'paymentReceived',
                actionUrl: `payment/${context.params.paymentId}`,
            },
        };

        await sendNotification(tokens, notification);
        await saveNotification(sellerId, notification);

        // Send payment received email to seller
        await emailService.sendPaymentReceivedEmail(after, context.params.paymentId);
    }
);

// ============================================================================
// REPORT NOTIFICATIONS (Firestore Triggers)
// ============================================================================

/**
 * Notify when a new report is created in Firestore
 */
exports.onReportCreated = onDocumentCreated(
    'reports/{reportId}',
    async (event) => {
        const snap = event.data;
        const context = { params: event.params };
        const db = getDb();
        const reportData = snap.data();

        // Notify all admins
        const adminsSnapshot = await db
            .collection('users')
            .where('role', '==', 'admin')
            .get();

        for (const adminDoc of adminsSnapshot.docs) {
            const tokens = await getUserFCMTokens(adminDoc.id);
            const notification = {
                title: '🚨 New Report',
                body: `New report: "${reportData.subject}" (${reportData.category}) needs review.`,
                type: 'newReportAdmin',
                data: {
                    userId: adminDoc.id,
                    reportId: context.params.reportId,
                    category: reportData.category || '',
                    type: 'newReportAdmin',
                    actionUrl: `admin/reports/${context.params.reportId}`,
                },
            };
            await sendNotification(tokens, notification);
            await saveNotification(adminDoc.id, notification);
        }
    }
);

/**
 * Notify user when report status changes
 */
exports.onReportStatusChanged = onDocumentUpdated(
    'reports/{reportId}',
    async (event) => {
        const change = { before: event.data.before(), after: event.data.after() };
        const context = { params: event.params };
        const before = change.before.data();
        const after = change.after.data();

        if (before.status === after.status) return;

        const userId = after.userId;
        const tokens = await getUserFCMTokens(userId);

        let title = '📋 Report Updated';
        let body = `Your report "${after.subject}" has been updated.`;

        switch (after.status) {
            case 'review':
                title = '🔍 Report Under Review';
                body = `Your report "${after.subject}" is now being reviewed.`;
                break;
            case 'inProgress':
                title = '⚙️ Report In Progress';
                body = `Your report "${after.subject}" is being processed.`;
                break;
            case 'done':
                title = '✅ Report Resolved';
                body = `Your report "${after.subject}" has been resolved.`;
                break;
            case 'rejected':
                title = '❌ Report Closed';
                body = `Your report "${after.subject}" has been closed.`;
                break;
        }

        const notification = {
            title: title,
            body: body,
            type: 'reportStatusChanged',
            data: {
                userId: userId,
                reportId: context.params.reportId,
                newStatus: after.status,
                type: 'reportStatusChanged',
                actionUrl: `report/${context.params.reportId}`,
            },
        };

        await sendNotification(tokens, notification);
        await saveNotification(userId, notification);

        // Send report status email
        await emailService.sendReportStatusEmail(userId, after, context.params.reportId, after.status);
    }
);

// ============================================================================
// SELLER ACCOUNT ACTIVATION
// ============================================================================

/**
 * Notify seller when their account is activated by admin
 */
exports.onSellerActivated = onDocumentUpdated(
    'sellers/{sellerId}',
    async (event) => {
        const change = { before: event.data.before(), after: event.data.after() };
        const context = { params: event.params };
        const before = change.before.data();
        const after = change.after.data();

        // Check if isActive changed from false to true
        if (!before.isActive && after.isActive) {
            const sellerId = context.params.sellerId;
            const displayName = after.displayName || after.businessName || 'Seller';
            const tokens = await getUserFCMTokens(sellerId);

            const notification = {
                title: '🎉 Account Activated!',
                body: `Congratulations ${displayName}! Your seller account has been verified and activated.`,
                type: 'sellerAccountActivated',
                data: {
                    userId: sellerId,
                    type: 'sellerAccountActivated',
                },
            };
            await sendNotification(tokens, notification);
            await saveNotification(sellerId, notification);

            // Send seller approval email
            await emailService.sendSellerApprovalEmail(sellerId, after);
        }

        // Check if verification was rejected
        if (before.verificationStatus !== 'rejected' && after.verificationStatus === 'rejected') {
            const sellerId = context.params.sellerId;
            // Send seller rejection email
            await emailService.sendSellerRejectionEmail(sellerId, after, after.rejectionReason);
        }
    }
);

// ============================================================================
// ADMIN NOTIFICATIONS
// ============================================================================

/**
 * Notify all admins when new product needs approval
 */
exports.notifyAdminsNewProduct = onDocumentCreated(
    'products/{productId}',
    async (event) => {
        const snap = event.data;
        const context = { params: event.params };
        const db = getDb();
        try {
            const productData = snap.data();

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
                        actionUrl: 'admin/approvals/products',
                    },
                };
                await sendNotification(tokens, notification);
                await saveNotification(adminDoc.id, notification);
            }

            // Send email to admins about new product
            await emailService.sendNewApprovalNeededEmail(productData, context.params.productId, 'product');
        } catch (error) {
            console.error('Error notifying admins:', error);
        }
    }
);

/**
 * Notify all admins when new auction needs approval
 */
exports.notifyAdminsNewAuction = onDocumentCreated(
    'auctions/{auctionId}',
    async (event) => {
        const snap = event.data;
        const context = { params: event.params };
        const db = getDb();
        try {
            const auctionData = snap.data();

            const adminsSnapshot = await db
                .collection('users')
                .where('role', '==', 'admin')
                .get();

            for (const adminDoc of adminsSnapshot.docs) {
                const tokens = await getUserFCMTokens(adminDoc.id);
                const notification = {
                    title: '⚠️ Auction Needs Approval',
                    body: `New auction "${auctionData.title}" awaits your review.`,
                    type: 'systemMessage',
                    data: {
                        userId: adminDoc.id,
                        auctionId: context.params.auctionId,
                        type: 'systemMessage',
                        actionUrl: 'admin/approvals/auctions',
                    },
                };
                await sendNotification(tokens, notification);
                await saveNotification(adminDoc.id, notification);
            }

            // Send email to admins about new auction
            await emailService.sendNewApprovalNeededEmail(auctionData, context.params.auctionId, 'auction');
        } catch (error) {
            console.error('Error notifying admins about auction:', error);
        }
    }
);

// ============================================================================
// PRODUCT CATEGORY BROADCAST
// ============================================================================

/**
 * Notify interested users when a product in their category is approved
 */
exports.broadcastProductApprovedByCategory = onDocumentUpdated(
    'products/{productId}',
    async (event) => {
        const change = { before: event.data.before(), after: event.data.after() };
        const context = { params: event.params };
        const db = getDb();
        const before = change.before.data();
        const after = change.after.data();

        if (before.approvalStatus === 'approved' || after.approvalStatus !== 'approved') return;

        const category = after.category;
        const productId = context.params.productId;

        const usersSnapshot = await db
            .collection('users')
            .where('interests', 'array-contains', category)
            .get();

        for (const userDoc of usersSnapshot.docs) {
            const tokens = await getUserFCMTokens(userDoc.id);
            const notification = {
                title: `✨ New ${category} Available!`,
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
);

console.log('Notification functions module loaded successfully!');
