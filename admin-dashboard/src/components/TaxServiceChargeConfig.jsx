import React, { useState, useEffect } from 'react';
import { Settings, Save, RefreshCw, DollarSign, Percent, Truck, AlertCircle, CheckCircle } from 'lucide-react';
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { db, auth } from '../services/firebase';

export default function TaxServiceChargeConfig() {
    const [config, setConfig] = useState({
        taxPercentage: 18.0,
        serviceChargePercentage: 2.0,
        codProcessingFee: 50.0,
    });
    const [originalConfig, setOriginalConfig] = useState(null);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [message, setMessage] = useState(null);
    const [history, setHistory] = useState([]);

    useEffect(() => {
        fetchConfig();
    }, []);

    const fetchConfig = async () => {
        try {
            setLoading(true);
            const docRef = doc(db, 'platform_config', 'tax_service_charge');
            const docSnap = await getDoc(docRef);

            if (docSnap.exists()) {
                const data = docSnap.data();
                const cfg = {
                    taxPercentage: data.taxPercentage ?? 18.0,
                    serviceChargePercentage: data.serviceChargePercentage ?? 2.0,
                    codProcessingFee: data.codProcessingFee ?? 50.0,
                };
                setConfig(cfg);
                setOriginalConfig(cfg);
            }

            // Fetch config history
            const historyRef = doc(db, 'platform_config', 'tax_service_charge_history');
            const historySnap = await getDoc(historyRef);
            if (historySnap.exists()) {
                setHistory(historySnap.data().changes || []);
            }
        } catch (error) {
            console.error('Error fetching config:', error);
            showMessage('Failed to load configuration', 'error');
        } finally {
            setLoading(false);
        }
    };

    const saveConfig = async () => {
        if (config.taxPercentage < 0 || config.taxPercentage > 100) {
            showMessage('Tax percentage must be between 0 and 100', 'error');
            return;
        }
        if (config.serviceChargePercentage < 0 || config.serviceChargePercentage > 100) {
            showMessage('Service charge must be between 0 and 100', 'error');
            return;
        }
        if (config.codProcessingFee < 0) {
            showMessage('COD processing fee cannot be negative', 'error');
            return;
        }

        try {
            setSaving(true);
            const docRef = doc(db, 'platform_config', 'tax_service_charge');

            await setDoc(docRef, {
                taxPercentage: parseFloat(config.taxPercentage),
                serviceChargePercentage: parseFloat(config.serviceChargePercentage),
                codProcessingFee: parseFloat(config.codProcessingFee),
                updatedAt: serverTimestamp(),
                updatedBy: auth.currentUser?.email || 'admin',
            });

            // Save to history
            const historyRef = doc(db, 'platform_config', 'tax_service_charge_history');
            const historySnap = await getDoc(historyRef);
            const existingHistory = historySnap.exists() ? (historySnap.data().changes || []) : [];

            const newEntry = {
                taxPercentage: parseFloat(config.taxPercentage),
                serviceChargePercentage: parseFloat(config.serviceChargePercentage),
                codProcessingFee: parseFloat(config.codProcessingFee),
                changedAt: new Date().toISOString(),
                changedBy: auth.currentUser?.email || 'admin',
            };

            await setDoc(historyRef, {
                changes: [newEntry, ...existingHistory].slice(0, 50), // Keep last 50 changes
            });

            setOriginalConfig({ ...config });
            setHistory([newEntry, ...existingHistory].slice(0, 50));
            showMessage('Configuration saved successfully!', 'success');
        } catch (error) {
            console.error('Error saving config:', error);
            showMessage('Failed to save configuration', 'error');
        } finally {
            setSaving(false);
        }
    };

    const showMessage = (text, type) => {
        setMessage({ text, type });
        setTimeout(() => setMessage(null), 4000);
    };

    const hasChanges = originalConfig &&
        (config.taxPercentage !== originalConfig.taxPercentage ||
            config.serviceChargePercentage !== originalConfig.serviceChargePercentage ||
            config.codProcessingFee !== originalConfig.codProcessingFee);

    if (loading) {
        return (
            <div className="flex items-center justify-center h-96">
                <div className="text-center">
                    <div className="w-12 h-12 border-4 border-gray-700 border-t-blue-400 rounded-full animate-spin mx-auto mb-4"></div>
                    <p className="text-gray-400">Loading configuration...</p>
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-3xl font-bold text-white mb-2">Tax & Service Charge Configuration</h2>
                    <p className="text-gray-400">Configure platform-wide tax rates and service charges. Changes apply to all new orders.</p>
                </div>
                <button
                    onClick={fetchConfig}
                    className="p-3 bg-gray-800 rounded-lg hover:bg-gray-700 transition-colors"
                    title="Refresh"
                >
                    <RefreshCw className="w-5 h-5 text-gray-400" />
                </button>
            </div>

            {/* Message */}
            {message && (
                <div className={`p-4 rounded-xl flex items-center gap-3 ${message.type === 'success'
                    ? 'bg-green-900/30 border border-green-700 text-green-400'
                    : 'bg-red-900/30 border border-red-700 text-red-400'
                    }`}>
                    {message.type === 'success'
                        ? <CheckCircle className="w-5 h-5" />
                        : <AlertCircle className="w-5 h-5" />
                    }
                    <span>{message.text}</span>
                </div>
            )}

            {/* Configuration Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {/* Tax Percentage */}
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700">
                    <div className="flex items-center gap-3 mb-4">
                        <div className="p-3 bg-blue-900/30 rounded-lg">
                            <Percent className="w-6 h-6 text-blue-400" />
                        </div>
                        <div>
                            <h3 className="text-white font-semibold">Tax (GST) Percentage</h3>
                            <p className="text-gray-500 text-sm">Applied on order subtotal</p>
                        </div>
                    </div>
                    <div className="relative">
                        <input
                            type="number"
                            step="0.1"
                            min="0"
                            max="100"
                            value={config.taxPercentage}
                            onChange={(e) => setConfig({ ...config, taxPercentage: parseFloat(e.target.value) || 0 })}
                            className="w-full bg-gray-700/50 border border-gray-600 rounded-lg px-4 py-3 text-white text-2xl font-bold focus:outline-none focus:border-blue-500 transition-colors"
                        />
                        <span className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 text-xl font-bold">%</span>
                    </div>
                    <p className="text-gray-500 text-xs mt-2">Example: On Rs.10,000 order = Rs.{(10000 * config.taxPercentage / 100).toFixed(2)} tax</p>
                </div>

                {/* Service Charge */}
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700">
                    <div className="flex items-center gap-3 mb-4">
                        <div className="p-3 bg-purple-900/30 rounded-lg">
                            <DollarSign className="w-6 h-6 text-purple-400" />
                        </div>
                        <div>
                            <h3 className="text-white font-semibold">Service Charge</h3>
                            <p className="text-gray-500 text-sm">Platform service fee percentage</p>
                        </div>
                    </div>
                    <div className="relative">
                        <input
                            type="number"
                            step="0.1"
                            min="0"
                            max="100"
                            value={config.serviceChargePercentage}
                            onChange={(e) => setConfig({ ...config, serviceChargePercentage: parseFloat(e.target.value) || 0 })}
                            className="w-full bg-gray-700/50 border border-gray-600 rounded-lg px-4 py-3 text-white text-2xl font-bold focus:outline-none focus:border-purple-500 transition-colors"
                        />
                        <span className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 text-xl font-bold">%</span>
                    </div>
                    <p className="text-gray-500 text-xs mt-2">Example: On Rs.10,000 order = Rs.{(10000 * config.serviceChargePercentage / 100).toFixed(2)} charge</p>
                </div>

                {/* COD Processing Fee */}
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700">
                    <div className="flex items-center gap-3 mb-4">
                        <div className="p-3 bg-yellow-900/30 rounded-lg">
                            <Truck className="w-6 h-6 text-yellow-400" />
                        </div>
                        <div>
                            <h3 className="text-white font-semibold">COD Processing Fee</h3>
                            <p className="text-gray-500 text-sm">Fixed fee for Cash on Delivery</p>
                        </div>
                    </div>
                    <div className="relative">
                        <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 text-xl font-bold">Rs.</span>
                        <input
                            type="number"
                            step="1"
                            min="0"
                            value={config.codProcessingFee}
                            onChange={(e) => setConfig({ ...config, codProcessingFee: parseFloat(e.target.value) || 0 })}
                            className="w-full bg-gray-700/50 border border-gray-600 rounded-lg pl-14 pr-4 py-3 text-white text-2xl font-bold focus:outline-none focus:border-yellow-500 transition-colors"
                        />
                    </div>
                    <p className="text-gray-500 text-xs mt-2">Additional fee charged for COD orders</p>
                </div>
            </div>

            {/* Save Button */}
            <div className="flex items-center gap-4">
                <button
                    onClick={saveConfig}
                    disabled={saving || !hasChanges}
                    className={`flex items-center gap-2 px-8 py-3 rounded-xl font-semibold transition-all ${hasChanges
                        ? 'bg-gradient-to-r from-blue-600 to-blue-700 text-white hover:from-blue-500 hover:to-blue-600 shadow-lg shadow-blue-900/30'
                        : 'bg-gray-800 text-gray-500 cursor-not-allowed'
                        }`}
                >
                    {saving ? (
                        <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    ) : (
                        <Save className="w-5 h-5" />
                    )}
                    {saving ? 'Saving...' : 'Save Configuration'}
                </button>
                {hasChanges && (
                    <span className="text-yellow-500 text-sm flex items-center gap-1">
                        <AlertCircle className="w-4 h-4" />
                        Unsaved changes
                    </span>
                )}
            </div>

            {/* Preview Card */}
            <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700">
                <h3 className="text-white font-semibold text-lg mb-4 flex items-center gap-2">
                    <Settings className="w-5 h-5 text-gray-400" />
                    Order Calculation Preview (Rs.10,000 order)
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-3">
                        <div className="flex justify-between text-gray-300">
                            <span>Subtotal</span>
                            <span>Rs.10,000.00</span>
                        </div>
                        <div className="flex justify-between text-blue-400">
                            <span>Tax ({config.taxPercentage}%)</span>
                            <span>Rs.{(10000 * config.taxPercentage / 100).toFixed(2)}</span>
                        </div>
                        <div className="flex justify-between text-purple-400">
                            <span>Service Charge ({config.serviceChargePercentage}%)</span>
                            <span>Rs.{(10000 * config.serviceChargePercentage / 100).toFixed(2)}</span>
                        </div>
                        <div className="border-t border-gray-600 pt-2 flex justify-between text-white font-bold text-lg">
                            <span>Total</span>
                            <span>Rs.{(10000 + 10000 * config.taxPercentage / 100 + 10000 * config.serviceChargePercentage / 100).toFixed(2)}</span>
                        </div>
                    </div>
                    <div className="space-y-3">
                        <h4 className="text-gray-400 text-sm font-semibold uppercase tracking-wider">Platform Earnings per Order</h4>
                        <div className="flex justify-between text-blue-400">
                            <span>Tax Collected</span>
                            <span className="font-bold">Rs.{(10000 * config.taxPercentage / 100).toFixed(2)}</span>
                        </div>
                        <div className="flex justify-between text-purple-400">
                            <span>Service Charge Collected</span>
                            <span className="font-bold">Rs.{(10000 * config.serviceChargePercentage / 100).toFixed(2)}</span>
                        </div>
                        <div className="border-t border-gray-600 pt-2 flex justify-between text-green-400 font-bold">
                            <span>Total Platform Revenue</span>
                            <span>Rs.{(10000 * (config.taxPercentage + config.serviceChargePercentage) / 100).toFixed(2)}</span>
                        </div>
                    </div>
                </div>
            </div>

            {/* Change History */}
            {history.length > 0 && (
                <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700">
                    <h3 className="text-white font-semibold text-lg mb-4">Configuration Change History</h3>
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm">
                            <thead>
                                <tr className="text-gray-400 border-b border-gray-700">
                                    <th className="text-left py-3 px-4">Date</th>
                                    <th className="text-left py-3 px-4">Tax %</th>
                                    <th className="text-left py-3 px-4">Service Charge %</th>
                                    <th className="text-left py-3 px-4">COD Fee</th>
                                    <th className="text-left py-3 px-4">Changed By</th>
                                </tr>
                            </thead>
                            <tbody>
                                {history.slice(0, 10).map((entry, index) => (
                                    <tr key={index} className="border-b border-gray-800 text-gray-300 hover:bg-gray-800/50">
                                        <td className="py-3 px-4">{new Date(entry.changedAt).toLocaleString()}</td>
                                        <td className="py-3 px-4">{entry.taxPercentage}%</td>
                                        <td className="py-3 px-4">{entry.serviceChargePercentage}%</td>
                                        <td className="py-3 px-4">Rs.{entry.codProcessingFee}</td>
                                        <td className="py-3 px-4">{entry.changedBy}</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>
            )}
        </div>
    );
}
