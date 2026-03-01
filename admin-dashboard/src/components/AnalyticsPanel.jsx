import React, { useState, useEffect, useRef } from 'react';
import {
    TrendingUp, DollarSign, ShoppingCart, Clock, Users, Zap, CheckCircle,
    Calendar, Download, FileText, ChevronLeft, ChevronRight, RefreshCw,
    BarChart3, ArrowUpRight, ArrowDownRight, Package, Store
} from 'lucide-react';
import { collection, query, where, getDocs, Timestamp } from 'firebase/firestore';
import { db } from '../services/firebase';

export default function AnalyticsPanel() {
    const [loading, setLoading] = useState(true);
    const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
    const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth());
    const [viewMode, setViewMode] = useState('overview'); // 'overview' | 'seller' | 'monthly'

    // Data state
    const [monthData, setMonthData] = useState(null);
    const [sellerBreakdown, setSellerBreakdown] = useState([]);
    const [monthlyTrend, setMonthlyTrend] = useState([]);
    const [platformStats, setPlatformStats] = useState({ totalSellers: 0, totalBuyers: 0, totalProducts: 0, totalAuctions: 0 });
    const [sellerNames, setSellerNames] = useState({});

    const canvasRef = useRef(null);

    const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
    ];

    useEffect(() => {
        fetchAllData();
    }, [selectedYear, selectedMonth]);

    useEffect(() => {
        if (monthlyTrend.length > 0) {
            drawChart();
        }
    }, [monthlyTrend, selectedMonth]);

    // ---- Data Fetching ----

    const fetchSellerNames = async (sellerIds) => {
        const names = { ...sellerNames };
        const unknownIds = sellerIds.filter(id => !names[id]);
        if (unknownIds.length === 0) return names;

        try {
            for (const sellerId of unknownIds) {
                try {
                    const sellerQuery = query(collection(db, 'sellers'), where('uid', '==', sellerId));
                    const sellerSnap = await getDocs(sellerQuery);
                    if (!sellerSnap.empty) {
                        const data = sellerSnap.docs[0].data();
                        names[sellerId] = data.shopName || data.businessName || data.name || data.email || sellerId.substring(0, 8);
                    } else {
                        const buyerQuery = query(collection(db, 'buyers'), where('uid', '==', sellerId));
                        const buyerSnap = await getDocs(buyerQuery);
                        if (!buyerSnap.empty) {
                            const data = buyerSnap.docs[0].data();
                            names[sellerId] = data.name || data.email || sellerId.substring(0, 8);
                        } else {
                            names[sellerId] = sellerId.substring(0, 8) + '...';
                        }
                    }
                } catch {
                    names[sellerId] = sellerId.substring(0, 8) + '...';
                }
            }
        } catch (error) {
            console.error('Error fetching seller names:', error);
        }

        setSellerNames(names);
        return names;
    };

    const fetchAllData = async () => {
        try {
            setLoading(true);
            await Promise.all([
                fetchMonthlyOrders(),
                fetchYearlyTrend(),
                fetchPlatformStats(),
            ]);
        } catch (error) {
            console.error('Error fetching analytics data:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchMonthlyOrders = async () => {
        try {
            const startDate = new Date(selectedYear, selectedMonth, 1);
            const endDate = new Date(selectedYear, selectedMonth + 1, 0, 23, 59, 59, 999);

            const ordersRef = collection(db, 'orders');
            const q = query(
                ordersRef,
                where('orderDate', '>=', Timestamp.fromDate(startDate)),
                where('orderDate', '<=', Timestamp.fromDate(endDate))
            );

            const snapshot = await getDocs(q);
            const orders = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

            let totalRevenue = 0;
            let totalTax = 0;
            let totalServiceCharge = 0;
            let completedOrders = 0;
            let pendingOrders = 0;
            let cancelledOrders = 0;
            let processingOrders = 0;
            const sellerMap = {};

            orders.forEach(order => {
                const amount = order.totalAmount || order.amount || 0;
                const taxAmount = order.taxAmount || 0;
                const serviceChargeAmount = order.serviceChargeAmount || 0;
                const status = (order.status || '').toLowerCase();

                totalRevenue += amount;
                totalTax += taxAmount;
                totalServiceCharge += serviceChargeAmount;

                if (status === 'completed' || status === 'delivered') completedOrders++;
                else if (status === 'pending') pendingOrders++;
                else if (status === 'cancelled' || status === 'canceled') cancelledOrders++;
                else processingOrders++;

                // Seller breakdown
                const items = order.items || [];
                if (items.length > 0) {
                    items.forEach(item => {
                        const sellerId = item.sellerId || 'unknown';
                        if (!sellerMap[sellerId]) {
                            sellerMap[sellerId] = {
                                sellerId,
                                revenue: 0,
                                taxAmount: 0,
                                serviceChargeAmount: 0,
                                orderCount: 0,
                                itemCount: 0,
                                completedOrders: 0,
                                pendingOrders: 0,
                            };
                        }
                        const itemTotal = (item.price || 0) * (item.quantity || 1);
                        const orderSubtotal = order.subtotalBeforeTax || amount;
                        const proportion = orderSubtotal > 0 ? itemTotal / orderSubtotal : 0;

                        sellerMap[sellerId].revenue += itemTotal;
                        sellerMap[sellerId].taxAmount += taxAmount * proportion;
                        sellerMap[sellerId].serviceChargeAmount += serviceChargeAmount * proportion;
                        sellerMap[sellerId].itemCount += item.quantity || 1;
                        sellerMap[sellerId].orderCount++;
                        if (status === 'completed' || status === 'delivered') sellerMap[sellerId].completedOrders++;
                        if (status === 'pending') sellerMap[sellerId].pendingOrders++;
                    });
                } else {
                    // Order without items array - attribute to sellerId on order
                    const sellerId = order.sellerId || 'unknown';
                    if (!sellerMap[sellerId]) {
                        sellerMap[sellerId] = {
                            sellerId,
                            revenue: 0,
                            taxAmount: 0,
                            serviceChargeAmount: 0,
                            orderCount: 0,
                            itemCount: 0,
                            completedOrders: 0,
                            pendingOrders: 0,
                        };
                    }
                    sellerMap[sellerId].revenue += amount;
                    sellerMap[sellerId].taxAmount += taxAmount;
                    sellerMap[sellerId].serviceChargeAmount += serviceChargeAmount;
                    sellerMap[sellerId].orderCount++;
                    if (status === 'completed' || status === 'delivered') sellerMap[sellerId].completedOrders++;
                    if (status === 'pending') sellerMap[sellerId].pendingOrders++;
                }
            });

            const sellerList = Object.values(sellerMap).sort((a, b) => b.revenue - a.revenue);
            const sellerIds = sellerList.map(s => s.sellerId).filter(id => id !== 'unknown');
            const names = await fetchSellerNames(sellerIds);
            sellerList.forEach(s => {
                s.sellerName = names[s.sellerId] || s.sellerId;
            });

            setMonthData({
                totalRevenue,
                totalTax,
                totalServiceCharge,
                totalOrders: orders.length,
                completedOrders,
                pendingOrders,
                cancelledOrders,
                processingOrders,
                avgOrderValue: orders.length > 0 ? totalRevenue / orders.length : 0,
                completionRate: orders.length > 0 ? Math.round((completedOrders / orders.length) * 100) : 0,
                activeSellers: sellerList.length,
            });

            setSellerBreakdown(sellerList);
        } catch (error) {
            console.error('Error fetching monthly orders:', error);
            setMonthData({
                totalRevenue: 0, totalTax: 0, totalServiceCharge: 0, totalOrders: 0,
                completedOrders: 0, pendingOrders: 0, cancelledOrders: 0, processingOrders: 0,
                avgOrderValue: 0, completionRate: 0, activeSellers: 0,
            });
            setSellerBreakdown([]);
        }
    };

    const fetchYearlyTrend = async () => {
        try {
            const yearStart = new Date(selectedYear, 0, 1);
            const yearEnd = new Date(selectedYear, 11, 31, 23, 59, 59, 999);

            const ordersRef = collection(db, 'orders');
            const q = query(
                ordersRef,
                where('orderDate', '>=', Timestamp.fromDate(yearStart)),
                where('orderDate', '<=', Timestamp.fromDate(yearEnd))
            );

            const snapshot = await getDocs(q);
            const data = Array.from({ length: 12 }, (_, i) => ({
                month: months[i].substring(0, 3),
                monthIndex: i,
                revenue: 0,
                taxAmount: 0,
                serviceChargeAmount: 0,
                orderCount: 0,
                completedOrders: 0,
            }));

            snapshot.docs.forEach(doc => {
                const d = doc.data();
                const orderDate = d.orderDate?.toDate?.();
                if (orderDate) {
                    const idx = orderDate.getMonth();
                    data[idx].revenue += d.totalAmount || d.amount || 0;
                    data[idx].taxAmount += d.taxAmount || 0;
                    data[idx].serviceChargeAmount += d.serviceChargeAmount || 0;
                    data[idx].orderCount++;
                    const status = (d.status || '').toLowerCase();
                    if (status === 'completed' || status === 'delivered') data[idx].completedOrders++;
                }
            });

            setMonthlyTrend(data);
        } catch (error) {
            console.error('Error fetching yearly trend:', error);
        }
    };

    const fetchPlatformStats = async () => {
        try {
            const [sellersSnap, buyersSnap, productsSnap, auctionsSnap] = await Promise.all([
                getDocs(collection(db, 'sellers')),
                getDocs(collection(db, 'buyers')),
                getDocs(collection(db, 'products')),
                getDocs(collection(db, 'auctions')),
            ]);
            setPlatformStats({
                totalSellers: sellersSnap.size,
                totalBuyers: buyersSnap.size,
                totalProducts: productsSnap.size,
                totalAuctions: auctionsSnap.size,
            });
        } catch (error) {
            console.error('Error fetching platform stats:', error);
        }
    };

    // ---- Chart Drawing ----

    const drawChart = () => {
        const canvas = canvasRef.current;
        if (!canvas || monthlyTrend.length === 0) return;

        const ctx = canvas.getContext('2d');
        const dpr = window.devicePixelRatio || 1;
        const rect = canvas.getBoundingClientRect();

        canvas.width = rect.width * dpr;
        canvas.height = rect.height * dpr;
        ctx.scale(dpr, dpr);

        const width = rect.width;
        const height = rect.height;
        const padding = { top: 40, right: 30, bottom: 50, left: 80 };
        const chartWidth = width - padding.left - padding.right;
        const chartHeight = height - padding.top - padding.bottom;

        ctx.clearRect(0, 0, width, height);

        const maxValue = Math.max(...monthlyTrend.map(d => d.revenue), 1) * 1.2;
        const barWidth = chartWidth / 12 - 8;

        // Grid lines
        ctx.strokeStyle = '#374151';
        ctx.lineWidth = 0.5;
        for (let i = 0; i <= 5; i++) {
            const y = padding.top + (chartHeight * (1 - i / 5));
            ctx.beginPath();
            ctx.moveTo(padding.left, y);
            ctx.lineTo(width - padding.right, y);
            ctx.stroke();

            ctx.fillStyle = '#9CA3AF';
            ctx.font = '11px Inter, sans-serif';
            ctx.textAlign = 'right';
            const val = (maxValue * i / 5);
            ctx.fillText(val >= 1000 ? `Rs.${(val / 1000).toFixed(1)}K` : `Rs.${val.toFixed(0)}`, padding.left - 8, y + 4);
        }

        // Bars
        monthlyTrend.forEach((data, index) => {
            const x = padding.left + (chartWidth / 12) * index + 4;
            const barHeight = maxValue > 0 ? (data.revenue / maxValue) * chartHeight : 0;
            const isSelected = index === selectedMonth;
            const barY = padding.top + chartHeight - barHeight;

            if (barHeight > 0) {
                const gradient = ctx.createLinearGradient(x, barY, x, padding.top + chartHeight);
                gradient.addColorStop(0, isSelected ? '#22D3EE' : '#06B6D470');
                gradient.addColorStop(1, isSelected ? '#0891B2' : '#0E747070');
                ctx.fillStyle = gradient;

                // Rounded top corners
                const r = barHeight > 4 ? 4 : 0;
                ctx.beginPath();
                ctx.moveTo(x + r, barY);
                ctx.lineTo(x + barWidth - r, barY);
                ctx.quadraticCurveTo(x + barWidth, barY, x + barWidth, barY + r);
                ctx.lineTo(x + barWidth, padding.top + chartHeight);
                ctx.lineTo(x, padding.top + chartHeight);
                ctx.lineTo(x, barY + r);
                ctx.quadraticCurveTo(x, barY, x + r, barY);
                ctx.closePath();
                ctx.fill();

                // Value on top of bar (for selected)
                if (isSelected && barHeight > 20) {
                    ctx.fillStyle = '#FFFFFF';
                    ctx.font = 'bold 10px Inter, sans-serif';
                    ctx.textAlign = 'center';
                    const label = data.revenue >= 1000 ? `Rs.${(data.revenue / 1000).toFixed(1)}K` : `Rs.${data.revenue.toFixed(0)}`;
                    ctx.fillText(label, x + barWidth / 2, barY - 6);
                }
            }

            // X-axis labels
            ctx.fillStyle = isSelected ? '#FFFFFF' : '#9CA3AF';
            ctx.font = isSelected ? 'bold 12px Inter, sans-serif' : '11px Inter, sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText(data.month, x + barWidth / 2, padding.top + chartHeight + 20);

            if (isSelected) {
                ctx.fillStyle = '#22D3EE';
                ctx.beginPath();
                ctx.arc(x + barWidth / 2, padding.top + chartHeight + 35, 3, 0, Math.PI * 2);
                ctx.fill();
            }
        });

        // Orders line overlay
        const maxOrders = Math.max(...monthlyTrend.map(d => d.orderCount), 1) * 1.2;
        ctx.strokeStyle = '#F59E0B';
        ctx.lineWidth = 2;
        ctx.setLineDash([4, 4]);
        ctx.beginPath();
        monthlyTrend.forEach((data, index) => {
            const x = padding.left + (chartWidth / 12) * index + 4 + barWidth / 2;
            const y = padding.top + chartHeight - (data.orderCount / maxOrders) * chartHeight;
            if (index === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        });
        ctx.stroke();
        ctx.setLineDash([]);

        // Order dots
        monthlyTrend.forEach((data, index) => {
            const x = padding.left + (chartWidth / 12) * index + 4 + barWidth / 2;
            const y = padding.top + chartHeight - (data.orderCount / maxOrders) * chartHeight;
            ctx.fillStyle = index === selectedMonth ? '#FBBF24' : '#F59E0B80';
            ctx.beginPath();
            ctx.arc(x, y, index === selectedMonth ? 5 : 3, 0, Math.PI * 2);
            ctx.fill();
        });

        // Legend
        ctx.font = '12px Inter, sans-serif';
        ctx.fillStyle = '#22D3EE';
        ctx.fillRect(padding.left, 10, 14, 14);
        ctx.fillStyle = '#D1D5DB';
        ctx.textAlign = 'left';
        ctx.fillText('Revenue', padding.left + 20, 22);

        ctx.strokeStyle = '#F59E0B';
        ctx.lineWidth = 2;
        ctx.setLineDash([4, 4]);
        ctx.beginPath();
        ctx.moveTo(padding.left + 100, 17);
        ctx.lineTo(padding.left + 114, 17);
        ctx.stroke();
        ctx.setLineDash([]);
        ctx.fillStyle = '#D1D5DB';
        ctx.fillText('Orders', padding.left + 120, 22);
    };

    // ---- Navigation ----

    const navigateMonth = (direction) => {
        let newMonth = selectedMonth + direction;
        let newYear = selectedYear;
        if (newMonth < 0) { newMonth = 11; newYear--; }
        else if (newMonth > 11) { newMonth = 0; newYear++; }
        setSelectedMonth(newMonth);
        setSelectedYear(newYear);
    };

    // ---- Helpers ----

    const formatCurrency = (amount) => {
        if (amount >= 1000000) return `Rs.${(amount / 1000000).toFixed(2)}M`;
        if (amount >= 1000) return `Rs.${(amount / 1000).toFixed(2)}K`;
        return `Rs.${(amount || 0).toFixed(2)}`;
    };

    const getPrevMonthData = () => {
        const prevIdx = selectedMonth === 0 ? 11 : selectedMonth - 1;
        return monthlyTrend[prevIdx] || { revenue: 0, orderCount: 0, taxAmount: 0, serviceChargeAmount: 0 };
    };

    const getGrowth = (current, previous) => {
        if (previous === 0) return current > 0 ? 100 : 0;
        return ((current - previous) / previous * 100).toFixed(1);
    };

    // ---- PDF Report Generation ----

    const generatePDFReport = (reportType = 'complete') => {
        if (!monthData) return;

        const prev = getPrevMonthData();
        const monthName = months[selectedMonth];

        let htmlContent = `
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>GemNest Analytics Report - ${monthName} ${selectedYear}</title>
<style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #1a1a2e; background: #fff; padding: 40px; }
    .header { text-align: center; margin-bottom: 30px; border-bottom: 3px solid #0891B2; padding-bottom: 20px; }
    .header h1 { font-size: 28px; color: #0891B2; margin-bottom: 5px; }
    .header h2 { font-size: 18px; color: #4a5568; font-weight: normal; }
    .header .date { font-size: 12px; color: #999; margin-top: 8px; }
    .summary-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 30px; }
    .summary-card { background: #f7fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 16px; text-align: center; }
    .summary-card .label { font-size: 11px; color: #999; text-transform: uppercase; letter-spacing: 1px; }
    .summary-card .value { font-size: 22px; font-weight: bold; color: #2d3748; margin-top: 4px; }
    .summary-card .sub { font-size: 11px; color: #718096; margin-top: 2px; }
    .summary-card.revenue .value { color: #0891B2; }
    .summary-card.orders .value { color: #2563EB; }
    .summary-card.avg .value { color: #7C3AED; }
    .summary-card.sellers .value { color: #059669; }
    .section { margin-bottom: 30px; }
    .section h3 { font-size: 16px; color: #2d3748; margin-bottom: 12px; padding-bottom: 6px; border-bottom: 1px solid #e2e8f0; }
    table { width: 100%; border-collapse: collapse; font-size: 13px; }
    th { background: #0891B2; color: white; padding: 10px 12px; text-align: left; font-weight: 600; }
    td { padding: 10px 12px; border-bottom: 1px solid #e2e8f0; }
    tr:nth-child(even) { background: #f7fafc; }
    tr:hover { background: #edf2f7; }
    .text-right { text-align: right; }
    .text-center { text-align: center; }
    .total-row { font-weight: bold; background: #edf2f7 !important; }
    .footer { margin-top: 40px; text-align: center; font-size: 11px; color: #999; border-top: 1px solid #e2e8f0; padding-top: 15px; }
    .growth { display: inline-block; padding: 2px 6px; border-radius: 4px; font-size: 11px; font-weight: bold; }
    .growth.positive { background: #c6f6d5; color: #22543d; }
    .growth.negative { background: #fed7d7; color: #742a2a; }
    .platform-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 30px; }
    .stat-box { background: #f1f5f9; border: 1px solid #e2e8f0; border-radius: 6px; padding: 12px; text-align: center; }
    .stat-box .stat-label { font-size: 10px; color: #64748b; text-transform: uppercase; }
    .stat-box .stat-value { font-size: 18px; font-weight: bold; color: #334155; }
    @media print { body { padding: 20px; } .no-print { display: none; } }
</style>
</head>
<body>
<div class="header">
    <h1>GemNest Platform</h1>
    <h2>Platform Analytics Report${reportType === 'seller' ? ' - Seller Breakdown' : ''}</h2>
    <p><strong>${monthName} ${selectedYear}</strong></p>
    <p class="date">Generated on ${new Date().toLocaleString()}</p>
</div>

<div class="summary-grid">
    <div class="summary-card revenue">
        <div class="label">Total Revenue</div>
        <div class="value">Rs.${monthData.totalRevenue.toFixed(2)}</div>
        <div class="sub">
            <span class="growth ${getGrowth(monthData.totalRevenue, prev.revenue) >= 0 ? 'positive' : 'negative'}">
                ${getGrowth(monthData.totalRevenue, prev.revenue)}% vs prev month
            </span>
        </div>
    </div>
    <div class="summary-card orders">
        <div class="label">Total Orders</div>
        <div class="value">${monthData.totalOrders}</div>
        <div class="sub">${monthData.completedOrders} completed, ${monthData.pendingOrders} pending</div>
    </div>
    <div class="summary-card avg">
        <div class="label">Avg Order Value</div>
        <div class="value">Rs.${monthData.avgOrderValue.toFixed(2)}</div>
        <div class="sub">${monthData.completionRate}% completion rate</div>
    </div>
    <div class="summary-card sellers">
        <div class="label">Active Sellers</div>
        <div class="value">${monthData.activeSellers}</div>
        <div class="sub">With orders this month</div>
    </div>
</div>

<div class="platform-stats">
    <div class="stat-box">
        <div class="stat-label">Total Sellers</div>
        <div class="stat-value">${platformStats.totalSellers}</div>
    </div>
    <div class="stat-box">
        <div class="stat-label">Total Buyers</div>
        <div class="stat-value">${platformStats.totalBuyers}</div>
    </div>
    <div class="stat-box">
        <div class="stat-label">Total Products</div>
        <div class="stat-value">${platformStats.totalProducts}</div>
    </div>
    <div class="stat-box">
        <div class="stat-label">Total Auctions</div>
        <div class="stat-value">${platformStats.totalAuctions}</div>
    </div>
</div>

<div class="section">
    <h3>Monthly Comparison</h3>
    <table>
        <thead><tr><th>Metric</th><th class="text-right">Previous Month</th><th class="text-right">Current Month</th><th class="text-right">Growth</th></tr></thead>
        <tbody>
            <tr>
                <td>Revenue</td>
                <td class="text-right">Rs.${prev.revenue.toFixed(2)}</td>
                <td class="text-right">Rs.${monthData.totalRevenue.toFixed(2)}</td>
                <td class="text-right"><span class="growth ${getGrowth(monthData.totalRevenue, prev.revenue) >= 0 ? 'positive' : 'negative'}">${getGrowth(monthData.totalRevenue, prev.revenue)}%</span></td>
            </tr>
            <tr>
                <td>Orders</td>
                <td class="text-right">${prev.orderCount}</td>
                <td class="text-right">${monthData.totalOrders}</td>
                <td class="text-right"><span class="growth ${getGrowth(monthData.totalOrders, prev.orderCount) >= 0 ? 'positive' : 'negative'}">${getGrowth(monthData.totalOrders, prev.orderCount)}%</span></td>
            </tr>
            <tr>
                <td>Tax Collected</td>
                <td class="text-right">Rs.${prev.taxAmount.toFixed(2)}</td>
                <td class="text-right">Rs.${monthData.totalTax.toFixed(2)}</td>
                <td class="text-right"><span class="growth ${getGrowth(monthData.totalTax, prev.taxAmount) >= 0 ? 'positive' : 'negative'}">${getGrowth(monthData.totalTax, prev.taxAmount)}%</span></td>
            </tr>
            <tr>
                <td>Service Charge</td>
                <td class="text-right">Rs.${prev.serviceChargeAmount.toFixed(2)}</td>
                <td class="text-right">Rs.${monthData.totalServiceCharge.toFixed(2)}</td>
                <td class="text-right"><span class="growth ${getGrowth(monthData.totalServiceCharge, prev.serviceChargeAmount) >= 0 ? 'positive' : 'negative'}">${getGrowth(monthData.totalServiceCharge, prev.serviceChargeAmount)}%</span></td>
            </tr>
        </tbody>
    </table>
</div>`;

        // Yearly trend table
        if (monthlyTrend.length > 0) {
            htmlContent += `
<div class="section">
    <h3>Yearly Revenue Trend - ${selectedYear}</h3>
    <table>
        <thead><tr><th>Month</th><th class="text-right">Revenue</th><th class="text-right">Tax</th><th class="text-right">Service Charge</th><th class="text-center">Orders</th><th class="text-center">Completed</th></tr></thead>
        <tbody>
            ${monthlyTrend.map((m, i) => `
            <tr${i === selectedMonth ? ' style="background:#e0f2fe;font-weight:bold"' : ''}>
                <td>${months[i]}</td>
                <td class="text-right">Rs.${m.revenue.toFixed(2)}</td>
                <td class="text-right">Rs.${m.taxAmount.toFixed(2)}</td>
                <td class="text-right">Rs.${m.serviceChargeAmount.toFixed(2)}</td>
                <td class="text-center">${m.orderCount}</td>
                <td class="text-center">${m.completedOrders}</td>
            </tr>`).join('')}
            <tr class="total-row">
                <td>Year Total</td>
                <td class="text-right">Rs.${monthlyTrend.reduce((s, m) => s + m.revenue, 0).toFixed(2)}</td>
                <td class="text-right">Rs.${monthlyTrend.reduce((s, m) => s + m.taxAmount, 0).toFixed(2)}</td>
                <td class="text-right">Rs.${monthlyTrend.reduce((s, m) => s + m.serviceChargeAmount, 0).toFixed(2)}</td>
                <td class="text-center">${monthlyTrend.reduce((s, m) => s + m.orderCount, 0)}</td>
                <td class="text-center">${monthlyTrend.reduce((s, m) => s + m.completedOrders, 0)}</td>
            </tr>
        </tbody>
    </table>
</div>`;
        }

        // Seller breakdown
        if (reportType === 'seller' || reportType === 'complete') {
            htmlContent += `
<div class="section">
    <h3>Seller Performance - ${monthName} ${selectedYear}</h3>
    <table>
        <thead><tr><th>#</th><th>Seller</th><th class="text-right">Revenue</th><th class="text-right">Tax</th><th class="text-right">Service Charge</th><th class="text-center">Orders</th><th class="text-center">Completed</th></tr></thead>
        <tbody>
            ${sellerBreakdown.length === 0 ? '<tr><td colspan="7" class="text-center" style="padding:20px;color:#999">No seller data for this month</td></tr>' :
                sellerBreakdown.map((s, i) => `
            <tr>
                <td>${i + 1}</td>
                <td>${s.sellerName}</td>
                <td class="text-right">Rs.${s.revenue.toFixed(2)}</td>
                <td class="text-right">Rs.${s.taxAmount.toFixed(2)}</td>
                <td class="text-right">Rs.${s.serviceChargeAmount.toFixed(2)}</td>
                <td class="text-center">${s.orderCount}</td>
                <td class="text-center">${s.completedOrders}</td>
            </tr>`).join('')}
            ${sellerBreakdown.length > 0 ? `
            <tr class="total-row">
                <td colspan="2">Total</td>
                <td class="text-right">Rs.${sellerBreakdown.reduce((s, e) => s + e.revenue, 0).toFixed(2)}</td>
                <td class="text-right">Rs.${sellerBreakdown.reduce((s, e) => s + e.taxAmount, 0).toFixed(2)}</td>
                <td class="text-right">Rs.${sellerBreakdown.reduce((s, e) => s + e.serviceChargeAmount, 0).toFixed(2)}</td>
                <td class="text-center">${sellerBreakdown.reduce((s, e) => s + e.orderCount, 0)}</td>
                <td class="text-center">${sellerBreakdown.reduce((s, e) => s + e.completedOrders, 0)}</td>
            </tr>` : ''}
        </tbody>
    </table>
</div>`;
        }

        htmlContent += `
<div class="footer">
    <p>This is an auto-generated report from GemNest Admin Dashboard.</p>
    <p>Report Period: ${monthName} ${selectedYear} | Report Type: ${reportType === 'complete' ? 'Complete Analytics Report' : 'Seller Performance Report'}</p>
</div>
</body>
</html>`;

        const printWindow = window.open('', '_blank');
        printWindow.document.write(htmlContent);
        printWindow.document.close();
        printWindow.onload = () => {
            printWindow.print();
        };
    };

    // ---- Render ----

    if (loading) {
        return (
            <div className="flex items-center justify-center h-96">
                <div className="text-center">
                    <div className="w-12 h-12 border-4 border-gray-700 border-t-cyan-400 rounded-full animate-spin mx-auto mb-4"></div>
                    <p className="text-gray-400">Loading analytics...</p>
                </div>
            </div>
        );
    }

    const prev = getPrevMonthData();

    return (
        <div className="space-y-6">
            {/* Header with Month Navigation */}
            <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
                <div>
                    <h2 className="text-3xl font-bold text-white mb-2">Analytics</h2>
                    <p className="text-gray-400">Platform performance and real-time metrics</p>
                </div>
                <div className="flex items-center gap-3">
                    <button
                        onClick={() => navigateMonth(-1)}
                        className="p-2 bg-gray-800 rounded-lg hover:bg-gray-700 transition-colors"
                    >
                        <ChevronLeft className="w-5 h-5 text-gray-400" />
                    </button>
                    <div className="bg-gray-800 rounded-lg px-4 py-2 flex items-center gap-2">
                        <Calendar className="w-4 h-4 text-cyan-400" />
                        <span className="text-white font-semibold">{months[selectedMonth]} {selectedYear}</span>
                    </div>
                    <button
                        onClick={() => navigateMonth(1)}
                        className="p-2 bg-gray-800 rounded-lg hover:bg-gray-700 transition-colors"
                    >
                        <ChevronRight className="w-5 h-5 text-gray-400" />
                    </button>
                    <button
                        onClick={fetchAllData}
                        className="p-2 bg-gray-800 rounded-lg hover:bg-gray-700 transition-colors"
                        title="Refresh"
                    >
                        <RefreshCw className="w-5 h-5 text-gray-400" />
                    </button>
                </div>
            </div>

            {/* Primary Metrics */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                {/* Total Revenue */}
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg hover:border-cyan-700/50 transition-all">
                    <div className="flex items-center justify-between mb-3">
                        <h3 className="text-gray-400 font-semibold text-xs uppercase tracking-wider">Total Revenue</h3>
                        <div className="p-2 bg-cyan-900/30 rounded-lg">
                            <DollarSign className="w-5 h-5 text-cyan-400" />
                        </div>
                    </div>
                    <p className="text-2xl font-bold text-cyan-400">{formatCurrency(monthData?.totalRevenue || 0)}</p>
                    <div className="flex items-center gap-1 mt-2">
                        {getGrowth(monthData?.totalRevenue || 0, prev.revenue) >= 0
                            ? <ArrowUpRight className="w-3 h-3 text-green-400" />
                            : <ArrowDownRight className="w-3 h-3 text-red-400" />}
                        <span className={`text-xs font-medium ${getGrowth(monthData?.totalRevenue || 0, prev.revenue) >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                            {getGrowth(monthData?.totalRevenue || 0, prev.revenue)}% vs prev month
                        </span>
                    </div>
                </div>

                {/* Total Orders */}
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg hover:border-blue-700/50 transition-all">
                    <div className="flex items-center justify-between mb-3">
                        <h3 className="text-gray-400 font-semibold text-xs uppercase tracking-wider">Total Orders</h3>
                        <div className="p-2 bg-blue-900/30 rounded-lg">
                            <ShoppingCart className="w-5 h-5 text-blue-400" />
                        </div>
                    </div>
                    <p className="text-2xl font-bold text-blue-400">{monthData?.totalOrders || 0}</p>
                    <div className="flex items-center gap-2 mt-2">
                        <span className="text-xs text-green-400">{monthData?.completedOrders || 0} completed</span>
                        <span className="text-gray-600">&#8226;</span>
                        <span className="text-xs text-yellow-400">{monthData?.pendingOrders || 0} pending</span>
                    </div>
                </div>

                {/* Avg Order Value */}
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg hover:border-purple-700/50 transition-all">
                    <div className="flex items-center justify-between mb-3">
                        <h3 className="text-gray-400 font-semibold text-xs uppercase tracking-wider">Avg Order Value</h3>
                        <div className="p-2 bg-purple-900/30 rounded-lg">
                            <Zap className="w-5 h-5 text-purple-400" />
                        </div>
                    </div>
                    <p className="text-2xl font-bold text-purple-400">{formatCurrency(monthData?.avgOrderValue || 0)}</p>
                    <p className="text-gray-500 text-xs mt-2">{monthData?.completionRate || 0}% completion rate</p>
                </div>

                {/* Active Sellers */}
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 shadow-lg hover:border-green-700/50 transition-all">
                    <div className="flex items-center justify-between mb-3">
                        <h3 className="text-gray-400 font-semibold text-xs uppercase tracking-wider">Active Sellers</h3>
                        <div className="p-2 bg-green-900/30 rounded-lg">
                            <Store className="w-5 h-5 text-green-400" />
                        </div>
                    </div>
                    <p className="text-2xl font-bold text-green-400">{monthData?.activeSellers || 0}</p>
                    <p className="text-gray-500 text-xs mt-2">With orders this month</p>
                </div>
            </div>

            {/* Platform Overview Cards */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                <div className="bg-gray-800/60 rounded-lg p-4 border border-gray-700/50">
                    <div className="flex items-center gap-2 mb-1">
                        <Store className="w-4 h-4 text-indigo-400" />
                        <span className="text-gray-400 text-xs uppercase">Total Sellers</span>
                    </div>
                    <p className="text-xl font-bold text-white">{platformStats.totalSellers}</p>
                </div>
                <div className="bg-gray-800/60 rounded-lg p-4 border border-gray-700/50">
                    <div className="flex items-center gap-2 mb-1">
                        <Users className="w-4 h-4 text-pink-400" />
                        <span className="text-gray-400 text-xs uppercase">Total Buyers</span>
                    </div>
                    <p className="text-xl font-bold text-white">{platformStats.totalBuyers}</p>
                </div>
                <div className="bg-gray-800/60 rounded-lg p-4 border border-gray-700/50">
                    <div className="flex items-center gap-2 mb-1">
                        <Package className="w-4 h-4 text-amber-400" />
                        <span className="text-gray-400 text-xs uppercase">Total Products</span>
                    </div>
                    <p className="text-xl font-bold text-white">{platformStats.totalProducts}</p>
                </div>
                <div className="bg-gray-800/60 rounded-lg p-4 border border-gray-700/50">
                    <div className="flex items-center gap-2 mb-1">
                        <Zap className="w-4 h-4 text-orange-400" />
                        <span className="text-gray-400 text-xs uppercase">Total Auctions</span>
                    </div>
                    <p className="text-xl font-bold text-white">{platformStats.totalAuctions}</p>
                </div>
            </div>

            {/* Performance Summary Row */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {/* Completion Rate */}
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700">
                    <h4 className="text-gray-400 text-xs uppercase tracking-wider mb-3">Order Completion</h4>
                    <div className="flex items-end gap-3 mb-3">
                        <span className="text-3xl font-bold text-white">{monthData?.completionRate || 0}%</span>
                        <span className="text-gray-500 text-sm mb-1">of orders completed</span>
                    </div>
                    <div className="w-full bg-gray-700 rounded-full h-2.5">
                        <div
                            className="bg-gradient-to-r from-cyan-500 to-green-400 h-2.5 rounded-full transition-all duration-500"
                            style={{ width: `${monthData?.completionRate || 0}%` }}
                        ></div>
                    </div>
                    <div className="grid grid-cols-3 gap-2 mt-4">
                        <div className="text-center">
                            <p className="text-xs text-gray-500">Completed</p>
                            <p className="text-sm font-bold text-green-400">{monthData?.completedOrders || 0}</p>
                        </div>
                        <div className="text-center">
                            <p className="text-xs text-gray-500">Pending</p>
                            <p className="text-sm font-bold text-yellow-400">{monthData?.pendingOrders || 0}</p>
                        </div>
                        <div className="text-center">
                            <p className="text-xs text-gray-500">Cancelled</p>
                            <p className="text-sm font-bold text-red-400">{monthData?.cancelledOrders || 0}</p>
                        </div>
                    </div>
                </div>

                {/* Tax & Service Breakdown */}
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700">
                    <h4 className="text-gray-400 text-xs uppercase tracking-wider mb-3">Platform Earnings (Tax + Service)</h4>
                    <p className="text-2xl font-bold text-green-400 mb-4">
                        {formatCurrency((monthData?.totalTax || 0) + (monthData?.totalServiceCharge || 0))}
                    </p>
                    <div className="space-y-3">
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                                <div className="w-3 h-3 rounded bg-blue-500"></div>
                                <span className="text-gray-400 text-sm">Tax Collected</span>
                            </div>
                            <span className="text-blue-400 font-semibold text-sm">{formatCurrency(monthData?.totalTax || 0)}</span>
                        </div>
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                                <div className="w-3 h-3 rounded bg-purple-500"></div>
                                <span className="text-gray-400 text-sm">Service Charge</span>
                            </div>
                            <span className="text-purple-400 font-semibold text-sm">{formatCurrency(monthData?.totalServiceCharge || 0)}</span>
                        </div>
                    </div>
                </div>

                {/* Month-over-Month Growth */}
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700">
                    <h4 className="text-gray-400 text-xs uppercase tracking-wider mb-3">Growth vs Previous Month</h4>
                    <div className="space-y-3">
                        {[
                            { label: 'Revenue', current: monthData?.totalRevenue || 0, previous: prev.revenue, color: 'cyan' },
                            { label: 'Orders', current: monthData?.totalOrders || 0, previous: prev.orderCount, color: 'blue' },
                            { label: 'Tax', current: monthData?.totalTax || 0, previous: prev.taxAmount, color: 'indigo' },
                        ].map((item) => {
                            const growth = getGrowth(item.current, item.previous);
                            const isPositive = growth >= 0;
                            return (
                                <div key={item.label} className="flex items-center justify-between p-2 bg-gray-700/30 rounded-lg">
                                    <span className="text-gray-300 text-sm">{item.label}</span>
                                    <div className="flex items-center gap-1">
                                        {isPositive
                                            ? <ArrowUpRight className="w-3.5 h-3.5 text-green-400" />
                                            : <ArrowDownRight className="w-3.5 h-3.5 text-red-400" />}
                                        <span className={`font-bold text-sm ${isPositive ? 'text-green-400' : 'text-red-400'}`}>
                                            {growth}%
                                        </span>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                </div>
            </div>

            {/* PDF Report Download Buttons */}
            <div className="flex flex-wrap gap-3">
                <button
                    onClick={() => generatePDFReport('complete')}
                    className="flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-cyan-600 to-cyan-700 text-white rounded-xl hover:from-cyan-500 hover:to-cyan-600 transition-all shadow-lg shadow-cyan-900/20 font-medium text-sm"
                >
                    <Download className="w-4 h-4" />
                    Download Complete Report (PDF)
                </button>
                <button
                    onClick={() => generatePDFReport('seller')}
                    className="flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-xl hover:from-purple-500 hover:to-purple-600 transition-all shadow-lg shadow-purple-900/20 font-medium text-sm"
                >
                    <FileText className="w-4 h-4" />
                    Download Seller Report (PDF)
                </button>
            </div>

            {/* Canvas Chart */}
            <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700">
                <div className="flex items-center justify-between mb-4">
                    <h3 className="text-white font-semibold text-lg flex items-center gap-2">
                        <BarChart3 className="w-5 h-5 text-cyan-400" />
                        Monthly Revenue & Orders - {selectedYear}
                    </h3>
                </div>
                <div style={{ width: '100%', height: '300px' }}>
                    <canvas
                        ref={canvasRef}
                        style={{ width: '100%', height: '100%' }}
                    />
                </div>
            </div>

            {/* View Toggle */}
            <div className="flex items-center gap-2">
                <button
                    onClick={() => setViewMode('overview')}
                    className={`px-4 py-2 rounded-lg font-medium text-sm transition-all ${viewMode === 'overview'
                        ? 'bg-cyan-600 text-white' : 'bg-gray-800 text-gray-400 hover:bg-gray-700'}`}
                >
                    Monthly Overview
                </button>
                <button
                    onClick={() => setViewMode('seller')}
                    className={`px-4 py-2 rounded-lg font-medium text-sm transition-all ${viewMode === 'seller'
                        ? 'bg-purple-600 text-white' : 'bg-gray-800 text-gray-400 hover:bg-gray-700'}`}
                >
                    <span className="flex items-center gap-1.5">
                        <Users className="w-4 h-4" />
                        Seller Breakdown
                    </span>
                </button>
                <button
                    onClick={() => setViewMode('monthly')}
                    className={`px-4 py-2 rounded-lg font-medium text-sm transition-all ${viewMode === 'monthly'
                        ? 'bg-blue-600 text-white' : 'bg-gray-800 text-gray-400 hover:bg-gray-700'}`}
                >
                    <span className="flex items-center gap-1.5">
                        <Calendar className="w-4 h-4" />
                        Yearly Table
                    </span>
                </button>
            </div>

            {/* Seller Breakdown Table */}
            {viewMode === 'seller' && (
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl border border-gray-700 overflow-hidden">
                    <div className="p-4 border-b border-gray-700">
                        <h3 className="text-white font-semibold text-lg flex items-center gap-2">
                            <Users className="w-5 h-5 text-purple-400" />
                            Seller Performance - {months[selectedMonth]} {selectedYear}
                        </h3>
                    </div>
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm">
                            <thead>
                                <tr className="text-gray-400 bg-gray-900/50">
                                    <th className="text-left py-3 px-4 font-semibold">#</th>
                                    <th className="text-left py-3 px-4 font-semibold">Seller</th>
                                    <th className="text-right py-3 px-4 font-semibold">Revenue</th>
                                    <th className="text-right py-3 px-4 font-semibold">Tax</th>
                                    <th className="text-right py-3 px-4 font-semibold">Service Charge</th>
                                    <th className="text-center py-3 px-4 font-semibold">Orders</th>
                                    <th className="text-center py-3 px-4 font-semibold">Completed</th>
                                    <th className="text-center py-3 px-4 font-semibold">Items</th>
                                </tr>
                            </thead>
                            <tbody>
                                {sellerBreakdown.length === 0 ? (
                                    <tr>
                                        <td colSpan="8" className="text-center py-8 text-gray-500">
                                            No seller data for this month
                                        </td>
                                    </tr>
                                ) : (
                                    sellerBreakdown.map((seller, index) => (
                                        <tr key={seller.sellerId} className="border-b border-gray-800 text-gray-300 hover:bg-gray-800/50 transition-colors">
                                            <td className="py-3 px-4">{index + 1}</td>
                                            <td className="py-3 px-4 font-medium text-white">{seller.sellerName}</td>
                                            <td className="py-3 px-4 text-right text-cyan-400">{formatCurrency(seller.revenue)}</td>
                                            <td className="py-3 px-4 text-right text-blue-400">{formatCurrency(seller.taxAmount)}</td>
                                            <td className="py-3 px-4 text-right text-purple-400">{formatCurrency(seller.serviceChargeAmount)}</td>
                                            <td className="py-3 px-4 text-center">{seller.orderCount}</td>
                                            <td className="py-3 px-4 text-center text-green-400">{seller.completedOrders}</td>
                                            <td className="py-3 px-4 text-center">{seller.itemCount}</td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                            {sellerBreakdown.length > 0 && (
                                <tfoot>
                                    <tr className="bg-gray-900/70 text-white font-semibold">
                                        <td className="py-3 px-4" colSpan="2">Total</td>
                                        <td className="py-3 px-4 text-right text-cyan-400">{formatCurrency(sellerBreakdown.reduce((s, e) => s + e.revenue, 0))}</td>
                                        <td className="py-3 px-4 text-right text-blue-400">{formatCurrency(sellerBreakdown.reduce((s, e) => s + e.taxAmount, 0))}</td>
                                        <td className="py-3 px-4 text-right text-purple-400">{formatCurrency(sellerBreakdown.reduce((s, e) => s + e.serviceChargeAmount, 0))}</td>
                                        <td className="py-3 px-4 text-center">{sellerBreakdown.reduce((s, e) => s + e.orderCount, 0)}</td>
                                        <td className="py-3 px-4 text-center text-green-400">{sellerBreakdown.reduce((s, e) => s + e.completedOrders, 0)}</td>
                                        <td className="py-3 px-4 text-center">{sellerBreakdown.reduce((s, e) => s + e.itemCount, 0)}</td>
                                    </tr>
                                </tfoot>
                            )}
                        </table>
                    </div>
                </div>
            )}

            {/* Monthly Overview Table */}
            {viewMode === 'overview' && (
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl border border-gray-700 overflow-hidden">
                    <div className="p-4 border-b border-gray-700">
                        <h3 className="text-white font-semibold text-lg">Order Summary - {months[selectedMonth]} {selectedYear}</h3>
                    </div>
                    <div className="p-6">
                        <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
                            <div className="bg-gray-700/30 rounded-lg p-4 border border-gray-600/30 text-center">
                                <p className="text-gray-400 text-xs uppercase mb-1">Total Orders</p>
                                <p className="text-2xl font-bold text-white">{monthData?.totalOrders || 0}</p>
                            </div>
                            <div className="bg-gray-700/30 rounded-lg p-4 border border-gray-600/30 text-center">
                                <p className="text-gray-400 text-xs uppercase mb-1">Completed</p>
                                <p className="text-2xl font-bold text-green-400">{monthData?.completedOrders || 0}</p>
                            </div>
                            <div className="bg-gray-700/30 rounded-lg p-4 border border-gray-600/30 text-center">
                                <p className="text-gray-400 text-xs uppercase mb-1">Pending</p>
                                <p className="text-2xl font-bold text-yellow-400">{monthData?.pendingOrders || 0}</p>
                            </div>
                            <div className="bg-gray-700/30 rounded-lg p-4 border border-gray-600/30 text-center">
                                <p className="text-gray-400 text-xs uppercase mb-1">Processing</p>
                                <p className="text-2xl font-bold text-blue-400">{monthData?.processingOrders || 0}</p>
                            </div>
                            <div className="bg-gray-700/30 rounded-lg p-4 border border-gray-600/30 text-center">
                                <p className="text-gray-400 text-xs uppercase mb-1">Cancelled</p>
                                <p className="text-2xl font-bold text-red-400">{monthData?.cancelledOrders || 0}</p>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Yearly Table */}
            {viewMode === 'monthly' && monthlyTrend.length > 0 && (
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl border border-gray-700 overflow-hidden">
                    <div className="p-4 border-b border-gray-700">
                        <h3 className="text-white font-semibold text-lg">Monthly Breakdown - {selectedYear}</h3>
                    </div>
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm">
                            <thead>
                                <tr className="text-gray-400 bg-gray-900/50">
                                    <th className="text-left py-3 px-4 font-semibold">Month</th>
                                    <th className="text-right py-3 px-4 font-semibold">Revenue</th>
                                    <th className="text-right py-3 px-4 font-semibold">Tax</th>
                                    <th className="text-right py-3 px-4 font-semibold">Service Charge</th>
                                    <th className="text-center py-3 px-4 font-semibold">Orders</th>
                                    <th className="text-center py-3 px-4 font-semibold">Completed</th>
                                </tr>
                            </thead>
                            <tbody>
                                {monthlyTrend.map((month, index) => (
                                    <tr
                                        key={index}
                                        className={`border-b border-gray-800 text-gray-300 hover:bg-gray-800/50 transition-colors ${index === selectedMonth ? 'bg-cyan-900/10 border-l-2 border-l-cyan-500' : ''}`}
                                    >
                                        <td className={`py-3 px-4 font-medium ${index === selectedMonth ? 'text-white' : ''}`}>
                                            {months[index]}
                                        </td>
                                        <td className="py-3 px-4 text-right text-cyan-400">{formatCurrency(month.revenue)}</td>
                                        <td className="py-3 px-4 text-right text-blue-400">{formatCurrency(month.taxAmount)}</td>
                                        <td className="py-3 px-4 text-right text-purple-400">{formatCurrency(month.serviceChargeAmount)}</td>
                                        <td className="py-3 px-4 text-center">{month.orderCount}</td>
                                        <td className="py-3 px-4 text-center text-green-400">{month.completedOrders}</td>
                                    </tr>
                                ))}
                            </tbody>
                            <tfoot>
                                <tr className="bg-gray-900/70 text-white font-semibold">
                                    <td className="py-3 px-4">Year Total</td>
                                    <td className="py-3 px-4 text-right text-cyan-400">{formatCurrency(monthlyTrend.reduce((s, m) => s + m.revenue, 0))}</td>
                                    <td className="py-3 px-4 text-right text-blue-400">{formatCurrency(monthlyTrend.reduce((s, m) => s + m.taxAmount, 0))}</td>
                                    <td className="py-3 px-4 text-right text-purple-400">{formatCurrency(monthlyTrend.reduce((s, m) => s + m.serviceChargeAmount, 0))}</td>
                                    <td className="py-3 px-4 text-center">{monthlyTrend.reduce((s, m) => s + m.orderCount, 0)}</td>
                                    <td className="py-3 px-4 text-center text-green-400">{monthlyTrend.reduce((s, m) => s + m.completedOrders, 0)}</td>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                </div>
            )}
        </div>
    );
}
