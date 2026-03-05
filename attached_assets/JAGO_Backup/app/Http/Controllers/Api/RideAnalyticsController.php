<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

class RideAnalyticsController extends Controller
{
    public function overview(Request $request): JsonResponse
    {
        $days = min($request->get('days', 30), 365);
        $zoneId = $request->get('zone_id');

        $cacheKey = "analytics_overview_{$days}_{$zoneId}";
        $data = Cache::remember($cacheKey, 600, function () use ($days, $zoneId) {
            $since = now()->subDays($days);

            $baseQuery = DB::table('trip_requests')->where('created_at', '>=', $since);
            if ($zoneId) $baseQuery->where('zone_id', $zoneId);

            $totalTrips = (clone $baseQuery)->count();
            $completedTrips = (clone $baseQuery)->where('current_status', 'completed')->count();
            $cancelledTrips = (clone $baseQuery)->where('current_status', 'cancelled')->count();
            $totalRevenue = (clone $baseQuery)->where('current_status', 'completed')->sum('paid_fare');
            $avgFare = (clone $baseQuery)->where('current_status', 'completed')->avg('paid_fare');
            $avgDistance = (clone $baseQuery)->where('current_status', 'completed')->avg('actual_distance');

            $rideTrips = (clone $baseQuery)->where('type', 'ride_request')->count();
            $parcelTrips = (clone $baseQuery)->where('type', 'parcel')->count();

            $activeDrivers = DB::table('driver_details')
                ->where('is_online', 'true')
                ->where('is_suspended', 0)
                ->count();

            $totalDrivers = DB::table('driver_details')
                ->where('is_suspended', 0)
                ->count();

            $totalCustomers = DB::table('users')
                ->where('user_type', 'customer')
                ->whereNull('deleted_at')
                ->count();

            return [
                'period_days' => $days,
                'trips' => [
                    'total' => $totalTrips,
                    'completed' => $completedTrips,
                    'cancelled' => $cancelledTrips,
                    'completion_rate' => $totalTrips > 0 ? round(($completedTrips / $totalTrips) * 100, 1) : 0,
                    'rides' => $rideTrips,
                    'parcels' => $parcelTrips,
                ],
                'revenue' => [
                    'total' => round((float) $totalRevenue, 2),
                    'average_fare' => round((float) $avgFare, 2),
                    'average_distance_km' => round((float) $avgDistance, 2),
                    'daily_average' => $days > 0 ? round((float) $totalRevenue / $days, 2) : 0,
                ],
                'users' => [
                    'active_drivers' => $activeDrivers,
                    'total_drivers' => $totalDrivers,
                    'total_customers' => $totalCustomers,
                ],
            ];
        });

        return response()->json(responseFormatter(DEFAULT_200, $data));
    }

    public function peakHours(Request $request): JsonResponse
    {
        $days = min($request->get('days', 30), 90);
        $zoneId = $request->get('zone_id');

        $cacheKey = "analytics_peak_{$days}_{$zoneId}";
        $data = Cache::remember($cacheKey, 1800, function () use ($days, $zoneId) {
            $since = now()->subDays($days);

            $query = DB::table('trip_requests')
                ->where('created_at', '>=', $since)
                ->where('current_status', 'completed');

            if ($zoneId) $query->where('zone_id', $zoneId);

            $hourly = $query->select(
                DB::raw("EXTRACT(HOUR FROM created_at) as hour"),
                DB::raw("COUNT(*) as trips"),
                DB::raw("ROUND(AVG(paid_fare)::numeric, 2) as avg_fare"),
                DB::raw("ROUND(AVG(actual_distance)::numeric, 2) as avg_distance")
            )
            ->groupBy('hour')
            ->orderBy('hour')
            ->get();

            $peakHour = $hourly->sortByDesc('trips')->first();
            $offPeakHour = $hourly->sortBy('trips')->first();

            $dayOfWeek = DB::table('trip_requests')
                ->where('created_at', '>=', $since)
                ->where('current_status', 'completed')
                ->select(
                    DB::raw("EXTRACT(DOW FROM created_at) as day_of_week"),
                    DB::raw("COUNT(*) as trips"),
                    DB::raw("ROUND(SUM(paid_fare)::numeric, 2) as revenue")
                )
                ->groupBy('day_of_week')
                ->orderBy('day_of_week')
                ->get()
                ->map(function ($item) {
                    $dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                    $item->day_name = $dayNames[(int) $item->day_of_week] ?? 'Unknown';
                    return $item;
                });

            return [
                'hourly_distribution' => $hourly,
                'peak_hour' => $peakHour ? [
                    'hour' => (int) $peakHour->hour,
                    'label' => sprintf('%02d:00 - %02d:00', $peakHour->hour, ($peakHour->hour + 1) % 24),
                    'trips' => $peakHour->trips,
                ] : null,
                'off_peak_hour' => $offPeakHour ? [
                    'hour' => (int) $offPeakHour->hour,
                    'label' => sprintf('%02d:00 - %02d:00', $offPeakHour->hour, ($offPeakHour->hour + 1) % 24),
                    'trips' => $offPeakHour->trips,
                ] : null,
                'day_of_week' => $dayOfWeek,
            ];
        });

        return response()->json(responseFormatter(DEFAULT_200, $data));
    }

    public function popularRoutes(Request $request): JsonResponse
    {
        $days = min($request->get('days', 30), 90);
        $limit = min($request->get('limit', 10), 25);
        $zoneId = $request->get('zone_id');

        $cacheKey = "analytics_routes_{$days}_{$limit}_{$zoneId}";
        $data = Cache::remember($cacheKey, 1800, function () use ($days, $limit, $zoneId) {
            $since = now()->subDays($days);

            $query = DB::table('trip_requests as t')
                ->join('trip_request_coordinates as c', 't.id', '=', 'c.trip_request_id')
                ->where('t.current_status', 'completed')
                ->where('t.created_at', '>=', $since);

            if ($zoneId) $query->where('t.zone_id', $zoneId);

            $routes = $query->select(
                DB::raw("c.pickup_address as pickup"),
                DB::raw("c.destination_address as destination"),
                DB::raw("COUNT(*) as trip_count"),
                DB::raw("ROUND(AVG(t.paid_fare)::numeric, 2) as avg_fare"),
                DB::raw("ROUND(AVG(t.actual_distance)::numeric, 2) as avg_distance_km")
            )
            ->groupBy('c.pickup_address', 'c.destination_address')
            ->orderByDesc('trip_count')
            ->limit($limit)
            ->get();

            return [
                'popular_routes' => $routes,
                'period_days' => $days,
            ];
        });

        return response()->json(responseFormatter(DEFAULT_200, $data));
    }

    public function revenueTrend(Request $request): JsonResponse
    {
        $days = min($request->get('days', 30), 365);
        $zoneId = $request->get('zone_id');

        $cacheKey = "analytics_revenue_trend_{$days}_{$zoneId}";
        $data = Cache::remember($cacheKey, 1800, function () use ($days, $zoneId) {
            $since = now()->subDays($days);

            $query = DB::table('trip_requests')
                ->where('current_status', 'completed')
                ->where('created_at', '>=', $since);

            if ($zoneId) $query->where('zone_id', $zoneId);

            $daily = $query->select(
                DB::raw("DATE(created_at) as date"),
                DB::raw("COUNT(*) as trips"),
                DB::raw("ROUND(SUM(paid_fare)::numeric, 2) as revenue"),
                DB::raw("ROUND(AVG(paid_fare)::numeric, 2) as avg_fare"),
                DB::raw("COUNT(DISTINCT driver_id) as active_drivers"),
                DB::raw("COUNT(DISTINCT customer_id) as active_customers")
            )
            ->groupBy('date')
            ->orderBy('date')
            ->get();

            $totalRevenue = $daily->sum('revenue');
            $totalTrips = $daily->sum('trips');
            $avgDailyRevenue = $daily->count() > 0 ? round($totalRevenue / $daily->count(), 2) : 0;

            $growth = null;
            if ($daily->count() >= 14) {
                $half = intdiv($daily->count(), 2);
                $firstHalf = $daily->take($half)->sum('revenue');
                $secondHalf = $daily->skip($half)->sum('revenue');
                if ($firstHalf > 0) {
                    $growth = round((($secondHalf - $firstHalf) / $firstHalf) * 100, 1);
                }
            }

            return [
                'daily_trend' => $daily,
                'summary' => [
                    'total_revenue' => $totalRevenue,
                    'total_trips' => $totalTrips,
                    'avg_daily_revenue' => $avgDailyRevenue,
                    'growth_percent' => $growth,
                ],
            ];
        });

        return response()->json(responseFormatter(DEFAULT_200, $data));
    }

    public function cancellationAnalysis(Request $request): JsonResponse
    {
        $days = min($request->get('days', 30), 90);

        $cacheKey = "analytics_cancellation_{$days}";
        $data = Cache::remember($cacheKey, 1800, function () use ($days) {
            $since = now()->subDays($days);

            $reasons = DB::table('trip_requests')
                ->where('current_status', 'cancelled')
                ->where('created_at', '>=', $since)
                ->whereNotNull('trip_cancellation_reason')
                ->select(
                    'trip_cancellation_reason as reason',
                    DB::raw('COUNT(*) as count')
                )
                ->groupBy('trip_cancellation_reason')
                ->orderByDesc('count')
                ->limit(15)
                ->get();

            $byType = DB::table('trip_requests')
                ->where('current_status', 'cancelled')
                ->where('created_at', '>=', $since)
                ->select('type', DB::raw('COUNT(*) as count'))
                ->groupBy('type')
                ->get();

            $totalCancelled = DB::table('trip_requests')
                ->where('current_status', 'cancelled')
                ->where('created_at', '>=', $since)
                ->count();

            $totalTrips = DB::table('trip_requests')
                ->where('created_at', '>=', $since)
                ->count();

            return [
                'total_cancelled' => $totalCancelled,
                'cancellation_rate' => $totalTrips > 0 ? round(($totalCancelled / $totalTrips) * 100, 1) : 0,
                'by_reason' => $reasons,
                'by_type' => $byType,
                'period_days' => $days,
            ];
        });

        return response()->json(responseFormatter(DEFAULT_200, $data));
    }
}
