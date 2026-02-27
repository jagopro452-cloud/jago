import { pgTable, text, varchar, boolean, timestamp, doublePrecision, numeric, integer, uuid } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";
import { sql } from "drizzle-orm";

export const admins = pgTable("admins", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  name: varchar("name", { length: 255 }).notNull(),
  email: varchar("email", { length: 191 }).notNull().unique(),
  password: varchar("password", { length: 191 }).notNull(),
  role: varchar("role", { length: 50 }).notNull().default("admin"),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

export const users = pgTable("users", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  fullName: varchar("full_name", { length: 255 }),
  firstName: varchar("first_name", { length: 191 }),
  lastName: varchar("last_name", { length: 191 }),
  email: varchar("email", { length: 191 }).unique(),
  phone: varchar("phone", { length: 20 }),
  profileImage: varchar("profile_image", { length: 191 }),
  userType: varchar("user_type", { length: 25 }).notNull().default("customer"),
  isActive: boolean("is_active").notNull().default(true),
  loyaltyPoints: doublePrecision("loyalty_points").notNull().default(0),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const vehicleCategories = pgTable("vehicle_categories", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  name: varchar("name", { length: 255 }).notNull(),
  icon: varchar("icon", { length: 255 }),
  type: varchar("type", { length: 50 }).default("ride"),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

export const zones = pgTable("zones", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  name: varchar("name", { length: 255 }).notNull(),
  coordinates: text("coordinates"),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

export const tripRequests = pgTable("trip_requests", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  refId: varchar("ref_id", { length: 20 }).notNull().unique(),
  customerId: uuid("customer_id"),
  driverId: uuid("driver_id"),
  vehicleCategoryId: uuid("vehicle_category_id"),
  zoneId: uuid("zone_id"),
  pickupAddress: text("pickup_address"),
  destinationAddress: text("destination_address"),
  pickupLat: doublePrecision("pickup_lat"),
  pickupLng: doublePrecision("pickup_lng"),
  destinationLat: doublePrecision("destination_lat"),
  destinationLng: doublePrecision("destination_lng"),
  estimatedFare: numeric("estimated_fare", { precision: 23, scale: 3 }).notNull().default("0"),
  actualFare: numeric("actual_fare", { precision: 23, scale: 3 }).default("0"),
  estimatedDistance: doublePrecision("estimated_distance").default(0),
  actualDistance: doublePrecision("actual_distance"),
  paymentMethod: varchar("payment_method", { length: 50 }).default("cash"),
  paymentStatus: varchar("payment_status", { length: 50 }).default("unpaid"),
  type: varchar("type", { length: 50 }).default("ride"),
  currentStatus: varchar("current_status", { length: 50 }).default("pending"),
  isScheduled: boolean("is_scheduled").default(false),
  scheduledAt: timestamp("scheduled_at"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const transactions = pgTable("transactions", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  userId: uuid("user_id"),
  tripId: uuid("trip_id"),
  account: varchar("account", { length: 50 }),
  debit: numeric("debit", { precision: 23, scale: 3 }).default("0"),
  credit: numeric("credit", { precision: 23, scale: 3 }).default("0"),
  balance: numeric("balance", { precision: 23, scale: 3 }).default("0"),
  transactionType: varchar("transaction_type", { length: 100 }),
  refTransactionId: varchar("ref_transaction_id", { length: 255 }),
  createdAt: timestamp("created_at").defaultNow(),
});

export const businessSettings = pgTable("business_settings", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  keyName: varchar("key_name", { length: 191 }).notNull().unique(),
  value: text("value").notNull(),
  settingsType: varchar("settings_type", { length: 191 }).notNull(),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const tripFares = pgTable("trip_fares", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  zoneId: uuid("zone_id"),
  vehicleCategoryId: uuid("vehicle_category_id"),
  baseFare: numeric("base_fare", { precision: 23, scale: 3 }).default("0"),
  farePerKm: numeric("fare_per_km", { precision: 23, scale: 3 }).default("0"),
  farePerMin: numeric("fare_per_min", { precision: 23, scale: 3 }).default("0"),
  minimumFare: numeric("minimum_fare", { precision: 23, scale: 3 }).default("0"),
  cancellationFee: numeric("cancellation_fee", { precision: 23, scale: 3 }).default("0"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const couponSetups = pgTable("coupon_setups", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  name: varchar("name", { length: 255 }).notNull(),
  code: varchar("code", { length: 100 }).notNull().unique(),
  discountAmount: numeric("discount_amount", { precision: 23, scale: 3 }).default("0"),
  discountType: varchar("discount_type", { length: 50 }).default("amount"),
  minTripAmount: numeric("min_trip_amount", { precision: 23, scale: 3 }).default("0"),
  maxDiscountAmount: numeric("max_discount_amount", { precision: 23, scale: 3 }).default("0"),
  limitPerUser: integer("limit_per_user").default(1),
  totalUsageLimit: integer("total_usage_limit"),
  startDate: timestamp("start_date"),
  endDate: timestamp("end_date"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

export const reviews = pgTable("reviews", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  tripId: uuid("trip_id"),
  reviewerId: uuid("reviewer_id"),
  revieweeId: uuid("reviewee_id"),
  reviewerType: varchar("reviewer_type", { length: 50 }),
  rating: numeric("rating", { precision: 3, scale: 1 }),
  feedback: text("feedback"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const driverDetails = pgTable("driver_details", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  userId: uuid("user_id").unique(),
  drivingLicenseId: varchar("driving_license_id", { length: 191 }),
  vehicleCategoryId: uuid("vehicle_category_id"),
  zoneId: uuid("zone_id"),
  availabilityStatus: varchar("availability_status", { length: 50 }).default("offline"),
  isOnline: boolean("is_online").default(false),
  totalTrips: integer("total_trips").default(0),
  avgRating: numeric("avg_rating", { precision: 3, scale: 2 }).default("0"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const cancellationReasons = pgTable("cancellation_reasons", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  reason: text("reason").notNull(),
  userType: varchar("user_type", { length: 50 }).default("customer"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

export const blogs = pgTable("blogs", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  title: varchar("title", { length: 255 }).notNull(),
  slug: varchar("slug", { length: 255 }).unique(),
  content: text("content"),
  image: varchar("image", { length: 255 }),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

export const withdrawRequests = pgTable("withdraw_requests", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  userId: uuid("user_id"),
  amount: numeric("amount", { precision: 23, scale: 3 }).default("0"),
  note: text("note"),
  status: varchar("status", { length: 50 }).default("pending"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Insert schemas
export const insertUserSchema = createInsertSchema(users).omit({ id: true, createdAt: true, updatedAt: true });
export const insertTripSchema = createInsertSchema(tripRequests).omit({ id: true, createdAt: true, updatedAt: true });
export const insertCouponSchema = createInsertSchema(couponSetups).omit({ id: true, createdAt: true });
export const insertZoneSchema = createInsertSchema(zones).omit({ id: true, createdAt: true });
export const insertVehicleCategorySchema = createInsertSchema(vehicleCategories).omit({ id: true, createdAt: true });
export const insertBlogSchema = createInsertSchema(blogs).omit({ id: true, createdAt: true });

// Types
export type User = typeof users.$inferSelect;
export type InsertUser = z.infer<typeof insertUserSchema>;
export type TripRequest = typeof tripRequests.$inferSelect;
export type InsertTripRequest = z.infer<typeof insertTripSchema>;
export type VehicleCategory = typeof vehicleCategories.$inferSelect;
export type Zone = typeof zones.$inferSelect;
export type Transaction = typeof transactions.$inferSelect;
export type BusinessSetting = typeof businessSettings.$inferSelect;
export type TripFare = typeof tripFares.$inferSelect;
export type CouponSetup = typeof couponSetups.$inferSelect;
export type Review = typeof reviews.$inferSelect;
export type DriverDetail = typeof driverDetails.$inferSelect;
export type CancellationReason = typeof cancellationReasons.$inferSelect;
export type Blog = typeof blogs.$inferSelect;
export type WithdrawRequest = typeof withdrawRequests.$inferSelect;
export type Admin = typeof admins.$inferSelect;
