import React, { useState, useEffect, useRef } from 'react';
import {
    DollarSign, TrendingUp, Users, Calendar, Download, FileText,
    ChevronLeft, ChevronRight, Filter, RefreshCw, BarChart3, ArrowUpRight, ArrowDownRight
} from 'lucide-react';
import { collection, query, where, getDocs, Timestamp } from 'firebase/firestore';
import { db } from '../services/firebase';

export default function TaxEarningsPanel() {
    const [loading, setLoading] = useState(true);
    const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
    const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth());
    const [viewMode, setViewMode] = useState('total'); // 'total' or 'seller'
    const [earningsData, setEarningsData] = useState(null);
    const [sellerEarnings, setSellerEarnings] = useState([]);
    const [monthlyTrend, setMonthlyTrend] = useState([]);
    const [sellerNames, setSellerNames] = useState({});
    const canvasRef = useRef(null);

    const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
    ];

    useEffect(() => {
        fetchEarnings();
    }, [selectedYear, selectedMonth]);

    useEffect(() => {
        if (monthlyTrend.length > 0) {
            drawChart();
        }
    }, [monthlyTrend, viewMode]);

    const fetchSellerNames = async (sellerIds) => {
        const names = { ...sellerNames };
        const unknownIds = sellerIds.filter(id => !names[id]);

        if (unknownIds.length === 0) return names;

        try {
            // Fetch from sellers collection
            for (const sellerId of unknownIds) {
                try {
                    const sellerQuery = query(collection(db, 'sellers'), where('uid', '==', sellerId));
                    const sellerSnap = await getDocs(sellerQuery);
                    if (!sellerSnap.empty) {
                        const data = sellerSnap.docs[0].data();
                        names[sellerId] = data.shopName || data.businessName || data.name || data.email || sellerId.substring(0, 8);
                    } else {
                        // Try users collection
                        const userQuery = query(collection(db, 'buyers'), where('uid', '==', sellerId));
                        const userSnap = await getDocs(userQuery);
                        if (!userSnap.empty) {
                            const data = userSnap.docs[0].data();
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

    const fetchEarnings = async () => {
        try {
            setLoading(true);

            // Get start and end of selected month
            const startDate = new Date(selectedYear, selectedMonth, 1);
            const endDate = new Date(selectedYear, selectedMonth + 1, 0, 23, 59, 59, 999);

            const startTimestamp = Timestamp.fromDate(startDate);
            const endTimestamp = Timestamp.fromDate(endDate);

            // Query orders for the selected month
            const ordersRef = collection(db, 'orders');
            const q = query(
                ordersRef,
                where('orderDate', '>=', startTimestamp),
                where('orderDate', '<=', endTimestamp)
            );

            const snapshot = await getDocs(q);
            const orders = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

            // Calculate totals
            let totalTax = 0;
            let totalServiceCharge = 0;
            let totalRevenue = 0;
            let orderCount = 0;
            const sellerMap = {};

            orders.forEach(order => {
                const taxAmount = order.taxAmount || 0;
                const serviceChargeAmount = order.serviceChargeAmount || 0;
                const totalAmount = order.totalAmount || 0;

                totalTax += taxAmount;
                totalServiceCharge += serviceChargeAmount;
                totalRevenue += totalAmount;
                orderCount++;

                // Group by seller
                const items = order.items || [];
                items.forEach(item => {
                    const sellerId = item.sellerId || 'unknown';
                    if (!sellerMap[sellerId]) {
                        sellerMap[sellerId] = {
                            sellerId,
                            taxAmount: 0,
                            serviceChargeAmount: 0,
                            totalRevenue: 0,
                            orderCount: 0,
                            itemCount: 0,
                        };
                    }
                    // Distribute tax/service proportionally by item value
                    const itemTotal = (item.price || 0) * (item.quantity || 1);
                    const orderSubtotal = order.subtotalBeforeTax || totalAmount;
                    const proportion = orderSubtotal > 0 ? itemTotal / orderSubtotal : 0;

                    sellerMap[sellerId].taxAmount += taxAmount * proportion;
                    sellerMap[sellerId].serviceChargeAmount += serviceChargeAmount * proportion;
                    sellerMap[sellerId].totalRevenue += itemTotal;
                    sellerMap[sellerId].itemCount += item.quantity || 1;
                    sellerMap[sellerId].orderCount++;
                });
            });

            const sellerList = Object.values(sellerMap).sort((a, b) => b.totalRevenue - a.totalRevenue);

            // Fetch seller names
            const sellerIds = sellerList.map(s => s.sellerId).filter(id => id !== 'unknown');
            const names = await fetchSellerNames(sellerIds);
            sellerList.forEach(s => {
                s.sellerName = names[s.sellerId] || s.sellerId;
            });

            setEarningsData({
                totalTax,
                totalServiceCharge,
                totalRevenue,
                orderCount,
                platformEarnings: totalTax + totalServiceCharge,
            });

            setSellerEarnings(sellerList);

            // Fetch yearly trend (all 12 months)
            await fetchYearlyTrend();

        } catch (error) {
            console.error('Error fetching earnings:', error);
        } finally {
            setLoading(false);
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
            const monthlyData = Array.from({ length: 12 }, (_, i) => ({
                month: months[i].substring(0, 3),
                monthIndex: i,
                taxAmount: 0,
                serviceChargeAmount: 0,
                totalRevenue: 0,
                orderCount: 0,
            }));

            snapshot.docs.forEach(doc => {
                const data = doc.data();
                const orderDate = data.orderDate?.toDate?.();
                if (orderDate) {
                    const monthIdx = orderDate.getMonth();
                    monthlyData[monthIdx].taxAmount += data.taxAmount || 0;
                    monthlyData[monthIdx].serviceChargeAmount += data.serviceChargeAmount || 0;
                    monthlyData[monthIdx].totalRevenue += data.totalAmount || 0;
                    monthlyData[monthIdx].orderCount++;
                }
            });

            setMonthlyTrend(monthlyData);
        } catch (error) {
            console.error('Error fetching yearly trend:', error);
        }
    };

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

        // Clear
        ctx.clearRect(0, 0, width, height);

        // Find max value
        const maxValue = Math.max(
            ...monthlyTrend.map(d => Math.max(d.taxAmount + d.serviceChargeAmount, 1))
        ) * 1.2;

        const barWidth = chartWidth / 12 - 8;

        // Draw grid lines
        ctx.strokeStyle = '#374151';
        ctx.lineWidth = 0.5;
        for (let i = 0; i <= 5; i++) {
            const y = padding.top + (chartHeight * (1 - i / 5));
            ctx.beginPath();
            ctx.moveTo(padding.left, y);
            ctx.lineTo(width - padding.right, y);
            ctx.stroke();

            // Y-axis labels
            ctx.fillStyle = '#9CA3AF';
            ctx.font = '11px Inter, sans-serif';
            ctx.textAlign = 'right';
            const val = (maxValue * i / 5);
            ctx.fillText(val >= 1000 ? `Rs.${(val / 1000).toFixed(1)}K` : `Rs.${val.toFixed(0)}`, padding.left - 8, y + 4);
        }

        // Draw bars
        monthlyTrend.forEach((data, index) => {
            const x = padding.left + (chartWidth / 12) * index + 4;
            const taxHeight = maxValue > 0 ? (data.taxAmount / maxValue) * chartHeight : 0;
            const serviceHeight = maxValue > 0 ? (data.serviceChargeAmount / maxValue) * chartHeight : 0;

            const isSelected = index === selectedMonth;

            // Service charge bar (bottom)
            const gradient1 = ctx.createLinearGradient(x, padding.top + chartHeight - serviceHeight - taxHeight, x, padding.top + chartHeight);
            gradient1.addColorStop(0, isSelected ? '#9333EA' : '#7C3AED80');
            gradient1.addColorStop(1, isSelected ? '#6B21A8' : '#581C8780');
            ctx.fillStyle = gradient1;

            const roundedRect = (x, y, w, h, r) => {
                ctx.beginPath();
                ctx.moveTo(x + r, y);
                ctx.lineTo(x + w - r, y);
                ctx.quadraticCurveTo(x + w, y, x + w, y + r);
                ctx.lineTo(x + w, y + h);
                ctx.lineTo(x, y + h);
                ctx.lineTo(x, y + r);
                ctx.quadraticCurveTo(x, y, x + r, y);
                ctx.closePath();
                ctx.fill();
            };

            // Tax bar (on top of service charge)
            const totalBarHeight = taxHeight + serviceHeight;
            const taxBarY = padding.top + chartHeight - totalBarHeight;

            // Draw combined background
            if (totalBarHeight > 0) {
                // Tax portion (top)
                const gradient2 = ctx.createLinearGradient(x, taxBarY, x, taxBarY + taxHeight);
                gradient2.addColorStop(0, isSelected ? '#3B82F6' : '#3B82F680');
                gradient2.addColorStop(1, isSelected ? '#2563EB' : '#1D4ED880');
                ctx.fillStyle = gradient2;
                roundedRect(x, taxBarY, barWidth, taxHeight, totalBarHeight > 4 ? 4 : 0);

                // Service charge portion (bottom)
                ctx.fillStyle = gradient1;
                ctx.fillRect(x, taxBarY + taxHeight, barWidth, serviceHeight);
            }

            // X-axis labels
            ctx.fillStyle = isSelected ? '#FFFFFF' : '#9CA3AF';
            ctx.font = isSelected ? 'bold 12px Inter, sans-serif' : '11px Inter, sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText(data.month, x + barWidth / 2, padding.top + chartHeight + 20);

            // Selected month indicator
            if (isSelected) {
                ctx.fillStyle = '#3B82F6';
                ctx.beginPath();
                ctx.arc(x + barWidth / 2, padding.top + chartHeight + 35, 3, 0, Math.PI * 2);
                ctx.fill();
            }
        });

        // Legend
        ctx.font = '12px Inter, sans-serif';

        ctx.fillStyle = '#3B82F6';
        ctx.fillRect(padding.left, 10, 14, 14);
        ctx.fillStyle = '#D1D5DB';
        ctx.textAlign = 'left';
        ctx.fillText('Tax Earnings', padding.left + 20, 22);

        ctx.fillStyle = '#9333EA';
        ctx.fillRect(padding.left + 130, 10, 14, 14);
        ctx.fillStyle = '#D1D5DB';
        ctx.fillText('Service Charge', padding.left + 155, 22);
    };

    const navigateMonth = (direction) => {
        let newMonth = selectedMonth + direction;
        let newYear = selectedYear;
        if (newMonth < 0) {
            newMonth = 11;
            newYear--;
        } else if (newMonth > 11) {
            newMonth = 0;
            newYear++;
        }
        setSelectedMonth(newMonth);
        setSelectedYear(newYear);
    };

    const formatCurrency = (amount) => {
        if (amount >= 1000000) return `Rs.${(amount / 1000000).toFixed(2)}M`;
        if (amount >= 1000) return `Rs.${(amount / 1000).toFixed(2)}K`;
        return `Rs.${amount.toFixed(2)}`;
    };

    // Compare with previous month
    const getPreviousMonthData = () => {
        const prevIdx = selectedMonth === 0 ? 11 : selectedMonth - 1;
        return monthlyTrend[prevIdx] || { taxAmount: 0, serviceChargeAmount: 0 };
    };

    const getGrowthPercentage = (current, previous) => {
        if (previous === 0) return current > 0 ? 100 : 0;
        return ((current - previous) / previous * 100).toFixed(1);
    };

    // ---- PDF Generation ----
    const generatePDFReport = (reportType = 'total') => {
        const data = earningsData;
        if (!data) return;

        const prevMonth = getPreviousMonthData();
        const monthName = months[selectedMonth];

        // Build HTML content for PDF
        let htmlContent = `
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>GemNest Tax & Service Charge Report - ${monthName} ${selectedYear}</title>
<style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #1a1a2e; background: #fff; padding: 40px; }
    .header { text-align: center; margin-bottom: 30px; border-bottom: 3px solid #667eea; padding-bottom: 20px; }
    .header h1 { font-size: 28px; color: #667eea; margin-bottom: 5px; }
    .header h2 { font-size: 18px; color: #4a5568; font-weight: normal; }
    .header .date { font-size: 12px; color: #999; margin-top: 8px; }
    .summary-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 30px; }
    .summary-card { background: #f7fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 16px; text-align: center; }
    .summary-card .label { font-size: 11px; color: #999; text-transform: uppercase; letter-spacing: 1px; }
    .summary-card .value { font-size: 22px; font-weight: bold; color: #2d3748; margin-top: 4px; }
    .summary-card .sub { font-size: 11px; color: #718096; margin-top: 2px; }
    .summary-card.tax .value { color: #3182ce; }
    .summary-card.service .value { color: #805ad5; }
    .summary-card.total .value { color: #38a169; }
    .section { margin-bottom: 30px; }
    .section h3 { font-size: 16px; color: #2d3748; margin-bottom: 12px; padding-bottom: 6px; border-bottom: 1px solid #e2e8f0; }
    table { width: 100%; border-collapse: collapse; font-size: 13px; }
    th { background: #667eea; color: white; padding: 10px 12px; text-align: left; font-weight: 600; }
    td { padding: 10px 12px; border-bottom: 1px solid #e2e8f0; }
    tr:nth-child(even) { background: #f7fafc; }
    tr:hover { background: #edf2f7; }
    .text-right { text-align: right; }
    .text-center { text-align: center; }
    .total-row { font-weight: bold; background: #edf2f7 !important; }
    .footer { margin-top: 40px; text-align: center; font-size: 11px; color: #999; border-top: 1px solid #e2e8f0; padding-top: 15px; }
    .monthly-trend { margin-bottom: 20px; }
    .bar-container { display: flex; align-items: flex-end; gap: 8px; height: 120px; margin-top: 10px; }
    .bar-wrapper { flex: 1; display: flex; flex-direction: column; align-items: center; }
    .bar { width: 100%; border-radius: 4px 4px 0 0; min-height: 2px; }
    .bar.tax { background: #3182ce; }
    .bar.service { background: #805ad5; }
    .bar-label { font-size: 9px; color: #999; margin-top: 4px; }
    .growth { display: inline-block; padding: 2px 6px; border-radius: 4px; font-size: 11px; font-weight: bold; }
    .growth.positive { background: #c6f6d5; color: #22543d; }
    .growth.negative { background: #fed7d7; color: #742a2a; }
    @media print { body { padding: 20px; } .no-print { display: none; } }
</style>
</head>
<body>
<div class="header">
    <h1>💎 GemNest Platform</h1>
    <h2>Tax & Service Charge Earnings Report</h2>
    <p><strong>${monthName} ${selectedYear}</strong></p>
    <p class="date">Generated on ${new Date().toLocaleString()}</p>
</div>

<div class="summary-grid">
    <div class="summary-card">
        <div class="label">Total Orders</div>
        <div class="value">${data.orderCount}</div>
    </div>
    <div class="summary-card tax">
        <div class="label">Tax Collected</div>
        <div class="value">Rs.${data.totalTax.toFixed(2)}</div>
        <div class="sub">${earningsData ? ((data.totalTax / (data.totalRevenue || 1)) * 100).toFixed(1) : 0}% of revenue</div>
    </div>
    <div class="summary-card service">
        <div class="label">Service Charge</div>
        <div class="value">Rs.${data.totalServiceCharge.toFixed(2)}</div>
        <div class="sub">${earningsData ? ((data.totalServiceCharge / (data.totalRevenue || 1)) * 100).toFixed(1) : 0}% of revenue</div>
    </div>
    <div class="summary-card total">
        <div class="label">Platform Earnings</div>
        <div class="value">Rs.${data.platformEarnings.toFixed(2)}</div>
        <div class="sub">Tax + Service Charge</div>
    </div>
</div>

<div class="section">
    <h3>Monthly Comparison</h3>
    <table>
        <thead><tr><th>Metric</th><th class="text-right">Previous Month</th><th class="text-right">Current Month</th><th class="text-right">Growth</th></tr></thead>
        <tbody>
            <tr>
                <td>Tax Earnings</td>
                <td class="text-right">Rs.${prevMonth.taxAmount.toFixed(2)}</td>
                <td class="text-right">Rs.${data.totalTax.toFixed(2)}</td>
                <td class="text-right"><span class="growth ${getGrowthPercentage(data.totalTax, prevMonth.taxAmount) >= 0 ? 'positive' : 'negative'}">${getGrowthPercentage(data.totalTax, prevMonth.taxAmount)}%</span></td>
            </tr>
            <tr>
                <td>Service Charge Earnings</td>
                <td class="text-right">Rs.${prevMonth.serviceChargeAmount.toFixed(2)}</td>
                <td class="text-right">Rs.${data.totalServiceCharge.toFixed(2)}</td>
                <td class="text-right"><span class="growth ${getGrowthPercentage(data.totalServiceCharge, prevMonth.serviceChargeAmount) >= 0 ? 'positive' : 'negative'}">${getGrowthPercentage(data.totalServiceCharge, prevMonth.serviceChargeAmount)}%</span></td>
            </tr>
            <tr class="total-row">
                <td>Total Platform Earnings</td>
                <td class="text-right">Rs.${(prevMonth.taxAmount + prevMonth.serviceChargeAmount).toFixed(2)}</td>
                <td class="text-right">Rs.${data.platformEarnings.toFixed(2)}</td>
                <td class="text-right"><span class="growth ${getGrowthPercentage(data.platformEarnings, prevMonth.taxAmount + prevMonth.serviceChargeAmount) >= 0 ? 'positive' : 'negative'}">${getGrowthPercentage(data.platformEarnings, prevMonth.taxAmount + prevMonth.serviceChargeAmount)}%</span></td>
            </tr>
        </tbody>
    </table>
</div>`;

        // Add yearly trend mini-bars
        if (monthlyTrend.length > 0) {
            const maxTrend = Math.max(...monthlyTrend.map(d => d.taxAmount + d.serviceChargeAmount), 1);
            htmlContent += `
<div class="section monthly-trend">
    <h3>Yearly Trend - ${selectedYear}</h3>
    <table>
        <thead><tr><th>Month</th><th class="text-right">Tax</th><th class="text-right">Service Charge</th><th class="text-right">Total</th><th class="text-right">Orders</th></tr></thead>
        <tbody>
            ${monthlyTrend.map((m, i) => `
            <tr${i === selectedMonth ? ' style="background:#edf2f7;font-weight:bold"' : ''}>
                <td>${months[i]}</td>
                <td class="text-right">Rs.${m.taxAmount.toFixed(2)}</td>
                <td class="text-right">Rs.${m.serviceChargeAmount.toFixed(2)}</td>
                <td class="text-right">Rs.${(m.taxAmount + m.serviceChargeAmount).toFixed(2)}</td>
                <td class="text-center">${m.orderCount}</td>
            </tr>`).join('')}
            <tr class="total-row">
                <td>Year Total</td>
                <td class="text-right">Rs.${monthlyTrend.reduce((s, m) => s + m.taxAmount, 0).toFixed(2)}</td>
                <td class="text-right">Rs.${monthlyTrend.reduce((s, m) => s + m.serviceChargeAmount, 0).toFixed(2)}</td>
                <td class="text-right">Rs.${monthlyTrend.reduce((s, m) => s + m.taxAmount + m.serviceChargeAmount, 0).toFixed(2)}</td>
                <td class="text-center">${monthlyTrend.reduce((s, m) => s + m.orderCount, 0)}</td>
            </tr>
        </tbody>
    </table>
</div>`;
        }

        // Add seller breakdown if requested or in total view
        if (reportType === 'seller' || reportType === 'total') {
            htmlContent += `
<div class="section">
    <h3>Seller-wise Breakdown - ${monthName} ${selectedYear}</h3>
    <table>
        <thead><tr><th>Seller</th><th class="text-right">Revenue</th><th class="text-right">Tax Collected</th><th class="text-right">Service Charge</th><th class="text-right">Total Platform Fee</th><th class="text-center">Orders</th></tr></thead>
        <tbody>
            ${sellerEarnings.map(s => `
            <tr>
                <td>${s.sellerName}</td>
                <td class="text-right">Rs.${s.totalRevenue.toFixed(2)}</td>
                <td class="text-right">Rs.${s.taxAmount.toFixed(2)}</td>
                <td class="text-right">Rs.${s.serviceChargeAmount.toFixed(2)}</td>
                <td class="text-right">Rs.${(s.taxAmount + s.serviceChargeAmount).toFixed(2)}</td>
                <td class="text-center">${s.orderCount}</td>
            </tr>`).join('')}
            <tr class="total-row">
                <td>Total</td>
                <td class="text-right">Rs.${sellerEarnings.reduce((s, e) => s + e.totalRevenue, 0).toFixed(2)}</td>
                <td class="text-right">Rs.${sellerEarnings.reduce((s, e) => s + e.taxAmount, 0).toFixed(2)}</td>
                <td class="text-right">Rs.${sellerEarnings.reduce((s, e) => s + e.serviceChargeAmount, 0).toFixed(2)}</td>
                <td class="text-right">Rs.${sellerEarnings.reduce((s, e) => s + e.taxAmount + e.serviceChargeAmount, 0).toFixed(2)}</td>
                <td class="text-center">${sellerEarnings.reduce((s, e) => s + e.orderCount, 0)}</td>
            </tr>
        </tbody>
    </table>
</div>`;
        }

        htmlContent += `
<div class="footer">
    <p>This is an auto-generated report from GemNest Admin Dashboard.</p>
    <p>Report Period: ${monthName} ${selectedYear} | Report Type: ${reportType === 'total' ? 'Complete Report' : 'Seller Report'}</p>
</div>
</body>
</html>`;

        // Open print dialog (generates PDF)
        const printWindow = window.open('', '_blank');
        printWindow.document.write(htmlContent);
        printWindow.document.close();
        printWindow.onload = () => {
            printWindow.print();
        };
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center h-96">
                <div className="text-center">
                    <div className="w-12 h-12 border-4 border-gray-700 border-t-blue-400 rounded-full animate-spin mx-auto mb-4"></div>
                    <p className="text-gray-400">Loading earnings data...</p>
                </div>
            </div>
        );
    }

    const prevMonth = getPreviousMonthData();

    return (
        <div className="space-y-6">
            {/* Header with Month Navigation */}
            <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
                <div>
                    <h2 className="text-3xl font-bold text-white mb-2">Tax & Service Charge Earnings</h2>
                    <p className="text-gray-400">Monthly analysis of platform tax and service charge collections</p>
                </div>
                <div className="flex items-center gap-3">
                    <button
                        onClick={() => navigateMonth(-1)}
                        className="p-2 bg-gray-800 rounded-lg hover:bg-gray-700 transition-colors"
                    >
                        <ChevronLeft className="w-5 h-5 text-gray-400" />
                    </button>
                    <div className="bg-gray-800 rounded-lg px-4 py-2 flex items-center gap-2">
                        <Calendar className="w-4 h-4 text-blue-400" />
                        <span className="text-white font-semibold">{months[selectedMonth]} {selectedYear}</span>
                    </div>
                    <button
                        onClick={() => navigateMonth(1)}
                        className="p-2 bg-gray-800 rounded-lg hover:bg-gray-700 transition-colors"
                    >
                        <ChevronRight className="w-5 h-5 text-gray-400" />
                    </button>
                    <button
                        onClick={fetchEarnings}
                        className="p-2 bg-gray-800 rounded-lg hover:bg-gray-700 transition-colors"
                        title="Refresh"
                    >
                        <RefreshCw className="w-5 h-5 text-gray-400" />
                    </button>
                </div>
            </div>

            {/* Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 hover:border-blue-700/50 transition-all">
                    <div className="flex items-center justify-between mb-3">
                        <h3 className="text-gray-400 font-semibold text-xs uppercase tracking-wider">Tax Collected</h3>
                        <div className="p-2 bg-blue-900/30 rounded-lg">
                            <DollarSign className="w-5 h-5 text-blue-400" />
                        </div>
                    </div>
                    <p className="text-2xl font-bold text-blue-400">{formatCurrency(earningsData?.totalTax || 0)}</p>
                    <div className="flex items-center gap-1 mt-2">
                        {getGrowthPercentage(earningsData?.totalTax || 0, prevMonth.taxAmount) >= 0
                            ? <ArrowUpRight className="w-3 h-3 text-green-400" />
                            : <ArrowDownRight className="w-3 h-3 text-red-400" />
                        }
                        <span className={`text-xs font-medium ${getGrowthPercentage(earningsData?.totalTax || 0, prevMonth.taxAmount) >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                            {getGrowthPercentage(earningsData?.totalTax || 0, prevMonth.taxAmount)}% vs prev month
                        </span>
                    </div>
                </div>

                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 hover:border-purple-700/50 transition-all">
                    <div className="flex items-center justify-between mb-3">
                        <h3 className="text-gray-400 font-semibold text-xs uppercase tracking-wider">Service Charge</h3>
                        <div className="p-2 bg-purple-900/30 rounded-lg">
                            <DollarSign className="w-5 h-5 text-purple-400" />
                        </div>
                    </div>
                    <p className="text-2xl font-bold text-purple-400">{formatCurrency(earningsData?.totalServiceCharge || 0)}</p>
                    <div className="flex items-center gap-1 mt-2">
                        {getGrowthPercentage(earningsData?.totalServiceCharge || 0, prevMonth.serviceChargeAmount) >= 0
                            ? <ArrowUpRight className="w-3 h-3 text-green-400" />
                            : <ArrowDownRight className="w-3 h-3 text-red-400" />
                        }
                        <span className={`text-xs font-medium ${getGrowthPercentage(earningsData?.totalServiceCharge || 0, prevMonth.serviceChargeAmount) >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                            {getGrowthPercentage(earningsData?.totalServiceCharge || 0, prevMonth.serviceChargeAmount)}% vs prev month
                        </span>
                    </div>
                </div>

                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 hover:border-green-700/50 transition-all">
                    <div className="flex items-center justify-between mb-3">
                        <h3 className="text-gray-400 font-semibold text-xs uppercase tracking-wider">Platform Earnings</h3>
                        <div className="p-2 bg-green-900/30 rounded-lg">
                            <TrendingUp className="w-5 h-5 text-green-400" />
                        </div>
                    </div>
                    <p className="text-2xl font-bold text-green-400">{formatCurrency(earningsData?.platformEarnings || 0)}</p>
                    <p className="text-gray-500 text-xs mt-2">Tax + Service Charge</p>
                </div>

                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 hover:border-yellow-700/50 transition-all">
                    <div className="flex items-center justify-between mb-3">
                        <h3 className="text-gray-400 font-semibold text-xs uppercase tracking-wider">Total Orders</h3>
                        <div className="p-2 bg-yellow-900/30 rounded-lg">
                            <BarChart3 className="w-5 h-5 text-yellow-400" />
                        </div>
                    </div>
                    <p className="text-2xl font-bold text-yellow-400">{earningsData?.orderCount || 0}</p>
                    <p className="text-gray-500 text-xs mt-2">Revenue: {formatCurrency(earningsData?.totalRevenue || 0)}</p>
                </div>
            </div>

            {/* Report Download Buttons */}
            <div className="flex flex-wrap gap-3">
                <button
                    onClick={() => generatePDFReport('total')}
                    className="flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-xl hover:from-blue-500 hover:to-blue-600 transition-all shadow-lg shadow-blue-900/20 font-medium text-sm"
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

            {/* Chart */}
            <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700">
                <div className="flex items-center justify-between mb-4">
                    <h3 className="text-white font-semibold text-lg flex items-center gap-2">
                        <BarChart3 className="w-5 h-5 text-blue-400" />
                        Monthly Earnings Trend - {selectedYear}
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
                    onClick={() => setViewMode('total')}
                    className={`px-4 py-2 rounded-lg font-medium text-sm transition-all ${viewMode === 'total'
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-800 text-gray-400 hover:bg-gray-700'
                        }`}
                >
                    Total Overview
                </button>
                <button
                    onClick={() => setViewMode('seller')}
                    className={`px-4 py-2 rounded-lg font-medium text-sm transition-all ${viewMode === 'seller'
                        ? 'bg-purple-600 text-white'
                        : 'bg-gray-800 text-gray-400 hover:bg-gray-700'
                        }`}
                >
                    <span className="flex items-center gap-1.5">
                        <Users className="w-4 h-4" />
                        Seller Breakdown
                    </span>
                </button>
            </div>

            {/* Seller Breakdown Table */}
            {viewMode === 'seller' && (
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl border border-gray-700 overflow-hidden">
                    <div className="p-4 border-b border-gray-700">
                        <h3 className="text-white font-semibold text-lg flex items-center gap-2">
                            <Users className="w-5 h-5 text-purple-400" />
                            Seller-wise Tax & Service Charge - {months[selectedMonth]} {selectedYear}
                        </h3>
                    </div>
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm">
                            <thead>
                                <tr className="text-gray-400 bg-gray-900/50">
                                    <th className="text-left py-3 px-4 font-semibold">#</th>
                                    <th className="text-left py-3 px-4 font-semibold">Seller</th>
                                    <th className="text-right py-3 px-4 font-semibold">Revenue</th>
                                    <th className="text-right py-3 px-4 font-semibold">Tax Collected</th>
                                    <th className="text-right py-3 px-4 font-semibold">Service Charge</th>
                                    <th className="text-right py-3 px-4 font-semibold">Platform Fee</th>
                                    <th className="text-center py-3 px-4 font-semibold">Orders</th>
                                </tr>
                            </thead>
                            <tbody>
                                {sellerEarnings.length === 0 ? (
                                    <tr>
                                        <td colSpan="7" className="text-center py-8 text-gray-500">
                                            No order data for this month
                                        </td>
                                    </tr>
                                ) : (
                                    sellerEarnings.map((seller, index) => (
                                        <tr key={seller.sellerId} className="border-b border-gray-800 text-gray-300 hover:bg-gray-800/50 transition-colors">
                                            <td className="py-3 px-4">{index + 1}</td>
                                            <td className="py-3 px-4 font-medium text-white">{seller.sellerName}</td>
                                            <td className="py-3 px-4 text-right">{formatCurrency(seller.totalRevenue)}</td>
                                            <td className="py-3 px-4 text-right text-blue-400">{formatCurrency(seller.taxAmount)}</td>
                                            <td className="py-3 px-4 text-right text-purple-400">{formatCurrency(seller.serviceChargeAmount)}</td>
                                            <td className="py-3 px-4 text-right text-green-400 font-semibold">{formatCurrency(seller.taxAmount + seller.serviceChargeAmount)}</td>
                                            <td className="py-3 px-4 text-center">{seller.orderCount}</td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                            {sellerEarnings.length > 0 && (
                                <tfoot>
                                    <tr className="bg-gray-900/70 text-white font-semibold">
                                        <td className="py-3 px-4" colSpan="2">Total</td>
                                        <td className="py-3 px-4 text-right">{formatCurrency(sellerEarnings.reduce((s, e) => s + e.totalRevenue, 0))}</td>
                                        <td className="py-3 px-4 text-right text-blue-400">{formatCurrency(sellerEarnings.reduce((s, e) => s + e.taxAmount, 0))}</td>
                                        <td className="py-3 px-4 text-right text-purple-400">{formatCurrency(sellerEarnings.reduce((s, e) => s + e.serviceChargeAmount, 0))}</td>
                                        <td className="py-3 px-4 text-right text-green-400">{formatCurrency(sellerEarnings.reduce((s, e) => s + e.taxAmount + e.serviceChargeAmount, 0))}</td>
                                        <td className="py-3 px-4 text-center">{sellerEarnings.reduce((s, e) => s + e.orderCount, 0)}</td>
                                    </tr>
                                </tfoot>
                            )}
                        </table>
                    </div>
                </div>
            )}

            {/* Total Overview Table */}
            {viewMode === 'total' && monthlyTrend.length > 0 && (
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl border border-gray-700 overflow-hidden">
                    <div className="p-4 border-b border-gray-700">
                        <h3 className="text-white font-semibold text-lg">Monthly Breakdown - {selectedYear}</h3>
                    </div>
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm">
                            <thead>
                                <tr className="text-gray-400 bg-gray-900/50">
                                    <th className="text-left py-3 px-4 font-semibold">Month</th>
                                    <th className="text-right py-3 px-4 font-semibold">Tax Collected</th>
                                    <th className="text-right py-3 px-4 font-semibold">Service Charge</th>
                                    <th className="text-right py-3 px-4 font-semibold">Total Platform Fee</th>
                                    <th className="text-right py-3 px-4 font-semibold">Revenue</th>
                                    <th className="text-center py-3 px-4 font-semibold">Orders</th>
                                </tr>
                            </thead>
                            <tbody>
                                {monthlyTrend.map((month, index) => (
                                    <tr
                                        key={index}
                                        className={`border-b border-gray-800 text-gray-300 hover:bg-gray-800/50 transition-colors ${index === selectedMonth ? 'bg-blue-900/10 border-l-2 border-l-blue-500' : ''}`}
                                    >
                                        <td className={`py-3 px-4 font-medium ${index === selectedMonth ? 'text-white' : ''}`}>
                                            {months[index]}
                                        </td>
                                        <td className="py-3 px-4 text-right text-blue-400">{formatCurrency(month.taxAmount)}</td>
                                        <td className="py-3 px-4 text-right text-purple-400">{formatCurrency(month.serviceChargeAmount)}</td>
                                        <td className="py-3 px-4 text-right text-green-400 font-semibold">{formatCurrency(month.taxAmount + month.serviceChargeAmount)}</td>
                                        <td className="py-3 px-4 text-right">{formatCurrency(month.totalRevenue)}</td>
                                        <td className="py-3 px-4 text-center">{month.orderCount}</td>
                                    </tr>
                                ))}
                            </tbody>
                            <tfoot>
                                <tr className="bg-gray-900/70 text-white font-semibold">
                                    <td className="py-3 px-4">Year Total</td>
                                    <td className="py-3 px-4 text-right text-blue-400">{formatCurrency(monthlyTrend.reduce((s, m) => s + m.taxAmount, 0))}</td>
                                    <td className="py-3 px-4 text-right text-purple-400">{formatCurrency(monthlyTrend.reduce((s, m) => s + m.serviceChargeAmount, 0))}</td>
                                    <td className="py-3 px-4 text-right text-green-400">{formatCurrency(monthlyTrend.reduce((s, m) => s + m.taxAmount + m.serviceChargeAmount, 0))}</td>
                                    <td className="py-3 px-4 text-right">{formatCurrency(monthlyTrend.reduce((s, m) => s + m.totalRevenue, 0))}</td>
                                    <td className="py-3 px-4 text-center">{monthlyTrend.reduce((s, m) => s + m.orderCount, 0)}</td>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                </div>
            )}
        </div>
    );
}
