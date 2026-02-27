<?php

namespace Modules\UserManagement\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use Brian2694\Toastr\Facades\Toastr;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;
use Modules\UserManagement\Entities\DriverSubscription;
use Modules\UserManagement\Entities\SubscriptionPlan;

class SubscriptionController extends Controller
{
    public function index(): View
    {
        $plans = SubscriptionPlan::latest()->paginate(paginationLimit());
        $totalActiveDrivers = DriverSubscription::where('status', 'active')->distinct('driver_id')->count('driver_id');
        $totalSubscriptions = DriverSubscription::count();

        return view('usermanagement::admin.subscription.index', compact('plans', 'totalActiveDrivers', 'totalSubscriptions'));
    }

    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'duration_type' => 'required|in:daily,weekly,monthly',
            'duration_days' => 'required|integer|min:1',
            'price' => 'required|numeric|min:0',
            'max_rides' => 'required|integer|min:1',
        ]);

        SubscriptionPlan::create($request->only([
            'name', 'description', 'duration_type', 'duration_days', 'price', 'max_rides',
        ]));

        Toastr::success(translate('subscription_plan_created_successfully'));
        return back();
    }

    public function update(Request $request, $id): RedirectResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'duration_type' => 'required|in:daily,weekly,monthly',
            'duration_days' => 'required|integer|min:1',
            'price' => 'required|numeric|min:0',
            'max_rides' => 'required|integer|min:1',
        ]);

        $plan = SubscriptionPlan::findOrFail($id);
        $plan->update($request->only([
            'name', 'description', 'duration_type', 'duration_days', 'price', 'max_rides',
        ]));

        Toastr::success(translate('subscription_plan_updated_successfully'));
        return back();
    }

    public function destroy($id): RedirectResponse
    {
        $plan = SubscriptionPlan::findOrFail($id);
        $plan->update(['is_active' => false]);

        Toastr::success(translate('subscription_plan_deactivated_successfully'));
        return back();
    }

    public function toggleStatus($id): RedirectResponse
    {
        $plan = SubscriptionPlan::findOrFail($id);
        $plan->update(['is_active' => !$plan->is_active]);

        $message = $plan->is_active
            ? translate('subscription_plan_activated_successfully')
            : translate('subscription_plan_deactivated_successfully');
        Toastr::success($message);
        return back();
    }

    public function subscribers(): View
    {
        $subscriptions = DriverSubscription::with('driver', 'plan')
            ->latest()
            ->paginate(paginationLimit());

        return view('usermanagement::admin.subscription.subscribers', compact('subscriptions'));
    }

    public function toggleLock($driverId): RedirectResponse
    {
        $subscription = DriverSubscription::where('driver_id', $driverId)
            ->where('status', 'active')
            ->latest()
            ->first();

        if ($subscription) {
            $subscription->update(['is_locked' => !$subscription->is_locked]);
            $message = $subscription->is_locked
                ? translate('driver_locked_successfully')
                : translate('driver_unlocked_successfully');
            Toastr::success($message);
        } else {
            Toastr::error(translate('no_active_subscription_found'));
        }

        return back();
    }
}
