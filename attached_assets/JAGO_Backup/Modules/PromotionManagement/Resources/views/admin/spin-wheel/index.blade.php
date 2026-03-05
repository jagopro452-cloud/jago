@section('title', translate('spin_wheel'))

@extends('adminmodule::layouts.master')

@push('css_or_js')
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
.sw-page {
    --sw-primary: #2563EB;
    --sw-primary-dark: #1E3A8A;
    --sw-primary-deeper: #0F172A;
    --sw-accent: #3B82F6;
    --sw-success: #10B981;
    --sw-success-dark: #059669;
    --sw-danger: #EF4444;
    --sw-warning: #F59E0B;
    --sw-purple: #8B5CF6;
    --sw-pink: #EC4899;
    --sw-cyan: #06B6D4;
    --sw-orange: #F97316;
    --sw-bg: #F8FAFC;
    --sw-card-bg: #FFFFFF;
    --sw-text: #0F172A;
    --sw-text-secondary: #64748B;
    --sw-border: #E2E8F0;
    --sw-radius: 16px;
    --sw-radius-sm: 10px;
    --sw-shadow: 0 1px 3px rgba(0,0,0,0.04), 0 4px 12px rgba(0,0,0,0.06);
    --sw-shadow-lg: 0 4px 6px rgba(0,0,0,0.04), 0 10px 30px rgba(0,0,0,0.08);
    --sw-shadow-xl: 0 8px 16px rgba(0,0,0,0.06), 0 20px 50px rgba(0,0,0,0.12);
    font-family: 'Poppins', sans-serif;
    background: var(--sw-bg);
}
.sw-page * { box-sizing: border-box; }

@keyframes fadeInUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
@keyframes shimmer { 0% { background-position: -200% 0; } 100% { background-position: 200% 0; } }
@keyframes pulse-glow { 0%, 100% { box-shadow: 0 0 20px rgba(37,99,235,0.2); } 50% { box-shadow: 0 0 40px rgba(37,99,235,0.4); } }
@keyframes float { 0%, 100% { transform: translateY(0px); } 50% { transform: translateY(-8px); } }
@keyframes spin-slow { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
@keyframes bounceIn { 0% { transform: scale(0.3); opacity: 0; } 50% { transform: scale(1.05); } 70% { transform: scale(0.95); } 100% { transform: scale(1); opacity: 1; } }
@keyframes confetti-fall { 0% { transform: translateY(-100vh) rotate(0deg); opacity: 1; } 100% { transform: translateY(100vh) rotate(720deg); opacity: 0; } }
@keyframes ripple { 0% { transform: scale(0); opacity: 0.6; } 100% { transform: scale(4); opacity: 0; } }

.sw-hero {
    background: linear-gradient(135deg, var(--sw-primary-deeper) 0%, var(--sw-primary-dark) 35%, var(--sw-primary) 65%, var(--sw-accent) 100%);
    border-radius: 20px;
    padding: 32px 36px;
    color: white;
    position: relative;
    overflow: hidden;
    margin-bottom: 28px;
    animation: fadeInUp 0.6s ease;
}
.sw-hero::before {
    content: '';
    position: absolute;
    top: -80px; right: -80px;
    width: 280px; height: 280px;
    border-radius: 50%;
    background: radial-gradient(circle, rgba(255,255,255,0.08) 0%, transparent 70%);
    animation: float 6s ease-in-out infinite;
}
.sw-hero::after {
    content: '';
    position: absolute;
    bottom: -60px; left: 20%;
    width: 200px; height: 200px;
    border-radius: 50%;
    background: radial-gradient(circle, rgba(255,255,255,0.04) 0%, transparent 70%);
    animation: float 8s ease-in-out infinite reverse;
}
.sw-hero-particles {
    position: absolute;
    top: 0; left: 0; right: 0; bottom: 0;
    overflow: hidden;
    pointer-events: none;
}
.sw-hero-particles span {
    position: absolute;
    width: 4px; height: 4px;
    background: rgba(255,255,255,0.15);
    border-radius: 50%;
    animation: float 4s ease-in-out infinite;
}
.sw-hero-particles span:nth-child(1) { top: 20%; left: 10%; animation-delay: 0s; }
.sw-hero-particles span:nth-child(2) { top: 60%; left: 30%; animation-delay: 1s; width: 3px; height: 3px; }
.sw-hero-particles span:nth-child(3) { top: 30%; left: 70%; animation-delay: 2s; width: 5px; height: 5px; }
.sw-hero-particles span:nth-child(4) { top: 70%; left: 85%; animation-delay: 0.5s; }
.sw-hero-particles span:nth-child(5) { top: 45%; left: 50%; animation-delay: 1.5s; width: 3px; height: 3px; }

.sw-hero-content { position: relative; z-index: 2; }
.sw-hero h2 {
    font-weight: 800;
    font-size: 26px;
    margin-bottom: 6px;
    letter-spacing: -0.3px;
    text-shadow: 0 2px 10px rgba(0,0,0,0.15);
}
.sw-hero p { opacity: 0.85; font-size: 14px; margin: 0; font-weight: 400; }

.sw-toggle-container {
    display: flex;
    align-items: center;
    gap: 14px;
    background: rgba(255,255,255,0.1);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255,255,255,0.15);
    border-radius: 14px;
    padding: 12px 20px;
}
.sw-toggle-switch {
    position: relative;
    width: 56px;
    height: 30px;
    cursor: pointer;
}
.sw-toggle-switch input { display: none; }
.sw-toggle-slider {
    position: absolute;
    top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(255,255,255,0.2);
    border-radius: 30px;
    transition: all 0.4s cubic-bezier(0.68, -0.55, 0.265, 1.55);
    border: 2px solid rgba(255,255,255,0.3);
}
.sw-toggle-slider::before {
    content: '';
    position: absolute;
    width: 22px; height: 22px;
    border-radius: 50%;
    background: white;
    top: 2px; left: 2px;
    transition: all 0.4s cubic-bezier(0.68, -0.55, 0.265, 1.55);
    box-shadow: 0 2px 6px rgba(0,0,0,0.2);
}
.sw-toggle-switch input:checked + .sw-toggle-slider {
    background: var(--sw-success);
    border-color: var(--sw-success);
}
.sw-toggle-switch input:checked + .sw-toggle-slider::before {
    transform: translateX(26px);
}
.sw-status-pill {
    padding: 6px 16px;
    border-radius: 30px;
    font-weight: 700;
    font-size: 12px;
    letter-spacing: 0.8px;
    text-transform: uppercase;
}
.sw-status-active {
    background: linear-gradient(135deg, var(--sw-success), var(--sw-success-dark));
    color: white;
    box-shadow: 0 2px 8px rgba(16,185,129,0.4);
}
.sw-status-inactive {
    background: rgba(255,255,255,0.15);
    color: rgba(255,255,255,0.8);
    border: 1px solid rgba(255,255,255,0.2);
}

.sw-hero-actions {
    display: flex;
    gap: 10px;
    align-items: center;
    flex-wrap: wrap;
}
.sw-hero-btn {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 10px 20px;
    border-radius: 10px;
    font-weight: 600;
    font-size: 13px;
    text-decoration: none;
    transition: all 0.3s;
    border: 1.5px solid rgba(255,255,255,0.25);
    background: rgba(255,255,255,0.1);
    backdrop-filter: blur(8px);
    color: white;
}
.sw-hero-btn:hover {
    background: rgba(255,255,255,0.2);
    border-color: rgba(255,255,255,0.4);
    transform: translateY(-2px);
    color: white;
}

.sw-stats-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 16px;
    margin-bottom: 28px;
    animation: fadeInUp 0.6s ease 0.1s both;
}
@media (max-width: 992px) { .sw-stats-grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 576px) { .sw-stats-grid { grid-template-columns: 1fr; } }
.sw-stat-card {
    background: var(--sw-card-bg);
    border-radius: var(--sw-radius);
    padding: 24px;
    box-shadow: var(--sw-shadow);
    border: 1px solid var(--sw-border);
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
    overflow: hidden;
}
.sw-stat-card::before {
    content: '';
    position: absolute;
    top: 0; left: 0; right: 0;
    height: 3px;
    border-radius: var(--sw-radius) var(--sw-radius) 0 0;
}
.sw-stat-card:hover { transform: translateY(-4px); box-shadow: var(--sw-shadow-lg); }
.sw-stat-card:nth-child(1)::before { background: linear-gradient(90deg, var(--sw-primary), var(--sw-accent)); }
.sw-stat-card:nth-child(2)::before { background: linear-gradient(90deg, var(--sw-success), #34D399); }
.sw-stat-card:nth-child(3)::before { background: linear-gradient(90deg, var(--sw-warning), var(--sw-orange)); }
.sw-stat-card:nth-child(4)::before { background: linear-gradient(90deg, var(--sw-pink), var(--sw-purple)); }
.sw-stat-icon {
    width: 52px; height: 52px;
    border-radius: 14px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 24px;
    flex-shrink: 0;
}
.sw-stat-value {
    font-size: 28px;
    font-weight: 800;
    color: var(--sw-text);
    line-height: 1.1;
    letter-spacing: -0.5px;
}
.sw-stat-label {
    font-size: 11px;
    color: var(--sw-text-secondary);
    text-transform: uppercase;
    letter-spacing: 1px;
    font-weight: 600;
    margin-top: 4px;
}

.sw-card {
    background: var(--sw-card-bg);
    border-radius: var(--sw-radius);
    box-shadow: var(--sw-shadow);
    border: 1px solid var(--sw-border);
    overflow: hidden;
    transition: box-shadow 0.3s;
    animation: fadeInUp 0.6s ease 0.2s both;
}
.sw-card:hover { box-shadow: var(--sw-shadow-lg); }
.sw-card-header {
    background: linear-gradient(135deg, var(--sw-primary-deeper), var(--sw-primary-dark), var(--sw-primary));
    color: white;
    padding: 18px 24px;
    font-weight: 600;
    font-size: 15px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    letter-spacing: 0.2px;
}
.sw-card-header-icon {
    width: 36px; height: 36px;
    border-radius: 10px;
    background: rgba(255,255,255,0.15);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 16px;
    flex-shrink: 0;
}
.sw-card-body { padding: 24px; }

.sw-wheel-stage {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 30px 20px 20px;
    position: relative;
}
.sw-wheel-glow {
    position: absolute;
    width: 340px; height: 340px;
    border-radius: 50%;
    background: radial-gradient(circle, rgba(37,99,235,0.1) 0%, transparent 70%);
    animation: pulse-glow 3s ease-in-out infinite;
    pointer-events: none;
}
.sw-wheel-wrapper {
    position: relative;
    width: 320px; height: 320px;
}
.sw-wheel-outer-ring {
    position: absolute;
    top: -12px; left: -12px;
    width: 344px; height: 344px;
    border-radius: 50%;
    background: conic-gradient(from 0deg, #1E3A8A, #2563EB, #3B82F6, #60A5FA, #3B82F6, #2563EB, #1E3A8A);
    padding: 4px;
    animation: spin-slow 20s linear infinite;
}
.sw-wheel-outer-ring-inner {
    width: 100%; height: 100%;
    border-radius: 50%;
    background: var(--sw-card-bg);
    padding: 4px;
}
.sw-wheel-canvas-wrap {
    position: absolute;
    top: 0; left: 0;
    width: 320px; height: 320px;
    border-radius: 50%;
    overflow: hidden;
    box-shadow: 0 0 0 5px var(--sw-primary-dark), 0 0 0 8px var(--sw-primary), 0 0 0 10px rgba(37,99,235,0.3), 0 8px 30px rgba(0,0,0,0.15);
}
.sw-wheel-canvas {
    width: 320px; height: 320px;
    transition: transform 5s cubic-bezier(0.12, 0.8, 0.14, 1);
}
.sw-wheel-pointer {
    position: absolute;
    top: -18px;
    left: 50%;
    transform: translateX(-50%);
    z-index: 20;
    filter: drop-shadow(0 3px 6px rgba(0,0,0,0.3));
}
.sw-wheel-pointer svg { width: 40px; height: 48px; }
.sw-wheel-center-btn {
    position: absolute;
    top: 50%; left: 50%;
    transform: translate(-50%, -50%);
    width: 72px; height: 72px;
    border-radius: 50%;
    background: linear-gradient(135deg, var(--sw-primary), var(--sw-primary-dark));
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-weight: 800;
    font-size: 13px;
    cursor: pointer;
    box-shadow: 0 0 0 4px rgba(255,255,255,0.8), 0 0 0 7px var(--sw-primary-dark), 0 8px 20px rgba(0,0,0,0.3);
    z-index: 15;
    transition: all 0.3s;
    letter-spacing: 1.5px;
    text-transform: uppercase;
    border: none;
    user-select: none;
}
.sw-wheel-center-btn:hover { transform: translate(-50%, -50%) scale(1.08); box-shadow: 0 0 0 4px rgba(255,255,255,0.9), 0 0 0 7px var(--sw-primary-dark), 0 12px 30px rgba(0,0,0,0.4); }
.sw-wheel-center-btn:active { transform: translate(-50%, -50%) scale(0.95); }
.sw-wheel-title-display {
    text-align: center;
    margin-bottom: 20px;
}
.sw-wheel-title-display h4 {
    font-weight: 700;
    font-size: 20px;
    color: var(--sw-text);
    margin-bottom: 2px;
}
.sw-wheel-title-display p {
    font-size: 13px;
    color: var(--sw-text-secondary);
    margin: 0;
}
.sw-wheel-hint {
    display: flex;
    align-items: center;
    gap: 6px;
    margin-top: 16px;
    padding: 8px 16px;
    background: #F1F5F9;
    border-radius: 30px;
    font-size: 12px;
    color: var(--sw-text-secondary);
    font-weight: 500;
}

.sw-seg-list { max-height: 520px; overflow-y: auto; padding: 4px; }
.sw-seg-list::-webkit-scrollbar { width: 5px; }
.sw-seg-list::-webkit-scrollbar-thumb { background: #CBD5E1; border-radius: 10px; }
.sw-seg-item {
    display: flex;
    align-items: center;
    gap: 14px;
    padding: 14px 16px;
    border-radius: 12px;
    margin-bottom: 8px;
    background: #FAFBFC;
    border: 1.5px solid #EEF2F6;
    transition: all 0.25s;
    position: relative;
}
.sw-seg-item:hover {
    background: #EFF6FF;
    border-color: #BFDBFE;
    transform: translateX(4px);
    box-shadow: 0 2px 8px rgba(37,99,235,0.08);
}
.sw-seg-item.disabled {
    opacity: 0.5;
    background: #F8F9FA;
}
.sw-seg-color {
    width: 36px; height: 36px;
    border-radius: 10px;
    flex-shrink: 0;
    box-shadow: 0 2px 6px rgba(0,0,0,0.12);
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 14px;
    font-weight: 800;
    color: white;
    text-shadow: 0 1px 2px rgba(0,0,0,0.3);
}
.sw-seg-details { flex: 1; min-width: 0; }
.sw-seg-name {
    font-weight: 700;
    font-size: 15px;
    color: var(--sw-text);
    display: flex;
    align-items: center;
    gap: 6px;
}
.sw-seg-name .amount {
    color: var(--sw-text-secondary);
    font-weight: 500;
    font-size: 13px;
}
.sw-seg-meta {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-top: 4px;
    font-size: 12px;
    color: var(--sw-text-secondary);
}
.sw-seg-probability {
    display: flex;
    align-items: center;
    gap: 6px;
}
.sw-seg-prob-bar {
    width: 70px; height: 5px;
    background: #E2E8F0;
    border-radius: 10px;
    overflow: hidden;
}
.sw-seg-prob-fill {
    height: 100%;
    border-radius: 10px;
    transition: width 0.4s ease;
}
.sw-seg-actions {
    display: flex;
    gap: 6px;
    flex-shrink: 0;
}
.sw-seg-btn {
    width: 34px; height: 34px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 14px;
    border: 1.5px solid;
    background: white;
    cursor: pointer;
    transition: all 0.2s;
}
.sw-seg-btn-edit { border-color: #BFDBFE; color: var(--sw-primary); }
.sw-seg-btn-edit:hover { background: var(--sw-primary); color: white; border-color: var(--sw-primary); }
.sw-seg-btn-toggle { border-color: #FDE68A; color: var(--sw-warning); }
.sw-seg-btn-toggle:hover { background: var(--sw-warning); color: white; border-color: var(--sw-warning); }
.sw-seg-btn-toggle.is-off { border-color: #BBF7D0; color: var(--sw-success); }
.sw-seg-btn-toggle.is-off:hover { background: var(--sw-success); color: white; }
.sw-seg-btn-del { border-color: #FECACA; color: var(--sw-danger); }
.sw-seg-btn-del:hover { background: var(--sw-danger); color: white; border-color: var(--sw-danger); }

.sw-config-section { margin-bottom: 24px; }
.sw-config-section-title {
    display: flex;
    align-items: center;
    gap: 8px;
    font-weight: 700;
    font-size: 14px;
    color: var(--sw-text);
    margin-bottom: 16px;
    padding-bottom: 8px;
    border-bottom: 2px solid #EEF2F6;
}
.sw-config-section-title i { color: var(--sw-primary); }
.sw-form-group { margin-bottom: 16px; }
.sw-form-label {
    display: block;
    font-weight: 600;
    font-size: 12px;
    color: var(--sw-text-secondary);
    margin-bottom: 6px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}
.sw-form-input {
    width: 100%;
    border: 1.5px solid var(--sw-border);
    border-radius: var(--sw-radius-sm);
    padding: 10px 14px;
    font-size: 14px;
    font-family: 'Poppins', sans-serif;
    transition: all 0.25s;
    background: #FAFBFC;
    color: var(--sw-text);
}
.sw-form-input:focus {
    border-color: var(--sw-primary);
    box-shadow: 0 0 0 3px rgba(37,99,235,0.08);
    outline: none;
    background: white;
}
.sw-form-input::placeholder { color: #94A3B8; }
.sw-form-hint {
    font-size: 11px;
    color: var(--sw-text-secondary);
    margin-top: 4px;
    display: flex;
    align-items: center;
    gap: 4px;
}
.sw-checkbox-wrap {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 14px 16px;
    background: #F8FAFC;
    border: 1.5px solid var(--sw-border);
    border-radius: var(--sw-radius-sm);
    cursor: pointer;
    transition: all 0.2s;
}
.sw-checkbox-wrap:hover { border-color: var(--sw-primary); background: #EFF6FF; }
.sw-checkbox-wrap input[type="checkbox"] {
    width: 20px; height: 20px;
    accent-color: var(--sw-primary);
    cursor: pointer;
}
.sw-checkbox-info { flex: 1; }
.sw-checkbox-label { font-weight: 600; font-size: 14px; color: var(--sw-text); }
.sw-checkbox-desc { font-size: 12px; color: var(--sw-text-secondary); margin-top: 2px; }

.sw-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    padding: 12px 28px;
    border-radius: var(--sw-radius-sm);
    font-weight: 700;
    font-size: 14px;
    cursor: pointer;
    transition: all 0.3s;
    border: none;
    font-family: 'Poppins', sans-serif;
    letter-spacing: 0.3px;
    position: relative;
    overflow: hidden;
}
.sw-btn::after {
    content: '';
    position: absolute;
    top: 50%; left: 50%;
    width: 0; height: 0;
    border-radius: 50%;
    background: rgba(255,255,255,0.3);
    transition: width 0.4s, height 0.4s, top 0.4s, left 0.4s;
}
.sw-btn:active::after { width: 200px; height: 200px; top: calc(50% - 100px); left: calc(50% - 100px); }
.sw-btn-primary {
    background: linear-gradient(135deg, var(--sw-primary), var(--sw-primary-dark));
    color: white;
    box-shadow: 0 4px 12px rgba(37,99,235,0.25);
}
.sw-btn-primary:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(37,99,235,0.35); color: white; }
.sw-btn-success {
    background: linear-gradient(135deg, var(--sw-success), var(--sw-success-dark));
    color: white;
    box-shadow: 0 4px 12px rgba(16,185,129,0.25);
}
.sw-btn-success:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(16,185,129,0.35); color: white; }

.sw-add-form {
    background: linear-gradient(135deg, #F0F9FF, #EFF6FF, #F8FAFC);
    border-radius: 14px;
    padding: 20px;
    border: 1.5px dashed #BFDBFE;
    transition: all 0.2s;
}
.sw-add-form:hover { border-color: var(--sw-primary); }
.sw-color-picker-wrap {
    position: relative;
    display: flex;
    align-items: center;
    gap: 8px;
}
.sw-color-preview {
    width: 40px; height: 40px;
    border-radius: var(--sw-radius-sm);
    border: 2px solid var(--sw-border);
    cursor: pointer;
    position: relative;
    overflow: hidden;
}
.sw-color-preview input[type="color"] {
    position: absolute;
    top: -8px; left: -8px;
    width: 60px; height: 60px;
    cursor: pointer;
    border: none;
    opacity: 0;
}

.sw-table-wrap { overflow-x: auto; }
.sw-table { width: 100%; border-collapse: collapse; font-size: 14px; }
.sw-table thead th {
    background: linear-gradient(135deg, #F1F5F9, #E2E8F0);
    font-weight: 700;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 1px;
    color: var(--sw-text-secondary);
    padding: 14px 16px;
    border: none;
    white-space: nowrap;
    position: sticky;
    top: 0;
    z-index: 5;
}
.sw-table tbody td {
    padding: 14px 16px;
    vertical-align: middle;
    border-bottom: 1px solid #F1F5F9;
}
.sw-table tbody tr { transition: background 0.15s; }
.sw-table tbody tr:hover { background: #F8FAFC; }
.sw-badge {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 5px 12px;
    border-radius: 8px;
    font-weight: 600;
    font-size: 12px;
}
.sw-badge-blue { background: #EFF6FF; color: var(--sw-primary); }
.sw-badge-green { background: #ECFDF5; color: var(--sw-success); }
.sw-badge-amber { background: #FFFBEB; color: var(--sw-warning); }
.sw-badge-pink { background: #FDF2F8; color: var(--sw-pink); }

.sw-modal-overlay {
    display: none;
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(15,23,42,0.6);
    backdrop-filter: blur(6px);
    z-index: 9999;
    justify-content: center;
    align-items: center;
    padding: 20px;
}
.sw-modal-overlay.active { display: flex; }
.sw-modal {
    background: white;
    border-radius: 20px;
    width: 100%;
    max-width: 440px;
    overflow: hidden;
    box-shadow: var(--sw-shadow-xl);
    animation: bounceIn 0.5s ease;
}
.sw-modal-header {
    background: linear-gradient(135deg, var(--sw-primary-deeper), var(--sw-primary));
    color: white;
    padding: 20px 24px;
    display: flex;
    align-items: center;
    justify-content: space-between;
}
.sw-modal-header h5 { font-weight: 700; font-size: 17px; margin: 0; display: flex; align-items: center; gap: 8px; }
.sw-modal-close {
    width: 32px; height: 32px;
    border-radius: 8px;
    background: rgba(255,255,255,0.15);
    border: none;
    color: white;
    font-size: 18px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
}
.sw-modal-close:hover { background: rgba(255,255,255,0.3); }
.sw-modal-body { padding: 24px; }

.sw-result-overlay {
    display: none;
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(15,23,42,0.7);
    backdrop-filter: blur(8px);
    z-index: 99999;
    justify-content: center;
    align-items: center;
}
.sw-result-overlay.active { display: flex; }
.sw-result-card {
    background: white;
    border-radius: 24px;
    padding: 48px 40px;
    text-align: center;
    max-width: 400px;
    width: 92%;
    animation: bounceIn 0.6s ease;
    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
    position: relative;
    overflow: hidden;
}
.sw-result-card::before {
    content: '';
    position: absolute;
    top: 0; left: 0; right: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--sw-primary), var(--sw-accent), var(--sw-success));
}
.sw-result-emoji { font-size: 56px; animation: float 2s ease-in-out infinite; }
.sw-result-title { font-size: 22px; font-weight: 800; color: var(--sw-text); margin-top: 8px; }
.sw-result-value {
    font-size: 72px;
    font-weight: 900;
    background: linear-gradient(135deg, var(--sw-primary), var(--sw-accent));
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    line-height: 1;
    margin: 12px 0;
    letter-spacing: -2px;
}
.sw-result-desc { color: var(--sw-text-secondary); font-size: 14px; margin-bottom: 24px; }

.sw-empty-state {
    text-align: center;
    padding: 50px 24px;
    color: var(--sw-text-secondary);
}
.sw-empty-state i { font-size: 48px; margin-bottom: 12px; opacity: 0.5; }
.sw-empty-state p { font-size: 14px; margin: 0; font-weight: 500; }

.edit-seg-modal .modal-content { border-radius: 16px; border: none; box-shadow: var(--sw-shadow-xl); }
.edit-seg-modal .modal-header { background: linear-gradient(135deg, var(--sw-primary-deeper), var(--sw-primary)); color: white; border-radius: 16px 16px 0 0; }
.edit-seg-modal .modal-header .btn-close-white { filter: brightness(0) invert(1); }
</style>
@endpush

@section('content')
<div class="main-content sw-page">
    <div class="container-fluid">

        <div class="sw-hero">
            <div class="sw-hero-particles">
                <span></span><span></span><span></span><span></span><span></span>
            </div>
            <div class="sw-hero-content">
                <div class="d-flex flex-wrap justify-content-between align-items-start gap-3">
                    <div>
                        <h2><i class="bi bi-stars me-2"></i>{{ translate('spin_wheel_rewards') }}</h2>
                        <p>{{ translate('configure_post_ride_rewards_for_customers') }}</p>
                    </div>
                    <div class="d-flex flex-column align-items-end gap-3">
                        <div class="sw-toggle-container">
                            <span style="font-size: 13px; font-weight: 500;">{{ translate('wheel_status') }}</span>
                            <label class="sw-toggle-switch">
                                <input type="checkbox" {{ $config->is_active ? 'checked' : '' }}
                                       onchange="location.href='{{ route('admin.promotion.spin-wheel.status') }}'">
                                <span class="sw-toggle-slider"></span>
                            </label>
                            <span class="sw-status-pill {{ $config->is_active ? 'sw-status-active' : 'sw-status-inactive' }}">
                                {{ $config->is_active ? translate('live') : translate('off') }}
                            </span>
                        </div>
                        <div class="sw-hero-actions">
                            <a href="{{ route('admin.promotion.spin-wheel.reports') }}" class="sw-hero-btn">
                                <i class="bi bi-graph-up-arrow"></i>{{ translate('analytics') }}
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="sw-stats-grid">
            <div class="sw-stat-card">
                <div class="d-flex align-items-center gap-3">
                    <div class="sw-stat-icon" style="background: #EFF6FF; color: var(--sw-primary);">
                        <i class="bi bi-arrow-repeat"></i>
                    </div>
                    <div>
                        <div class="sw-stat-value">{{ number_format($totalSpins) }}</div>
                        <div class="sw-stat-label">{{ translate('total_spins') }}</div>
                    </div>
                </div>
            </div>
            <div class="sw-stat-card">
                <div class="d-flex align-items-center gap-3">
                    <div class="sw-stat-icon" style="background: #ECFDF5; color: var(--sw-success);">
                        <i class="bi bi-wallet2"></i>
                    </div>
                    <div>
                        <div class="sw-stat-value">₹{{ number_format($totalWalletCredits, 0) }}</div>
                        <div class="sw-stat-label">{{ translate('total_credits') }}</div>
                    </div>
                </div>
            </div>
            <div class="sw-stat-card">
                <div class="d-flex align-items-center gap-3">
                    <div class="sw-stat-icon" style="background: #FFFBEB; color: var(--sw-warning);">
                        <i class="bi bi-people-fill"></i>
                    </div>
                    <div>
                        <div class="sw-stat-value">{{ number_format($uniqueUsers) }}</div>
                        <div class="sw-stat-label">{{ translate('unique_users') }}</div>
                    </div>
                </div>
            </div>
            <div class="sw-stat-card">
                <div class="d-flex align-items-center gap-3">
                    <div class="sw-stat-icon" style="background: #FDF2F8; color: var(--sw-pink);">
                        <i class="bi bi-lightning-charge-fill"></i>
                    </div>
                    <div>
                        <div class="sw-stat-value">{{ number_format($todaySpins) }}</div>
                        <div class="sw-stat-label">{{ translate('today') }} <span style="font-size:10px; opacity:0.7;">(₹{{ number_format($todayCredits, 0) }})</span></div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-4">

            <div class="col-xl-5">
                <div class="sw-card mb-4">
                    <div class="sw-card-header">
                        <div class="d-flex align-items-center gap-2">
                            <div class="sw-card-header-icon"><i class="bi bi-eye-fill"></i></div>
                            <span>{{ translate('live_wheel_preview') }}</span>
                        </div>
                        <span class="badge bg-white bg-opacity-25 text-white" style="font-size: 11px; border-radius: 6px;">{{ translate('interactive') }}</span>
                    </div>
                    <div class="sw-card-body p-0">
                        <div class="sw-wheel-stage">
                            <div class="sw-wheel-title-display">
                                <h4 id="previewTitle">{{ $config->title }}</h4>
                                <p id="previewSubtitle">{{ $config->subtitle }}</p>
                            </div>
                            <div class="sw-wheel-glow"></div>
                            <div class="sw-wheel-wrapper">
                                <div class="sw-wheel-outer-ring"><div class="sw-wheel-outer-ring-inner"></div></div>
                                <div class="sw-wheel-pointer">
                                    <svg viewBox="0 0 40 48" fill="none">
                                        <defs>
                                            <linearGradient id="pointerGrad" x1="0" y1="0" x2="0" y2="1">
                                                <stop offset="0%" stop-color="#DC2626"/>
                                                <stop offset="100%" stop-color="#991B1B"/>
                                            </linearGradient>
                                            <filter id="pointerShadow"><feDropShadow dx="0" dy="2" stdDeviation="2" flood-color="#00000040"/></filter>
                                        </defs>
                                        <path d="M20 48 L4 8 A4 4 0 0 1 8 4 L32 4 A4 4 0 0 1 36 8 Z" fill="url(#pointerGrad)" filter="url(#pointerShadow)"/>
                                        <circle cx="20" cy="14" r="5" fill="white" fill-opacity="0.3"/>
                                    </svg>
                                </div>
                                <div class="sw-wheel-canvas-wrap">
                                    <canvas id="wheelCanvas" class="sw-wheel-canvas" width="640" height="640"></canvas>
                                </div>
                                <button class="sw-wheel-center-btn" id="spinBtn" type="button">SPIN</button>
                            </div>
                            <div class="sw-wheel-hint">
                                <i class="bi bi-hand-index-thumb"></i>
                                {{ translate('click_spin_to_preview_animation') }}
                            </div>
                        </div>
                    </div>
                </div>

                <div class="sw-card">
                    <div class="sw-card-header">
                        <div class="d-flex align-items-center gap-2">
                            <div class="sw-card-header-icon"><i class="bi bi-plus-lg"></i></div>
                            <span>{{ translate('add_segment') }}</span>
                        </div>
                    </div>
                    <div class="sw-card-body">
                        <form action="{{ route('admin.promotion.spin-wheel.segment.add') }}" method="POST">
                            @csrf
                            <div class="sw-add-form">
                                <div class="row g-3">
                                    <div class="col-6">
                                        <label class="sw-form-label">{{ translate('display_label') }}</label>
                                        <input type="text" name="label" class="sw-form-input" placeholder="e.g. ₹10 OFF" required>
                                    </div>
                                    <div class="col-6">
                                        <label class="sw-form-label">{{ translate('reward_amount') }} (₹)</label>
                                        <input type="number" name="amount" class="sw-form-input" placeholder="10" min="1" step="0.01" required>
                                    </div>
                                    <div class="col-6">
                                        <label class="sw-form-label">{{ translate('segment_color') }}</label>
                                        <div class="sw-color-picker-wrap">
                                            <div class="sw-color-preview" id="addColorPreview" style="background: #2563EB;">
                                                <input type="color" name="color" value="#2563EB" onchange="this.parentElement.style.background=this.value">
                                            </div>
                                            <span class="small text-muted" id="addColorHex">#2563EB</span>
                                        </div>
                                    </div>
                                    <div class="col-6">
                                        <label class="sw-form-label">{{ translate('probability_weight') }}</label>
                                        <input type="number" name="weight" class="sw-form-input" value="10" min="1" max="100" required>
                                        <div class="sw-form-hint"><i class="bi bi-info-circle"></i>{{ translate('higher_=_more_chance') }}</div>
                                    </div>
                                    <div class="col-12">
                                        <button type="submit" class="sw-btn sw-btn-success w-100">
                                            <i class="bi bi-plus-circle-fill"></i>{{ translate('add_to_wheel') }}
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>

            <div class="col-xl-7">

                <div class="sw-card mb-4">
                    <div class="sw-card-header">
                        <div class="d-flex align-items-center gap-2">
                            <div class="sw-card-header-icon"><i class="bi bi-sliders2"></i></div>
                            <span>{{ translate('wheel_configuration') }}</span>
                        </div>
                    </div>
                    <div class="sw-card-body">
                        <form action="{{ route('admin.promotion.spin-wheel.update') }}" method="POST">
                            @csrf
                            @method('PUT')

                            <div class="sw-config-section">
                                <div class="sw-config-section-title">
                                    <i class="bi bi-type"></i>{{ translate('display_settings') }}
                                </div>
                                <div class="row g-3">
                                    <div class="col-md-6">
                                        <div class="sw-form-group">
                                            <label class="sw-form-label">{{ translate('wheel_title') }}</label>
                                            <input type="text" name="title" class="sw-form-input" value="{{ $config->title }}" id="titleInput">
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="sw-form-group">
                                            <label class="sw-form-label">{{ translate('subtitle') }}</label>
                                            <input type="text" name="subtitle" class="sw-form-input" value="{{ $config->subtitle }}" id="subtitleInput">
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="sw-config-section">
                                <div class="sw-config-section-title">
                                    <i class="bi bi-shield-check"></i>{{ translate('limits_&_controls') }}
                                </div>
                                <div class="row g-3">
                                    <div class="col-md-4">
                                        <div class="sw-form-group">
                                            <label class="sw-form-label">{{ translate('spins_per_day') }}</label>
                                            <input type="number" name="spins_per_day" class="sw-form-input" value="{{ $config->spins_per_day }}" min="1" max="10">
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div class="sw-form-group">
                                            <label class="sw-form-label">{{ translate('min_reward') }} (₹)</label>
                                            <input type="number" name="min_discount" class="sw-form-input" value="{{ $config->min_discount }}" min="1">
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div class="sw-form-group">
                                            <label class="sw-form-label">{{ translate('max_reward') }} (₹)</label>
                                            <input type="number" name="max_discount" class="sw-form-input" value="{{ $config->max_discount }}" min="1">
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="sw-form-group">
                                            <label class="sw-form-label">{{ translate('lifetime_earning_cap') }} (₹)</label>
                                            <input type="number" name="max_total_per_user" class="sw-form-input" value="{{ $config->max_total_per_user ?? 500 }}" min="0" step="1">
                                            <div class="sw-form-hint"><i class="bi bi-info-circle"></i>{{ translate('0_for_unlimited') }}</div>
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="sw-form-group">
                                            <label class="sw-form-label d-md-none">&nbsp;</label>
                                            <label class="sw-checkbox-wrap">
                                                <input type="checkbox" name="ride_completion_required" {{ ($config->ride_completion_required ?? true) ? 'checked' : '' }}>
                                                <div class="sw-checkbox-info">
                                                    <div class="sw-checkbox-label">{{ translate('ride_required') }}</div>
                                                    <div class="sw-checkbox-desc">{{ translate('must_complete_ride_to_spin') }}</div>
                                                </div>
                                            </label>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <button type="submit" class="sw-btn sw-btn-primary">
                                <i class="bi bi-check-circle-fill"></i>{{ translate('save_configuration') }}
                            </button>
                        </form>
                    </div>
                </div>

                <div class="sw-card mb-4">
                    <div class="sw-card-header">
                        <div class="d-flex align-items-center gap-2">
                            <div class="sw-card-header-icon"><i class="bi bi-pie-chart-fill"></i></div>
                            <span>{{ translate('wheel_segments') }}</span>
                        </div>
                        <div class="d-flex align-items-center gap-2">
                            @php $totalWeight = $segments->where('is_active', true)->sum('weight'); @endphp
                            <span class="badge bg-white bg-opacity-25 text-white" style="font-size: 11px; border-radius: 6px;">
                                {{ $segments->count() }} {{ translate('segments') }} &middot; {{ translate('weight') }}: {{ $totalWeight }}
                            </span>
                        </div>
                    </div>
                    <div class="sw-card-body p-2">
                        <div class="sw-seg-list">
                            @forelse($segments as $seg)
                            <div class="sw-seg-item {{ !$seg->is_active ? 'disabled' : '' }}">
                                <div class="sw-seg-color" style="background: {{ $seg->color }};">
                                    {{ $seg->sort_order }}
                                </div>
                                <div class="sw-seg-details">
                                    <div class="sw-seg-name">
                                        {{ $seg->label }}
                                        <span class="amount">₹{{ number_format($seg->amount, 2) }}</span>
                                        @if(!$seg->is_active)
                                            <span class="sw-badge" style="background: #FEF2F2; color: var(--sw-danger); font-size: 10px; padding: 2px 8px;">{{ translate('disabled') }}</span>
                                        @endif
                                    </div>
                                    <div class="sw-seg-meta">
                                        <div class="sw-seg-probability">
                                            <span>{{ translate('W') }}: {{ $seg->weight }}</span>
                                            @if($totalWeight > 0)
                                                <div class="sw-seg-prob-bar">
                                                    <div class="sw-seg-prob-fill" style="width: {{ min(($seg->weight / $totalWeight) * 100, 100) }}%; background: {{ $seg->color }};"></div>
                                                </div>
                                                <span>{{ number_format(($seg->weight / $totalWeight) * 100, 1) }}%</span>
                                            @endif
                                        </div>
                                    </div>
                                </div>
                                <div class="sw-seg-actions">
                                    <button class="sw-seg-btn sw-seg-btn-edit" data-bs-toggle="modal" data-bs-target="#editSeg{{ $seg->id }}" title="{{ translate('edit') }}">
                                        <i class="bi bi-pencil-fill"></i>
                                    </button>
                                    <a href="{{ route('admin.promotion.spin-wheel.segment.toggle', $seg->id) }}" class="sw-seg-btn sw-seg-btn-toggle {{ !$seg->is_active ? 'is-off' : '' }}" title="{{ $seg->is_active ? translate('disable') : translate('enable') }}">
                                        <i class="bi {{ $seg->is_active ? 'bi-pause-fill' : 'bi-play-fill' }}"></i>
                                    </a>
                                    <form action="{{ route('admin.promotion.spin-wheel.segment.delete', $seg->id) }}" method="POST" class="d-inline" onsubmit="return confirm('{{ translate('delete_this_segment') }}?')">
                                        @csrf
                                        @method('DELETE')
                                        <button class="sw-seg-btn sw-seg-btn-del" type="submit" title="{{ translate('delete') }}">
                                            <i class="bi bi-trash3-fill"></i>
                                        </button>
                                    </form>
                                </div>
                            </div>

                            <div class="modal fade edit-seg-modal" id="editSeg{{ $seg->id }}" tabindex="-1">
                                <div class="modal-dialog modal-dialog-centered">
                                    <div class="modal-content">
                                        <div class="modal-header">
                                            <h6 class="modal-title"><i class="bi bi-pencil-square me-2"></i>{{ translate('edit_segment') }}: {{ $seg->label }}</h6>
                                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                                        </div>
                                        <div class="modal-body p-4">
                                            <form action="{{ route('admin.promotion.spin-wheel.segment.update', $seg->id) }}" method="POST">
                                                @csrf
                                                @method('PUT')
                                                <div class="row g-3">
                                                    <div class="col-6">
                                                        <label class="sw-form-label">{{ translate('label') }}</label>
                                                        <input type="text" name="label" class="sw-form-input" value="{{ $seg->label }}" required>
                                                    </div>
                                                    <div class="col-6">
                                                        <label class="sw-form-label">{{ translate('amount') }} (₹)</label>
                                                        <input type="number" name="amount" class="sw-form-input" value="{{ $seg->amount }}" min="1" step="0.01" required>
                                                    </div>
                                                    <div class="col-6">
                                                        <label class="sw-form-label">{{ translate('color') }}</label>
                                                        <input type="color" name="color" class="form-control form-control-color w-100" value="{{ $seg->color }}" style="height: 42px; border-radius: 10px; border: 2px solid var(--sw-border);">
                                                    </div>
                                                    <div class="col-6">
                                                        <label class="sw-form-label">{{ translate('weight') }}</label>
                                                        <input type="number" name="weight" class="sw-form-input" value="{{ $seg->weight }}" min="1" max="100" required>
                                                    </div>
                                                    <div class="col-12">
                                                        <button type="submit" class="sw-btn sw-btn-primary w-100">
                                                            <i class="bi bi-check-circle-fill"></i>{{ translate('update_segment') }}
                                                        </button>
                                                    </div>
                                                </div>
                                            </form>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            @empty
                            <div class="sw-empty-state">
                                <i class="bi bi-pie-chart"></i>
                                <p>{{ translate('no_segments_yet') }}<br><span style="font-size: 12px;">{{ translate('add_your_first_segment_to_get_started') }}</span></p>
                            </div>
                            @endforelse
                        </div>
                    </div>
                </div>

                @if($recentResults->count() > 0)
                <div class="sw-card">
                    <div class="sw-card-header">
                        <div class="d-flex align-items-center gap-2">
                            <div class="sw-card-header-icon"><i class="bi bi-clock-history"></i></div>
                            <span>{{ translate('recent_activity') }}</span>
                        </div>
                        <span class="badge bg-white bg-opacity-25 text-white" style="font-size: 11px; border-radius: 6px;">{{ translate('last') }} {{ $recentResults->count() }}</span>
                    </div>
                    <div class="sw-card-body p-0">
                        <div class="sw-table-wrap">
                            <table class="sw-table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>{{ translate('customer') }}</th>
                                        <th>{{ translate('reward') }}</th>
                                        <th>{{ translate('wallet') }}</th>
                                        <th>{{ translate('time') }}</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($recentResults as $key => $result)
                                    <tr>
                                        <td><span class="fw-bold text-muted">{{ $key + 1 }}</span></td>
                                        <td>
                                            <div class="fw-semibold" style="font-size: 13px;">{{ $result->user ? $result->user->first_name . ' ' . $result->user->last_name : 'N/A' }}</div>
                                        </td>
                                        <td><span class="sw-badge sw-badge-blue">₹{{ $result->discount_value }}</span></td>
                                        <td><span class="sw-badge sw-badge-green">₹{{ number_format($result->wallet_amount, 2) }}</span></td>
                                        <td><span class="text-muted" style="font-size: 12px;">{{ $result->created_at->format('d M, h:i A') }}</span></td>
                                    </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                @endif
            </div>
        </div>
    </div>
</div>

<div class="sw-result-overlay" id="resultOverlay">
    <div class="sw-result-card">
        <div class="sw-result-emoji">🎉</div>
        <div class="sw-result-title">{{ translate('congratulations') }}!</div>
        <div class="sw-result-value" id="resultValue">₹20</div>
        <div class="sw-result-desc">{{ translate('added_to_your_wallet_balance') }}</div>
        <button class="sw-btn sw-btn-primary" onclick="document.getElementById('resultOverlay').classList.remove('active')" type="button">
            <i class="bi bi-hand-thumbs-up-fill"></i>{{ translate('awesome') }}!
        </button>
    </div>
</div>
@endsection

@push('script')
@php
    $jsSegs = $segments->where('is_active', true)->pluck('label')->toArray();
    $jsCols = $segments->where('is_active', true)->pluck('color')->toArray();
    $jsAmounts = $segments->where('is_active', true)->pluck('amount')->toArray();
    if (empty($jsSegs)) {
        $jsSegs = ['₹5', '₹10'];
        $jsCols = ['#2563EB', '#16A34A'];
        $jsAmounts = [5, 10];
    }
@endphp
<script>
(function() {
    const segments = {!! json_encode(array_values($jsSegs)) !!};
    const colors = {!! json_encode(array_values($jsCols)) !!};
    const amounts = {!! json_encode(array_values($jsAmounts)) !!};
    let isSpinning = false;
    let currentRotation = 0;

    function hexToHSL(hex) {
        let r = parseInt(hex.slice(1,3),16)/255, g = parseInt(hex.slice(3,5),16)/255, b = parseInt(hex.slice(5,7),16)/255;
        let max = Math.max(r,g,b), min = Math.min(r,g,b), h, s, l = (max+min)/2;
        if(max===min){h=s=0;}else{
            let d=max-min; s=l>0.5?d/(2-max-min):d/(max+min);
            switch(max){case r:h=((g-b)/d+(g<b?6:0))/6;break;case g:h=((b-r)/d+2)/6;break;case b:h=((r-g)/d+4)/6;break;}
        }
        return {h:h*360,s:s*100,l:l*100};
    }

    function drawWheel(segs, cols) {
        const canvas = document.getElementById('wheelCanvas');
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        const w = canvas.width, h = canvas.height;
        const cx = w/2, cy = h/2, r = w/2 - 6;
        const n = segs.length;
        if (n < 1) return;
        const arc = (2*Math.PI)/n;
        ctx.clearRect(0, 0, w, h);

        for (let i = 0; i < n; i++) {
            const sa = i*arc - Math.PI/2;
            const ea = sa + arc;
            const col = cols[i % cols.length];
            const hsl = hexToHSL(col);

            const grad = ctx.createRadialGradient(cx, cy, r*0.15, cx, cy, r);
            grad.addColorStop(0, `hsla(${hsl.h}, ${Math.min(hsl.s+10,100)}%, ${Math.min(hsl.l+15,90)}%, 0.9)`);
            grad.addColorStop(0.5, col);
            grad.addColorStop(1, `hsla(${hsl.h}, ${hsl.s}%, ${Math.max(hsl.l-10,10)}%, 1)`);

            ctx.beginPath();
            ctx.moveTo(cx, cy);
            ctx.arc(cx, cy, r, sa, ea);
            ctx.closePath();
            ctx.fillStyle = grad;
            ctx.fill();

            ctx.beginPath();
            ctx.moveTo(cx, cy);
            ctx.arc(cx, cy, r, sa, ea);
            ctx.closePath();
            ctx.strokeStyle = 'rgba(255,255,255,0.35)';
            ctx.lineWidth = 2;
            ctx.stroke();

            ctx.save();
            ctx.translate(cx, cy);
            ctx.rotate(sa + arc/2);
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';

            ctx.fillStyle = 'rgba(0,0,0,0.12)';
            ctx.font = `bold ${Math.max(18, Math.min(32, 220/n))}px 'Poppins', sans-serif`;
            ctx.fillText(segs[i], r*0.6 + 1, 2);

            ctx.fillStyle = '#fff';
            ctx.font = `bold ${Math.max(18, Math.min(32, 220/n))}px 'Poppins', sans-serif`;
            ctx.shadowColor = 'rgba(0,0,0,0.35)';
            ctx.shadowBlur = 4;
            ctx.shadowOffsetY = 1;
            ctx.fillText(segs[i], r*0.6, 0);
            ctx.restore();
        }

        const dotR = r + 2;
        const dotCount = n * 3;
        for (let i = 0; i < dotCount; i++) {
            const angle = (i/dotCount) * 2 * Math.PI - Math.PI/2;
            const dx = cx + dotR * Math.cos(angle);
            const dy = cy + dotR * Math.sin(angle);
            ctx.beginPath();
            ctx.arc(dx, dy, 2.5, 0, 2*Math.PI);
            ctx.fillStyle = i % 3 === 0 ? 'rgba(255,255,255,0.8)' : 'rgba(255,255,255,0.3)';
            ctx.fill();
        }
    }

    drawWheel(segments, colors);

    const titleInput = document.getElementById('titleInput');
    const subtitleInput = document.getElementById('subtitleInput');
    if (titleInput) titleInput.addEventListener('input', function() { document.getElementById('previewTitle').textContent = this.value; });
    if (subtitleInput) subtitleInput.addEventListener('input', function() { document.getElementById('previewSubtitle').textContent = this.value; });

    document.getElementById('spinBtn').addEventListener('click', function() {
        if (isSpinning) return;
        isSpinning = true;
        this.style.pointerEvents = 'none';

        const canvas = document.getElementById('wheelCanvas');
        const n = segments.length;
        const winIndex = Math.floor(Math.random() * n);
        const arcDeg = 360 / n;
        const targetAngle = 360 - (winIndex * arcDeg + arcDeg / 2);
        const totalRotation = currentRotation + 2160 + targetAngle;

        canvas.style.transition = 'transform 5s cubic-bezier(0.12, 0.8, 0.14, 1)';
        canvas.style.transform = 'rotate(' + totalRotation + 'deg)';
        currentRotation = totalRotation;

        setTimeout(() => {
            isSpinning = false;
            this.style.pointerEvents = '';
            document.getElementById('resultValue').textContent = segments[winIndex];
            document.getElementById('resultOverlay').classList.add('active');
        }, 5300);
    });

    document.getElementById('resultOverlay').addEventListener('click', function(e) {
        if (e.target === this) this.classList.remove('active');
    });
})();
</script>
@endpush
