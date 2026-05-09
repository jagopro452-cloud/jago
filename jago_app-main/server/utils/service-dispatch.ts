import { getDriverEligibleServices, getServicesForLocation } from "../dynamic-services";

const DRIVER_SERVICE_CACHE = new Map<string, { expiresAt: number; services: Set<string>; parcelVehicles: Set<string> }>();
const LOCATION_SERVICE_CACHE = new Map<string, { expiresAt: number; services: Set<string> }>();
const CACHE_TTL_MS = 30_000;

const DISPATCH_SERVICE_KEYS: Record<string, string[]> = {
  bike: ["bike_ride"],
  bike_ride: ["bike_ride"],
  auto: ["auto_ride"],
  auto_ride: ["auto_ride"],
  mini: ["mini_car"],
  mini_car: ["mini_car"],
  sedan: ["sedan"],
  suv: ["suv"],
  premium: ["premium"],
  cab: ["mini_car", "sedan", "suv", "premium"],
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
};

export function getDispatchServiceKeys(serviceType: string): string[] {
  return DISPATCH_SERVICE_KEYS[String(serviceType || "").toLowerCase()] || ["auto_ride"];
}

async function getCachedDriverEligibility(driverId: string) {
  const cached = DRIVER_SERVICE_CACHE.get(driverId);
  if (cached && cached.expiresAt > Date.now()) return cached;

  const eligibility = await getDriverEligibleServices(driverId);
  const services = new Set((eligibility.services || []).map((svc) => String(svc.key || "").toLowerCase()).filter(Boolean));
  const parcelVehicles = new Set((eligibility.parcelVehicles || []).map((svc) => String(svc.key || "").toLowerCase()).filter(Boolean));
  const entry = { expiresAt: Date.now() + CACHE_TTL_MS, services, parcelVehicles };
  DRIVER_SERVICE_CACHE.set(driverId, entry);
  return entry;
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
  parcelVehicleCategory?: string;
}): Promise<boolean> {
  const { driverId, serviceType, pickupLat, pickupLng, parcelVehicleCategory } = opts;
  const [driverEligibility, locationServices] = await Promise.all([
    getCachedDriverEligibility(driverId),
    getCachedLocationServices(pickupLat, pickupLng),
  ]);

  const neededServiceKeys = getDispatchServiceKeys(serviceType);
  const serviceEnabledAtLocation = neededServiceKeys.some((key) => locationServices.has(key));
  if (!serviceEnabledAtLocation) return false;

  const driverSupportsService = neededServiceKeys.some((key) => driverEligibility.services.has(key));
  if (!driverSupportsService) return false;

  if (parcelVehicleCategory) {
    return driverEligibility.parcelVehicles.has(String(parcelVehicleCategory).toLowerCase());
  }

  return true;
}
