import React, { useState, useEffect } from 'react';
import { db } from '../services/firebase';
import {
    collection,
    query,
    orderBy,
    onSnapshot,
    doc,
    updateDoc,
    arrayUnion,
    Timestamp,
} from 'firebase/firestore';
import {
    AlertTriangle,
    Clock,
    Eye,
    Settings,
    CheckCircle,
    XCircle,
    Send,
    ChevronDown,
    ChevronUp,
    Filter,
    Search,
    MessageSquare,
    Lightbulb,
    Flag,
    User,
    Calendar,
    Tag,
    Image as ImageIcon,
    FileText,
    RefreshCw,
    X,
} from 'lucide-react';

const STATUS_OPTIONS = [
    { value: 'submitted', label: 'Submitted', color: '#3B82F6', bg: '#EFF6FF', icon: Send },
    { value: 'review', label: 'Under Review', color: '#F59E0B', bg: '#FFFBEB', icon: Eye },
    { value: 'inProgress', label: 'In Progress', color: '#8B5CF6', bg: '#F5F3FF', icon: Settings },
    { value: 'done', label: 'Done', color: '#10B981', bg: '#ECFDF5', icon: CheckCircle },
    { value: 'rejected', label: 'Rejected', color: '#EF4444', bg: '#FEF2F2', icon: XCircle },
];

const PRIORITY_MAP = {
    low: { label: 'Low', color: '#10B981' },
    medium: { label: 'Medium', color: '#3B82F6' },
    high: { label: 'High', color: '#F59E0B' },
    urgent: { label: 'Urgent', color: '#EF4444' },
};

const CATEGORY_MAP = {
    payment: 'Payment Issue',
    delivery: 'Delivery Issue',
    product: 'Product Issue',
    account: 'Account Issue',
    auction: 'Auction Issue',
    technical: 'Technical Issue',
    other: 'Other',
};

export default function ReportManagement() {
    const [reports, setReports] = useState([]);
    const [filteredReports, setFilteredReports] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedReport, setSelectedReport] = useState(null);
    const [statusFilter, setStatusFilter] = useState('all');
    const [roleFilter, setRoleFilter] = useState('all');
    const [searchQuery, setSearchQuery] = useState('');
    const [responseText, setResponseText] = useState('');
    const [solutionText, setSolutionText] = useState('');
    const [sendingResponse, setSendingResponse] = useState(false);
    const [showDetailPanel, setShowDetailPanel] = useState(false);
    const [counts, setCounts] = useState({});

    useEffect(() => {
        const q = query(collection(db, 'reports'), orderBy('createdAt', 'desc'));
        const unsubscribe = onSnapshot(q, (snapshot) => {
            const data = snapshot.docs.map((doc) => ({
                id: doc.id,
                ...doc.data(),
                createdAt: doc.data().createdAt?.toDate?.() || new Date(),
                updatedAt: doc.data().updatedAt?.toDate?.() || new Date(),
            }));
            setReports(data);
            setLoading(false);

            // Compute counts
            const c = { total: data.length, submitted: 0, review: 0, inProgress: 0, done: 0, rejected: 0 };
            data.forEach((r) => { c[r.status] = (c[r.status] || 0) + 1; });
            setCounts(c);
        });
        return () => unsubscribe();
    }, []);

    useEffect(() => {
        let filtered = [...reports];
        if (statusFilter !== 'all') {
            filtered = filtered.filter((r) => r.status === statusFilter);
        }
        if (roleFilter !== 'all') {
            filtered = filtered.filter((r) => r.userRole === roleFilter);
        }
        if (searchQuery.trim()) {
            const q = searchQuery.toLowerCase();
            filtered = filtered.filter(
                (r) =>
                    r.subject?.toLowerCase().includes(q) ||
                    r.description?.toLowerCase().includes(q) ||
                    r.userName?.toLowerCase().includes(q) ||
                    r.userEmail?.toLowerCase().includes(q)
            );
        }
        setFilteredReports(filtered);
    }, [reports, statusFilter, roleFilter, searchQuery]);

    const updateStatus = async (reportId, newStatus) => {
        try {
            await updateDoc(doc(db, 'reports', reportId), {
                status: newStatus,
                updatedAt: Timestamp.now(),
            });
            if (selectedReport?.id === reportId) {
                setSelectedReport((prev) => ({ ...prev, status: newStatus }));
            }
        } catch (error) {
            console.error('Error updating status:', error);
        }
    };

    const sendAdminResponse = async () => {
        if (!responseText.trim() || !selectedReport) return;
        setSendingResponse(true);
        try {
            const response = {
                adminId: 'admin',
                adminName: 'Admin',
                message: responseText.trim(),
                respondedAt: Timestamp.now(),
            };
            await updateDoc(doc(db, 'reports', selectedReport.id), {
                adminResponses: arrayUnion(response),
                updatedAt: Timestamp.now(),
            });
            setResponseText('');
        } catch (error) {
            console.error('Error sending response:', error);
        } finally {
            setSendingResponse(false);
        }
    };

    const sendSolution = async (newStatus) => {
        if (!solutionText.trim() || !selectedReport) return;
        setSendingResponse(true);
        try {
            await updateDoc(doc(db, 'reports', selectedReport.id), {
                adminSolution: solutionText.trim(),
                status: newStatus,
                updatedAt: Timestamp.now(),
            });
            setSolutionText('');
        } catch (error) {
            console.error('Error sending solution:', error);
        } finally {
            setSendingResponse(false);
        }
    };

    const getStatusConfig = (status) =>
        STATUS_OPTIONS.find((s) => s.value === status) || STATUS_OPTIONS[0];

    const formatDate = (date) => {
        if (!date) return '-';
        return new Date(date).toLocaleString('en-US', {
            month: 'short', day: 'numeric', year: 'numeric',
            hour: '2-digit', minute: '2-digit',
        });
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center h-96">
                <RefreshCw className="w-8 h-8 text-primary animate-spin" />
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-gray-100">Report Management</h2>
                    <p className="text-sm text-gray-400 mt-1">
                        Manage user-reported problems and provide solutions
                    </p>
                </div>
            </div>

            {/* Status overview cards */}
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
                {[
                    { label: 'Total', value: counts.total || 0, color: '#6B7280', bg: 'from-gray-800 to-gray-900' },
                    ...STATUS_OPTIONS.map((s) => ({
                        label: s.label,
                        value: counts[s.value] || 0,
                        color: s.color,
                        bg: `from-gray-800 to-gray-900`,
                    })),
                ].map((card, idx) => (
                    <div
                        key={idx}
                        className={`bg-gradient-to-br ${card.bg} rounded-xl p-4 border border-gray-800 cursor-pointer hover:border-gray-600 transition-all`}
                        onClick={() => setStatusFilter(idx === 0 ? 'all' : STATUS_OPTIONS[idx - 1].value)}
                    >
                        <div className="text-2xl font-bold" style={{ color: card.color }}>
                            {card.value}
                        </div>
                        <div className="text-xs text-gray-400 mt-1 font-medium">{card.label}</div>
                    </div>
                ))}
            </div>

            {/* Filters */}
            <div className="flex flex-wrap items-center gap-3 bg-gray-900 rounded-xl p-4 border border-gray-800">
                <div className="flex items-center gap-2">
                    <Filter className="w-4 h-4 text-gray-400" />
                    <span className="text-sm text-gray-400 font-medium">Filters:</span>
                </div>
                <div className="relative flex-1 min-w-[200px]">
                    <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-500" />
                    <input
                        type="text"
                        placeholder="Search reports..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full pl-10 pr-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-sm text-gray-200 placeholder-gray-500 focus:outline-none focus:border-primary"
                    />
                </div>
                <select
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                    className="bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-gray-200 focus:outline-none focus:border-primary"
                >
                    <option value="all">All Status</option>
                    {STATUS_OPTIONS.map((s) => (
                        <option key={s.value} value={s.value}>{s.label}</option>
                    ))}
                </select>
                <select
                    value={roleFilter}
                    onChange={(e) => setRoleFilter(e.target.value)}
                    className="bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-gray-200 focus:outline-none focus:border-primary"
                >
                    <option value="all">All Roles</option>
                    <option value="buyer">Buyer</option>
                    <option value="seller">Seller</option>
                </select>
            </div>

            <div className="flex gap-6">
                {/* Report List */}
                <div className={`${showDetailPanel ? 'w-1/2' : 'w-full'} space-y-3 transition-all`}>
                    {filteredReports.length === 0 ? (
                        <div className="text-center py-16 bg-gray-900 rounded-xl border border-gray-800">
                            <AlertTriangle className="w-12 h-12 text-gray-600 mx-auto mb-3" />
                            <p className="text-gray-400 font-medium">No reports found</p>
                            <p className="text-sm text-gray-500 mt-1">Try adjusting your filters</p>
                        </div>
                    ) : (
                        filteredReports.map((report) => {
                            const statusCfg = getStatusConfig(report.status);
                            const priorityCfg = PRIORITY_MAP[report.priority] || PRIORITY_MAP.medium;
                            const StatusIcon = statusCfg.icon;
                            const isSelected = selectedReport?.id === report.id;

                            return (
                                <div
                                    key={report.id}
                                    onClick={() => {
                                        setSelectedReport(report);
                                        setShowDetailPanel(true);
                                    }}
                                    className={`bg-gray-900 rounded-xl p-5 border cursor-pointer transition-all hover:border-gray-600 ${isSelected ? 'border-primary ring-1 ring-primary/20' : 'border-gray-800'
                                        }`}
                                >
                                    <div className="flex items-start justify-between gap-4">
                                        <div className="flex-1 min-w-0">
                                            <div className="flex items-center gap-2 mb-2">
                                                <span
                                                    className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold"
                                                    style={{
                                                        backgroundColor: statusCfg.bg,
                                                        color: statusCfg.color,
                                                    }}
                                                >
                                                    <StatusIcon className="w-3 h-3" />
                                                    {statusCfg.label}
                                                </span>
                                                <span
                                                    className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium border"
                                                    style={{
                                                        color: priorityCfg.color,
                                                        borderColor: priorityCfg.color + '33',
                                                    }}
                                                >
                                                    <Flag className="w-3 h-3" />
                                                    {priorityCfg.label}
                                                </span>
                                                <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${report.userRole === 'seller'
                                                        ? 'bg-purple-900/40 text-purple-300 border border-purple-700/30'
                                                        : 'bg-blue-900/40 text-blue-300 border border-blue-700/30'
                                                    }`}>
                                                    {report.userRole === 'seller' ? 'Seller' : 'Buyer'}
                                                </span>
                                            </div>
                                            <h3 className="text-sm font-semibold text-gray-200 truncate">
                                                {report.subject}
                                            </h3>
                                            <p className="text-xs text-gray-400 mt-1 line-clamp-2">
                                                {report.description}
                                            </p>
                                            <div className="flex items-center gap-4 mt-3 text-xs text-gray-500">
                                                <span className="flex items-center gap-1">
                                                    <User className="w-3 h-3" />
                                                    {report.userName}
                                                </span>
                                                <span className="flex items-center gap-1">
                                                    <Tag className="w-3 h-3" />
                                                    {CATEGORY_MAP[report.category] || report.category}
                                                </span>
                                                <span className="flex items-center gap-1">
                                                    <Clock className="w-3 h-3" />
                                                    {formatDate(report.createdAt)}
                                                </span>
                                                {report.adminResponses?.length > 0 && (
                                                    <span className="flex items-center gap-1 text-green-400">
                                                        <MessageSquare className="w-3 h-3" />
                                                        {report.adminResponses.length} response(s)
                                                    </span>
                                                )}
                                            </div>
                                        </div>
                                        <div>
                                            <select
                                                value={report.status}
                                                onClick={(e) => e.stopPropagation()}
                                                onChange={(e) => {
                                                    e.stopPropagation();
                                                    updateStatus(report.id, e.target.value);
                                                }}
                                                className="bg-gray-800 border border-gray-700 rounded-lg px-2 py-1.5 text-xs text-gray-200 focus:outline-none focus:border-primary"
                                            >
                                                {STATUS_OPTIONS.map((s) => (
                                                    <option key={s.value} value={s.value}>
                                                        {s.label}
                                                    </option>
                                                ))}
                                            </select>
                                        </div>
                                    </div>
                                </div>
                            );
                        })
                    )}
                </div>

                {/* Detail Panel */}
                {showDetailPanel && selectedReport && (
                    <div className="w-1/2 bg-gray-900 rounded-xl border border-gray-800 overflow-y-auto max-h-[calc(100vh-300px)] sticky top-6">
                        <div className="p-6 space-y-6">
                            {/* Header */}
                            <div className="flex items-start justify-between">
                                <div>
                                    <h3 className="text-lg font-bold text-gray-100">
                                        {selectedReport.subject}
                                    </h3>
                                    <p className="text-xs text-gray-500 mt-1">
                                        Report ID: {selectedReport.id}
                                    </p>
                                </div>
                                <button
                                    onClick={() => {
                                        setShowDetailPanel(false);
                                        setSelectedReport(null);
                                    }}
                                    className="p-1.5 hover:bg-gray-800 rounded-lg transition-colors"
                                >
                                    <X className="w-5 h-5 text-gray-400" />
                                </button>
                            </div>

                            {/* Status + Priority */}
                            <div className="flex items-center gap-3">
                                {(() => {
                                    const cfg = getStatusConfig(selectedReport.status);
                                    const Icon = cfg.icon;
                                    return (
                                        <span
                                            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold"
                                            style={{ backgroundColor: cfg.bg, color: cfg.color }}
                                        >
                                            <Icon className="w-3.5 h-3.5" />
                                            {cfg.label}
                                        </span>
                                    );
                                })()}
                                {(() => {
                                    const p = PRIORITY_MAP[selectedReport.priority] || PRIORITY_MAP.medium;
                                    return (
                                        <span
                                            className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium"
                                            style={{ color: p.color, border: `1px solid ${p.color}33` }}
                                        >
                                            <Flag className="w-3 h-3" /> {p.label} Priority
                                        </span>
                                    );
                                })()}
                            </div>

                            {/* Info grid */}
                            <div className="grid grid-cols-2 gap-3">
                                <InfoItem icon={User} label="User" value={selectedReport.userName} />
                                <InfoItem icon={Tag} label="Role" value={selectedReport.userRole === 'seller' ? 'Seller' : 'Buyer'} />
                                <InfoItem icon={FileText} label="Category" value={CATEGORY_MAP[selectedReport.category] || selectedReport.category} />
                                <InfoItem icon={Calendar} label="Submitted" value={formatDate(selectedReport.createdAt)} />
                                {selectedReport.orderId && (
                                    <InfoItem icon={FileText} label="Order ID" value={selectedReport.orderId} />
                                )}
                                <InfoItem icon={Clock} label="Updated" value={formatDate(selectedReport.updatedAt)} />
                            </div>

                            {/* Description */}
                            <div>
                                <h4 className="text-sm font-semibold text-gray-300 mb-2 flex items-center gap-2">
                                    <FileText className="w-4 h-4 text-primary" /> Description
                                </h4>
                                <div className="bg-gray-800 rounded-lg p-4 text-sm text-gray-300 leading-relaxed">
                                    {selectedReport.description}
                                </div>
                            </div>

                            {/* Images */}
                            {selectedReport.imageUrls?.length > 0 && (
                                <div>
                                    <h4 className="text-sm font-semibold text-gray-300 mb-2 flex items-center gap-2">
                                        <ImageIcon className="w-4 h-4 text-primary" /> Attachments ({selectedReport.imageUrls.length})
                                    </h4>
                                    <div className="flex gap-2 overflow-x-auto pb-2">
                                        {selectedReport.imageUrls.map((url, i) => (
                                            <a key={i} href={url} target="_blank" rel="noopener noreferrer">
                                                <img
                                                    src={url}
                                                    alt={`Attachment ${i + 1}`}
                                                    className="w-24 h-24 object-cover rounded-lg border border-gray-700 hover:border-primary transition-colors"
                                                />
                                            </a>
                                        ))}
                                    </div>
                                </div>
                            )}

                            {/* Change Status */}
                            <div>
                                <h4 className="text-sm font-semibold text-gray-300 mb-2 flex items-center gap-2">
                                    <Settings className="w-4 h-4 text-primary" /> Change Status
                                </h4>
                                <div className="flex flex-wrap gap-2">
                                    {STATUS_OPTIONS.map((s) => {
                                        const Icon = s.icon;
                                        const isActive = selectedReport.status === s.value;
                                        return (
                                            <button
                                                key={s.value}
                                                onClick={() => updateStatus(selectedReport.id, s.value)}
                                                className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-all border ${isActive
                                                        ? 'ring-2 ring-offset-1 ring-offset-gray-900'
                                                        : 'opacity-60 hover:opacity-100'
                                                    }`}
                                                style={{
                                                    backgroundColor: isActive ? s.bg : 'transparent',
                                                    color: s.color,
                                                    borderColor: s.color + '44',
                                                    ...(isActive ? { ringColor: s.color } : {}),
                                                }}
                                            >
                                                <Icon className="w-3.5 h-3.5" />
                                                {s.label}
                                            </button>
                                        );
                                    })}
                                </div>
                            </div>

                            {/* Previous Responses */}
                            {selectedReport.adminResponses?.length > 0 && (
                                <div>
                                    <h4 className="text-sm font-semibold text-gray-300 mb-2 flex items-center gap-2">
                                        <MessageSquare className="w-4 h-4 text-primary" /> Previous Responses
                                    </h4>
                                    <div className="space-y-2">
                                        {selectedReport.adminResponses.map((resp, i) => (
                                            <div
                                                key={i}
                                                className="bg-gray-800 rounded-lg p-3 border border-gray-700"
                                            >
                                                <div className="flex items-center justify-between mb-1">
                                                    <span className="text-xs font-medium text-primary">
                                                        {resp.adminName || 'Admin'}
                                                    </span>
                                                    <span className="text-xs text-gray-500">
                                                        {resp.respondedAt?.toDate
                                                            ? formatDate(resp.respondedAt.toDate())
                                                            : formatDate(resp.respondedAt)}
                                                    </span>
                                                </div>
                                                <p className="text-sm text-gray-300">{resp.message}</p>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}

                            {/* Admin Solution */}
                            {selectedReport.adminSolution && (
                                <div className="bg-green-900/20 border border-green-700/30 rounded-lg p-4">
                                    <h4 className="text-sm font-semibold text-green-400 mb-2 flex items-center gap-2">
                                        <Lightbulb className="w-4 h-4" /> Solution Provided
                                    </h4>
                                    <p className="text-sm text-gray-300">{selectedReport.adminSolution}</p>
                                </div>
                            )}

                            {/* Send Response */}
                            <div>
                                <h4 className="text-sm font-semibold text-gray-300 mb-2 flex items-center gap-2">
                                    <Send className="w-4 h-4 text-primary" /> Send Response
                                </h4>
                                <textarea
                                    value={responseText}
                                    onChange={(e) => setResponseText(e.target.value)}
                                    placeholder="Type your response message..."
                                    rows={3}
                                    className="w-full bg-gray-800 border border-gray-700 rounded-lg p-3 text-sm text-gray-200 placeholder-gray-500 focus:outline-none focus:border-primary resize-none"
                                />
                                <button
                                    onClick={sendAdminResponse}
                                    disabled={!responseText.trim() || sendingResponse}
                                    className="mt-2 inline-flex items-center gap-2 px-4 py-2 bg-primary text-gray-950 rounded-lg text-sm font-semibold hover:bg-yellow-500 transition-colors disabled:opacity-50"
                                >
                                    <Send className="w-4 h-4" />
                                    {sendingResponse ? 'Sending...' : 'Send Response'}
                                </button>
                            </div>

                            {/* Provide Solution */}
                            <div>
                                <h4 className="text-sm font-semibold text-gray-300 mb-2 flex items-center gap-2">
                                    <Lightbulb className="w-4 h-4 text-green-400" /> Provide Solution & Close
                                </h4>
                                <textarea
                                    value={solutionText}
                                    onChange={(e) => setSolutionText(e.target.value)}
                                    placeholder="Provide your final solution..."
                                    rows={3}
                                    className="w-full bg-gray-800 border border-gray-700 rounded-lg p-3 text-sm text-gray-200 placeholder-gray-500 focus:outline-none focus:border-green-500 resize-none"
                                />
                                <div className="flex gap-2 mt-2">
                                    <button
                                        onClick={() => sendSolution('done')}
                                        disabled={!solutionText.trim() || sendingResponse}
                                        className="inline-flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg text-sm font-semibold hover:bg-green-500 transition-colors disabled:opacity-50"
                                    >
                                        <CheckCircle className="w-4 h-4" />
                                        Resolve & Mark Done
                                    </button>
                                    <button
                                        onClick={() => sendSolution('rejected')}
                                        disabled={!solutionText.trim() || sendingResponse}
                                        className="inline-flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-semibold hover:bg-red-500 transition-colors disabled:opacity-50"
                                    >
                                        <XCircle className="w-4 h-4" />
                                        Reject with Reason
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}

function InfoItem({ icon: Icon, label, value }) {
    return (
        <div className="bg-gray-800 rounded-lg p-3 flex items-center gap-3">
            <Icon className="w-4 h-4 text-gray-500 flex-shrink-0" />
            <div className="min-w-0">
                <p className="text-xs text-gray-500">{label}</p>
                <p className="text-sm text-gray-200 font-medium truncate">{value}</p>
            </div>
        </div>
    );
}
