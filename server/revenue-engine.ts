/**
 * ══════════════════════════════════════════════════════════════════════════════
 *  UNIFIED REVENUE ENGINE — Production-grade revenue management
 * ══════════════════════════════════════════════════════════════════════════════
 *
 *  Commission Model: percentage + GST + insurance → all go to admin/platform
 *  Subscription Model: fixed platform_fee + GST + insurance → all go to admin
 *  Hybrid Model: commission% + platform_fee + GST + insurance → admin
 *
 *  Supports: Rides, Parcel, B2B Parcel, City Carpool, Outstation Pool
 *  Each service has INDEPENDENT revenue model configuration.
 *
 *  Key invariant (Telugu request): Commission model lo percentage + GST + insurance
 *  anni admin ki ravali — all three must flow to admin wallet/revenue.
 */

import { db } from "./db";
import { sql } from "drizzle-orm";

const rawDb = db;
const rawSql = sql;

// ═══════════════════════════════════════════════════════════════════════════════
//  TYPES
// ═══════════════════════════════════════════════════════════════════════════════

export interface RevenueBreakdown {
  model: "commission" | "subscription" | "hybrid" | "launch_free";
  commission: number;       // commission amount (₹)
  platformFee: number;      // subscription flat fee (₹)
  gst: number;              // GST amount (₹)
  insurance: number;        // insurance amount (₹)
  total: number;            // total platform deduction (₹)
  commissionPct: number;    // commission rate used
  gstPct: number;           // GST rate used
  fareBeforeDeduction: number;
  driverEarnings: number;   // what the driver keeps
}

export type ServiceCategory = "rides" | "parcel" | "b2b_parcel" | "cargo" | "intercity"
  | "city_pool" | "outstation_pool";

export type PaymentMethod = "cash" | "upi" | "wallet" | "online" | "razorpay" | "card" | "prepaid";

export interface UPIProvider {
  id: string;
  name: string;
  upiHandle: string;
  icon: string;
  isActive: boolean;
}

export const SUPPORTED_UPI_PROVIDERS: UPIProvider[] = [
  { id: "gpay",    name: "Google Pay", upiHandle: "@okicici",   icon: "💳", isActive: true },
  { id: "phonepe", name: "PhonePe",    upiHandle: "@ybl",       icon: "💜", isActive: true },
  { id: "paytm",   name: "Paytm",      upiHandle: "@paytm",     icon: "🔵", isActive: true },
  { id: "bhim",    name: "BHIM",        upiHandle: "@upi",       icon: "🇮🇳", isActive: true },
];

// ═══════════════════════════════════════════════════════════════════════════════
//  SERVICE MODEL KEY MAPPING
// ═══════════════════════════════════════════════════════════════════════════════

/** Map service category → revenue_model_settings key */
function getModelKey(serviceCategory: ServiceCategory): string {
  switch (serviceCategory) {
    case "rides":           return "rides_model";
    case "parcel":          return "parcels_model";
    case "b2b_parcel":      return "parcels_model";       // B2B parcel uses same as parcel
    case "cargo":           return "cargo_model";
    case "intercity":       return "intercity_model";
    case "city_pool":       return "city_pool_model";
    case "outstation_pool": return "outstation_pool_model";
    default:                return "rides_model";
  }
}

/** Map service category → GST rate key */
function getGstKey(serviceCategory: ServiceCategory): string {
  switch (serviceCategory) {
    case "parcel":
    case "b2b_parcel":
    case "cargo":           return "parcel_gst_rate";
    default:                return "ride_gst_rate";
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  LOAD REVENUE SETTINGS
// ═══════════════════════════════════════════════════════════════════════════════

export async function loadRevenueSettings(): Promise<Record<string, string>> {
  const r = await rawDb.execute(rawSql`
    SELECT key_name, value FROM revenue_model_settings
  `).catch(() => ({ rows: [] as any[] }));
  const s: Record<string, string> = {};
  (r.rows as any[]).forEach((row: any) => { s[row.key_name] = row.value; });
  return s;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CORE: Calculate revenue breakdown for ANY service
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * Calculate the full revenue breakdown for a completed trip/order.
 * Commission model: commission% + GST + insurance → all to admin
 * Subscription model: platform_fee + GST + insurance → all to admin
 * Hybrid: commission% + platform_fee + GST + insurance → all to admin
 *
 * Returns exact paise-based calculations (no floating point drift).
 */
export async function calculateRevenueBreakdown(
  fare: number,
  serviceCategory: ServiceCategory,
  driverId?: string,
): Promise<RevenueBreakdown> {
  const s = await loadRevenueSettings();

  // Determine active model for this service
  const modelKey = getModelKey(serviceCategory);
  const activeModel = s[modelKey] || s.active_model || "commission";

  // Check launch free period
  let launchFreeApplied = false;
  if (driverId) {
    const campaignGlobalOn = s["launch_campaign_enabled"] !== "false";
    if (campaignGlobalOn) {
      const dr = await rawDb.execute(rawSql`
        SELECT launch_free_active, free_period_end FROM users WHERE id=${driverId}::uuid LIMIT 1
      `).catch(() => ({ rows: [] as any[] }));
      const d = dr.rows[0] as any;
      if (d?.launch_free_active === true && d?.free_period_end && new Date(d.free_period_end) >= new Date()) {
        launchFreeApplied = true;
      }
      // Auto-expire
      if (d?.launch_free_active === true && d?.free_period_end && new Date(d.free_period_end) < new Date()) {
        await rawDb.execute(rawSql`UPDATE users SET launch_free_active=false WHERE id=${driverId}::uuid`).catch(() => {});
      }
    }
  }

  // GST rate for this service
  const gstKey = getGstKey(serviceCategory);
  const gstRatePct = parseFloat(s[gstKey] || "5"); // 5% default for rides, 18% for parcel

  // INTEGER PAISE MATH to prevent floating-point drift
  const farePaise = Math.round(fare * 100);
  const gstPaise = Math.round(farePaise * Math.round(gstRatePct * 100) / 10000);
  const gstAmount = gstPaise / 100;

  let deductPaise = 0;
  let breakdown: RevenueBreakdown;

  if (launchFreeApplied) {
    // Launch free: only GST charged
    deductPaise = gstPaise;
    breakdown = {
      model: "launch_free", commission: 0, platformFee: 0,
      gst: gstAmount, insurance: 0, total: deductPaise / 100,
      commissionPct: 0, gstPct: gstRatePct,
      fareBeforeDeduction: fare, driverEarnings: (farePaise - deductPaise) / 100,
    };
  } else if (activeModel === "commission") {
    // COMMISSION MODEL: percentage + GST + insurance → ALL go to admin
    const commPctX100 = Math.round(parseFloat(s.commission_pct || "15") * 100);
    const insPaise = Math.round(parseFloat(s.commission_insurance_per_ride || "2") * 100);
    const commPaise = Math.round(farePaise * commPctX100 / 10000);
    deductPaise = commPaise + gstPaise + insPaise; // ALL THREE → admin

    breakdown = {
      model: "commission",
      commission: commPaise / 100,
      platformFee: 0,
      gst: gstAmount,
      insurance: insPaise / 100,
      total: deductPaise / 100,
      commissionPct: commPctX100 / 100,
      gstPct: gstRatePct,
      fareBeforeDeduction: fare,
      driverEarnings: (farePaise - deductPaise) / 100,
    };
  } else if (activeModel === "subscription") {
    // SUBSCRIPTION MODEL: flat fee + GST + insurance → admin
    const platPaise = Math.round(parseFloat(s.sub_platform_fee_per_ride || "5") * 100);
    const insPaise = Math.round(parseFloat(s.commission_insurance_per_ride || "2") * 100);
    deductPaise = platPaise + gstPaise + insPaise;

    breakdown = {
      model: "subscription",
      commission: 0,
      platformFee: platPaise / 100,
      gst: gstAmount,
      insurance: insPaise / 100,
      total: deductPaise / 100,
      commissionPct: 0,
      gstPct: gstRatePct,
      fareBeforeDeduction: fare,
      driverEarnings: (farePaise - deductPaise) / 100,
    };
  } else if (activeModel === "hybrid") {
    // HYBRID: commission% + platform_fee + GST + insurance → admin
    const commPctX100 = Math.round(parseFloat(s.hybrid_commission_pct || s.commission_pct || "10") * 100);
    const platPaise = Math.round(parseFloat(s.hybrid_platform_fee_per_ride || s.sub_platform_fee_per_ride || "5") * 100);
    const insPaise = Math.round(parseFloat(s.hybrid_insurance_per_ride || s.commission_insurance_per_ride || "2") * 100);
    const commPaise = Math.round(farePaise * commPctX100 / 10000);
    deductPaise = commPaise + platPaise + gstPaise + insPaise;

    breakdown = {
      model: "hybrid",
      commission: commPaise / 100,
      platformFee: platPaise / 100,
      gst: gstAmount,
      insurance: insPaise / 100,
      total: deductPaise / 100,
      commissionPct: commPctX100 / 100,
      gstPct: gstRatePct,
      fareBeforeDeduction: fare,
      driverEarnings: (farePaise - deductPaise) / 100,
    };
  } else {
    // fallback — treat as commission
    const commPctX100 = Math.round(parseFloat(s.commission_pct || "15") * 100);
    const insPaise = Math.round(parseFloat(s.commission_insurance_per_ride || "2") * 100);
    const commPaise = Math.round(farePaise * commPctX100 / 10000);
    deductPaise = commPaise + gstPaise + insPaise;

    breakdown = {
      model: "commission",
      commission: commPaise / 100,
      platformFee: 0,
      gst: gstAmount,
      insurance: insPaise / 100,
      total: deductPaise / 100,
      commissionPct: commPctX100 / 100,
      gstPct: gstRatePct,
      fareBeforeDeduction: fare,
      driverEarnings: (farePaise - deductPaise) / 100,
    };
  }

  return breakdown;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SETTLE: Apply revenue to driver wallet + admin revenue + GST wallet
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * After calculating breakdown, settle it:
 * 1. Update driver wallet (negative for cash, positive for online)
 * 2. Record commission_settlements
 * 3. Credit company_gst_wallet
 * 4. Record admin_revenue
 * 5. Auto-lock if threshold breached
 *
 * Returns: { newWalletBalance, isLocked, lockReason }
 */
export async function settleRevenue(params: {
  driverId: string;
  tripId: string;
  fare: number;
  paymentMethod: PaymentMethod;
  breakdown: RevenueBreakdown;
  serviceCategory: ServiceCategory;
  serviceLabel?: string;
  customerWalletBalance?: number; // Needed for wallet payment validation
}): Promise<{ newWalletBalance: number; isLocked: boolean; lockReason?: string }> {
  const { driverId, tripId, fare, paymentMethod, breakdown, serviceCategory, serviceLabel } = params;
  const deductAmount = breakdown.total;
  const driverWalletCredit = breakdown.driverEarnings;
  const gstAmount = breakdown.gst;
  const commissionOwed = parseFloat((deductAmount - gstAmount).toFixed(2)); // commission + insurance portion

  if (deductAmount <= 0) {
    return { newWalletBalance: 0, isLocked: false };
  }

  const s = await loadRevenueSettings();
  const lockThresholdVal = parseFloat(s.commission_lock_threshold || "200");
  const legacyThreshold = parseFloat(s.auto_lock_threshold || "-200");

  // Fetch current pending balances (needed for lock threshold check)
  const balBeforeR = await rawDb.execute(rawSql`
    SELECT pending_commission_balance, pending_gst_balance, total_pending_balance, wallet_balance
    FROM users WHERE id=${driverId}::uuid LIMIT 1
  `).catch(() => ({ rows: [] as any[] }));
  const balBefore = balBeforeR.rows[0] as any || {};
  const prevTotal = parseFloat(balBefore.total_pending_balance ?? "0") || 0;

  // Determine if payment is online (platform collected) or cash (driver collected)
  let effectivePaymentMethod = paymentMethod;
  if (paymentMethod === "wallet" && params.customerWalletBalance !== undefined) {
    if (params.customerWalletBalance < fare) {
      effectivePaymentMethod = "cash"; // Insufficient wallet → treat as cash
    }
  }
  const isOnlinePayment = ["online", "wallet", "upi", "razorpay", "card", "prepaid"].includes(effectivePaymentMethod);

  let wUpd: any;
  let newTotal = prevTotal;

  if (isOnlinePayment) {
    // ONLINE: Platform already collected fare. Credit driver net amount.
    wUpd = await rawDb.execute(rawSql`
      UPDATE users
      SET wallet_balance = wallet_balance + ${driverWalletCredit},
          completed_rides_count = COALESCE(completed_rides_count, 0) + 1
      WHERE id=${driverId}::uuid
      RETURNING wallet_balance, is_locked, total_pending_balance
    `);
    newTotal = prevTotal;
  } else {
    // CASH: Driver collected full fare. Platform dues tracked as debt.
    // Use atomic SQL addition to prevent lost-update race conditions.
    wUpd = await rawDb.execute(rawSql`
      UPDATE users
      SET wallet_balance = wallet_balance - ${deductAmount},
          pending_commission_balance = COALESCE(pending_commission_balance, 0) + ${commissionOwed},
          pending_gst_balance = COALESCE(pending_gst_balance, 0) + ${gstAmount},
          total_pending_balance = COALESCE(total_pending_balance, 0) + ${deductAmount},
          completed_rides_count = COALESCE(completed_rides_count, 0) + 1
      WHERE id=${driverId}::uuid
      RETURNING wallet_balance, is_locked, total_pending_balance
    `);
    newTotal = parseFloat((wUpd?.rows?.[0] as any)?.total_pending_balance ?? "0") || 0;
  }

  const wRow: any = wUpd?.rows?.[0] || {};
  const newWalletBalance = parseFloat(wRow.wallet_balance ?? 0);
  let isLocked = wRow.is_locked === true;
  let lockReason: string | undefined;

  // Auto-lock for CASH rides only
  if (!isOnlinePayment && !isLocked) {
    if (newTotal >= lockThresholdVal) {
      lockReason = `Pending balance ₹${newTotal.toFixed(2)} exceeds ₹${lockThresholdVal} limit. Pay to unlock.`;
      await rawDb.execute(rawSql`
        UPDATE users SET is_locked=true, lock_reason=${lockReason}, locked_at=NOW()
        WHERE id=${driverId}::uuid
      `);
      isLocked = true;
    } else if (newWalletBalance < legacyThreshold) {
      lockReason = `Wallet balance ₹${newWalletBalance.toFixed(2)}. Pay ₹${Math.abs(newWalletBalance).toFixed(2)} to unlock.`;
      await rawDb.execute(rawSql`
        UPDATE users SET is_locked=true, lock_reason=${lockReason}, locked_at=NOW()
        WHERE id=${driverId}::uuid
      `);
      isLocked = true;
    }
  }

  // ── GST: credit to company GST wallet ───────────────────────────────────
  if (gstAmount > 0) {
    await rawDb.execute(rawSql`
      UPDATE company_gst_wallet
      SET balance = balance + ${gstAmount},
          total_collected = total_collected + ${gstAmount},
          total_trips = total_trips + 1,
          updated_at = NOW()
      WHERE id = 1
    `).catch(() => {});
  }

  // ── Commission settlements audit trail ──────────────────────────────────
  const svcLabel = serviceLabel || serviceCategory || "ride";
  if (commissionOwed > 0) {
    await rawDb.execute(rawSql`
      INSERT INTO commission_settlements
        (driver_id, trip_id, settlement_type, commission_amount, gst_amount, total_amount,
         direction, balance_before, balance_after, ride_fare, service_type, description)
      VALUES
        (${driverId}::uuid, ${tripId}::uuid, 'commission_debit',
         ${commissionOwed}, 0, ${commissionOwed},
         'debit', ${prevTotal}, ${newTotal}, ${fare}, ${svcLabel},
         ${"Commission " + (breakdown.model) + " for " + svcLabel + " " + tripId.slice(0, 8)})
    `).catch(() => {});
  }
  if (gstAmount > 0) {
    await rawDb.execute(rawSql`
      INSERT INTO commission_settlements
        (driver_id, trip_id, settlement_type, commission_amount, gst_amount, total_amount,
         direction, balance_before, balance_after, ride_fare, service_type, description)
      VALUES
        (${driverId}::uuid, ${tripId}::uuid, 'gst_debit',
         0, ${gstAmount}, ${gstAmount},
         'debit', ${prevTotal}, ${newTotal}, ${fare}, ${svcLabel},
         ${"GST (" + breakdown.gstPct + "%) for " + svcLabel + " " + tripId.slice(0, 8)})
    `).catch(() => {});
  }

  // ── Admin revenue record ────────────────────────────────────────────────
  const revenueType = breakdown.model === "launch_free" ? "gst_only"
    : breakdown.model === "commission" ? "commission"
    : breakdown.model === "hybrid" ? "hybrid_fee"
    : "subscription_fee";
  await rawDb.execute(rawSql`
    INSERT INTO admin_revenue (driver_id, trip_id, amount, revenue_type, breakdown)
    VALUES (${driverId}::uuid, ${tripId}::uuid, ${deductAmount}, ${revenueType}, ${JSON.stringify(breakdown)}::jsonb)
  `).catch(() => {});

  // ── Driver payment record (legacy table) ────────────────────────────────
  const deductDesc = breakdown.model === "launch_free"
    ? `GST ₹${gstAmount} for ${svcLabel} ${tripId.slice(0, 8)}… (launch period)`
    : `Platform fee (${breakdown.model}) ₹${deductAmount} [comm:₹${breakdown.commission} + GST:₹${gstAmount} + ins:₹${breakdown.insurance}] for ${svcLabel} ${tripId.slice(0, 8)}…`;
  await rawDb.execute(rawSql`
    INSERT INTO driver_payments (driver_id, amount, payment_type, status, description)
    VALUES (${driverId}::uuid, ${deductAmount}, 'deduction', 'completed', ${deductDesc})
  `).catch(() => {});

  // ── Transaction record ──────────────────────────────────────────────────
  try {
    if (isOnlinePayment) {
      await rawDb.execute(rawSql`
        INSERT INTO transactions (user_id, account, credit, debit, balance, transaction_type, ref_transaction_id)
        VALUES (${driverId}::uuid, ${"Trip earnings (online " + svcLabel + ")"}, ${driverWalletCredit}, 0, ${newWalletBalance}, ${"trip_earning"}, ${tripId})
        ON CONFLICT (ref_transaction_id, transaction_type) WHERE ref_transaction_id IS NOT NULL DO NOTHING
      `);
    } else {
      await rawDb.execute(rawSql`
        INSERT INTO transactions (user_id, account, credit, debit, balance, transaction_type, ref_transaction_id)
        VALUES (${driverId}::uuid, ${"Platform fee (cash " + svcLabel + ")"}, 0, ${deductAmount}, ${newWalletBalance}, ${"commission_deduction"}, ${tripId})
        ON CONFLICT (ref_transaction_id, transaction_type) WHERE ref_transaction_id IS NOT NULL DO NOTHING
      `);
    }
  } catch (e: any) { console.error("[REVENUE-TX]", e.message); }

  return { newWalletBalance, isLocked, lockReason };
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WALLET OPERATIONS
// ═══════════════════════════════════════════════════════════════════════════════

/** Get driver wallet summary */
export async function getDriverWalletSummary(driverId: string) {
  const r = await rawDb.execute(rawSql`
    SELECT wallet_balance, pending_commission_balance, pending_gst_balance,
           total_pending_balance, is_locked, lock_reason, locked_at
    FROM users WHERE id=${driverId}::uuid LIMIT 1
  `);
  if (!r.rows.length) return null;
  const w = r.rows[0] as any;
  return {
    walletBalance: parseFloat(w.wallet_balance ?? "0"),
    pendingCommission: parseFloat(w.pending_commission_balance ?? "0"),
    pendingGst: parseFloat(w.pending_gst_balance ?? "0"),
    totalPending: parseFloat(w.total_pending_balance ?? "0"),
    isLocked: w.is_locked === true,
    lockReason: w.lock_reason || null,
    lockedAt: w.locked_at || null,
  };
}

/** Process driver withdrawal request */
export async function requestWithdrawal(driverId: string, amount: number, method: string = "bank_transfer") {
  const wallet = await getDriverWalletSummary(driverId);
  if (!wallet) throw new Error("Driver not found");
  if (wallet.walletBalance < amount) throw new Error("Insufficient wallet balance");
  if (amount <= 0) throw new Error("Amount must be greater than 0");

  // Create withdrawal request
  const r = await rawDb.execute(rawSql`
    INSERT INTO driver_payments (driver_id, amount, payment_type, status, description)
    VALUES (${driverId}::uuid, ${amount}, 'withdrawal_request', 'pending',
            ${"Withdrawal request ₹" + amount + " via " + method})
    RETURNING id, amount, status, created_at
  `);

  // Debit wallet immediately (hold funds)
  await rawDb.execute(rawSql`
    UPDATE users SET wallet_balance = wallet_balance - ${amount} WHERE id=${driverId}::uuid
  `);

  // Record transaction
  const newBal = wallet.walletBalance - amount;
  await rawDb.execute(rawSql`
    INSERT INTO transactions (user_id, account, credit, debit, balance, transaction_type)
    VALUES (${driverId}::uuid, ${"Withdrawal via " + method}, 0, ${amount}, ${newBal}, 'withdrawal')
  `).catch(() => {});

  return (r.rows as any[])[0];
}

/** Admin: approve withdrawal */
export async function approveWithdrawal(paymentId: string) {
  await rawDb.execute(rawSql`
    UPDATE driver_payments SET status='completed', updated_at=NOW()
    WHERE id=${paymentId}::uuid AND payment_type='withdrawal_request' AND status='pending'
  `);
}

/** Admin: reject withdrawal (refund to driver wallet) */
export async function rejectWithdrawal(paymentId: string) {
  const r = await rawDb.execute(rawSql`
    UPDATE driver_payments SET status='rejected', updated_at=NOW()
    WHERE id=${paymentId}::uuid AND payment_type='withdrawal_request' AND status='pending'
    RETURNING driver_id, amount
  `);
  const row = (r.rows as any[])[0];
  if (row) {
    await rawDb.execute(rawSql`
      UPDATE users SET wallet_balance = wallet_balance + ${row.amount} WHERE id=${row.driver_id}::uuid
    `);
    await rawDb.execute(rawSql`
      INSERT INTO transactions (user_id, account, credit, debit, balance, transaction_type)
      VALUES (${row.driver_id}::uuid, 'Withdrawal rejected - refund', ${row.amount}, 0, 0, 'withdrawal_refund')
    `).catch(() => {});
  }
}

/** Get pending withdrawals */
export async function getPendingWithdrawals() {
  const r = await rawDb.execute(rawSql`
    SELECT dp.*, u.full_name as driver_name, u.phone as driver_phone, u.wallet_balance
    FROM driver_payments dp
    LEFT JOIN users u ON u.id = dp.driver_id
    WHERE dp.payment_type = 'withdrawal_request'
    ORDER BY dp.created_at DESC
    LIMIT 100
  `);
  return r.rows;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CUSTOMER WALLET: top-up / deduct / balance
// ═══════════════════════════════════════════════════════════════════════════════

export async function getCustomerWallet(customerId: string) {
  const r = await rawDb.execute(rawSql`
    SELECT wallet_balance FROM users WHERE id=${customerId}::uuid LIMIT 1
  `);
  return parseFloat((r.rows[0] as any)?.wallet_balance ?? "0");
}

export async function topUpCustomerWallet(customerId: string, amount: number, paymentMethod: string, paymentId?: string) {
  if (amount <= 0) throw new Error("Amount must be > 0");
  const r = await rawDb.execute(rawSql`
    UPDATE users SET wallet_balance = wallet_balance + ${amount} WHERE id=${customerId}::uuid
    RETURNING wallet_balance
  `);
  const newBal = parseFloat((r.rows[0] as any)?.wallet_balance ?? "0");

  await rawDb.execute(rawSql`
    INSERT INTO transactions (user_id, account, credit, debit, balance, transaction_type, ref_transaction_id)
    VALUES (${customerId}::uuid, ${"Wallet top-up via " + paymentMethod}, ${amount}, 0, ${newBal}, 'wallet_topup', ${paymentId || null})
  `).catch(() => {});

  if (paymentId) {
    await rawDb.execute(rawSql`
      INSERT INTO customer_payments (customer_id, amount, payment_type, razorpay_payment_id, status)
      VALUES (${customerId}::uuid, ${amount}, 'wallet_topup', ${paymentId}, 'completed')
    `).catch(() => {});
  }

  return newBal;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ADMIN: Revenue analytics per service
// ═══════════════════════════════════════════════════════════════════════════════

export async function getRevenueAnalytics(days: number = 7) {
  const r = await rawDb.execute(rawSql`
    SELECT
      revenue_type,
      COUNT(*)::int as total_trips,
      COALESCE(SUM(amount), 0)::numeric(12,2) as total_revenue,
      COALESCE(AVG(amount), 0)::numeric(12,2) as avg_revenue_per_trip,
      COALESCE(SUM((breakdown->>'commission')::numeric), 0)::numeric(12,2) as total_commission,
      COALESCE(SUM((breakdown->>'gst')::numeric), 0)::numeric(12,2) as total_gst,
      COALESCE(SUM((breakdown->>'insurance')::numeric), 0)::numeric(12,2) as total_insurance,
      COALESCE(SUM((breakdown->>'platformFee')::numeric), 0)::numeric(12,2) as total_platform_fee
    FROM admin_revenue
    WHERE created_at > NOW() - (${days} || ' days')::interval
    GROUP BY revenue_type
    ORDER BY total_revenue DESC
  `);
  return r.rows;
}

export async function getRevenueByService(days: number = 7) {
  const r = await rawDb.execute(rawSql`
    SELECT
      cs.service_type,
      COUNT(*)::int as total_settlements,
      COALESCE(SUM(cs.commission_amount), 0)::numeric(12,2) as commission_collected,
      COALESCE(SUM(cs.gst_amount), 0)::numeric(12,2) as gst_collected,
      COALESCE(SUM(cs.total_amount), 0)::numeric(12,2) as total_collected
    FROM commission_settlements cs
    WHERE cs.created_at > NOW() - (${days} || ' days')::interval
      AND cs.direction = 'debit'
    GROUP BY cs.service_type
    ORDER BY total_collected DESC
  `);
  return r.rows;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  INIT: Ensure revenue tables have required columns
// ═══════════════════════════════════════════════════════════════════════════════

export async function initRevenueEngineTables() {
  // Add city_pool_model to revenue_model_settings if missing
  const newSettings: Record<string, string> = {
    city_pool_model:        "commission",
    city_pool_commission:   "10",
    outstation_pool_commission: "15",
    b2b_parcel_model:       "commission",
    insurance_optional:     "true",
  };
  for (const [key, value] of Object.entries(newSettings)) {
    await rawDb.execute(rawSql`
      INSERT INTO revenue_model_settings (key_name, value)
      VALUES (${key}, ${value})
      ON CONFLICT (key_name) DO NOTHING
    `).catch(() => {});
  }

  // Ensure outstation bookings have commission columns
  await rawDb.execute(rawSql`
    ALTER TABLE outstation_pool_bookings ADD COLUMN IF NOT EXISTS commission_amount NUMERIC(10,2) DEFAULT 0;
    ALTER TABLE outstation_pool_bookings ADD COLUMN IF NOT EXISTS gst_amount NUMERIC(10,2) DEFAULT 0;
    ALTER TABLE outstation_pool_bookings ADD COLUMN IF NOT EXISTS insurance_amount NUMERIC(10,2) DEFAULT 0;
    ALTER TABLE outstation_pool_bookings ADD COLUMN IF NOT EXISTS driver_earnings NUMERIC(10,2) DEFAULT 0;
    ALTER TABLE outstation_pool_bookings ADD COLUMN IF NOT EXISTS revenue_model VARCHAR(30) DEFAULT 'commission';
    ALTER TABLE outstation_pool_bookings ADD COLUMN IF NOT EXISTS revenue_breakdown JSONB DEFAULT '{}';
  `).catch(() => {});

  // Ensure parcel_orders has revenue breakdown columns
  await rawDb.execute(rawSql`
    ALTER TABLE parcel_orders ADD COLUMN IF NOT EXISTS gst_amount NUMERIC(10,2) DEFAULT 0;
    ALTER TABLE parcel_orders ADD COLUMN IF NOT EXISTS insurance_amount NUMERIC(10,2) DEFAULT 0;
    ALTER TABLE parcel_orders ADD COLUMN IF NOT EXISTS driver_earnings NUMERIC(10,2) DEFAULT 0;
    ALTER TABLE parcel_orders ADD COLUMN IF NOT EXISTS revenue_model VARCHAR(30) DEFAULT 'commission';
    ALTER TABLE parcel_orders ADD COLUMN IF NOT EXISTS revenue_breakdown JSONB DEFAULT '{}';
  `).catch(() => {});

  // Ensure driver_payments has updated_at column for withdrawal tracking
  await rawDb.execute(rawSql`
    ALTER TABLE driver_payments ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();
    ALTER TABLE driver_payments ADD COLUMN IF NOT EXISTS description TEXT;
  `).catch(() => {});

  console.log("[revenue-engine] Tables and settings initialized");
}
