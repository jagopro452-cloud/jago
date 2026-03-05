<?php

namespace Modules\UserManagement\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Modules\UserManagement\Service\Interfaces\NewsletterSubscriptionServiceInterface;

class NewsletterController extends Controller
{
    protected $newsletterSubscriptionService;

    public function __construct(NewsletterSubscriptionServiceInterface $newsletterSubscriptionService)
    {
        $this->newsletterSubscriptionService = $newsletterSubscriptionService;
    }

    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $this->authorize('user_view');
        $attributes = [];
        $attributes['search'] = $request->has('search') ? $request->search : null;
        $subscriptionList = $this->newsletterSubscriptionService->index(criteria: $attributes, orderBy: ['created_at' => 'desc'], limit: paginationLimit(), offset: $request['page'] ?? 1, appends: $request->all());

        return view('usermanagement::admin.newsletter.subscription-list', compact('subscriptionList'));
    }


    public function export(Request $request)
    {
        $this->authorize('user_view');
        $attributes = [];
        $attributes['search'] = $request->has('search') ? $request->search : null;
        $subscriptionList = $this->newsletterSubscriptionService->index(criteria: $attributes, orderBy: ['created_at' => 'desc'], limit: paginationLimit(), offset: $request['page'] ?? 1, appends: $request->all());

        $data = $subscriptionList->map(fn($item) => [
            'id' => $item['id'],
            'Email' => $item['email'],
            'Created At' => $item['created_at']->format('d F, Y'),
            'Updated At' => $item['updated_at']->format('d F, Y'),
        ]);

        return exportData($data, $request['file'], '');

    }
}
