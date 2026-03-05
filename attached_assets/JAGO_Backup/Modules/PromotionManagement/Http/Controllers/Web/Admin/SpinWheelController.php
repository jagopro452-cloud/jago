<?php

namespace Modules\PromotionManagement\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use Brian2694\Toastr\Facades\Toastr;
use Carbon\Carbon;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;
use Modules\PromotionManagement\Entities\SpinWheelConfig;
use Modules\PromotionManagement\Entities\SpinWheelResult;
use Modules\PromotionManagement\Entities\SpinWheelSegment;

class SpinWheelController extends Controller
{
    private function getOrCreateConfig(): SpinWheelConfig
    {
        $config = SpinWheelConfig::first();
        if (!$config) {
            $config = SpinWheelConfig::create([
                'is_active' => false,
                'title' => 'Spin & Win!',
                'subtitle' => 'Spin the wheel to win wallet rewards after your ride!',
                'min_discount' => 5,
                'max_discount' => 100,
                'spins_per_day' => 1,
                'max_total_per_user' => 500,
                'ride_completion_required' => true,
                'segments' => [5, 10, 15, 20, 25, 50],
                'segment_colors' => ['#2563EB', '#16A34A', '#DC2626', '#D97706', '#7C3AED', '#0891B2'],
            ]);
            $defaultSegments = [
                ['label' => '₹5', 'amount' => 5, 'color' => '#2563EB', 'weight' => 30, 'sort_order' => 1],
                ['label' => '₹10', 'amount' => 10, 'color' => '#16A34A', 'weight' => 25, 'sort_order' => 2],
                ['label' => '₹15', 'amount' => 15, 'color' => '#DC2626', 'weight' => 20, 'sort_order' => 3],
                ['label' => '₹20', 'amount' => 20, 'color' => '#D97706', 'weight' => 15, 'sort_order' => 4],
                ['label' => '₹25', 'amount' => 25, 'color' => '#7C3AED', 'weight' => 7, 'sort_order' => 5],
                ['label' => '₹50', 'amount' => 50, 'color' => '#0891B2', 'weight' => 3, 'sort_order' => 6],
            ];
            foreach ($defaultSegments as $seg) {
                $seg['spin_wheel_config_id'] = $config->id;
                SpinWheelSegment::create($seg);
            }
        }
        return $config;
    }

    public function index(): View
    {
        $config = $this->getOrCreateConfig();
        $segments = SpinWheelSegment::where('spin_wheel_config_id', $config->id)
            ->orderBy('sort_order')
            ->get();

        $totalSpins = SpinWheelResult::count();
        $totalWalletCredits = SpinWheelResult::sum('wallet_amount');
        $uniqueUsers = SpinWheelResult::distinct('user_id')->count('user_id');
        $todaySpins = SpinWheelResult::whereDate('created_at', Carbon::today())->count();
        $todayCredits = SpinWheelResult::whereDate('created_at', Carbon::today())->sum('wallet_amount');

        $recentResults = SpinWheelResult::with('user')
            ->orderBy('created_at', 'desc')
            ->limit(25)
            ->get();

        return view('promotionmanagement::admin.spin-wheel.index', compact(
            'config', 'segments', 'totalSpins', 'totalWalletCredits',
            'uniqueUsers', 'todaySpins', 'todayCredits', 'recentResults'
        ));
    }

    public function update(Request $request): RedirectResponse
    {
        $request->validate([
            'title' => 'required|string|max:100',
            'subtitle' => 'required|string|max:255',
            'min_discount' => 'required|numeric|min:1|max:10000',
            'max_discount' => 'required|numeric|min:1|max:10000|gte:min_discount',
            'spins_per_day' => 'required|integer|min:1|max:10',
            'max_total_per_user' => 'required|numeric|min:0|max:100000',
        ]);

        $config = $this->getOrCreateConfig();

        $config->update([
            'title' => $request->title,
            'subtitle' => $request->subtitle,
            'min_discount' => $request->min_discount,
            'max_discount' => $request->max_discount,
            'spins_per_day' => $request->spins_per_day,
            'max_total_per_user' => $request->max_total_per_user,
            'ride_completion_required' => $request->has('ride_completion_required'),
        ]);

        $this->syncConfigSegments($config);

        Toastr::success(translate('spin_wheel_settings_updated'));
        return back();
    }

    public function status(Request $request): RedirectResponse
    {
        $config = $this->getOrCreateConfig();
        $activeSegments = SpinWheelSegment::where('spin_wheel_config_id', $config->id)
            ->where('is_active', true)
            ->count();

        if (!$config->is_active && $activeSegments < 2) {
            Toastr::error(translate('add_at_least_2_active_segments_before_enabling'));
            return back();
        }

        $config->update(['is_active' => !$config->is_active]);
        Toastr::success(translate('status_updated'));
        return back();
    }

    public function addSegment(Request $request): RedirectResponse
    {
        $request->validate([
            'label' => 'required|string|max:50',
            'amount' => 'required|numeric|min:1|max:10000',
            'color' => 'required|string|max:9',
            'weight' => 'required|integer|min:1|max:100',
        ]);

        $config = $this->getOrCreateConfig();

        $maxOrder = SpinWheelSegment::where('spin_wheel_config_id', $config->id)->max('sort_order') ?? 0;

        SpinWheelSegment::create([
            'spin_wheel_config_id' => $config->id,
            'label' => $request->label,
            'amount' => $request->amount,
            'color' => $request->color,
            'weight' => $request->weight,
            'is_active' => true,
            'sort_order' => $maxOrder + 1,
        ]);

        $this->syncConfigSegments($config);

        Toastr::success(translate('segment_added_successfully'));
        return back();
    }

    public function updateSegment(Request $request, $id): RedirectResponse
    {
        $request->validate([
            'label' => 'required|string|max:50',
            'amount' => 'required|numeric|min:1|max:10000',
            'color' => 'required|string|max:9',
            'weight' => 'required|integer|min:1|max:100',
        ]);

        $segment = SpinWheelSegment::findOrFail($id);
        $segment->update([
            'label' => $request->label,
            'amount' => $request->amount,
            'color' => $request->color,
            'weight' => $request->weight,
        ]);

        $this->syncConfigSegments($segment->config);

        Toastr::success(translate('segment_updated_successfully'));
        return back();
    }

    public function deleteSegment($id): RedirectResponse
    {
        $segment = SpinWheelSegment::findOrFail($id);
        $configId = $segment->spin_wheel_config_id;

        $activeCount = SpinWheelSegment::where('spin_wheel_config_id', $configId)
            ->where('is_active', true)
            ->where('id', '!=', $id)
            ->count();

        if ($activeCount < 2) {
            Toastr::error(translate('cannot_delete_must_have_at_least_2_segments'));
            return back();
        }

        $segment->delete();
        $config = SpinWheelConfig::find($configId);
        if ($config) {
            $this->syncConfigSegments($config);
        }

        Toastr::success(translate('segment_deleted_successfully'));
        return back();
    }

    public function toggleSegment($id): RedirectResponse
    {
        $segment = SpinWheelSegment::findOrFail($id);

        if ($segment->is_active) {
            $activeCount = SpinWheelSegment::where('spin_wheel_config_id', $segment->spin_wheel_config_id)
                ->where('is_active', true)
                ->where('id', '!=', $id)
                ->count();
            if ($activeCount < 2) {
                Toastr::error(translate('cannot_disable_must_have_at_least_2_active_segments'));
                return back();
            }
        }

        $segment->update(['is_active' => !$segment->is_active]);
        $this->syncConfigSegments($segment->config);

        Toastr::success(translate('segment_status_updated'));
        return back();
    }

    public function reports(Request $request): View
    {
        $config = $this->getOrCreateConfig();

        $dateFrom = $request->date_from ? Carbon::parse($request->date_from)->startOfDay() : Carbon::now()->subDays(30)->startOfDay();
        $dateTo = $request->date_to ? Carbon::parse($request->date_to)->endOfDay() : Carbon::now()->endOfDay();

        $query = SpinWheelResult::with('user')
            ->whereBetween('created_at', [$dateFrom, $dateTo]);

        $totalSpins = (clone $query)->count();
        $totalCredits = (clone $query)->sum('wallet_amount');
        $uniqueUsers = (clone $query)->distinct('user_id')->count('user_id');
        $avgReward = $totalSpins > 0 ? $totalCredits / $totalSpins : 0;

        $userStats = SpinWheelResult::with('user')
            ->whereBetween('created_at', [$dateFrom, $dateTo])
            ->selectRaw('user_id, COUNT(*) as spin_count, SUM(wallet_amount) as total_earned, MAX(created_at) as last_spin')
            ->groupBy('user_id')
            ->orderByDesc('total_earned')
            ->paginate(20);

        $dailyStats = SpinWheelResult::whereBetween('created_at', [$dateFrom, $dateTo])
            ->selectRaw("DATE(created_at) as date, COUNT(*) as spins, SUM(wallet_amount) as credits")
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        $segmentStats = SpinWheelResult::whereBetween('created_at', [$dateFrom, $dateTo])
            ->selectRaw('discount_value, COUNT(*) as times_won, SUM(wallet_amount) as total_amount')
            ->groupBy('discount_value')
            ->orderBy('discount_value')
            ->get();

        return view('promotionmanagement::admin.spin-wheel.reports', compact(
            'config', 'totalSpins', 'totalCredits', 'uniqueUsers', 'avgReward',
            'userStats', 'dailyStats', 'segmentStats', 'dateFrom', 'dateTo'
        ));
    }

    public function exportReports(Request $request)
    {
        $dateFrom = $request->date_from ? Carbon::parse($request->date_from)->startOfDay() : Carbon::now()->subDays(30)->startOfDay();
        $dateTo = $request->date_to ? Carbon::parse($request->date_to)->endOfDay() : Carbon::now()->endOfDay();

        $results = SpinWheelResult::with('user')
            ->whereBetween('created_at', [$dateFrom, $dateTo])
            ->orderBy('created_at', 'desc')
            ->get();

        $filename = 'spin_wheel_report_' . $dateFrom->format('Y-m-d') . '_to_' . $dateTo->format('Y-m-d') . '.csv';

        $headers = [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => "attachment; filename=\"$filename\"",
        ];

        $callback = function () use ($results) {
            $file = fopen('php://output', 'w');
            fputcsv($file, ['SL', 'Customer Name', 'Phone', 'Reward Amount', 'Wallet Credit', 'Trip ID', 'Date']);
            foreach ($results as $i => $result) {
                fputcsv($file, [
                    $i + 1,
                    $result->user ? $result->user->first_name . ' ' . $result->user->last_name : 'N/A',
                    $result->user->phone ?? 'N/A',
                    $result->discount_value,
                    number_format($result->wallet_amount, 2),
                    $result->trip_request_id ?? 'N/A',
                    $result->created_at->format('d M Y, h:i A'),
                ]);
            }
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    private function syncConfigSegments(SpinWheelConfig $config): void
    {
        $activeSegments = SpinWheelSegment::where('spin_wheel_config_id', $config->id)
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        $segments = $activeSegments->pluck('amount')->map(fn($a) => (int) $a)->toArray();
        $segmentColors = $activeSegments->pluck('color')->toArray();

        $config->update([
            'segments' => $segments,
            'segment_colors' => $segmentColors,
        ]);
    }
}
