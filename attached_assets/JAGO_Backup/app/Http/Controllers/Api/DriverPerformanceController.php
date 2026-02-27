<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

class DriverPerformanceController extends Controller
{
    private const WEIGHT_RATING = 0.30;
    private const WEIGHT_ACCEPTANCE = 0.25;
    private const WEIGHT_CANCELLATION = 0.20;
    private const WEIGHT_COMPLETION = 0.15;
    private const WEIGHT_ONTIME = 0.10;

    public function score(Request $request, string $driverId): JsonResponse
    {
        $cacheKey = "driver_performance_{$driverId}";
        $data = Cache::remember($cacheKey, 300, function () use ($driverId) {
            return $this->calculatePerformance($driverId);
        });

        if (!$data) {
            return response()->json(responseFormatter(DEFAULT_404, null), 404);
        }

        return response()->json(responseFormatter(DEFAULT_200, $data));
    }

    public function leaderboard(Request $request): JsonResponse
    {
        $limit = min($request->get('limit', 20), 50);
        $zoneId = $request->get('zone_id');

        $cacheKey = "driver_leaderboard_{$limit}_{$zoneId}";
        $data = Cache::remember($cacheKey, 600, function () use ($limit, $zoneId) {
            $zoneFilter = $zoneId ? "AND u.zone_id = " . DB::getPdo()->quote($zoneId) : "";

            $results = DB::select("
                WITH driver_stats AS (
                    SELECT
                        u.id as driver_id,
                        TRIM(CONCAT(u.first_name, ' ', u.last_name)) as name,
                        u.profile_image,
                        COUNT(t.id) FILTER (WHERE t.current_status IN ('completed','cancelled')) as total_trips,
                        COUNT(t.id) FILTER (WHERE t.current_status = 'completed') as completed_trips,
                        COUNT(t.id) FILTER (WHERE t.current_status = 'cancelled') as cancelled_trips,
                        COALESCE(AVG(r.rating), 0) as avg_rating,
                        COUNT(t.id) as total_requests,
                        COALESCE((SELECT COUNT(*) FROM trip_request_ignoreds ti WHERE ti.user_id = u.id), 0) as ignored_count
                    FROM users u
                    JOIN driver_details dd ON u.id = dd.user_id
                    LEFT JOIN trip_requests t ON t.driver_id = u.id
                    LEFT JOIN reviews r ON r.received_by = u.id AND r.deleted_at IS NULL
                    WHERE u.user_type = 'driver'
                      AND dd.is_suspended = 0
                      AND u.deleted_at IS NULL
                      {$zoneFilter}
                    GROUP BY u.id, u.first_name, u.last_name, u.profile_image
                    HAVING COUNT(t.id) FILTER (WHERE t.current_status IN ('completed','cancelled')) >= 5
                )
                SELECT *,
                    ROUND((
                        LEAST((COALESCE(avg_rating,0)/5)*100, 100) * 0.30 +
                        CASE WHEN total_requests > 0 THEN LEAST(((total_requests - ignored_count)::float / total_requests) * 100, 100) ELSE 0 END * 0.25 +
                        CASE WHEN total_trips > 0 THEN GREATEST(100 - (cancelled_trips::float / total_trips * 100 * 2), 0) ELSE 100 END * 0.20 +
                        CASE WHEN total_trips > 0 THEN LEAST((completed_trips::float / total_trips) * 100, 100) ELSE 0 END * 0.15 +
                        80 * 0.10
                    )::numeric, 1) as composite_score
                FROM driver_stats
                ORDER BY composite_score DESC
                LIMIT ?
            ", [$limit]);

            return collect($results)->map(function ($row) {
                $score = (float) $row->composite_score;
                return [
                    'driver_id' => $row->driver_id,
                    'name' => $row->name,
                    'profile_image' => $row->profile_image,
                    'score' => $score,
                    'rating' => round((float) $row->avg_rating, 2),
                    'total_trips' => (int) $row->total_trips,
                    'tier' => match(true) {
                        $score >= 90 => 'platinum',
                        $score >= 75 => 'gold',
                        $score >= 60 => 'silver',
                        default => 'bronze',
                    },
                ];
            })->toArray();
        });

        return response()->json(responseFormatter(DEFAULT_200, $data));
    }

    private function calculatePerformance(string $driverId): ?array
    {
        $driver = DB::table('users')
            ->join('driver_details', 'users.id', '=', 'driver_details.user_id')
            ->where('users.id', $driverId)
            ->where('users.user_type', 'driver')
            ->select('users.id', 'users.first_name', 'users.last_name')
            ->first();

        if (!$driver) {
            return null;
        }

        $totalTrips = DB::table('trip_requests')
            ->where('driver_id', $driverId)
            ->whereIn('current_status', ['completed', 'cancelled'])
            ->count();

        $completedTrips = DB::table('trip_requests')
            ->where('driver_id', $driverId)
            ->where('current_status', 'completed')
            ->count();

        $cancelledByDriver = DB::table('trip_requests')
            ->where('driver_id', $driverId)
            ->where('current_status', 'cancelled')
            ->count();

        $avgRating = DB::table('reviews')
            ->where('received_by', $driverId)
            ->whereNull('deleted_at')
            ->avg('rating') ?? 0;

        $totalRequests = DB::table('trip_requests')
            ->where('driver_id', $driverId)
            ->count();

        $ignoredRequests = DB::table('trip_request_ignoreds')
            ->where('user_id', $driverId)
            ->count();

        $acceptedRequests = max($totalRequests - $ignoredRequests, 0);
        $acceptanceRate = $totalRequests > 0 ? ($acceptedRequests / $totalRequests) * 100 : 0;
        $completionRate = $totalTrips > 0 ? ($completedTrips / $totalTrips) * 100 : 0;
        $cancellationRate = $totalTrips > 0 ? ($cancelledByDriver / $totalTrips) * 100 : 0;

        $onTimeTrips = DB::table('trip_requests')
            ->where('driver_id', $driverId)
            ->where('current_status', 'completed')
            ->whereNotNull('estimated_time_minutes')
            ->whereRaw('EXTRACT(EPOCH FROM (updated_at - created_at))/60 <= estimated_time_minutes * 1.2')
            ->count();

        $estimatedTrips = DB::table('trip_requests')
            ->where('driver_id', $driverId)
            ->where('current_status', 'completed')
            ->whereNotNull('estimated_time_minutes')
            ->count();

        $onTimeRate = $estimatedTrips > 0 ? ($onTimeTrips / $estimatedTrips) * 100 : 80;

        $ratingScore = min(($avgRating / 5) * 100, 100);
        $acceptanceScore = min($acceptanceRate, 100);
        $cancellationScore = max(100 - ($cancellationRate * 2), 0);
        $completionScore = min($completionRate, 100);
        $onTimeScore = min($onTimeRate, 100);

        $compositeScore = round(
            ($ratingScore * self::WEIGHT_RATING) +
            ($acceptanceScore * self::WEIGHT_ACCEPTANCE) +
            ($cancellationScore * self::WEIGHT_CANCELLATION) +
            ($completionScore * self::WEIGHT_COMPLETION) +
            ($onTimeScore * self::WEIGHT_ONTIME),
            1
        );

        $tier = match(true) {
            $compositeScore >= 90 => 'platinum',
            $compositeScore >= 75 => 'gold',
            $compositeScore >= 60 => 'silver',
            default => 'bronze',
        };

        return [
            'driver_id' => $driverId,
            'composite_score' => $compositeScore,
            'tier' => $tier,
            'total_trips' => $totalTrips,
            'completed_trips' => $completedTrips,
            'metrics' => [
                'average_rating' => round($avgRating, 2),
                'acceptance_rate' => round($acceptanceRate, 1),
                'cancellation_rate' => round($cancellationRate, 1),
                'completion_rate' => round($completionRate, 1),
                'on_time_rate' => round($onTimeRate, 1),
            ],
            'weights' => [
                'rating' => self::WEIGHT_RATING,
                'acceptance' => self::WEIGHT_ACCEPTANCE,
                'cancellation' => self::WEIGHT_CANCELLATION,
                'completion' => self::WEIGHT_COMPLETION,
                'on_time' => self::WEIGHT_ONTIME,
            ],
        ];
    }
}
