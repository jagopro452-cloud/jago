import { db as rawDb } from "./db";
import { sql as rawSql } from "drizzle-orm";

export interface VehicleCategoryMeta {
  id: string;
  name: string;
  icon: string | null;
  vehicleType: string;
  serviceType: string;
  type: string;
  description: string;
  isCarpool: boolean;
}

export interface ResolvedBookingVehicleSelection {
  vehicleCategoryId: string | null;
  vehicleCategoryName: string | null;
  vehicleType: string | null;
  driverRoom: string | null;
  serviceType: string | null;
  typeMismatch: boolean;
}

export function normalizeVehicleKey(value: string | null | undefined): string {
  return String(value || "")
    .trim()
    .toLowerCase()
    .replace(/&/g, "and")
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

export function normalizeBookingVehicleType(value: string | null | undefined): string | null {
  const key = normalizeVehicleKey(value);
  if (!key) return null;

  if (key === "bike_parcel" || (key.includes("parcel") && key.includes("bike"))) return "bike_parcel";
  if (
    key === "auto_parcel" ||
    key === "mini_cargo_auto" ||
    (key.includes("parcel") && key.includes("auto"))
  ) {
    return "auto_parcel";
  }
  if (key === "tata_ace" || key === "mini_truck") return "mini_truck";
  if (key === "pickup_truck" || key === "bolero_pickup" || key === "bolero_cargo") return "pickup_truck";
  if (key === "tempo_407") return "tempo_407";

  if (
    key === "bike" ||
    key === "bike_ride" ||
    key === "motor_bike" ||
    key === "motorbike" ||
    key === "motor_cycle" ||
    key === "motorcycle" ||
    key === "two_wheeler" ||
    key === "two_wheel"
  ) {
    return "bike";
  }

  if (
    key === "auto" ||
    key === "auto_ride" ||
    key === "mini_auto" ||
    key === "rickshaw" ||
    key === "e_rickshaw" ||
    key === "three_wheeler" ||
    key === "three_wheel"
  ) {
    return "auto";
  }

  if (
    key === "car" ||
    key === "cab" ||
    key === "cab_ride" ||
    key === "mini_car" ||
    key === "sedan" ||
    key === "suv" ||
    key === "suv_xl" ||
    key === "pool_mini" ||
    key === "pool_sedan" ||
    key === "pool_suv" ||
    key === "carpool" ||
    key === "city_pool" ||
    key === "intercity_pool" ||
    key === "outstation_pool"
  ) {
    return "car";
  }

  return key;
}

export function getDriverSocketRoomKey(meta: VehicleCategoryMeta | null): string | null {
  if (!meta) return null;
  return normalizeBookingVehicleType(meta.vehicleType || meta.name || meta.type);
}

export function getDriverDbVehicleType(vehicleType: string | null | undefined): string | null {
  const normalized = normalizeBookingVehicleType(vehicleType);
  if (normalized === "bike") return "motor_bike";
  if (normalized === "auto") return "auto";
  if (normalized === "car") return "car";
  return null;
}

function deriveServiceType(row: any): string {
  const explicit = String(row.service_type || "").trim().toLowerCase();
  if (explicit) return explicit;
  if (row.is_carpool === true || row.is_carpool === "true") return "pool";
  const type = String(row.type || "").trim().toLowerCase();
  if (type === "parcel" || type === "cargo") return "parcel";
  const key = normalizeVehicleKey(row.vehicle_type || row.name);
  if (key.includes("parcel") || key.includes("truck") || key.includes("tempo") || key.includes("pickup")) {
    return "parcel";
  }
  if (key.includes("pool") || key.includes("carpool") || key.includes("share")) {
    return "pool";
  }
  return "ride";
}

function allowedVehicleKeys(meta: VehicleCategoryMeta): string[] {
  const key = normalizeVehicleKey(meta.vehicleType || meta.name);
  const serviceType = normalizeVehicleKey(meta.serviceType);

  if (serviceType === "parcel" || key.includes("parcel") || key.includes("truck") || key.includes("pickup") || key.includes("tempo")) {
    // Strict separation: parcel bookings must NEVER reach ride-only drivers.
    // Previously bike_parcel fell back to plain "bike" and auto_parcel fell
    // back to plain "auto", which meant a parcel booking would notify regular
    // ride drivers — confusing for them and against rider/pilot expectations.
    switch (key) {
      case "bike_parcel":
        return ["bike_parcel"];
      case "auto_parcel":
      case "mini_cargo_auto":
        return ["auto_parcel", "mini_cargo_auto"];
      case "tata_ace":
      case "mini_truck":
        return ["tata_ace", "mini_truck"];
      case "pickup_truck":
      case "bolero_pickup":
      case "bolero_cargo":
        return ["pickup_truck", "bolero_pickup", "bolero_cargo"];
      case "tempo_407":
        return ["tempo_407"];
      default:
        return [key];
    }
  }

  if (serviceType === "pool" || meta.isCarpool || key.includes("pool") || key.includes("carpool") || key.includes("share")) {
    switch (key) {
      case "pool_mini":
        return ["pool_mini", "mini_car"];
      case "pool_sedan":
        return ["pool_sedan", "sedan"];
      case "pool_suv":
        return ["pool_suv", "suv"];
      case "carpool":
      case "city_pool":
      case "intercity_pool":
      case "outstation_pool":
        return ["carpool", "pool_mini", "pool_sedan", "pool_suv", "mini_car", "sedan", "suv"];
      default:
        return [key];
    }
  }

  switch (key) {
    case "bike":
    case "bike_ride":
      return ["bike"];
    case "auto":
    case "auto_ride":
      return ["auto"];
    case "mini_car":
    case "car":
      return ["mini_car"];
    case "sedan":
      return ["sedan"];
    case "suv":
    case "suv_xl":
      return ["suv"];
    default:
      return [key];
  }
}

export async function getVehicleCategoryMeta(categoryId?: string | null): Promise<VehicleCategoryMeta | null> {
  if (!categoryId) return null;
  const result = await rawDb.execute(rawSql`
    SELECT
      id,
      name,
      icon,
      COALESCE(vehicle_type, '') as vehicle_type,
      COALESCE(service_type, '') as service_type,
      COALESCE(type, '') as type,
      COALESCE(description, '') as description,
      COALESCE(is_carpool, false) as is_carpool
    FROM vehicle_categories
    WHERE id = ${categoryId}::uuid
    LIMIT 1
  `).catch(() => ({ rows: [] as any[] }));

  if (!result.rows.length) return null;
  const row = result.rows[0] as any;
  return {
    id: row.id,
    name: row.name || "",
    icon: row.icon || null,
    vehicleType: normalizeVehicleKey(row.vehicle_type || row.name),
    serviceType: deriveServiceType(row),
    type: String(row.type || "").toLowerCase(),
    description: row.description || "",
    isCarpool: row.is_carpool === true || row.is_carpool === "true",
  };
}

export async function getDriverSocketRoomKeyForCategoryId(categoryId?: string | null): Promise<string | null> {
  const meta = await getVehicleCategoryMeta(categoryId);
  return getDriverSocketRoomKey(meta);
}

export async function resolveBookingVehicleSelection(params: {
  vehicleCategoryId?: string | null;
  vehicleType?: string | null;
}): Promise<ResolvedBookingVehicleSelection> {
  const meta = await getVehicleCategoryMeta(params.vehicleCategoryId);
  const categoryVehicleType = getDriverSocketRoomKey(meta);
  const requestedVehicleType = normalizeBookingVehicleType(params.vehicleType);

  return {
    vehicleCategoryId: meta?.id ?? (params.vehicleCategoryId || null),
    vehicleCategoryName: meta?.name ?? null,
    vehicleType: categoryVehicleType || requestedVehicleType,
    driverRoom:
      categoryVehicleType || requestedVehicleType
        ? `drivers_${categoryVehicleType || requestedVehicleType}`
        : null,
    serviceType: meta?.serviceType ?? null,
    typeMismatch:
      Boolean(categoryVehicleType) &&
      Boolean(requestedVehicleType) &&
      categoryVehicleType !== requestedVehicleType,
  };
}

export async function getMatchingDriverCategoryIds(categoryId?: string | null): Promise<string[] | null> {
  const meta = await getVehicleCategoryMeta(categoryId);
  if (!meta) return categoryId ? [categoryId] : null;

  const allowedKeys = new Set(allowedVehicleKeys(meta));
  const categories = await rawDb.execute(rawSql`
    SELECT
      id,
      name,
      COALESCE(vehicle_type, '') as vehicle_type,
      COALESCE(service_type, '') as service_type,
      COALESCE(type, '') as type,
      COALESCE(is_carpool, false) as is_carpool
    FROM vehicle_categories
    WHERE is_active = true
  `).catch(() => ({ rows: [] as any[] }));

  const ids = (categories.rows as any[])
    .filter((row) => {
      const rowKey = normalizeVehicleKey(row.vehicle_type || row.name);
      return allowedKeys.has(rowKey);
    })
    .map((row) => row.id as string);

  return ids.length ? ids : [meta.id];
}

export function getPlatformServiceKeyForCategory(meta: VehicleCategoryMeta | null): string | null {
  if (!meta) return null;
  const key = normalizeVehicleKey(meta.vehicleType || meta.name);

  if (meta.serviceType === "parcel") return "parcel_delivery";
  if (meta.serviceType === "pool" || meta.isCarpool || key.includes("pool") || key.includes("share")) {
    return "city_pool";
  }
  if (key === "bike") return "bike_ride";
  if (key === "auto") return "auto_ride";
  if (key === "mini_car" || key === "car" || key === "pool_mini") return "mini_car";
  if (key === "sedan" || key === "pool_sedan") return "sedan";
  if (key === "suv" || key === "pool_suv") return "suv";
  return "bike_ride";
}
