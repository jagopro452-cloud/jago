import { db as rawDb } from "../db";
import { sql as rawSql } from "drizzle-orm";
import { getServicesForLocation } from "../dynamic-services";
import { getMatchingDriverCategoryIds, normalizeVehicleKey } from "../vehicle-matching";

type DriverDispatchProfile = {
  expiresAt: number;
  vehicleCategoryId: string | null;
  vehicleKey: string;
  seatCapacity: number;
  parcelVehicles: Set<string>;
};

const DRIVER_PROFILE_CACHE = new Map<string, DriverDispatchProfile>();
const LOCATION_SERVICE_CACHE = new Map<string, { expiresAt: number; services: Set<string> }>();
const CATEGORY_MATCH_CACHE = new Map<string, { expiresAt: number; ids: string[] }>();
const CACHE_TTL_MS = 30_000;

const DISPATCH_SERVICE_KEYS: Record<string, string[]> = {
  bike: ["bike_ride"],
  bike_ride: ["bike_ride"],
  auto: ["auto_ride"],
  auto_ride: ["auto_ride"],
  mini: ["mini_car"],
  mini_car: ["mini_car"],
  sedan: ["sedan"],
  premium: ["premium"],
  suv: ["suv"],
  cab: ["mini_car", "sedan", "premium", "suv"],
  city_pool: ["city_pool"],
  carpool: ["city_pool"],
  intercity: ["intercity_pool"],
  intercity_pool: ["intercity_pool"],
  outstation: ["outstation_pool"],
  outstation_pool: ["outstation_pool"],
  parcel: ["parcel_delivery"],
  b2b_parcel: ["parcel_delivery"],
  cargo: ["parcel_delivery"],
  parcel_bike: ["parcel_delivery"],
  parcel_auto: ["parcel_delivery"],
  cargo_auto: ["parcel_delivery"],
  tempo: ["parcel_delivery"],
  mini_truck: ["parcel_delivery"],
  pickup_truck: ["parcel_delivery"],
};

const SERVICE_VEHICLE_KEYS: Record<string, string[]> = {
  bike: ["bike", "bike_ride"],
  bike_ride: ["bike", "bike_ride"],
  auto: ["auto", "auto_ride"],
  auto_ride: ["auto", "auto_ride"],
  mini_car: ["mini_car", "car"],
  mini: ["mini_car", "car"],
  sedan: ["sedan"],
  premium: ["premium"],
  suv: ["suv", "suv_xl"],
  city_pool: ["carpool", "city_pool", "pool_mini", "pool_sedan", "pool_suv"],
  carpool: ["carpool", "city_pool", "pool_mini", "pool_sedan", "pool_suv"],
  intercity: ["intercity_pool"],
  intercity_pool: ["intercity_pool"],
  outstation: ["outstation_pool"],
  outstation_pool: ["outstation_pool"],
  parcel: ["bike_parcel", "auto_parcel", "cargo_auto", "mini_cargo_auto", "cargo_car", "tata_ace", "mini_truck", "pickup_truck", "bolero_cargo", "bolero_pickup", "tempo", "tempo_407"],
  b2b_parcel: ["bike_parcel", "auto_parcel", "cargo_auto", "mini_cargo_auto", "cargo_car", "tata_ace", "mini_truck", "pickup_truck", "bolero_cargo", "bolero_pickup", "tempo", "tempo_407"],
  parcel_bike: ["bike_parcel"],
  parcel_auto: ["auto_parcel", "cargo_auto", "mini_cargo_auto"],
  cargo_auto: ["auto_parcel", "cargo_auto", "mini_cargo_auto"],
  tempo: ["tempo", "tempo_407"],
  mini_truck: ["mini_truck", "tata_ace"],
  pickup_truck: ["pickup_truck", "bolero_pickup", "bolero_cargo"],
};

export function getDispatchServiceKeys(serviceType: string): string[] {
  return DISPATCH_SERVICE_KEYS[String(serviceType || "").toLowerCase()] || ["auto_ride"];
}

function getCompatibleVehicleKeys(serviceType: string): string[] {
  return SERVICE_VEHICLE_KEYS[String(serviceType || "").toLowerCase()] || [];
}

function deriveParcelVehicles(vehicleKey: string): string[] {
  switch (vehicleKey) {
    case "bike":
    case "bike_ride":
    case "bike_parcel":
      return ["bike_parcel"];
    case "auto":
    case "auto_ride":
    case "auto_parcel":
    case "cargo_auto":
    case "mini_cargo_auto":
      return ["auto_parcel", "cargo_auto", "mini_cargo_auto"];
    case "mini_truck":
    case "tata_ace":
      return ["mini_truck", "tata_ace"];
    case "pickup_truck":
    case "bolero_pickup":
    case "bolero_cargo":
      return ["pickup_truck", "bolero_pickup", "bolero_cargo"];
    case "tempo":
    case "tempo_407":
      return ["tempo", "tempo_407"];
    case "cargo_car":
      return ["cargo_car"];
    default:
      return [];
  }
}

async function getCachedDriverProfile(driverId: string): Promise<DriverDispatchProfile> {
  const cached = DRIVER_PROFILE_CACHE.get(driverId);
  if (cached && cached.expiresAt > Date.now()) return cached;

  const result = await rawDb.execute(rawSql`
    SELECT
      dd.vehicle_category_id,
      COALESCE(vc.vehicle_type, vc.name, '') as vehicle_key,
      COALESCE(vc.total_seats, 0) as seat_capacity
    FROM driver_details dd
    LEFT JOIN vehicle_categories vc ON vc.id = dd.vehicle_category_id
    WHERE dd.user_id = ${driverId}::uuid
    LIMIT 1
  `).catch(() => ({ rows: [] as any[] }));

  const row = result.rows[0] as any;
  const vehicleKey = normalizeVehicleKey(row?.vehicle_key || "");
  const profile: DriverDispatchProfile = {
    expiresAt: Date.now() + CACHE_TTL_MS,
    vehicleCategoryId: row?.vehicle_category_id || null,
    vehicleKey,
    seatCapacity: Number(row?.seat_capacity) || 0,
    parcelVehicles: new Set(deriveParcelVehicles(vehicleKey)),
  };
  DRIVER_PROFILE_CACHE.set(driverId, profile);
  return profile;
}

async function getCachedLocationServices(lat: number, lng: number) {
  const key = `${lat.toFixed(3)}:${lng.toFixed(3)}`;
  const cached = LOCATION_SERVICE_CACHE.get(key);
  if (cached && cached.expiresAt > Date.now()) return cached.services;

  const location = await getServicesForLocation(lat, lng);
  const services = new Set((location.services || []).map((svc) => String(svc.key || "").toLowerCase()).filter(Boolean));
  LOCATION_SERVICE_CACHE.set(key, { expiresAt: Date.now() + CACHE_TTL_MS, services });
  return services;
}

async function getCachedMatchingCategoryIds(vehicleCategoryId?: string): Promise<string[] | null> {
  if (!vehicleCategoryId) return null;
  const cached = CATEGORY_MATCH_CACHE.get(vehicleCategoryId);
  if (cached && cached.expiresAt > Date.now()) return cached.ids;
  const ids = await getMatchingDriverCategoryIds(vehicleCategoryId);
  if (!ids?.length) return null;
  CATEGORY_MATCH_CACHE.set(vehicleCategoryId, { expiresAt: Date.now() + CACHE_TTL_MS, ids });
  return ids;
}

export async function isDispatchServiceAvailableAtLocation(
  serviceType: string,
  pickupLat: number,
  pickupLng: number,
): Promise<boolean> {
  const activeKeys = await getCachedLocationServices(pickupLat, pickupLng);
  const neededKeys = getDispatchServiceKeys(serviceType);
  return neededKeys.some((key) => activeKeys.has(key));
}

export async function driverCanHandleDispatchService(opts: {
  driverId: string;
  serviceType: string;
  pickupLat: number;
  pickupLng: number;
  requestedVehicleCategoryId?: string;
  parcelVehicleCategory?: string;
  requestedSeats?: number;
}): Promise<boolean> {
  const {
    driverId,
    serviceType,
    pickupLat,
    pickupLng,
    requestedVehicleCategoryId,
    parcelVehicleCategory,
    requestedSeats,
  } = opts;

  const [profile, locationServices, matchingCategoryIds] = await Promise.all([
    getCachedDriverProfile(driverId),
    getCachedLocationServices(pickupLat, pickupLng),
    getCachedMatchingCategoryIds(requestedVehicleCategoryId),
  ]);

  const neededServiceKeys = getDispatchServiceKeys(serviceType);
  if (!neededServiceKeys.some((key) => locationServices.has(key))) return false;

  if (matchingCategoryIds?.length) {
    if (!profile.vehicleCategoryId || !matchingCategoryIds.includes(profile.vehicleCategoryId)) {
      return false;
    }
  }

  const compatibleVehicleKeys = getCompatibleVehicleKeys(serviceType);
  if (compatibleVehicleKeys.length > 0 && !compatibleVehicleKeys.includes(profile.vehicleKey)) {
    return false;
  }

  if (parcelVehicleCategory) {
    const neededParcelKey = String(parcelVehicleCategory).toLowerCase();
    if (!profile.parcelVehicles.has(neededParcelKey)) return false;
  }

  if (requestedSeats && requestedSeats > 1) {
    if (profile.seatCapacity <= 0 || profile.seatCapacity < requestedSeats) return false;
  }

  return true;
}
