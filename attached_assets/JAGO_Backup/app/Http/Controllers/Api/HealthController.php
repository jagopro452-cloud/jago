<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Queue;
use Illuminate\Http\JsonResponse;

class HealthController extends Controller
{
    public function __invoke(): JsonResponse
    {
        $health = [
            'status' => 'ok',
            'timestamp' => now()->toIso8601String(),
            'version' => config('app.version', '1.0.0'),
            'services' => [],
        ];

        $dbStatus = $this->checkDatabase();
        $health['services']['database'] = $dbStatus;

        $cacheStatus = $this->checkCache();
        $health['services']['cache'] = $cacheStatus;

        $queueStatus = $this->checkQueue();
        $health['services']['queue'] = $queueStatus;

        $storageStatus = $this->checkStorage();
        $health['services']['storage'] = $storageStatus;

        $health['services']['memory'] = [
            'status' => 'ok',
            'usage_mb' => round(memory_get_usage(true) / 1024 / 1024, 2),
            'peak_mb' => round(memory_get_peak_usage(true) / 1024 / 1024, 2),
        ];

        $overallOk = collect($health['services'])->every(fn($s) => $s['status'] === 'ok');
        $health['status'] = $overallOk ? 'ok' : 'degraded';

        $statusCode = $overallOk ? 200 : 503;

        return response()->json($health, $statusCode);
    }

    private function checkDatabase(): array
    {
        try {
            $start = microtime(true);
            DB::select('SELECT 1');
            $latency = round((microtime(true) - $start) * 1000, 2);

            return [
                'status' => 'ok',
                'latency_ms' => $latency,
            ];
        } catch (\Exception $e) {
            return ['status' => 'error', 'message' => 'Connection failed'];
        }
    }

    private function checkCache(): array
    {
        try {
            $key = 'health_check_' . time();
            Cache::put($key, 'ok', 10);
            $value = Cache::get($key);
            Cache::forget($key);

            return [
                'status' => $value === 'ok' ? 'ok' : 'error',
            ];
        } catch (\Exception $e) {
            return ['status' => 'error'];
        }
    }

    private function checkQueue(): array
    {
        try {
            $pendingJobs = DB::table('jobs')->count();
            $failedJobs = DB::table('failed_jobs')->count();

            return [
                'status' => 'ok',
                'pending_jobs' => $pendingJobs,
                'failed_jobs' => $failedJobs,
            ];
        } catch (\Exception $e) {
            return ['status' => 'error'];
        }
    }

    private function checkStorage(): array
    {
        try {
            $path = storage_path('app');
            $writable = is_writable($path);

            return [
                'status' => $writable ? 'ok' : 'error',
                'writable' => $writable,
            ];
        } catch (\Exception $e) {
            return ['status' => 'error'];
        }
    }
}
