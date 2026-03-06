export interface ServiceHealth {
  service: string;
  status: "ok" | "degraded" | "down";
  timestamp: string;
}

export type MobilityServiceType =
  | "bike"
  | "auto"
  | "car"
  | "parcel"
  | "car_sharing"
  | "intercity"
  | "hyperlocal";

export interface BookingIntent {
  serviceType: MobilityServiceType;
  pickupLat: number;
  pickupLng: number;
  destinationLat?: number;
  destinationLng?: number;
  vehicleCategoryId?: string;
}

export interface UnifiedBookingRequest {
  serviceType: MobilityServiceType;
  customerId: string;
  pickupAddress: string;
  pickupLat: number;
  pickupLng: number;
  destinationAddress?: string;
  destinationLat?: number;
  destinationLng?: number;
  paymentMethod?: "cash" | "wallet" | "online";
  vehicleCategoryId?: string;
  passengers?: number;
  seatsBooked?: number;
  routeId?: string;
  scheduledAt?: string;
  receiverName?: string;
  receiverPhone?: string;
  parcelType?: string;
  parcelWeight?: string;
}

export interface UnifiedBookingEstimate {
  serviceType: MobilityServiceType;
  distanceKm: number;
  etaMinutes: number;
  estimatedFare: number;
  surgeMultiplier: number;
  currency: "INR";
}

export interface DriverCandidate {
  driverId: string;
  score: number;
  distanceKm: number;
  etaMinutes: number;
  rating?: number;
  acceptanceRate?: number;
  activeTrips?: number;
}

export interface DispatchDecision {
  requestId: string;
  serviceType: MobilityServiceType;
  candidates: DriverCandidate[];
  selectedDriverId?: string;
  acceptanceDeadlineEpochMs: number;
  strategy: "distance_rating_load_balanced_v1";
}

export interface DriverLocationUpdate {
  driverId: string;
  lat: number;
  lng: number;
  speedKmph?: number;
  heading?: number;
  accuracyMeters?: number;
  ts?: string;
}

export interface FraudFlag {
  entityType: "customer" | "driver" | "trip";
  entityId: string;
  riskScore: number;
  reason: string;
  action: "review" | "block" | "challenge_otp";
  createdAt: string;
}

export interface DemandZone {
  zoneId: string;
  lat: number;
  lng: number;
  city: string;
  demandScore: number;
  surgeMultiplier: number;
  recommendation: string;
}
