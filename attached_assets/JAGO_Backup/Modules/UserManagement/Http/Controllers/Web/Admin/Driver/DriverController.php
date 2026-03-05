<?php

namespace Modules\UserManagement\Http\Controllers\Web\Admin\Driver;

use App\Http\Controllers\BaseController;
use Brian2694\Toastr\Facades\Toastr;
use Illuminate\Contracts\Foundation\Application;
use Illuminate\Contracts\Support\Renderable;
use Illuminate\Contracts\View\Factory;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\View\View;
use Modules\AdminModule\Service\Interfaces\ActivityLogServiceInterface;
use Modules\TransactionManagement\Service\Interfaces\TransactionServiceInterface;
use Modules\UserManagement\Entities\User;
use Modules\UserManagement\Enums\SuspendReasonEnum;
use Modules\UserManagement\Http\Requests\DriverStoreOrUpdateRequest;
use Modules\UserManagement\Service\Interfaces\AppNotificationServiceInterface;
use Modules\UserManagement\Service\Interfaces\DriverDetailServiceInterface;
use Modules\UserManagement\Service\Interfaces\DriverLevelServiceInterface;
use Modules\UserManagement\Service\Interfaces\DriverServiceInterface;
use Symfony\Component\HttpFoundation\StreamedResponse;

class DriverController extends BaseController
{
    use AuthorizesRequests;

    protected $driverService;
    protected $driverLevelService;
    protected $appNotificationService;
    protected $transactionService;
    protected $activityLogService;
    protected $driverDetailService;

    public function __construct(
        DriverServiceInterface          $driverService,
        DriverLevelServiceInterface     $driverLevelService,
        AppNotificationServiceInterface $appNotificationService,
        TransactionServiceInterface     $transactionService,
        ActivityLogServiceInterface $activityLogService,
        DriverDetailServiceInterface $driverDetailService
    )
    {
        parent::__construct($driverService);
        $this->driverService = $driverService;
        $this->driverLevelService = $driverLevelService;
        $this->appNotificationService = $appNotificationService;
        $this->transactionService = $transactionService;
        $this->activityLogService = $activityLogService;
        $this->driverDetailService = $driverDetailService;
    }

    public function index(?Request $request, string $type = null): View|Collection|LengthAwarePaginator|null|callable|RedirectResponse
    {
        $this->authorize('user_view');
        $drivers = $this->driverService->index(criteria: $request?->all(), relations: ['level', 'driverTrips', 'driverTripsStatus', 'lastLocations.zone'], orderBy: ['created_at' => 'desc'], limit: paginationLimit(), offset: $request['page'] ?? 1);
        return view('usermanagement::admin.driver.index', compact('drivers'));
    }

    public function create(): Renderable
    {
        $this->authorize('user_add');
        return view('usermanagement::admin.driver.create');
    }

    public function store(DriverStoreOrUpdateRequest $request): RedirectResponse
    {
        $this->authorize('user_add');
        $firstLevel = $this->driverLevelService->findOneBy(criteria: ['user_type' => DRIVER, 'sequence' => 1]);
        if (!$firstLevel) {
            Toastr::error(LEVEL_403['message']);
            return back();
        }
        $request->merge([
            'user_level_id' => $firstLevel->id
        ]);
        $this->driverService->create(data: $request->validated());
        Toastr::success(DRIVER_STORE_200['message']);
        return redirect(route('admin.driver.index'));

    }

    public function show($id, Request $request): Renderable|RedirectResponse
    {
        $this->authorize('user_view');
        $driver = $this->driverService->findOne(id: $id, relations: ['userAccount', 'receivedReviews', 'driverTrips', 'driverDetails', 'driverTrips']);
        if (!$driver) {
            Toastr::warning(translate("Driver not found"));
            return back();
        }
        $data = $this->driverService->show(id: $id, data: $request->all());
        $commonData = $data['commonData'];
        $otherData = $data['otherData'];

        return view('usermanagement::admin.driver.details', compact('driver', 'commonData', 'otherData'));

    }

    public function edit($id): Renderable
    {
        $this->authorize('user_edit');
        $driver = $this->driverService
            ->findOneBy(criteria: ['id' => $id, 'user_type' => DRIVER]);
        return view('usermanagement::admin.driver.edit', compact('driver'));
    }

    public function update(DriverStoreOrUpdateRequest $request, $id): RedirectResponse
    {
        $this->authorize('user_edit');
        $data = array_merge($request->validated(), ['type' => 'web']);
        $this->driverService->update(id: $id, data: $data);
        Toastr::success(DRIVER_UPDATE_200['message']);
        return back();
    }

    public function destroy($id): RedirectResponse
    {
        $this->authorize('user_delete');
        $driver = $this->driverService->findOne($id);
        if(count($driver->getDriverLastTrip())!=0|| $driver?->userAccount->payable_balance>0 || $driver?->userAccount->pending_balance>0 || $driver?->userAccount->receivable_balance>0){
            Toastr::success(translate("Sorry you can't delete this driver, because there are ongoing rides or payment due this driver."));
            return back();
        }
        $this->driverService->delete(id: $id);
        Toastr::success(DRIVER_DELETE_200['message']);
        return back();
    }

    public function updateStatus(Request $request): JsonResponse
    {
        $this->authorize('user_edit');
        $driver = $this->driverService->statusChange(id: $request->id, data: $request->all());
        $sentTime = pushSentTime($driver->updated_at);
        $driverNotification = $this->appNotificationService->getBy(criteria: ['user_id' => $request->id, 'action' => 'account_approved']);
        if (count($driverNotification) == 0) {
            $push = getNotification('registration_approved');
            if ($request->status && $driver?->fcm_token) {
                sendDeviceNotification(
                    fcm_token: $driver?->fcm_token,
                    title: translate(key: $push['title'], locale: $driver?->current_language_key),
                    description: textVariableDataFormat(value: $push['description'], userName: $driver->first_name . ' ' . $driver->last_name, sentTime: $sentTime, locale: $driver?->current_language_key),
                    status: $push['status'],
                    notification_type: 'driver',
                    action: $push['action'],
                    user_id: $driver?->id
                );
            }
        }
        if ($driver?->is_active == 0) {
            foreach ($driver?->tokens as $token) {
                $token->revoke();
            }
        }
        return response()->json($driver);
    }

    public function getAllAjax(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'search' => 'sometimes'
        ]);
        $drivers = $this->driverService->getDriverWithoutVehicle(criteria:$request->all(),limit: 100, offset:$request['page']??1);
        $mapped = $drivers->map(function ($items) {
            return [
                'text' => $items['first_name'] . ' ' . $items['last_name'] . ' ' . '(' . $items['phone'] . ')',
                'id' => $items['id']
            ];
        });
        if ($request->all_driver) {
            $all_driver = (object)['id' => 0, 'text' => translate('all_driver')];
            $mapped->prepend($all_driver);
        }

        return response()->json($mapped);
    }

    public function getAllAjaxVehicle(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'search' => 'sometimes'
        ]);

        $drivers = $this->driverService->getDriverWithoutVehicle(criteria:$request->all(),limit: 100, offset:$request['page']??1);
        $mapped = $drivers->map(function ($items) {
            return [
                'text' => $items['first_name'] . ' ' . $items['last_name'] . ' ' . '(' . $items['phone'] . ')',
                'id' => $items['id']
            ];
        });
        if ($request->all_driver) {
            $all_driver = (object)['id' => 0, 'text' => translate('all_driver')];
            $mapped->prepend($all_driver);
        }

        return response()->json($mapped);
    }

    public function statistics(Request $request)
    {
        $analytics = $this->driverService->getStatisticsData($request->all());
        $total = $analytics['total'];
        $active = $analytics['active'];
        $inactive = $analytics['inactive'];
        $car = $analytics['car'];
        $motor_bike = $analytics['motor_bike'];
        return response()->json(view('usermanagement::admin.driver._statistics',
            compact('total', 'active', 'inactive', 'car', 'motor_bike'))->render());
    }

    public function export(Request $request): View|Factory|Response|StreamedResponse|string|Application
    {
        $this->authorize('user_export');
        $attributes = [
            'relations' => ['level'],
            // 'query' => $request['query'],
            // 'value' => $request['value'],
        ];

        !is_null($request['search']) ? $attributes['search'] = $request['search'] : '';
        !is_null($request['query']) ? $attributes['query'] = $request['query'] : '';
        !is_null($request['value']) ? $attributes['value'] = $request['value'] : '';

        $request->merge(['relations' => ['level', 'driverTrips', 'driverTripsStatus', 'lastLocations.zone']]);

        $data = $this->driverService->export(criteria: $request->all(), relations: ['level', 'driverTrips', 'driverTripsStatus', 'lastLocations.zone'], orderBy: ['created_at' => 'desc']);
        return exportData($data, $request['file'], 'usermanagement::admin.driver.print');
    }

    public function driverTransactionExport(Request $request)
    {
        $request->merge([
            'driver_id' => $request['id']
        ]);
        $exportData = $this->transactionService->export(criteria: $request->all(), orderBy: ['created_at' => 'desc']);
        return exportData($exportData, $request['file'], 'usermanagement::admin.driver.transaction.print');
    }

    public function log(Request $request): View|Factory|Response|StreamedResponse|string|Application
    {
        $this->authorize('user_log');
        $request->merge([
            'logable_type' => User::class,
            'user_type' => DRIVER
        ]);
        $logs = $this->activityLogService->log($request->all());
        $file = array_key_exists('file', $request->all()) ? $request['file'] : '';
        return logViewerNew($logs,$file);
    }

    public function trash(Request $request)
    {
        $this->authorize('super-admin');
        $drivers = $this->driverService->trashedData(criteria: $request->all(), relations: ['level', 'lastLocations.zone', 'driverTrips', 'driverTripsStatus'], limit: paginationLimit(), offset:$request['page']??1);
        return view('usermanagement::admin.driver.trashed', compact('drivers'));
    }

    public function restore($id): RedirectResponse
    {
        $this->authorize('super-admin');
        $this->driverService->restoreData(id: $id);
        Toastr::success(DEFAULT_RESTORE_200['message']);
        return redirect()->route('admin.driver.index');
    }

    public function permanentDelete($id)
    {
        $this->authorize('super-admin');
        $this->driverService->permanentDelete(id: $id);
        Toastr::success(DRIVER_DELETE_200['message']);
        return back();
    }

    //identity image change
    public function profileUpdateRequestList(Request $request): Renderable
    {
        $this->authorize('user_edit');
        $request->merge(['pending' => true]);
        $drivers = $this->driverService->index(criteria: $request?->all(), relations: ['level', 'driverTrips', 'driverTripsStatus', 'lastLocations.zone'], orderBy : ['created_at' => 'desc'], limit: paginationLimit(), offset:$request['page'] ?? 1);
        return view('usermanagement::admin.driver.profile-update-request', compact('drivers'));
    }

    public function profileUpdateRequestListExport(Request $request): View|Factory|Response|StreamedResponse|string|Application
    {
        $this->authorize('user_edit');
        $request->merge(['pending' => true]);

        $attributes = [
            'relations' => ['level'],
        ];

        !is_null($request['search']) ? $attributes['search'] = $request['search'] : '';
        !is_null($request['query']) ? $attributes['query'] = $request['query'] : '';
        !is_null($request['value']) ? $attributes['value'] = $request['value'] : '';

        $request->merge(['relations' => ['level', 'driverTrips', 'driverTripsStatus', 'lastLocations.zone']]);

        $data = $this->driverService->export(criteria: $request->all(), relations: ['level', 'driverTrips', 'driverTripsStatus', 'lastLocations.zone'],orderBy : ['created_at' => 'desc']);
        return exportData($data, $request['file'], 'usermanagement::admin.driver.print');
    }

    public function profileUpdateRequestApprovedOrRejected($id,Request $request)
    {
        $this->authorize('user_edit');
        $this->driverService->updateIdentityImage(id: $id,data: $request->all());
        $driver = $this->driverService->findOne(id: $id);
        $sentTime = pushSentTime($driver->updated_at);
        if ($request->status=='approved'){
            $push = getNotification('identity_image_approved');
            sendDeviceNotification(
                fcm_token: $driver?->fcm_token,
                title: translate(key: $push['title'], locale: $driver?->current_language_key),
                description: textVariableDataFormat(value: $push['description'], userName: $driver->first_name . ' ' . $driver->last_name, sentTime: $sentTime, locale: $driver?->current_language_key),
                status: $push['status'],
                notification_type: 'driver',
                action: $push['action'],
                user_id: $driver?->id
            );
            Toastr::success(translate('driver_identity_image_approved_successfully'));
        }else{
            $push = getNotification('identity_image_rejected');
            sendDeviceNotification(
                fcm_token: $driver?->fcm_token,
                title: translate(key: $push['title'], locale: $driver?->current_language_key),
                description: textVariableDataFormat(value: $push['description'], userName: $driver->first_name . ' ' . $driver->last_name, sentTime: $sentTime, locale: $driver?->current_language_key),
                status: $push['status'],
                notification_type: 'driver',
                action: $push['action'],
                user_id: $driver?->id
            );
            Toastr::success(translate('driver_identity_image_rejected_successfully'));
        }
        return redirect()->back();
    }

    public function updateSuspensionStatus(Request $request, $id)
    {
        $this->authorize('user_edit');
        $driver = $this->driverService
            ->findOneBy(criteria: ['id' => $id, 'user_type' => DRIVER], relations: ['driverDetails']);

        if ($driver->driverDetails->suspend_reason == SuspendReasonEnum::CASH_IN_HAND_LIMIT->value && $request->action == REACTIVATE)
        {
            Toastr::error(DRIVER_SUSPEND_FOR_CASH_IN_HAND_LIMIT_EXCEEDS['message']);

            return back();
        }

        if ($driver->driverDetails->suspend_reason == SuspendReasonEnum::FACE_VERIFICATION->value && $request->action == REACTIVATE)
        {
            Toastr::error(DRIVER_SUSPEND_FOR_FACE_VERIFICATION['message']);

            return back();
        }

        if ($request->action == SUSPEND && $driver->driverDetails->is_suspended)
        {
            Toastr::error(DRIVER_ALREADY_SUSPENDED['message']);

            return back();
        }

        $this->driverService->changeSuspensionStatus(driver: $driver, action: $request->action);

        Toastr::success($request->action == REACTIVATE ? DRIVER_MARK_AS_UN_SUSPENDED['message'] :DRIVER_MARK_AS_SUSPENDED['message']);

        return back();
    }

    public function markAsVerified($id)
    {
        $this->authorize('user_edit');
        $driver = $this->driverService->findOne(id: $id, relations: ['driverDetails']);
        $this->driverDetailService->updatedBy(criteria: ['user_id' => $driver->id], data: ['is_verified' => 1]);

        Toastr::success(DRIVER_MARK_AS_VERIFIED['message']);

        return back();
    }

    public function unlockNegativeBalance($id)
    {
        $this->authorize('user_edit');
        $result = \Modules\UserManagement\Service\DriverWalletService::adminManualUnlock($id);
        if ($result) {
            Toastr::success(translate('driver_unlocked_successfully'));
        } else {
            Toastr::error(translate('driver_is_not_locked_for_negative_balance'));
        }
        return back();
    }

}
