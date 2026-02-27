<?php

namespace Modules\BusinessManagement\Http\Controllers\Web\Admin\BusinessSetup;

use App\Http\Controllers\Controller;
use Brian2694\Toastr\Facades\Toastr;
use Illuminate\Http\Request;
use Modules\BusinessManagement\Entities\CorporateAccount;
use Modules\BusinessManagement\Entities\B2bParcelPlan;
use Modules\UserManagement\Entities\User;

class CorporateController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->search;
        $corporates = CorporateAccount::when($search, function($q) use ($search) {
            $q->where('company_name', 'like', "%$search%")
              ->orWhere('company_code', 'like', "%$search%");
        })->orderBy('created_at', 'desc')->paginate(15);

        return view('businessmanagement::admin.corporate.index', compact('corporates', 'search'));
    }

    public function create()
    {
        return view('businessmanagement::admin.corporate.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'company_name' => 'required|string|max:255',
            'company_code' => 'required|string|max:50|unique:corporate_accounts,company_code',
            'contact_person' => 'required|string|max:255',
            'contact_email' => 'required|email',
            'contact_phone' => 'required|string|max:20',
            'plan_type' => 'required|in:basic,standard,premium,enterprise',
            'discount_percent' => 'nullable|numeric|min:0|max:50',
            'credit_limit' => 'nullable|numeric|min:0',
            'billing_cycle' => 'required|in:monthly,quarterly,annual',
            'max_employees' => 'required|integer|min:1',
            'ride_allowed' => 'nullable',
            'parcel_allowed' => 'nullable',
            'contract_start' => 'nullable|date',
            'contract_end' => 'nullable|date|after:contract_start',
        ]);

        $data = $request->all();
        $data['ride_allowed'] = $request->has('ride_allowed');
        $data['parcel_allowed'] = $request->has('parcel_allowed');

        CorporateAccount::create($data);
        Toastr::success(translate('Corporate account created successfully'));
        return redirect()->route('admin.business.setup.corporate.index');
    }

    public function edit($id)
    {
        $corporate = CorporateAccount::findOrFail($id);
        $employees = User::where('corporate_account_id', $id)->paginate(10);
        return view('businessmanagement::admin.corporate.edit', compact('corporate', 'employees'));
    }

    public function update(Request $request, $id)
    {
        $corporate = CorporateAccount::findOrFail($id);

        $request->validate([
            'company_name' => 'required|string|max:255',
            'company_code' => 'required|string|max:50|unique:corporate_accounts,company_code,' . $id,
            'contact_person' => 'required|string|max:255',
            'contact_email' => 'required|email',
            'contact_phone' => 'required|string|max:20',
            'plan_type' => 'required|in:basic,standard,premium,enterprise',
            'discount_percent' => 'nullable|numeric|min:0|max:50',
            'credit_limit' => 'nullable|numeric|min:0',
            'billing_cycle' => 'required|in:monthly,quarterly,annual',
            'max_employees' => 'required|integer|min:1',
            'ride_allowed' => 'nullable',
            'parcel_allowed' => 'nullable',
            'contract_start' => 'nullable|date',
            'contract_end' => 'nullable|date|after:contract_start',
        ]);

        $data = $request->all();
        $data['ride_allowed'] = $request->has('ride_allowed');
        $data['parcel_allowed'] = $request->has('parcel_allowed');

        $corporate->update($data);
        Toastr::success(translate('Corporate account updated successfully'));
        return back();
    }

    public function status($id)
    {
        $corporate = CorporateAccount::findOrFail($id);
        $corporate->update(['is_active' => !$corporate->is_active]);
        Toastr::success(translate('Status updated successfully'));
        return back();
    }

    public function addEmployee(Request $request, $id)
    {
        $corporate = CorporateAccount::findOrFail($id);

        $request->validate([
            'phone' => 'required|string',
            'employee_id' => 'required|string|max:50',
        ]);

        $user = User::where('phone', $request->phone)->first();
        if (!$user) {
            Toastr::error(translate('User not found with this phone number'));
            return back();
        }
        if ($user->corporate_account_id) {
            Toastr::error(translate('User is already linked to a corporate account'));
            return back();
        }
        if ($corporate->active_employees >= $corporate->max_employees) {
            Toastr::error(translate('Maximum employee limit reached'));
            return back();
        }

        $user->update([
            'corporate_account_id' => $id,
            'employee_id' => $request->employee_id,
            'user_category' => 'corporate',
        ]);
        $corporate->increment('active_employees');

        Toastr::success(translate('Employee added successfully'));
        return back();
    }

    public function removeEmployee($corporateId, $userId)
    {
        $user = User::findOrFail($userId);
        if ($user->corporate_account_id === $corporateId) {
            $user->update([
                'corporate_account_id' => null,
                'employee_id' => null,
                'user_category' => 'regular',
            ]);
            CorporateAccount::where('id', $corporateId)->decrement('active_employees');
            Toastr::success(translate('Employee removed successfully'));
        }
        return back();
    }

    public function b2bPlans(Request $request)
    {
        $plans = B2bParcelPlan::orderBy('sort_order')->paginate(15);
        return view('businessmanagement::admin.corporate.b2b-plans', compact('plans'));
    }

    public function storeB2bPlan(Request $request)
    {
        $request->validate([
            'plan_name' => 'required|string|max:255',
            'plan_code' => 'required|string|max:50|unique:b2b_parcel_plans,plan_code',
            'monthly_fee' => 'required|numeric|min:0',
            'included_deliveries' => 'required|integer|min:0',
            'per_delivery_rate' => 'required|numeric|min:0',
            'discount_percent' => 'nullable|numeric|min:0|max:50',
            'max_weight_kg' => 'required|integer|min:1',
        ]);

        $data = $request->all();
        $data['priority_pickup'] = $request->has('priority_pickup');
        $data['dedicated_support'] = $request->has('dedicated_support');
        $data['api_access'] = $request->has('api_access');

        B2bParcelPlan::create($data);
        Toastr::success(translate('B2B parcel plan created successfully'));
        return back();
    }

    public function updateB2bPlan(Request $request, $id)
    {
        $plan = B2bParcelPlan::findOrFail($id);

        $request->validate([
            'plan_name' => 'required|string|max:255',
            'plan_code' => 'required|string|max:50|unique:b2b_parcel_plans,plan_code,' . $id,
            'monthly_fee' => 'required|numeric|min:0',
            'included_deliveries' => 'required|integer|min:0',
            'per_delivery_rate' => 'required|numeric|min:0',
            'discount_percent' => 'nullable|numeric|min:0|max:50',
            'max_weight_kg' => 'required|integer|min:1',
        ]);

        $data = $request->all();
        $data['priority_pickup'] = $request->has('priority_pickup');
        $data['dedicated_support'] = $request->has('dedicated_support');
        $data['api_access'] = $request->has('api_access');

        $plan->update($data);
        Toastr::success(translate('B2B parcel plan updated successfully'));
        return back();
    }

    public function b2bPlanStatus($id)
    {
        $plan = B2bParcelPlan::findOrFail($id);
        $plan->update(['is_active' => !$plan->is_active]);
        Toastr::success(translate('Status updated successfully'));
        return back();
    }
}
