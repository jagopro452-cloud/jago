/**
 * Unified Mapping Architecture — Production-Grade (Uber/Ola/Porter Level)
 *
 * Extends maps-cache.ts with:
 * 1. Places Autocomplete (with session tokens for cost optimization)
 * 2. Reverse Geocoding (lat/lng → address)
 * 3. Multi-waypoint Directions (for multi-drop parcels)
 * 4. Short Location Name extraction (e.g., "Benz Circle" from full address)
 * 5. Real-time ETA estimation with traffic
 * 6. Address component parsing (area, city, state, pincode)
 * 7. Nearby places search (for POI suggestions)
 *
 * Note: Geocode, Distance, Route caching is handled in maps-cache.ts.
 * This module adds higher-level mapping features used by the app UI.
 */

import { db as rawDb } from "./db";
import { sql as rawSql } from "drizzle-orm";
import { getDistanceWithCache, getRouteWithCache, geocodeWithCache } from "./maps-cache";

// ── Types ────────────────────────────────────────────────────────────────────

export interface PlacePrediction {
  placeId: string;
  mainText: string;        // "Benz Circle"
  secondaryText: string;   // "Vijayawada, Andhra Pradesh"
  fullDescription: string; // "Benz Circle, Vijayawada, Andhra Pradesh, India"
  types: string[];
  lat?: number;
  lng?: number;
}

export interface ReverseGeocodeResult {
  formattedAddress: string;
  shortName: string;        // First locality component
  area: string;
  city: string;
  state: string;
  pincode: string;
  country: string;
}

export interface MultiWaypointRoute {
  legs: Array<{
    originAddress: string;
    destAddress: string;
    distanceKm: number;
    durationMinutes: number;
    polyline: string;
  }>;
  totalDistanceKm: number;
  totalDurationMinutes: number;
  overviewPolyline: string;
  waypointOrder: number[];
}

export interface ETAResult {
  etaMinutes: number;
  distanceKm: number;
  trafficCondition: "light" | "moderate" | "heavy";
  updatedAt: string;
}

export interface NearbyPlace {
  name: string;
  address: string;
  lat: number;
  lng: number;
  type: string;
  distance_km: number;
}

// ── API Key helper (shared with maps-cache) ──────────────────────────────────

let cachedApiKey: string | null = null;
let apiKeyFetchedAt = 0;

async function getGoogleMapsKey(): Promise<string | null> {
  if (cachedApiKey && Date.now() - apiKeyFetchedAt < 5 * 60 * 1000) return cachedApiKey;
  try {
    const r = await rawDb.execute(rawSql`
      SELECT value FROM business_settings WHERE key_name IN ('google_maps_key', 'GOOGLE_MAPS_API_KEY') LIMIT 1
    `);
    const val = (r.rows[0] as any)?.value?.trim();
    if (val) { cachedApiKey = val; apiKeyFetchedAt = Date.now(); return cachedApiKey; }

    const envKey = process.env.GOOGLE_MAPS_API_KEY;
    if (envKey) { cachedApiKey = envKey; apiKeyFetchedAt = Date.now(); return cachedApiKey; }
    
    return cachedApiKey;
  } catch { return cachedApiKey; }
}

// ── In-memory caches for mapping data ────────────────────────────────────────

interface CacheEntry<T> { value: T; expiresAt: number; }

class SimpleCache<T> {
  private cache = new Map<string, CacheEntry<T>>();
  private readonly maxSize: number;
  private readonly ttlMs: number;

  constructor(maxSize: number, ttlMs: number) {
    this.maxSize = maxSize;
    this.ttlMs = ttlMs;
  }

  get(key: string): T | undefined {
    const e = this.cache.get(key);
    if (!e) return undefined;
    if (e.expiresAt < Date.now()) { this.cache.delete(key); return undefined; }
    return e.value;
  }

  set(key: string, value: T): void {
    if (this.cache.size >= this.maxSize) {
      const firstKey = this.cache.keys().next().value;
      if (firstKey !== undefined) this.cache.delete(firstKey);
    }
    this.cache.set(key, { value, expiresAt: Date.now() + this.ttlMs });
  }

  get size(): number { return this.cache.size; }
}

const reverseGeocodeCache = new SimpleCache<ReverseGeocodeResult>(2000, 60 * 60 * 1000);  // 1 hour
const placesCache = new SimpleCache<PlacePrediction[]>(1000, 5 * 60 * 1000);               // 5 min
const etaCache = new SimpleCache<ETAResult>(3000, 2 * 60 * 1000);                          // 2 min

const CURATED_FALLBACK_PLACES: Array<{
  name: string;
  fullAddress: string;
  lat: number;
  lng: number;
  aliases?: string[];
}> = [
  { name: "Benz Circle", fullAddress: "Benz Circle, Vijayawada, Andhra Pradesh, India", lat: 16.5062, lng: 80.648, aliases: ["benz", "benz circle road", "benzcircle", "benz circe", "benzcirce", "benz circel", "benz center"] },
  { name: "Vijayawada Railway Station", fullAddress: "Vijayawada Junction, Vijayawada, Andhra Pradesh, India", lat: 16.5175, lng: 80.64, aliases: ["railway station", "junction", "vijayawada junction"] },
  { name: "Pandit Nehru Bus Station", fullAddress: "PNBS Bus Stand, Vijayawada, Andhra Pradesh, India", lat: 16.5179, lng: 80.6238, aliases: ["pnbs", "bus stand", "bus station"] },
  { name: "Kanaka Durga Temple", fullAddress: "Kanaka Durga Temple, Vijayawada, Andhra Pradesh, India", lat: 16.5176, lng: 80.6121, aliases: ["durga temple", "kanakadurga"] },
  { name: "Gannavaram Airport", fullAddress: "Vijayawada International Airport, Gannavaram, Andhra Pradesh, India", lat: 16.5304, lng: 80.7968, aliases: ["airport", "vijayawada airport", "gannavaram"] },
  { name: "Governorpet", fullAddress: "Governorpet, Vijayawada, Andhra Pradesh, India", lat: 16.5135, lng: 80.6346, aliases: ["governor pet"] },
  { name: "Patamata", fullAddress: "Patamata, Vijayawada, Andhra Pradesh, India", lat: 16.4883, lng: 80.6681, aliases: ["patamata center", "patamata circle"] },
  { name: "M G Road", fullAddress: "M G Road, Vijayawada, Andhra Pradesh, India", lat: 16.5069, lng: 80.6489, aliases: ["mg road", "bandar road"] },
  { name: "Auto Nagar", fullAddress: "Auto Nagar, Vijayawada, Andhra Pradesh, India", lat: 16.4947, lng: 80.6907, aliases: ["autonagar"] },
  { name: "Poranki", fullAddress: "Poranki, Vijayawada, Andhra Pradesh, India", lat: 16.4741, lng: 80.7151, aliases: ["poranki center"] },
  { name: "One Town", fullAddress: "One Town, Vijayawada, Andhra Pradesh, India", lat: 16.5217, lng: 80.6185, aliases: ["1 town", "old city"] },
  { name: "Bhavanipuram", fullAddress: "Bhavanipuram, Vijayawada, Andhra Pradesh, India", lat: 16.5104, lng: 80.5989, aliases: ["bhavani puram"] },
  { name: "Labbipet", fullAddress: "Labbipet, Vijayawada, Andhra Pradesh, India", lat: 16.5034, lng: 80.6488, aliases: ["labbipeta"] },
  { name: "Moghalrajpuram", fullAddress: "Moghalrajpuram, Vijayawada, Andhra Pradesh, India", lat: 16.5057, lng: 80.6465, aliases: ["mogalrajpuram"] },
  { name: "Currency Nagar", fullAddress: "Currency Nagar, Vijayawada, Andhra Pradesh, India", lat: 16.4928, lng: 80.6689, aliases: ["currency nagar"] },
  { name: "Siddhartha Nagar", fullAddress: "Siddhartha Nagar, Vijayawada, Andhra Pradesh, India", lat: 16.4968, lng: 80.6502, aliases: ["siddartha nagar"] },
  { name: "NTR Circle", fullAddress: "NTR Circle, Vijayawada, Andhra Pradesh, India", lat: 16.5065, lng: 80.6443, aliases: ["ntr center"] },
  { name: "Krishna Lanka", fullAddress: "Krishna Lanka, Vijayawada, Andhra Pradesh, India", lat: 16.501, lng: 80.6117, aliases: ["krishnalanka"] },
];

const DEFAULT_SEARCH_CENTER = { lat: 16.5062, lng: 80.6480 };

function normalizePlaceSearchText(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9\s]/g, " ").replace(/\s+/g, " ").trim();
}

function scoreTextMatch(query: string, candidate: string): number {
  const normalizedQuery = normalizePlaceSearchText(query);
  const normalizedCandidate = normalizePlaceSearchText(candidate);
  if (!normalizedQuery || !normalizedCandidate) return 0;

  let score = 0;
  if (normalizedCandidate === normalizedQuery) score += 120;
  if (normalizedCandidate.startsWith(normalizedQuery)) score += 90;
  if (normalizedCandidate.includes(` ${normalizedQuery}`)) score += 70;
  else if (normalizedCandidate.includes(normalizedQuery)) score += 50;

  const tokens = normalizedQuery.split(/\s+/).filter(Boolean);
  let matchedTokens = 0;
  for (const token of tokens) {
    if (normalizedCandidate === token) score += 24;
    else if (normalizedCandidate.startsWith(token)) score += 18;
    else if (normalizedCandidate.includes(` ${token}`)) score += 14;
    else if (normalizedCandidate.includes(token)) score += 8;
    if (normalizedCandidate.includes(token)) matchedTokens++;
  }

  if (tokens.length > 1 && matchedTokens === tokens.length) score += 30;
  return score;
}

function scoreDistanceBias(lat: number | undefined, lng: number | undefined, placeLat?: number, placeLng?: number): number {
  if (!lat || !lng || !placeLat || !placeLng) return 0;
  const distanceKm = Math.sqrt(Math.pow(lat - placeLat, 2) + Math.pow(lng - placeLng, 2)) * 111;
  if (distanceKm <= 3) return 20;
  if (distanceKm <= 8) return 12;
  if (distanceKm <= 20) return 6;
  return 0;
}

function scorePredictionForQuery(query: string, prediction: PlacePrediction, lat?: number, lng?: number): number {
  let score = 0;
  score += scoreTextMatch(query, prediction.mainText) * 2;
  score += scoreTextMatch(query, prediction.fullDescription);
  score += scoreTextMatch(query, prediction.secondaryText);
  score += scoreDistanceBias(lat, lng, prediction.lat, prediction.lng);
  if (prediction.types.includes("popular_location")) score += 12;
  if (prediction.types.includes("curated_fallback")) score += 26;
  const normalizedDescription = normalizePlaceSearchText(prediction.fullDescription);
  if (normalizedDescription.includes("vijayawada")) score += 28;
  if (normalizedDescription.includes("andhra pradesh")) score += 8;
  if (normalizedDescription.includes("india")) score += 3;
  return score;
}

function rankPredictions(query: string, predictions: PlacePrediction[], lat?: number, lng?: number): PlacePrediction[] {
  const deduped = new Map<string, PlacePrediction>();
  for (const prediction of predictions) {
    const key = normalizePlaceSearchText(prediction.fullDescription || `${prediction.mainText} ${prediction.secondaryText}`);
    const existing = deduped.get(key);
    if (!existing) {
      deduped.set(key, prediction);
      continue;
    }
    const existingScore = scorePredictionForQuery(query, existing, lat, lng);
    const newScore = scorePredictionForQuery(query, prediction, lat, lng);
    if (newScore > existingScore || (!existing.lat && prediction.lat)) {
      deduped.set(key, prediction);
    }
  }

  return Array.from(deduped.values())
    .map((prediction) => ({ prediction, score: scorePredictionForQuery(query, prediction, lat, lng) }))
    .filter((entry) => entry.score > 0)
    .sort((a, b) => b.score - a.score || a.prediction.mainText.localeCompare(b.prediction.mainText))
    .slice(0, 10)
    .map((entry) => entry.prediction);
}

function searchCuratedFallbackLocations(query: string, lat?: number, lng?: number): PlacePrediction[] {
  const normalized = normalizePlaceSearchText(query);
  if (!normalized) return [];

  const scored = CURATED_FALLBACK_PLACES.map((place) => {
    const haystacks = [place.name, place.fullAddress, ...(place.aliases || [])];
    let score = Math.max(...haystacks.map((candidate) => scoreTextMatch(normalized, candidate)));
    score += scoreDistanceBias(lat, lng, place.lat, place.lng);
    return { place, score };
  })
    .filter((entry) => entry.score > 0)
    .sort((a, b) => b.score - a.score || a.place.name.localeCompare(b.place.name))
    .slice(0, 8);

  return scored.map(({ place }) => ({
    placeId: `curated:${place.name.toLowerCase().replace(/\s+/g, "-")}`,
    mainText: place.name,
    secondaryText: place.fullAddress.replace(`${place.name}, `, ""),
    fullDescription: place.fullAddress,
    description: place.fullAddress,
    types: ["curated_fallback"],
    lat: place.lat,
    lng: place.lng,
  }));
}

// ── 1. PLACES AUTOCOMPLETE ──────────────────────────────────────────────────

/**
 * Search places with Google Places Autocomplete.
 * Uses session tokens to group autocomplete+select into one billing session.
 * Falls back to DB popular locations if API unavailable.
 */
export async function searchPlaces(
  query: string,
  sessionToken?: string,
  lat?: number,
  lng?: number,
  radius?: number
): Promise<PlacePrediction[]> {
  if (!query || query.length < 2) return [];

  const cacheKey = `places:${query.toLowerCase().trim()}:${lat?.toFixed(2)}:${lng?.toFixed(2)}`;
  const cached = placesCache.get(cacheKey);
  if (cached) return cached;

  const apiKey = await getGoogleMapsKey();
  if (!apiKey) {
    const localResults = await searchPopularLocations(query);
    const nomResults = await searchNominatimFallback(query, lat, lng, radius);
    return rankPredictions(query, [...nomResults, ...localResults, ...searchCuratedFallbackLocations(query, lat, lng)], lat, lng);
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 4000);

  try {
    let url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(query)}&key=${apiKey}&components=country:in&language=en&region=in`;

    if (lat && lng) {
      url += `&location=${lat},${lng}&radius=${radius || 50000}`;
    }
    if (sessionToken) {
      url += `&sessiontoken=${encodeURIComponent(sessionToken)}`;
    }

    console.log(`[mapping] Fetching from Google: ${url.replace(apiKey, "REDACTED")}`);
    const r = await fetch(url, { 
      signal: controller.signal,
      headers: { 'Referer': 'https://jagopro.org' }
    });
    if (!r.ok) {
        console.error(`[mapping] Google API returned status ${r.status}`);
        const localResults = await searchPopularLocations(query);
        const nomResults = await searchNominatimFallback(query, lat, lng, radius);
        return rankPredictions(query, [...nomResults, ...localResults, ...searchCuratedFallbackLocations(query, lat, lng)], lat, lng);
    }
    const data = await r.json() as any;
    console.log(`[mapping] Google response status: ${data.status}`);

    if (data?.status !== "OK") {
      console.warn(`[mapping-unified:searchPlaces] Google API Status: ${data?.status}, Msg: ${data?.error_message || 'none'}. Falling back to Nominatim/Local.`);
      const nomResults = await searchNominatimFallback(query, lat, lng, radius);
      if (nomResults.length > 0) {
        return rankPredictions(query, [...nomResults, ...searchCuratedFallbackLocations(query, lat, lng)], lat, lng);
      }
      const localResults = await searchPopularLocations(query);
      return rankPredictions(query, [...localResults, ...searchCuratedFallbackLocations(query, lat, lng)], lat, lng);
    }

    if (!data.predictions?.length) {
      console.log(`[mapping-unified:searchPlaces] Google returned 0 results. Trying Nominatim fallback.`);
      return rankPredictions(query, [...await searchNominatimFallback(query, lat, lng, radius), ...searchCuratedFallbackLocations(query, lat, lng)], lat, lng);
    }

    const results: PlacePrediction[] = data.predictions.map((p: any) => ({
      placeId: p.place_id,
      mainText: p.structured_formatting?.main_text || p.description?.split(",")[0] || "",
      secondaryText: p.structured_formatting?.secondary_text || "",
      fullDescription: p.description || "",
      description: p.description || "", // Backward compatibility
      types: p.types || [],
    }));

    const localResults = await searchPopularLocations(query);
    const nomResults = query.trim().length >= 4
      ? await searchNominatimFallback(query, lat, lng, radius)
      : [];
    const rankedResults = rankPredictions(
      query,
      [...results, ...nomResults, ...localResults, ...searchCuratedFallbackLocations(query, lat, lng)],
      lat,
      lng,
    );
    placesCache.set(cacheKey, rankedResults);
    return rankedResults;
  } catch (e: any) {
    console.error(`[mapping-unified:searchPlaces] Failed:`, e.message || e);
    const nomResults = await searchNominatimFallback(query, lat, lng, radius);
    if (nomResults.length > 0) return rankPredictions(query, [...nomResults, ...searchCuratedFallbackLocations(query, lat, lng)], lat, lng);
    const localResults = await searchPopularLocations(query);
    return rankPredictions(query, [...localResults, ...searchCuratedFallbackLocations(query, lat, lng)], lat, lng);
  } finally {
    clearTimeout(timeout);
  }
}

function buildSearchViewbox(lat?: number, lng?: number, radiusMeters?: number): string {
  const centerLat = lat || DEFAULT_SEARCH_CENTER.lat;
  const centerLng = lng || DEFAULT_SEARCH_CENTER.lng;
  const radiusKm = Math.max(8, Math.min(35, (radiusMeters || 25000) / 1000));
  const latDelta = radiusKm / 111;
  const lngDelta = radiusKm / (111 * Math.cos((centerLat * Math.PI) / 180) || 1);
  const west = (centerLng - lngDelta).toFixed(5);
  const north = (centerLat + latDelta).toFixed(5);
  const east = (centerLng + lngDelta).toFixed(5);
  const south = (centerLat - latDelta).toFixed(5);
  return `${west},${north},${east},${south}`;
}

async function searchNominatimFallback(query: string, lat?: number, lng?: number, radius?: number): Promise<PlacePrediction[]> {
  try {
    const nomController = new AbortController();
    const nomTimeout = setTimeout(() => nomController.abort(), 4000);
    const viewbox = buildSearchViewbox(lat, lng, radius);
    const nomUrl =
      `https://nominatim.openstreetmap.org/search?format=jsonv2&q=${encodeURIComponent(query)}` +
      `&limit=15&addressdetails=1&countrycodes=in&dedupe=1&bounded=1&viewbox=${encodeURIComponent(viewbox)}`;
    
    const nr = await fetch(nomUrl, {
      signal: nomController.signal,
      headers: { "User-Agent": "JagoPro/1.0 (ride-hailing app)" }
    });
    
    clearTimeout(nomTimeout);
    
    if (nr.ok) {
      const nd = await nr.json() as any[];
      if (Array.isArray(nd) && nd.length > 0) {
        const results: PlacePrediction[] = nd.map((p: any) => {
          const parts = (p.display_name || "").split(",");
          const main = p.name || parts[0];
          const sec = parts.slice(1).join(",").trim();
          const fullDescription = p.display_name || "";
          return {
            placeId: `nom:${p.place_id}`,
            mainText: main,
            secondaryText: sec,
            fullDescription,
            description: fullDescription, // Backward compatibility
            types: [p.type || "point_of_interest"],
            lat: parseFloat(p.lat) || 0,
            lng: parseFloat(p.lon) || 0,
          };
        });
        
        // Deduplicate nominatim results by mainText
        const unique = new Map<string, PlacePrediction>();
        for (const res of results) {
          const key = (res.mainText + res.secondaryText).toLowerCase();
          if (!unique.has(key)) unique.set(key, res);
        }
        return Array.from(unique.values()).slice(0, 8);
      }
    }
  } catch(e) {
    console.error("[mapping-unified] Nominatim fallback failed:", e);
  }
  const localResults = await searchPopularLocations(query);
  return rankPredictions(query, [...localResults, ...searchCuratedFallbackLocations(query, lat, lng)], lat, lng);
}

/**
 * Get place details (lat/lng) from place_id.
 * This is the step after autocomplete selection — billed together with session token.
 */
export async function getPlaceDetails(
  placeId: string,
  sessionToken?: string
): Promise<{ lat: number; lng: number; address: string; shortName: string } | null> {
  if (placeId.startsWith("curated:")) {
    const slug = placeId.replace("curated:", "");
    const match = CURATED_FALLBACK_PLACES.find((place) => place.name.toLowerCase().replace(/\s+/g, "-") === slug);
    if (match) {
      return {
        lat: match.lat,
        lng: match.lng,
        address: match.fullAddress,
        shortName: match.name,
      };
    }
  }

  if (placeId.startsWith("local:")) {
    const localName = placeId.replace("local:", "").trim();
    try {
      const r = await rawDb.execute(rawSql`
        SELECT name, full_address, latitude, longitude
        FROM popular_locations
        WHERE LOWER(name) = ${localName.toLowerCase()}
        LIMIT 1
      `);
      const row = r.rows[0] as any;
      if (row) {
        return {
          lat: parseFloat(String(row.latitude)) || 0,
          lng: parseFloat(String(row.longitude)) || 0,
          address: `${row.name}, ${row.full_address || ""}`.replace(/,\s*$/, ""),
          shortName: row.name || extractShortName(row.full_address || ""),
        };
      }
    } catch {}
  }

  const apiKey = await getGoogleMapsKey();
  if (!apiKey) return null;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 4000);

  try {
    let url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${encodeURIComponent(placeId)}&fields=geometry,formatted_address,name,address_components&key=${apiKey}`;
    if (sessionToken) url += `&sessiontoken=${encodeURIComponent(sessionToken)}`;

    const r = await fetch(url, { 
      signal: controller.signal,
      headers: { 'Referer': 'https://jagopro.org' }
    });
    if (!r.ok) return null;
    const data = await r.json() as any;

    if (data?.status !== "OK" || !data.result?.geometry?.location) return null;

    const loc = data.result.geometry.location;
    return {
      lat: Number(loc.lat),
      lng: Number(loc.lng),
      address: data.result.formatted_address || "",
      shortName: data.result.name || extractShortName(data.result.formatted_address || ""),
    };
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

// Fallback: search popular_locations table
async function searchPopularLocations(query: string): Promise<PlacePrediction[]> {
  try {
    const r = await rawDb.execute(rawSql`
      SELECT DISTINCT name, full_address, latitude, longitude
      FROM popular_locations
      WHERE is_active = true
        AND (LOWER(name) LIKE ${"%" + query.toLowerCase() + "%"}
             OR LOWER(full_address) LIKE ${"%" + query.toLowerCase() + "%"})
      ORDER BY name ASC
      LIMIT 10
    `);
    const rawResults = r.rows.map((row: any) => ({
      placeId: `local:${row.name}`,
      mainText: row.name,
      secondaryText: row.full_address || "",
      fullDescription: `${row.name}, ${row.full_address || ""}`,
      description: `${row.name}, ${row.full_address || ""}`, // Backward compatibility
      types: ["popular_location"],
      lat: parseFloat(String(row.latitude)) || 0,
      lng: parseFloat(String(row.longitude)) || 0,
    }));

    // Deduplicate by name to prevent multiple results for the same location
    const unique = new Map<string, PlacePrediction>();
    for (const res of rawResults) {
      if (!unique.has(res.mainText.toLowerCase())) {
        unique.set(res.mainText.toLowerCase(), res);
      }
    }
    return Array.from(unique.values());
  } catch {
    return searchCuratedFallbackLocations(query);
  }
}

// ── 2. REVERSE GEOCODING ────────────────────────────────────────────────────

/**
 * Convert lat/lng to address with component parsing.
 * Memory cache → DB cache → Google API
 */
export async function reverseGeocode(
  lat: number,
  lng: number
): Promise<ReverseGeocodeResult | null> {
  const key = `rev:${lat.toFixed(5)},${lng.toFixed(5)}`;

  // Layer 1: Memory
  const cached = reverseGeocodeCache.get(key);
  if (cached) return cached;

  // Layer 2: DB
  try {
    const dbr = await rawDb.execute(rawSql`
      SELECT data_json FROM maps_cache
      WHERE cache_type = 'reverse_geocode'
        AND cache_key = ${key}
        AND expires_at > NOW()
      LIMIT 1
    `);
    if (dbr.rows.length) {
      const parsed = typeof (dbr.rows[0] as any).data_json === "string"
        ? JSON.parse((dbr.rows[0] as any).data_json)
        : (dbr.rows[0] as any).data_json;
      reverseGeocodeCache.set(key, parsed);
      return parsed;
    }
  } catch {}

  // Layer 3: Google API
  const apiKey = await getGoogleMapsKey();
  if (apiKey) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 4000);
    try {
      const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lng}&key=${apiKey}`;
      const r = await fetch(url, { 
      signal: controller.signal,
      headers: { 'Referer': 'https://jagopro.org' }
    });
      if (r.ok) {
        const data = await r.json() as any;
        if (data?.status === "OK" && data.results?.length) {
          const top = data.results[0];
          const components = top.address_components || [];
          const result: ReverseGeocodeResult = {
            formattedAddress: top.formatted_address || "",
            shortName: extractShortName(top.formatted_address || ""),
            area: findComponent(components, "sublocality_level_1", "sublocality", "neighborhood") || "",
            city: findComponent(components, "locality", "administrative_area_level_2") || "",
            state: findComponent(components, "administrative_area_level_1") || "",
            pincode: findComponent(components, "postal_code") || "",
            country: findComponent(components, "country") || "India",
          };
          reverseGeocodeCache.set(key, result);
          rawDb.execute(rawSql`
            INSERT INTO maps_cache (cache_type, cache_key, lat, lng, formatted_address, data_json, expires_at)
            VALUES ('reverse_geocode', ${key}, ${lat}, ${lng}, ${result.formattedAddress}, ${JSON.stringify(result)}::jsonb, NOW() + INTERVAL '60 minutes')
            ON CONFLICT (cache_type, cache_key) DO UPDATE SET
              data_json = EXCLUDED.data_json, expires_at = EXCLUDED.expires_at, updated_at = NOW()
          `).catch(() => {});
          return result;
        }
      }
    } catch {}
    finally { clearTimeout(timeout); }
  }

  // Layer 4: Nominatim fallback (free, no key required)
  try {
    const nomController = new AbortController();
    const nomTimeout = setTimeout(() => nomController.abort(), 4000);
    try {
      const nomUrl = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&addressdetails=1`;
      const nr = await fetch(nomUrl, {
        signal: nomController.signal,
        headers: { "User-Agent": "JagoPro/1.0 (ride-hailing app)" },
      });
      if (nr.ok) {
        const nd = await nr.json() as any;
        if (nd?.display_name) {
          const addr = nd.address || {};
          const result: ReverseGeocodeResult = {
            formattedAddress: nd.display_name,
            shortName: addr.suburb || addr.neighbourhood || addr.city || addr.town || "",
            area: addr.suburb || addr.neighbourhood || addr.quarter || "",
            city: addr.city || addr.town || addr.village || addr.county || "",
            state: addr.state || "",
            pincode: addr.postcode || "",
            country: addr.country || "India",
          };
          reverseGeocodeCache.set(key, result);
          return result;
        }
      }
    } finally { clearTimeout(nomTimeout); }
  } catch {}

  return null;
}

function findComponent(components: any[], ...types: string[]): string {
  for (const type of types) {
    const c = components.find((c: any) => c.types?.includes(type));
    if (c) return c.long_name || c.short_name || "";
  }
  return "";
}

// ── 3. SHORT LOCATION NAME EXTRACTION ───────────────────────────────────────

/**
 * Extract a short, human-friendly name from a full address.
 * "Near Benz Circle, MG Road, Vijayawada, AP 520010" → "Benz Circle"
 */
export function extractShortName(fullAddress: string): string {
  if (!fullAddress) return "";
  const parts = fullAddress.split(",").map((s) => s.trim()).filter(Boolean);
  if (!parts.length) return fullAddress;

  // Remove generic prefixes
  let first = parts[0]
    .replace(/^(near|opp|opposite|beside|behind|in front of|next to)\s+/i, "")
    .replace(/^\d+[\s,/-]+/, ""); // Remove house numbers

  // If too long, truncate
  if (first.length > 40) first = first.substring(0, 40).trim();

  return first || parts[0];
}

// ── 4. MULTI-WAYPOINT DIRECTIONS ────────────────────────────────────────────

/**
 * Get directions with multiple waypoints (for multi-drop parcels).
 * Supports waypoint optimization (reordering for shortest route).
 */
export async function getMultiWaypointRoute(
  origin: { lat: number; lng: number },
  destination: { lat: number; lng: number },
  waypoints: Array<{ lat: number; lng: number }>,
  optimize: boolean = true
): Promise<MultiWaypointRoute | null> {
  // If no waypoints, use simple route
  if (!waypoints.length) {
    const route = await getRouteWithCache(origin.lat, origin.lng, destination.lat, destination.lng);
    if (!route) return null;
    return {
      legs: [{
        originAddress: "",
        destAddress: "",
        distanceKm: route.distanceKm,
        durationMinutes: route.durationMinutes,
        polyline: route.polyline,
      }],
      totalDistanceKm: route.distanceKm,
      totalDurationMinutes: route.durationMinutes,
      overviewPolyline: route.polyline,
      waypointOrder: [],
    };
  }

  const apiKey = await getGoogleMapsKey();
  if (!apiKey) {
    // Haversine fallback for multi-waypoint
    return haversineMultiRoute(origin, destination, waypoints);
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 8000);

  try {
    const wpParam = waypoints
      .map((w) => `${w.lat},${w.lng}`)
      .join("|");
    const optimizeParam = optimize ? "optimize:true|" : "";

    const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${origin.lat},${origin.lng}&destination=${destination.lat},${destination.lng}&waypoints=${optimizeParam}${wpParam}&key=${apiKey}`;
    const r = await fetch(url, { 
      signal: controller.signal,
      headers: { 'Referer': 'https://jagopro.org' }
    });
    if (!r.ok) return haversineMultiRoute(origin, destination, waypoints);
    const data = await r.json() as any;

    if (data?.status !== "OK" || !data.routes?.length) {
      return haversineMultiRoute(origin, destination, waypoints);
    }

    const route = data.routes[0];
    const legs = (route.legs || []).map((leg: any) => ({
      originAddress: leg.start_address || "",
      destAddress: leg.end_address || "",
      distanceKm: Math.round((leg.distance?.value || 0) / 1000 * 100) / 100,
      durationMinutes: Math.round((leg.duration?.value || 0) / 60),
      polyline: leg.steps?.map((s: any) => s.polyline?.points || "").join("") || "",
    }));

    const totalDist = legs.reduce((sum: number, l: any) => sum + l.distanceKm, 0);
    const totalDur = legs.reduce((sum: number, l: any) => sum + l.durationMinutes, 0);

    return {
      legs,
      totalDistanceKm: Math.round(totalDist * 100) / 100,
      totalDurationMinutes: totalDur,
      overviewPolyline: route.overview_polyline?.points || "",
      waypointOrder: route.waypoint_order || [],
    };
  } catch {
    return haversineMultiRoute(origin, destination, waypoints);
  } finally {
    clearTimeout(timeout);
  }
}

function haversineMultiRoute(
  origin: { lat: number; lng: number },
  destination: { lat: number; lng: number },
  waypoints: Array<{ lat: number; lng: number }>
): MultiWaypointRoute {
  const haversineKm = (lat1: number, lng1: number, lat2: number, lng2: number) => {
    const R = 6371;
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLng = (lng2 - lng1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) ** 2 + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLng / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  };

  const allPoints = [origin, ...waypoints, destination];
  const legs = [];
  let totalDist = 0;
  let totalDur = 0;

  for (let i = 0; i < allPoints.length - 1; i++) {
    const d = haversineKm(allPoints[i].lat, allPoints[i].lng, allPoints[i + 1].lat, allPoints[i + 1].lng);
    const dur = Math.round((d / 25) * 60);
    legs.push({
      originAddress: "",
      destAddress: "",
      distanceKm: Math.round(d * 100) / 100,
      durationMinutes: dur,
      polyline: "",
    });
    totalDist += d;
    totalDur += dur;
  }

  return {
    legs,
    totalDistanceKm: Math.round(totalDist * 100) / 100,
    totalDurationMinutes: totalDur,
    overviewPolyline: "",
    waypointOrder: waypoints.map((_, i) => i),
  };
}

// ── 5. REAL-TIME ETA ────────────────────────────────────────────────────────

/**
 * Calculate real-time ETA with traffic consideration.
 * Uses Google Distance Matrix with departure_time for traffic data.
 */
export async function getRealTimeETA(
  driverLat: number,
  driverLng: number,
  destLat: number,
  destLng: number
): Promise<ETAResult> {
  const key = `eta:${driverLat.toFixed(3)},${driverLng.toFixed(3)}:${destLat.toFixed(3)},${destLng.toFixed(3)}`;

  // Short TTL cache
  const cached = etaCache.get(key);
  if (cached) return cached;

  const apiKey = await getGoogleMapsKey();
  if (!apiKey) {
    // Haversine fallback
    const dist = haversineKm(driverLat, driverLng, destLat, destLng);
    const eta = Math.round((dist / 25) * 60);
    return { etaMinutes: eta, distanceKm: Math.round(dist * 100) / 100, trafficCondition: "moderate", updatedAt: new Date().toISOString() };
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 4000);

  try {
    const url = `https://maps.googleapis.com/maps/api/distancematrix/json?origins=${driverLat},${driverLng}&destinations=${destLat},${destLng}&departure_time=now&traffic_model=best_guess&key=${apiKey}`;
    const r = await fetch(url, { 
      signal: controller.signal,
      headers: { 'Referer': 'https://jagopro.org' }
    });
    if (!r.ok) throw new Error("API failed");
    const data = await r.json() as any;
    const el = data?.rows?.[0]?.elements?.[0];

    if (el?.status !== "OK") throw new Error("No result");

    const distKm = Math.round((el.distance.value / 1000) * 100) / 100;
    const durationInTrafficSec = el.duration_in_traffic?.value || el.duration.value;
    const normalDurationSec = el.duration.value;
    const etaMin = Math.round(durationInTrafficSec / 60);

    // Determine traffic condition
    const trafficRatio = durationInTrafficSec / normalDurationSec;
    const condition = trafficRatio < 1.15 ? "light" : trafficRatio < 1.4 ? "moderate" : "heavy";

    const result: ETAResult = {
      etaMinutes: etaMin,
      distanceKm: distKm,
      trafficCondition: condition as "light" | "moderate" | "heavy",
      updatedAt: new Date().toISOString(),
    };

    etaCache.set(key, result);
    return result;
  } catch {
    const dist = haversineKm(driverLat, driverLng, destLat, destLng);
    return { etaMinutes: Math.round((dist / 25) * 60), distanceKm: Math.round(dist * 100) / 100, trafficCondition: "moderate", updatedAt: new Date().toISOString() };
  } finally {
    clearTimeout(timeout);
  }
}

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ── 6. NEARBY PLACES SEARCH ─────────────────────────────────────────────────

/**
 * Search for nearby places (gas stations, restaurants, etc.)
 */
export async function searchNearbyPlaces(
  lat: number,
  lng: number,
  type: string = "point_of_interest",
  radius: number = 2000
): Promise<NearbyPlace[]> {
  const apiKey = await getGoogleMapsKey();
  if (!apiKey) return [];

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);

  try {
    const url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=${radius}&type=${encodeURIComponent(type)}&key=${apiKey}`;
    const r = await fetch(url, { signal: controller.signal });
    if (!r.ok) return [];
    const data = await r.json() as any;
    if (data?.status !== "OK") return [];

    return (data.results || []).slice(0, 15).map((p: any) => ({
      name: p.name || "",
      address: p.vicinity || "",
      lat: p.geometry?.location?.lat || 0,
      lng: p.geometry?.location?.lng || 0,
      type: (p.types || [])[0] || type,
      distance_km: haversineKm(lat, lng, p.geometry?.location?.lat || 0, p.geometry?.location?.lng || 0),
    }));
  } catch {
    return [];
  } finally {
    clearTimeout(timeout);
  }
}

// ── 7. MAPPING STATS ────────────────────────────────────────────────────────

export function getMappingStats() {
  return {
    reverseGeocodeCache: reverseGeocodeCache.size,
    placesCache: placesCache.size,
    etaCache: etaCache.size,
  };
}
