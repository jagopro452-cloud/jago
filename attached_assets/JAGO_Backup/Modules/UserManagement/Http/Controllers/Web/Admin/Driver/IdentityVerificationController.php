<?php

namespace Modules\UserManagement\Http\Controllers\Web\Admin\Driver;

use App\Http\Controllers\Controller;
use Brian2694\Toastr\Facades\Toastr;
use Carbon\Factory;
use Illuminate\Console\Application;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\View\View;
use Modules\UserManagement\Http\Requests\MarkIdentityAsVerifiedStoreOrUpdateRequest;
use Modules\UserManagement\Service\Interfaces\DriverIdentityVerificationServiceInterface;
use Symfony\Component\HttpFoundation\StreamedResponse;

class IdentityVerificationController extends Controller
{
    protected $driverIdentityVerificationService;

    public function __construct(DriverIdentityVerificationServiceInterface $driverIdentityVerificationService)
    {
        $this->driverIdentityVerificationService = $driverIdentityVerificationService;
    }

    public function unverifiedList(Request $request)
    {
        $this->authorize('user_view');
        $attributes = [];
        $attributes['search'] = $request->has('search') ?  $request->search : null;

        if ($request->has('verification_status')) {
            $attributes['verification_status'] = $request->verification_status;
        }

        if (!is_null($request->filter_date) && $request->filter_date != 'custom_date') {
            $attributes['filter_date'] = getDateRange($request->filter_date);
        } elseif (!is_null($request->filter_date)) {
            $attributes['filter_date'] = getDateRange([
                'start' => $request->start_date,
                'end' => $request->end_date
            ]);
        }

        if ($request->has('order_by')) {
            $attributes['order_by'] = $request->order_by;
        }

        $unverifiedDrivers = $this->driverIdentityVerificationService->index(criteria: $attributes, relations: ['driver.driverDetails'], orderBy: ['created_at' => 'desc'], limit: paginationLimit(), offset: $request['page'] ?? 1, appends: $request->all());

        return view('usermanagement::admin.driver.verification.unverified-list', compact('unverifiedDrivers'));
    }

    public function exportUnverifiedList(Request $request): View|Factory|Response|StreamedResponse|string|Application
    {
        $this->authorize('user_edit');
        $attributes = [];
        $attributes['search'] = $request->has('search') ?  $request->search : null;

        if ($request->has('verification_status')) {
            $attributes['verification_status'] = $request->verification_status;
        }

        if (!is_null($request->filter_date) && $request->filter_date != 'custom_date') {
            $attributes['filter_date'] = getDateRange($request->filter_date);
        } elseif (!is_null($request->filter_date)) {
            $attributes['filter_date'] = getDateRange([
                'start' => $request->start_date,
                'end' => $request->end_date
            ]);
        }

        if ($request->has('order_by')) {
            $attributes['order_by'] = $request->order_by;
        }

        $unverifiedDrivers = $this->driverIdentityVerificationService->index(criteria: $attributes, relations: ['driver'], orderBy: ['created_at' => 'desc'], limit: paginationLimit(), offset: $request['page'] ?? 1, appends: $request->all());
        $data = $unverifiedDrivers->map(function ($item) {
            $attemptDetails = collect($item->attempt_details);

            return  [
                'Driver Info' => ($item->driver->first_name ?? '') . ($item->driver->last_name ?? '') . ' (' . $item->driver->phone . ')',
                'Attempts Made' => $attemptDetails->count() ?? 0,
                'Last Attempt Time' => $attemptDetails->last()['time'] ?? 'N/A',
                'Verification Status' => $item->current_status,
            ];
        });

        return exportData($data, $request['file'], '');
    }

    public function viewVerificationRequest($id)
    {
        $this->authorize('user_edit');
        $unverifiedDriverInfo = $this->driverIdentityVerificationService->findOne(id: $id, relations: ['driver.driverDetails', 'driver.level']);

        return view('usermanagement::admin.driver.verification.partials._view-driver-verification-request', compact('unverifiedDriverInfo'));
    }

    public function markAsVerified(MarkIdentityAsVerifiedStoreOrUpdateRequest $request, $id)
    {
        $this->authorize('user_edit');
        $unverifiedDriverInfo = $this->driverIdentityVerificationService->findOne(id: $id, relations: ['driver.driverDetails']);

        $this->driverIdentityVerificationService->MarkIdentityAsVerified(unverifiedDriverInfo: $unverifiedDriverInfo, data: $request->validated());

        Toastr::success(DRIVER_MARK_AS_VERIFIED['message']);

        return back();
    }

    public function markAsSuspended($id)
    {
        $this->authorize('user_edit');
        $unverifiedDriverInfo = $this->driverIdentityVerificationService->findOne(id: $id, relations: ['driver.driverDetails']);

        if ($unverifiedDriverInfo->driver->driverDetails->is_suspended)
        {
            Toastr::error(DRIVER_ALREADY_SUSPENDED['message']);

            return back();
        }

        $this->driverIdentityVerificationService->MarkIdentityAsSuspended(unverifiedDriverInfo: $unverifiedDriverInfo);

        Toastr::success(DRIVER_MARK_AS_SUSPENDED['message']);

        return back();
    }
}
