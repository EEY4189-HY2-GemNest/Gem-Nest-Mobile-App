/**
 * GemNest Email Templates
 * Beautiful, colorful HTML email templates for all email types
 */

// ============================================================================
// BASE TEMPLATE WRAPPER
// ============================================================================

const baseTemplate = (content, previewText = '') => `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>GemNest</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
    
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Poppins', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f0f2f5; }
    
    .email-wrapper {
      max-width: 640px;
      margin: 0 auto;
      background: #ffffff;
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 4px 24px rgba(0,0,0,0.08);
    }
    
    .header {
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
      padding: 32px 40px;
      text-align: center;
    }
    
    .header-logo {
      font-size: 32px;
      font-weight: 700;
      color: #ffffff;
      letter-spacing: 2px;
    }
    
    .header-logo span {
      background: linear-gradient(135deg, #e94560, #c23152);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }
    
    .header-gem {
      font-size: 40px;
      display: inline-block;
      margin-right: 8px;
    }
    
    .header-tagline {
      color: #a8b2d1;
      font-size: 13px;
      margin-top: 6px;
      letter-spacing: 3px;
      text-transform: uppercase;
    }
    
    .accent-bar {
      height: 4px;
      background: linear-gradient(90deg, #e94560, #c23152, #8b1a4a, #e94560);
      background-size: 300% 100%;
    }
    
    .content {
      padding: 40px;
    }
    
    .greeting {
      font-size: 22px;
      font-weight: 600;
      color: #1a1a2e;
      margin-bottom: 8px;
    }
    
    .subtitle {
      font-size: 15px;
      color: #6b7280;
      margin-bottom: 28px;
      line-height: 1.6;
    }
    
    .info-card {
      background: linear-gradient(135deg, #f8f9ff 0%, #f0f4ff 100%);
      border: 1px solid #e0e7ff;
      border-radius: 12px;
      padding: 24px;
      margin: 20px 0;
    }
    
    .info-card-title {
      font-size: 14px;
      font-weight: 600;
      color: #4338ca;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin-bottom: 16px;
      display: flex;
      align-items: center;
    }
    
    .info-row {
      display: flex;
      justify-content: space-between;
      padding: 8px 0;
      border-bottom: 1px solid #e5e7eb;
      font-size: 14px;
    }
    
    .info-row:last-child { border-bottom: none; }
    .info-label { color: #6b7280; font-weight: 500; }
    .info-value { color: #1f2937; font-weight: 600; text-align: right; }
    
    .total-row {
      display: flex;
      justify-content: space-between;
      padding: 16px 0 0;
      margin-top: 12px;
      border-top: 2px solid #4338ca;
      font-size: 18px;
    }
    
    .total-label { color: #1a1a2e; font-weight: 700; }
    .total-value { color: #e94560; font-weight: 700; font-size: 20px; }
    
    .status-badge {
      display: inline-block;
      padding: 6px 16px;
      border-radius: 20px;
      font-size: 13px;
      font-weight: 600;
      letter-spacing: 0.5px;
    }
    
    .status-confirmed { background: #dcfce7; color: #166534; }
    .status-pending { background: #fef3c7; color: #92400e; }
    .status-shipped { background: #dbeafe; color: #1e40af; }
    .status-delivered { background: #d1fae5; color: #065f46; }
    .status-cancelled { background: #fee2e2; color: #991b1b; }
    .status-approved { background: #dcfce7; color: #166534; }
    .status-rejected { background: #fee2e2; color: #991b1b; }
    
    .item-card {
      display: flex;
      align-items: center;
      padding: 12px;
      margin: 8px 0;
      background: #ffffff;
      border: 1px solid #e5e7eb;
      border-radius: 10px;
    }
    
    .item-img {
      width: 64px;
      height: 64px;
      border-radius: 8px;
      object-fit: cover;
      margin-right: 16px;
      background: #f3f4f6;
    }
    
    .item-details { flex: 1; }
    .item-name { font-size: 14px; font-weight: 600; color: #1f2937; }
    .item-qty { font-size: 12px; color: #6b7280; margin-top: 2px; }
    .item-price { font-size: 15px; font-weight: 700; color: #e94560; }
    
    .cta-button {
      display: inline-block;
      padding: 14px 36px;
      background: linear-gradient(135deg, #e94560, #c23152);
      color: #ffffff !important;
      text-decoration: none;
      border-radius: 10px;
      font-weight: 600;
      font-size: 15px;
      margin: 24px 0;
      text-align: center;
      box-shadow: 0 4px 14px rgba(233, 69, 96, 0.4);
    }
    
    .cta-button:hover {
      background: linear-gradient(135deg, #c23152, #a02040);
    }
    
    .highlight-box {
      background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
      border: 1px solid #f59e0b;
      border-radius: 12px;
      padding: 20px;
      margin: 20px 0;
      text-align: center;
    }
    
    .highlight-box .amount {
      font-size: 32px;
      font-weight: 700;
      color: #92400e;
    }
    
    .highlight-box .label {
      font-size: 13px;
      color: #b45309;
      margin-top: 4px;
    }
    
    .success-box {
      background: linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%);
      border: 1px solid #22c55e;
      border-radius: 12px;
      padding: 24px;
      margin: 20px 0;
      text-align: center;
    }
    
    .success-icon { font-size: 48px; margin-bottom: 8px; }
    .success-title { font-size: 20px; font-weight: 700; color: #166534; }
    .success-text { font-size: 14px; color: #15803d; margin-top: 6px; }
    
    .warning-box {
      background: linear-gradient(135deg, #fff7ed 0%, #ffedd5 100%);
      border: 1px solid #f97316;
      border-radius: 12px;
      padding: 20px;
      margin: 20px 0;
    }
    
    .doc-card {
      background: #f8f9ff;
      border: 1px solid #c7d2fe;
      border-radius: 10px;
      padding: 16px;
      margin: 8px 0;
      display: flex;
      align-items: center;
    }
    
    .doc-icon { font-size: 28px; margin-right: 12px; }
    .doc-name { font-size: 14px; font-weight: 600; color: #1f2937; }
    .doc-link { font-size: 12px; color: #4338ca; text-decoration: underline; }
    
    .divider {
      height: 1px;
      background: #e5e7eb;
      margin: 24px 0;
    }
    
    .footer {
      background: #1a1a2e;
      padding: 32px 40px;
      text-align: center;
    }
    
    .footer-text {
      color: #a8b2d1;
      font-size: 12px;
      line-height: 1.8;
    }
    
    .footer-links {
      margin: 16px 0;
    }
    
    .footer-link {
      color: #e94560;
      text-decoration: none;
      font-size: 12px;
      margin: 0 12px;
      font-weight: 500;
    }
    
    .social-icons {
      margin-top: 16px;
    }
    
    .social-icon {
      display: inline-block;
      width: 36px;
      height: 36px;
      border-radius: 50%;
      background: rgba(255,255,255,0.1);
      margin: 0 6px;
      line-height: 36px;
      font-size: 16px;
      text-decoration: none;
    }

    table { border-collapse: collapse; width: 100%; }
    td { vertical-align: top; }
    
    @media (max-width: 600px) {
      .content { padding: 24px 20px; }
      .header { padding: 24px 20px; }
      .footer { padding: 24px 20px; }
      .greeting { font-size: 18px; }
    }
  </style>
</head>
<body style="margin:0;padding:20px 10px;background:#f0f2f5;">
  ${previewText ? `<div style="display:none;max-height:0;overflow:hidden;">${previewText}</div>` : ''}
  <div class="email-wrapper">
    <div class="header">
      <div><span class="header-gem">💎</span><span class="header-logo">Gem<span>Nest</span></span></div>
      <div class="header-tagline">Premium Gemstone Marketplace</div>
    </div>
    <div class="accent-bar"></div>
    ${content}
    <div class="footer">
      <div class="footer-links">
        <a href="#" class="footer-link">Shop</a>
        <a href="#" class="footer-link">Auctions</a>
        <a href="#" class="footer-link">Support</a>
        <a href="#" class="footer-link">Privacy</a>
      </div>
      <div class="footer-text">
        &copy; ${new Date().getFullYear()} GemNest. All rights reserved.<br>
        Premium Gemstone Marketplace<br><br>
        This is an automated email. Please do not reply directly.<br>
        If you need help, contact us at <a href="mailto:support@gemnest.com" style="color: #e94560;">support@gemnest.com</a>
      </div>
    </div>
  </div>
</body>
</html>
`;

// ============================================================================
// 1. ORDER CONFIRMATION / BILL EMAIL (Regular Purchase)
// ============================================================================

const orderConfirmationTemplate = (data) => {
    const {
        buyerName, orderId, orderDate, items = [],
        subtotal, taxPercentage, taxAmount, serviceChargePercentage,
        serviceChargeAmount, deliveryCharge, totalAmount,
        paymentMethod, deliveryAddress, deliveryMethod,
        estimatedDelivery, specialInstructions
    } = data;

    const itemsHtml = items.map(item => `
        <tr>
            <td style="padding:12px;border-bottom:1px solid #e5e7eb;">
                <div style="display:flex;align-items:center;">
                    ${item.image ? `<img src="${item.image}" style="width:56px;height:56px;border-radius:8px;object-fit:cover;margin-right:12px;" alt="${item.name}">` : '<div style="width:56px;height:56px;border-radius:8px;background:linear-gradient(135deg,#e0e7ff,#c7d2fe);margin-right:12px;text-align:center;line-height:56px;font-size:24px;">💎</div>'}
                    <div>
                        <div style="font-weight:600;color:#1f2937;font-size:14px;">${item.name}</div>
                        <div style="color:#6b7280;font-size:12px;">Qty: ${item.quantity || 1}</div>
                    </div>
                </div>
            </td>
            <td style="padding:12px;border-bottom:1px solid #e5e7eb;text-align:right;font-weight:600;color:#1f2937;">
                Rs. ${(item.price * (item.quantity || 1)).toLocaleString('en-US', { minimumFractionDigits: 2 })}
            </td>
        </tr>
    `).join('');

    return baseTemplate(`
        <div class="content">
            <div class="success-box">
                <div class="success-icon">✅</div>
                <div class="success-title">Order Confirmed!</div>
                <div class="success-text">Thank you for your purchase, ${buyerName}!</div>
            </div>

            <div class="info-card" style="background:linear-gradient(135deg,#eff6ff,#dbeafe);border-color:#93c5fd;">
                <div class="info-card-title" style="color:#1d4ed8;">📋 Order Details</div>
                <div class="info-row">
                    <span class="info-label">Order ID</span>
                    <span class="info-value" style="color:#4338ca;font-family:monospace;">#${orderId}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Order Date</span>
                    <span class="info-value">${orderDate}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Payment Method</span>
                    <span class="info-value">${paymentMethod || 'N/A'}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Status</span>
                    <span class="info-value"><span class="status-badge status-confirmed">Confirmed</span></span>
                </div>
            </div>

            <div class="info-card">
                <div class="info-card-title">🛍️ Items Ordered</div>
                <table style="width:100%;">
                    <thead>
                        <tr>
                            <th style="text-align:left;padding:8px 12px;color:#6b7280;font-size:12px;text-transform:uppercase;letter-spacing:0.5px;border-bottom:2px solid #e5e7eb;">Item</th>
                            <th style="text-align:right;padding:8px 12px;color:#6b7280;font-size:12px;text-transform:uppercase;letter-spacing:0.5px;border-bottom:2px solid #e5e7eb;">Price</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${itemsHtml}
                    </tbody>
                </table>
            </div>

            <div class="info-card" style="background:linear-gradient(135deg,#fefce8,#fef9c3);border-color:#fde047;">
                <div class="info-card-title" style="color:#a16207;">💰 Bill Summary</div>
                <div class="info-row">
                    <span class="info-label">Subtotal</span>
                    <span class="info-value">Rs. ${Number(subtotal).toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Tax (${taxPercentage || 0}%)</span>
                    <span class="info-value">Rs. ${Number(taxAmount || 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Service Charge (${serviceChargePercentage || 0}%)</span>
                    <span class="info-value">Rs. ${Number(serviceChargeAmount || 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Delivery</span>
                    <span class="info-value">Rs. ${Number(deliveryCharge || 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
                </div>
                <div class="total-row">
                    <span class="total-label">Total Amount</span>
                    <span class="total-value">Rs. ${Number(totalAmount).toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
                </div>
            </div>

            <div style="display:flex;gap:16px;margin:20px 0;">
                <div class="info-card" style="flex:1;margin:0;">
                    <div class="info-card-title" style="color:#059669;">📍 Delivery Address</div>
                    <p style="font-size:14px;color:#374151;line-height:1.6;">${deliveryAddress || 'N/A'}</p>
                </div>
                <div class="info-card" style="flex:1;margin:0;">
                    <div class="info-card-title" style="color:#7c3aed;">🚚 Delivery Info</div>
                    <p style="font-size:14px;color:#374151;">Method: <strong>${deliveryMethod || 'Standard'}</strong></p>
                    <p style="font-size:14px;color:#374151;">Est. Delivery: <strong>${estimatedDelivery || 'TBD'}</strong></p>
                </div>
            </div>

            ${specialInstructions ? `
            <div class="warning-box">
                <div style="font-weight:600;color:#9a3412;margin-bottom:4px;">📝 Special Instructions</div>
                <div style="font-size:14px;color:#c2410c;">${specialInstructions}</div>
            </div>
            ` : ''}

            <div style="text-align:center;">
                <a href="#" class="cta-button">Track Your Order</a>
            </div>

            <p style="font-size:13px;color:#9ca3af;text-align:center;margin-top:16px;">
                A copy of this receipt has been saved to your account. You can view your order history anytime in the GemNest app.
            </p>
        </div>
    `, `Order Confirmed! #${orderId} - Total: Rs. ${totalAmount}`);
};

// ============================================================================
// 2. AUCTION WIN BILL EMAIL
// ============================================================================

const auctionWinBillTemplate = (data) => {
    const {
        buyerName, auctionTitle, auctionId, orderId, winningBid,
        taxPercentage, taxAmount, serviceChargePercentage,
        serviceChargeAmount, deliveryCharge, totalAmount,
        paymentMethod, deliveryAddress, imageUrl
    } = data;

    return baseTemplate(`
        <div class="content">
            <div style="background:linear-gradient(135deg,#fef3c7,#fde68a);border:2px solid #f59e0b;border-radius:16px;padding:32px;text-align:center;margin-bottom:24px;">
                <div style="font-size:56px;">🏆</div>
                <div style="font-size:24px;font-weight:700;color:#92400e;margin-top:8px;">Congratulations, ${buyerName}!</div>
                <div style="font-size:15px;color:#b45309;margin-top:6px;">You won the auction!</div>
            </div>

            <div class="info-card" style="background:linear-gradient(135deg,#faf5ff,#f3e8ff);border-color:#c084fc;">
                <div class="info-card-title" style="color:#7c3aed;">🔨 Auction Details</div>
                <div style="display:flex;align-items:center;margin-bottom:16px;">
                    ${imageUrl ? `<img src="${imageUrl}" style="width:80px;height:80px;border-radius:12px;object-fit:cover;margin-right:16px;" alt="${auctionTitle}">` : '<div style="width:80px;height:80px;border-radius:12px;background:linear-gradient(135deg,#e0e7ff,#c7d2fe);margin-right:16px;text-align:center;line-height:80px;font-size:36px;">💎</div>'}
                    <div>
                        <div style="font-size:18px;font-weight:700;color:#1f2937;">${auctionTitle}</div>
                        <div style="font-size:13px;color:#6b7280;margin-top:2px;">Auction ID: ${auctionId}</div>
                    </div>
                </div>
                <div class="info-row">
                    <span class="info-label">Winning Bid</span>
                    <span class="info-value" style="color:#e94560;font-size:18px;">Rs. ${Number(winningBid).toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
                </div>
                ${orderId ? `<div class="info-row">
                    <span class="info-label">Order ID</span>
                    <span class="info-value" style="font-family:monospace;">#${orderId}</span>
                </div>` : ''}
            </div>

            <div class="info-card" style="background:linear-gradient(135deg,#fefce8,#fef9c3);border-color:#fde047;">
                <div class="info-card-title" style="color:#a16207;">💰 Payment Summary</div>
                <div class="info-row">
                    <span class="info-label">Winning Bid</span>
                    <span class="info-value">Rs. ${Number(winningBid).toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Tax (${taxPercentage || 0}%)</span>
                    <span class="info-value">Rs. ${Number(taxAmount || 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Service Charge (${serviceChargePercentage || 0}%)</span>
                    <span class="info-value">Rs. ${Number(serviceChargeAmount || 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Delivery</span>
                    <span class="info-value">Rs. ${Number(deliveryCharge || 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
                </div>
                <div class="total-row">
                    <span class="total-label">Total Paid</span>
                    <span class="total-value">Rs. ${Number(totalAmount).toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
                </div>
            </div>

            <div class="info-card">
                <div class="info-card-title">📦 Delivery & Payment</div>
                <div class="info-row">
                    <span class="info-label">Payment Method</span>
                    <span class="info-value">${paymentMethod || 'N/A'}</span>
                </div>
                ${deliveryAddress ? `<div class="info-row">
                    <span class="info-label">Delivery To</span>
                    <span class="info-value">${deliveryAddress}</span>
                </div>` : ''}
            </div>

            <div style="text-align:center;">
                <a href="#" class="cta-button">View Auction Details</a>
            </div>
        </div>
    `, `You won "${auctionTitle}"! Total: Rs. ${totalAmount}`);
};

// ============================================================================
// 3. SELLER REGISTRATION → ADMIN EMAIL
// ============================================================================

const sellerRegistrationAdminTemplate = (data) => {
    const {
        sellerName, sellerEmail, phoneNumber, businessName,
        brNumber, nicNumber, address, businessRegistrationUrl,
        nicDocumentUrl, registrationDate
    } = data;

    return baseTemplate(`
        <div class="content">
            <div style="background:linear-gradient(135deg,#fff7ed,#ffedd5);border:2px solid #f97316;border-radius:16px;padding:28px;text-align:center;margin-bottom:24px;">
                <div style="font-size:48px;">👤</div>
                <div style="font-size:22px;font-weight:700;color:#9a3412;">New Seller Registration</div>
                <div style="font-size:14px;color:#c2410c;margin-top:4px;">Requires verification and approval</div>
            </div>

            <div class="info-card" style="background:linear-gradient(135deg,#eff6ff,#dbeafe);border-color:#93c5fd;">
                <div class="info-card-title" style="color:#1d4ed8;">👤 Seller Information</div>
                <div class="info-row">
                    <span class="info-label">Full Name</span>
                    <span class="info-value">${sellerName}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Email</span>
                    <span class="info-value" style="color:#4338ca;">${sellerEmail}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Phone</span>
                    <span class="info-value">${phoneNumber}</span>
                </div>
                ${address ? `<div class="info-row">
                    <span class="info-label">Address</span>
                    <span class="info-value">${address}</span>
                </div>` : ''}
                <div class="info-row">
                    <span class="info-label">NIC Number</span>
                    <span class="info-value">${nicNumber}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Registration Date</span>
                    <span class="info-value">${registrationDate || new Date().toLocaleDateString()}</span>
                </div>
            </div>

            <div class="info-card" style="background:linear-gradient(135deg,#f0fdf4,#dcfce7);border-color:#86efac;">
                <div class="info-card-title" style="color:#166534;">🏢 Business Details</div>
                <div class="info-row">
                    <span class="info-label">Business Name</span>
                    <span class="info-value">${businessName}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">BR Number</span>
                    <span class="info-value" style="font-family:monospace;">${brNumber}</span>
                </div>
            </div>

            <div class="info-card">
                <div class="info-card-title">📄 Uploaded Documents</div>
                ${businessRegistrationUrl ? `
                <div class="doc-card">
                    <span class="doc-icon">📋</span>
                    <div>
                        <div class="doc-name">Business Registration Document</div>
                        <a href="${businessRegistrationUrl}" class="doc-link" target="_blank">View Document →</a>
                    </div>
                </div>
                ` : ''}
                ${nicDocumentUrl ? `
                <div class="doc-card">
                    <span class="doc-icon">🪪</span>
                    <div>
                        <div class="doc-name">NIC Document</div>
                        <a href="${nicDocumentUrl}" class="doc-link" target="_blank">View Document →</a>
                    </div>
                </div>
                ` : ''}
            </div>

            <div style="text-align:center;">
                <a href="#" class="cta-button" style="background:linear-gradient(135deg,#f97316,#ea580c);">Review in Admin Dashboard</a>
            </div>

            <div class="warning-box">
                <div style="font-weight:600;color:#9a3412;margin-bottom:4px;">⚠️ Action Required</div>
                <div style="font-size:14px;color:#c2410c;">Please verify the submitted documents and approve or reject this seller registration from the Admin Dashboard.</div>
            </div>
        </div>
    `, `New Seller Registration: ${businessName} by ${sellerName}`);
};

// ============================================================================
// 4. SELLER APPROVAL EMAIL
// ============================================================================

const sellerApprovalTemplate = (data) => {
    const { sellerName, businessName } = data;

    return baseTemplate(`
        <div class="content">
            <div class="success-box" style="padding:36px;">
                <div class="success-icon">🎉</div>
                <div class="success-title" style="font-size:24px;">Account Approved!</div>
                <div class="success-text" style="font-size:15px;">Welcome to the GemNest Seller Community</div>
            </div>

            <div class="greeting">Dear ${sellerName},</div>
            <div class="subtitle">
                Great news! Your seller account for <strong>"${businessName}"</strong> has been verified and approved by our admin team. You can now start selling your premium gemstones on GemNest!
            </div>

            <div class="info-card" style="background:linear-gradient(135deg,#f0fdf4,#dcfce7);border-color:#86efac;">
                <div class="info-card-title" style="color:#166534;">🚀 What You Can Do Now</div>
                <div style="padding:8px 0;">
                    <div style="display:flex;align-items:center;margin:10px 0;">
                        <span style="width:32px;height:32px;border-radius:50%;background:#16a34a;color:#fff;text-align:center;line-height:32px;font-size:14px;font-weight:700;margin-right:12px;">1</span>
                        <span style="font-size:14px;color:#374151;"><strong>List Products</strong> — Add your gemstones with photos and descriptions</span>
                    </div>
                    <div style="display:flex;align-items:center;margin:10px 0;">
                        <span style="width:32px;height:32px;border-radius:50%;background:#16a34a;color:#fff;text-align:center;line-height:32px;font-size:14px;font-weight:700;margin-right:12px;">2</span>
                        <span style="font-size:14px;color:#374151;"><strong>Create Auctions</strong> — Set up auctions for rare and special pieces</span>
                    </div>
                    <div style="display:flex;align-items:center;margin:10px 0;">
                        <span style="width:32px;height:32px;border-radius:50%;background:#16a34a;color:#fff;text-align:center;line-height:32px;font-size:14px;font-weight:700;margin-right:12px;">3</span>
                        <span style="font-size:14px;color:#374151;"><strong>Manage Orders</strong> — Process and fulfill customer orders</span>
                    </div>
                    <div style="display:flex;align-items:center;margin:10px 0;">
                        <span style="width:32px;height:32px;border-radius:50%;background:#16a34a;color:#fff;text-align:center;line-height:32px;font-size:14px;font-weight:700;margin-right:12px;">4</span>
                        <span style="font-size:14px;color:#374151;"><strong>Configure Delivery</strong> — Set up your delivery options and pricing</span>
                    </div>
                </div>
            </div>

            <div style="text-align:center;">
                <a href="#" class="cta-button">Open GemNest App</a>
            </div>

            <p style="font-size:13px;color:#9ca3af;text-align:center;">Need help getting started? Check our Seller Guide in the app or contact our support team.</p>
        </div>
    `, `Your GemNest seller account has been approved!`);
};

// ============================================================================
// 5. SELLER REJECTION EMAIL
// ============================================================================

const sellerRejectionTemplate = (data) => {
    const { sellerName, businessName, rejectionReason } = data;

    return baseTemplate(`
        <div class="content">
            <div style="background:linear-gradient(135deg,#fef2f2,#fee2e2);border:2px solid #ef4444;border-radius:16px;padding:32px;text-align:center;margin-bottom:24px;">
                <div style="font-size:48px;">📋</div>
                <div style="font-size:22px;font-weight:700;color:#991b1b;">Verification Update</div>
                <div style="font-size:14px;color:#dc2626;">Additional action required</div>
            </div>

            <div class="greeting">Dear ${sellerName},</div>
            <div class="subtitle">
                We've reviewed your seller account application for <strong>"${businessName}"</strong>. Unfortunately, we were unable to approve your application at this time.
            </div>

            ${rejectionReason ? `
            <div class="info-card" style="background:linear-gradient(135deg,#fef2f2,#fee2e2);border-color:#fca5a5;">
                <div class="info-card-title" style="color:#dc2626;">📝 Reason</div>
                <p style="font-size:14px;color:#7f1d1d;line-height:1.6;">${rejectionReason}</p>
            </div>
            ` : ''}

            <div class="info-card">
                <div class="info-card-title">🔄 What You Can Do</div>
                <p style="font-size:14px;color:#374151;line-height:1.8;">
                    • Review the rejection reason above<br>
                    • Update your documents or information as needed<br>
                    • Re-submit your application through the GemNest app<br>
                    • Contact our support team if you have questions
                </p>
            </div>

            <div style="text-align:center;">
                <a href="mailto:support@gemnest.com" class="cta-button" style="background:linear-gradient(135deg,#6366f1,#4f46e5);">Contact Support</a>
            </div>
        </div>
    `, `Update on your GemNest seller application for ${businessName}`);
};

// ============================================================================
// 6. WELCOME EMAIL (Buyer Registration)
// ============================================================================

const welcomeEmailTemplate = (data) => {
    const { userName, userEmail } = data;

    return baseTemplate(`
        <div class="content">
            <div style="background:linear-gradient(135deg,#ede9fe,#ddd6fe);border:2px solid #8b5cf6;border-radius:16px;padding:36px;text-align:center;margin-bottom:24px;">
                <div style="font-size:56px;">💎</div>
                <div style="font-size:26px;font-weight:700;color:#5b21b6;margin-top:8px;">Welcome to GemNest!</div>
                <div style="font-size:15px;color:#7c3aed;margin-top:4px;">Your gateway to premium gemstones</div>
            </div>

            <div class="greeting">Hello ${userName || 'there'}! 👋</div>
            <div class="subtitle">
                Welcome to GemNest — the premier marketplace for authentic gemstones. We're thrilled to have you join our community of gem enthusiasts!
            </div>

            <div class="info-card" style="background:linear-gradient(135deg,#f5f3ff,#ede9fe);border-color:#c4b5fd;">
                <div class="info-card-title" style="color:#7c3aed;">✨ Explore GemNest</div>
                <div style="padding:4px 0;">
                    <div style="display:flex;align-items:center;margin:12px 0;">
                        <div style="width:48px;height:48px;border-radius:12px;background:linear-gradient(135deg,#7c3aed,#6d28d9);text-align:center;line-height:48px;font-size:22px;margin-right:16px;">💎</div>
                        <div>
                            <div style="font-weight:600;color:#1f2937;font-size:15px;">Browse Premium Gemstones</div>
                            <div style="color:#6b7280;font-size:13px;">Discover sapphires, rubies, emeralds and more</div>
                        </div>
                    </div>
                    <div style="display:flex;align-items:center;margin:12px 0;">
                        <div style="width:48px;height:48px;border-radius:12px;background:linear-gradient(135deg,#e94560,#c23152);text-align:center;line-height:48px;font-size:22px;margin-right:16px;">🔨</div>
                        <div>
                            <div style="font-weight:600;color:#1f2937;font-size:15px;">Join Live Auctions</div>
                            <div style="color:#6b7280;font-size:13px;">Bid on exclusive and rare gemstones</div>
                        </div>
                    </div>
                    <div style="display:flex;align-items:center;margin:12px 0;">
                        <div style="width:48px;height:48px;border-radius:12px;background:linear-gradient(135deg,#f59e0b,#d97706);text-align:center;line-height:48px;font-size:22px;margin-right:16px;">🔒</div>
                        <div>
                            <div style="font-weight:600;color:#1f2937;font-size:15px;">Secure Payments</div>
                            <div style="color:#6b7280;font-size:13px;">Shop with confidence using Stripe secure payments</div>
                        </div>
                    </div>
                </div>
            </div>

            <div style="text-align:center;">
                <a href="#" class="cta-button">Start Shopping</a>
            </div>
        </div>
    `, `Welcome to GemNest, ${userName}! Start exploring premium gemstones.`);
};

// ============================================================================
// 7. ORDER STATUS UPDATE EMAIL
// ============================================================================

const orderStatusUpdateTemplate = (data) => {
    const { buyerName, orderId, newStatus, items = [] } = data;

    const statusConfig = {
        confirmed: { icon: '✅', color: '#166534', bg: '#dcfce7', text: 'Your order has been confirmed by the seller.' },
        processing: { icon: '⚙️', color: '#92400e', bg: '#fef3c7', text: 'Your order is being processed and prepared.' },
        shipped: { icon: '📦', color: '#1e40af', bg: '#dbeafe', text: 'Your order has been shipped and is on the way!' },
        delivered: { icon: '🎉', color: '#065f46', bg: '#d1fae5', text: 'Your order has been delivered successfully!' },
        cancelled: { icon: '❌', color: '#991b1b', bg: '#fee2e2', text: 'Your order has been cancelled.' },
        refunded: { icon: '💸', color: '#7c2d12', bg: '#ffedd5', text: 'Your order has been refunded.' },
    };

    const config = statusConfig[newStatus] || statusConfig.confirmed;

    const itemsPreview = items.slice(0, 3).map(i => i.name).join(', ');

    return baseTemplate(`
        <div class="content">
            <div style="background:${config.bg};border-radius:16px;padding:32px;text-align:center;margin-bottom:24px;">
                <div style="font-size:56px;">${config.icon}</div>
                <div style="font-size:22px;font-weight:700;color:${config.color};margin-top:8px;">Order ${newStatus.charAt(0).toUpperCase() + newStatus.slice(1)}</div>
                <div style="font-size:14px;color:${config.color};margin-top:4px;">${config.text}</div>
            </div>

            <div class="greeting">Hi ${buyerName},</div>
            <div class="subtitle">${config.text}</div>

            <div class="info-card">
                <div class="info-card-title">📋 Order Info</div>
                <div class="info-row">
                    <span class="info-label">Order ID</span>
                    <span class="info-value" style="font-family:monospace;">#${orderId}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Status</span>
                    <span class="info-value"><span class="status-badge status-${newStatus}">${newStatus.charAt(0).toUpperCase() + newStatus.slice(1)}</span></span>
                </div>
                ${itemsPreview ? `<div class="info-row">
                    <span class="info-label">Items</span>
                    <span class="info-value">${itemsPreview}${items.length > 3 ? ` +${items.length - 3} more` : ''}</span>
                </div>` : ''}
            </div>

            <div style="text-align:center;">
                <a href="#" class="cta-button">View Order Details</a>
            </div>
        </div>
    `, `Order #${orderId} - ${newStatus.charAt(0).toUpperCase() + newStatus.slice(1)}`);
};

// ============================================================================
// 8. PAYMENT RECEIVED EMAIL (To Seller)
// ============================================================================

const paymentReceivedTemplate = (data) => {
    const { sellerName, orderId, amount, paymentMethod, buyerName } = data;

    return baseTemplate(`
        <div class="content">
            <div class="highlight-box" style="border-color:#22c55e;background:linear-gradient(135deg,#f0fdf4,#dcfce7);">
                <div style="font-size:48px;">💰</div>
                <div class="amount" style="color:#166534;">Rs. ${Number(amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}</div>
                <div class="label" style="color:#15803d;">Payment Received</div>
            </div>

            <div class="greeting">Hi ${sellerName},</div>
            <div class="subtitle">You've received a payment for an order. Here are the details:</div>

            <div class="info-card">
                <div class="info-card-title">💳 Payment Details</div>
                <div class="info-row">
                    <span class="info-label">Order ID</span>
                    <span class="info-value" style="font-family:monospace;">#${orderId}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Amount</span>
                    <span class="info-value" style="color:#e94560;font-weight:700;">Rs. ${Number(amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Payment Method</span>
                    <span class="info-value">${paymentMethod || 'N/A'}</span>
                </div>
                ${buyerName ? `<div class="info-row">
                    <span class="info-label">From Buyer</span>
                    <span class="info-value">${buyerName}</span>
                </div>` : ''}
            </div>

            <div style="text-align:center;">
                <a href="#" class="cta-button">View Order</a>
            </div>
        </div>
    `, `Payment of Rs. ${amount} received for Order #${orderId}`);
};

// ============================================================================
// 9. PRODUCT/AUCTION APPROVAL EMAIL (To Seller)
// ============================================================================

const productApprovalTemplate = (data) => {
    const { sellerName, productTitle, productId, type = 'product', status, rejectionReason } = data;

    const isApproved = status === 'approved';
    const typeLabel = type === 'auction' ? 'Auction' : 'Product';

    return baseTemplate(`
        <div class="content">
            <div style="background:${isApproved ? 'linear-gradient(135deg,#dcfce7,#bbf7d0)' : 'linear-gradient(135deg,#fee2e2,#fecaca)'};border:2px solid ${isApproved ? '#22c55e' : '#ef4444'};border-radius:16px;padding:32px;text-align:center;margin-bottom:24px;">
                <div style="font-size:48px;">${isApproved ? '✅' : '❌'}</div>
                <div style="font-size:22px;font-weight:700;color:${isApproved ? '#166534' : '#991b1b'};">${typeLabel} ${isApproved ? 'Approved' : 'Rejected'}</div>
            </div>

            <div class="greeting">Hi ${sellerName},</div>
            <div class="subtitle">
                ${isApproved 
                    ? `Your ${typeLabel.toLowerCase()} <strong>"${productTitle}"</strong> has been approved and is now ${type === 'auction' ? 'live' : 'visible to customers'}!`
                    : `Your ${typeLabel.toLowerCase()} <strong>"${productTitle}"</strong> was not approved.`
                }
            </div>

            ${!isApproved && rejectionReason ? `
            <div class="info-card" style="background:linear-gradient(135deg,#fef2f2,#fee2e2);border-color:#fca5a5;">
                <div class="info-card-title" style="color:#dc2626;">📝 Reason for Rejection</div>
                <p style="font-size:14px;color:#7f1d1d;line-height:1.6;">${rejectionReason}</p>
            </div>
            ` : ''}

            <div style="text-align:center;">
                <a href="#" class="cta-button">${isApproved ? `View ${typeLabel}` : 'Edit & Resubmit'}</a>
            </div>
        </div>
    `, `${typeLabel} "${productTitle}" - ${isApproved ? 'Approved' : 'Rejected'}`);
};

// ============================================================================
// 10. OUTBID NOTIFICATION EMAIL
// ============================================================================

const outbidTemplate = (data) => {
    const { buyerName, auctionTitle, currentBid, auctionId } = data;

    return baseTemplate(`
        <div class="content">
            <div style="background:linear-gradient(135deg,#fff7ed,#ffedd5);border:2px solid #f97316;border-radius:16px;padding:32px;text-align:center;margin-bottom:24px;">
                <div style="font-size:48px;">📈</div>
                <div style="font-size:22px;font-weight:700;color:#9a3412;">You've Been Outbid!</div>
            </div>

            <div class="greeting">Hi ${buyerName},</div>
            <div class="subtitle">
                Someone placed a higher bid on <strong>"${auctionTitle}"</strong>. Don't let it get away!
            </div>

            <div class="highlight-box">
                <div class="label" style="margin-bottom:4px;">Current Highest Bid</div>
                <div class="amount">Rs. ${Number(currentBid).toLocaleString('en-US', { minimumFractionDigits: 2 })}</div>
            </div>

            <div style="text-align:center;">
                <a href="#" class="cta-button" style="background:linear-gradient(135deg,#f97316,#ea580c);">Place a Higher Bid</a>
            </div>

            <p style="font-size:13px;color:#9ca3af;text-align:center;">Hurry! The auction may end soon.</p>
        </div>
    `, `You've been outbid on "${auctionTitle}" - Current bid: Rs. ${currentBid}`);
};

// ============================================================================
// 11. REPORT STATUS UPDATE EMAIL
// ============================================================================

const reportStatusTemplate = (data) => {
    const { userName, reportSubject, reportId, newStatus, adminResponse } = data;

    const statusMap = {
        review: { icon: '🔍', label: 'Under Review', color: '#1d4ed8', bg: '#dbeafe' },
        inProgress: { icon: '⚙️', label: 'In Progress', color: '#92400e', bg: '#fef3c7' },
        done: { icon: '✅', label: 'Resolved', color: '#166534', bg: '#dcfce7' },
        rejected: { icon: '❌', label: 'Closed', color: '#991b1b', bg: '#fee2e2' },
    };

    const config = statusMap[newStatus] || statusMap.review;

    return baseTemplate(`
        <div class="content">
            <div style="background:${config.bg};border-radius:16px;padding:28px;text-align:center;margin-bottom:24px;">
                <div style="font-size:48px;">${config.icon}</div>
                <div style="font-size:20px;font-weight:700;color:${config.color};">Report ${config.label}</div>
            </div>

            <div class="greeting">Hi ${userName},</div>
            <div class="subtitle">Your report <strong>"${reportSubject}"</strong> has been updated.</div>

            <div class="info-card">
                <div class="info-card-title">📋 Report Details</div>
                <div class="info-row">
                    <span class="info-label">Report ID</span>
                    <span class="info-value" style="font-family:monospace;">#${reportId}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Status</span>
                    <span class="info-value"><span class="status-badge" style="background:${config.bg};color:${config.color};">${config.label}</span></span>
                </div>
            </div>

            ${adminResponse ? `
            <div class="info-card" style="background:linear-gradient(135deg,#f0f9ff,#e0f2fe);border-color:#7dd3fc;">
                <div class="info-card-title" style="color:#0369a1;">💬 Admin Response</div>
                <p style="font-size:14px;color:#374151;line-height:1.6;">${adminResponse}</p>
            </div>
            ` : ''}

            <div style="text-align:center;">
                <a href="#" class="cta-button">View Report</a>
            </div>
        </div>
    `, `Report "${reportSubject}" - ${config.label}`);
};

// ============================================================================
// 12. NEW PRODUCT/AUCTION NEEDS APPROVAL (Admin Email)
// ============================================================================

const newApprovalNeededTemplate = (data) => {
    const { type, title, sellerName, sellerId, itemId, category, price, description, imageUrl } = data;

    const typeLabel = type === 'auction' ? 'Auction' : 'Product';

    return baseTemplate(`
        <div class="content">
            <div style="background:linear-gradient(135deg,#fef3c7,#fde68a);border:2px solid #f59e0b;border-radius:16px;padding:28px;text-align:center;margin-bottom:24px;">
                <div style="font-size:48px;">⚠️</div>
                <div style="font-size:22px;font-weight:700;color:#92400e;">New ${typeLabel} Needs Approval</div>
            </div>

            <div class="info-card" style="background:linear-gradient(135deg,#faf5ff,#f3e8ff);border-color:#c084fc;">
                <div class="info-card-title" style="color:#7c3aed;">${type === 'auction' ? '🔨' : '💎'} ${typeLabel} Details</div>
                <div style="display:flex;align-items:center;margin-bottom:16px;">
                    ${imageUrl ? `<img src="${imageUrl}" style="width:72px;height:72px;border-radius:10px;object-fit:cover;margin-right:16px;" alt="${title}">` : '<div style="width:72px;height:72px;border-radius:10px;background:linear-gradient(135deg,#e0e7ff,#c7d2fe);margin-right:16px;text-align:center;line-height:72px;font-size:30px;">💎</div>'}
                    <div>
                        <div style="font-size:16px;font-weight:700;color:#1f2937;">${title}</div>
                        ${category ? `<div style="font-size:13px;color:#6b7280;margin-top:2px;">Category: ${category}</div>` : ''}
                    </div>
                </div>
                <div class="info-row">
                    <span class="info-label">Seller</span>
                    <span class="info-value">${sellerName || 'N/A'}</span>
                </div>
                ${price ? `<div class="info-row">
                    <span class="info-label">${type === 'auction' ? 'Starting Price' : 'Price'}</span>
                    <span class="info-value" style="color:#e94560;">Rs. ${Number(price).toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
                </div>` : ''}
                ${description ? `<div class="info-row">
                    <span class="info-label">Description</span>
                    <span class="info-value" style="max-width:300px;">${description.substring(0, 100)}${description.length > 100 ? '...' : ''}</span>
                </div>` : ''}
            </div>

            <div style="text-align:center;">
                <a href="#" class="cta-button" style="background:linear-gradient(135deg,#f97316,#ea580c);">Review in Admin Dashboard</a>
            </div>
        </div>
    `, `New ${typeLabel} "${title}" needs your approval`);
};

module.exports = {
    orderConfirmationTemplate,
    auctionWinBillTemplate,
    sellerRegistrationAdminTemplate,
    sellerApprovalTemplate,
    sellerRejectionTemplate,
    welcomeEmailTemplate,
    orderStatusUpdateTemplate,
    paymentReceivedTemplate,
    productApprovalTemplate,
    outbidTemplate,
    reportStatusTemplate,
    newApprovalNeededTemplate,
};
