/**
 * Firebase Cloud Functions for Stripe Payment Integration
 * 
 * This replaces the Node.js backend and uses Firebase Cloud Functions instead.
 * 
 * Installation:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Initialize functions: firebase init functions
 * 3. Install dependencies in functions folder:
 *    npm install stripe express cors
 * 
 * Deploy:
 * firebase deploy --only functions
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY || "sk_test_placeholder");
const cors = require("cors")({ origin: true });
const express = require("express");

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Create Express app for HTTP functions
const app = express();
app.use(express.json());

/**
 * Create Payment Intent Cloud Function
 * Called from Flutter app to create a Stripe payment intent
 */
exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
    try {
        // Verify user is authenticated
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const { amount, currency, description, orderId } = data;

        // Validate input
        if (!amount || amount <= 0) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Invalid amount"
            );
        }

        if (!currency || currency.length !== 3) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Invalid currency"
            );
        }

        const customerId = context.auth.uid;

        // Create payment intent with Stripe
        const paymentIntent = await stripe.paymentIntents.create({
            amount: Math.round(amount * 100), // Convert to cents
            currency: currency.toLowerCase(),
            customer: customerId,
            metadata: {
                orderId: orderId || "unknown",
                userId: customerId,
            },
            description: description || "GemNest Purchase",
            automatic_payment_methods: {
                enabled: true,
            },
        });

        // Save order to Firestore with payment intent ID
        const orderRef = db.collection("orders").doc(orderId || paymentIntent.id);
        await orderRef.set(
            {
                userId: customerId,
                paymentIntentId: paymentIntent.id,
                amount: amount,
                currency: currency,
                description: description || "GemNest Purchase",
                status: "pending",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
        );

        return {
            clientSecret: paymentIntent.client_secret,
            intentId: paymentIntent.id,
            status: paymentIntent.status,
        };
    } catch (error) {
        console.error("Error creating payment intent:", error);
        throw new functions.https.HttpsError("internal", error.message);
    }
});

/**
 * Create Ephemeral Key Cloud Function
 * Used for returning customers
 */
exports.createEphemeralKey = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const customerId = context.auth.uid;

        const ephemeralKey = await stripe.ephemeralKeys.create(
            { customer: customerId },
            { apiVersion: "2024-04-10" }
        );

        return {
            secret: ephemeralKey.secret,
        };
    } catch (error) {
        console.error("Error creating ephemeral key:", error);
        throw new functions.https.HttpsError("internal", error.message);
    }
});

/**
 * Confirm Payment Cloud Function
 * Verify payment was successful and update order status
 */
exports.confirmPayment = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const { intentId, orderId } = data;
        const userId = context.auth.uid;

        if (!intentId) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Intent ID required"
            );
        }

        // Retrieve payment intent from Stripe
        const paymentIntent = await stripe.paymentIntents.retrieve(intentId);

        // Verify payment was successful
        if (paymentIntent.status === "succeeded") {
            // Update order status in Firestore
            const orderRef = db.collection("orders").doc(orderId || intentId);
            await orderRef.set(
                {
                    status: "completed",
                    paymentStatus: "paid",
                    paidAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    chargeId: paymentIntent.charges && paymentIntent.charges.data && paymentIntent.charges.data[0] ? paymentIntent.charges.data[0].id : null,
                },
                { merge: true }
            );

            // You can add additional logic here:
            // - Send confirmation email
            // - Create invoice
            // - Update inventory
            // - Trigger order fulfillment

            return {
                success: true,
                status: "completed",
                amount: paymentIntent.amount / 100,
                currency: paymentIntent.currency,
            };
        } else if (paymentIntent.status === "processing") {
            return {
                success: false,
                status: "processing",
                message: "Payment is processing",
            };
        } else {
            // Update order with failed status
            const orderRef = db.collection("orders").doc(orderId || intentId);
            await orderRef.set(
                {
                    status: "failed",
                    paymentStatus: "failed",
                    failedAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                },
                { merge: true }
            );

            return {
                success: false,
                status: paymentIntent.status,
                message: "Payment failed",
            };
        }
    } catch (error) {
        console.error("Error confirming payment:", error);
        throw new functions.https.HttpsError("internal", error.message);
    }
});

/**
 * Webhook Handler Cloud Function
 * Stripe sends payment events to this endpoint
 */
exports.stripeWebhook = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        if (req.method !== "POST") {
            return res.status(400).send("Invalid request method");
        }

        const sig = req.headers["stripe-signature"];
        const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

        let event;

        try {
            event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
        } catch (error) {
            console.error("Webhook signature verification failed:", error);
            return res.status(400).send(`Webhook Error: ${error.message}`);
        }

        try {
            // Handle different Stripe events
            switch (event.type) {
                case "payment_intent.succeeded":
                    const succeededPayment = event.data.object;
                    console.log("Payment succeeded:", succeededPayment.id);

                    // Update order status
                    const succeededOrders = await db
                        .collection("orders")
                        .where("paymentIntentId", "==", succeededPayment.id)
                        .get();

                    for (const doc of succeededOrders.docs) {
                        await doc.ref.update({
                            status: "completed",
                            paymentStatus: "paid",
                            paidAt: admin.firestore.FieldValue.serverTimestamp(),
                            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                        });
                    }

                    // Send confirmation email (implement as needed)
                    // await sendConfirmationEmail(succeededPayment);

                    break;

                case "payment_intent.payment_failed":
                    const failedPayment = event.data.object;
                    console.log("Payment failed:", failedPayment.id);

                    // Update order status
                    const failedOrders = await db
                        .collection("orders")
                        .where("paymentIntentId", "==", failedPayment.id)
                        .get();

                    for (const doc of failedOrders.docs) {
                        await doc.ref.update({
                            status: "failed",
                            paymentStatus: "failed",
                            failedAt: admin.firestore.FieldValue.serverTimestamp(),
                            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                        });
                    }

                    // Send failure notification (implement as needed)
                    // await sendFailureEmail(failedPayment);

                    break;

                case "charge.refunded":
                    const refundedCharge = event.data.object;
                    console.log("Charge refunded:", refundedCharge.id);

                    // Update order status
                    const refundedOrders = await db
                        .collection("orders")
                        .where("chargeId", "==", refundedCharge.id)
                        .get();

                    for (const doc of refundedOrders.docs) {
                        await doc.ref.update({
                            status: "refunded",
                            paymentStatus: "refunded",
                            refundedAt: admin.firestore.FieldValue.serverTimestamp(),
                            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                            refundAmount: refundedCharge.amount_refunded / 100,
                        });
                    }

                    break;

                default:
                    console.log(`Unhandled event type: ${event.type}`);
            }

            res.json({ received: true });
        } catch (error) {
            console.error("Error processing webhook event:", error);
            res.status(500).json({ error: error.message });
        }
    });
});

/**
 * Get Order Details Cloud Function
 */
exports.getOrderDetails = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const { orderId } = data;
        const userId = context.auth.uid;

        if (!orderId) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Order ID required"
            );
        }

        const orderDoc = await db.collection("orders").doc(orderId).get();

        if (!orderDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Order not found");
        }

        const order = orderDoc.data();

        // Verify user owns this order
        if (order.userId !== userId) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "Unauthorized access"
            );
        }

        return order;
    } catch (error) {
        console.error("Error getting order details:", error);
        throw new functions.https.HttpsError("internal", error.message);
    }
});

/**
 * Process Refund Cloud Function
 */
exports.processRefund = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const { orderId, amount } = data;
        const userId = context.auth.uid;

        if (!orderId) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Order ID required"
            );
        }

        // Get order from Firestore
        const orderDoc = await db.collection("orders").doc(orderId).get();

        if (!orderDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Order not found");
        }

        const order = orderDoc.data();

        // Verify user owns this order
        if (order.userId !== userId) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "Unauthorized access"
            );
        }

        // Process refund with Stripe
        const refund = await stripe.refunds.create({
            payment_intent: order.paymentIntentId,
            amount: amount ? Math.round(amount * 100) : undefined,
        });

        // Update order status
        await db.collection("orders").doc(orderId).update({
            status: "refunded",
            paymentStatus: "refunded",
            refundedAt: admin.firestore.FieldValue.serverTimestamp(),
            refundId: refund.id,
            refundAmount: refund.amount / 100,
        });

        return {
            success: true,
            refundId: refund.id,
            status: refund.status,
            amount: refund.amount / 100,
        };
    } catch (error) {
        console.error("Error processing refund:", error);
        throw new functions.https.HttpsError("internal", error.message);
    }
});

/**
 * Get User Orders Cloud Function
 */
exports.getUserOrders = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const userId = context.auth.uid;

        const ordersSnapshot = await db
            .collection("orders")
            .where("userId", "==", userId)
            .orderBy("createdAt", "desc")
            .get();

        const orders = [];
        ordersSnapshot.forEach((doc) => {
            orders.push({
                id: doc.id,
                ...doc.data(),
            });
        });

        return { orders };
    } catch (error) {
        console.error("Error getting user orders:", error);
        throw new functions.https.HttpsError("internal", error.message);
    }
});

/**
 * SETUP INSTRUCTIONS:
 *
 * 1. Install Firebase CLI:
 *    npm install -g firebase-tools
 *
 * 2. Initialize functions in your Firebase project:
 *    firebase init functions
 *
 * 3. Install dependencies in functions folder:
 *    cd functions
 *    npm install stripe express cors
 *
 * 4. Set environment variables:
 *    firebase functions:config:set stripe.secret_key="sk_test_YOUR_KEY"
 *    firebase functions:config:set stripe.webhook_secret="whsec_test_YOUR_WEBHOOK_SECRET"
 *
 * 5. Deploy functions:
 *    firebase deploy --only functions
 *
 * 6. Get your Cloud Function URLs from Firebase Console and update Flutter app
 *
 * 7. Set up Stripe Webhook:
 *    - Go to Stripe Dashboard > Developers > Webhooks
 *    - Click "Add endpoint"
 *    - Set endpoint URL: https://your-region-your-project.cloudfunctions.net/stripeWebhook
 *    - Select events: payment_intent.succeeded, payment_intent.payment_failed, charge.refunded
 *    - Copy the signing secret and set it as environment variable
 */
