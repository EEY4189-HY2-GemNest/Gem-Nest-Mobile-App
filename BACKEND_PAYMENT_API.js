/**
 * Backend API for Stripe Payment Integration
 * 
 * This is an example Node.js/Express backend for handling Stripe payments securely.
 * Never expose your Stripe secret key to the frontend.
 * 
 * Installation:
 * npm install express stripe cors dotenv
 * 
 * Environment Variables (.env):
 * STRIPE_SECRET_KEY=sk_test_your_secret_key
 * PORT=3000
 * FRONTEND_URL=http://localhost:3000
 */

const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors({
  origin: process.env.FRONTEND_URL,
  credentials: true
}));
app.use(express.json());

/**
 * Create Payment Intent
 * POST /api/payment/create-intent
 * 
 * Request body:
 * {
 *   "amount": 1000,  // Amount in cents (e.g., $10.00)
 *   "currency": "USD",
 *   "customerId": "user_123",
 *   "description": "Purchase from GemNest"
 * }
 */
app.post('/api/payment/create-intent', async (req, res) => {
  try {
    const { amount, currency, customerId, description } = req.body;

    // Validate input
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }

    if (!currency || currency.length !== 3) {
      return res.status(400).json({ error: 'Invalid currency' });
    }

    // Create payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount), // Amount in cents
      currency: currency.toLowerCase(),
      metadata: {
        customerId,
        description
      },
      description
    });

    res.json({
      client_secret: paymentIntent.client_secret,
      intent_id: paymentIntent.id,
      status: paymentIntent.status
    });
  } catch (error) {
    console.error('Error creating payment intent:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Create Ephemeral Key (for returning customers)
 * POST /api/payment/create-ephemeral-key
 * 
 * Request body:
 * {
 *   "customerId": "user_123",
 *   "apiVersion": "2024-04-10"
 * }
 */
app.post('/api/payment/create-ephemeral-key', async (req, res) => {
  try {
    const { customerId } = req.body;

    if (!customerId) {
      return res.status(400).json({ error: 'Customer ID required' });
    }

    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customerId },
      { apiVersion: '2024-04-10' }
    );

    res.json({
      secret: ephemeralKey.secret
    });
  } catch (error) {
    console.error('Error creating ephemeral key:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Confirm Payment
 * POST /api/payment/confirm
 * 
 * Request body:
 * {
 *   "intentId": "pi_xxx",
 *   "customerId": "user_123"
 * }
 */
app.post('/api/payment/confirm', async (req, res) => {
  try {
    const { intentId, customerId } = req.body;

    if (!intentId) {
      return res.status(400).json({ error: 'Intent ID required' });
    }

    // Retrieve payment intent to verify
    const paymentIntent = await stripe.paymentIntents.retrieve(intentId);

    if (paymentIntent.status === 'succeeded') {
      // Payment successful - update order in database
      // Save order to database with status 'completed'
      
      res.json({
        success: true,
        status: 'completed',
        amount: paymentIntent.amount,
        currency: paymentIntent.currency,
        customerId
      });
    } else if (paymentIntent.status === 'processing') {
      res.json({
        success: false,
        status: 'processing',
        message: 'Payment is processing'
      });
    } else {
      res.status(400).json({
        success: false,
        status: paymentIntent.status,
        message: 'Payment failed'
      });
    }
  } catch (error) {
    console.error('Error confirming payment:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Webhook Handler
 * POST /api/payment/webhook
 * 
 * This endpoint receives events from Stripe
 * Set this URL in Stripe Dashboard: Developers > Webhooks
 * Webhook URL: https://your-domain.com/api/payment/webhook
 */
app.post('/api/payment/webhook', express.raw({type: 'application/json'}), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
  } catch (error) {
    console.error('Webhook signature verification failed:', error);
    return res.sendStatus(400);
  }

  // Handle the event
  switch (event.type) {
    case 'payment_intent.succeeded':
      const paymentIntent = event.data.object;
      console.log('Payment succeeded:', paymentIntent.id);
      
      // Update order status in database to 'completed'
      // Send confirmation email to customer
      // Update customer's purchase history
      
      break;

    case 'payment_intent.payment_failed':
      const failedPayment = event.data.object;
      console.log('Payment failed:', failedPayment.id);
      
      // Update order status to 'failed'
      // Send failure notification
      
      break;

    case 'charge.refunded':
      const refundedCharge = event.data.object;
      console.log('Charge refunded:', refundedCharge.id);
      
      // Update order status to 'refunded'
      // Process refund in your system
      
      break;

    default:
      console.log(`Unhandled event type: ${event.type}`);
  }

  res.json({ received: true });
});

/**
 * Refund Payment
 * POST /api/payment/refund
 * 
 * Request body:
 * {
 *   "intentId": "pi_xxx",
 *   "amount": 1000  // Optional: refund amount in cents
 * }
 */
app.post('/api/payment/refund', async (req, res) => {
  try {
    const { intentId, amount } = req.body;

    if (!intentId) {
      return res.status(400).json({ error: 'Intent ID required' });
    }

    const refund = await stripe.refunds.create({
      payment_intent: intentId,
      amount: amount ? Math.round(amount) : undefined
    });

    res.json({
      success: true,
      refund_id: refund.id,
      status: refund.status,
      amount: refund.amount
    });
  } catch (error) {
    console.error('Error processing refund:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Retrieve Payment Intent
 * GET /api/payment/intent/:intentId
 */
app.get('/api/payment/intent/:intentId', async (req, res) => {
  try {
    const paymentIntent = await stripe.paymentIntents.retrieve(req.params.intentId);
    
    res.json({
      id: paymentIntent.id,
      status: paymentIntent.status,
      amount: paymentIntent.amount,
      currency: paymentIntent.currency,
      client_secret: paymentIntent.client_secret
    });
  } catch (error) {
    console.error('Error retrieving payment intent:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Health Check
 * GET /health
 */
app.get('/health', (req, res) => {
  res.json({ status: 'Server is running' });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Payment server running on port ${PORT}`);
  console.log(`Stripe secret key configured: ${process.env.STRIPE_SECRET_KEY ? 'Yes' : 'No'}`);
});

module.exports = app;

/**
 * SETUP INSTRUCTIONS:
 * 
 * 1. Install dependencies:
 *    npm install express stripe cors dotenv
 * 
 * 2. Create .env file:
 *    STRIPE_SECRET_KEY=sk_test_your_actual_key
 *    STRIPE_WEBHOOK_SECRET=whsec_test_your_webhook_secret
 *    PORT=3000
 *    FRONTEND_URL=http://localhost:3000
 * 
 * 3. Get webhook secret:
 *    - Go to Stripe Dashboard > Developers > Webhooks
 *    - Click "Add endpoint"
 *    - Set endpoint URL: https://your-domain.com/api/payment/webhook
 *    - Select events: payment_intent.succeeded, payment_intent.payment_failed, charge.refunded
 *    - Copy the signing secret
 * 
 * 4. Update your Flutter app's backendUrl in stripe_service.dart:
 *    static const String backendUrl = 'https://your-domain.com';
 * 
 * 5. Start the server:
 *    node server.js
 */
