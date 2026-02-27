<?php

namespace App\Http\Controllers;

use Brian2694\Toastr\Facades\Toastr;
use Illuminate\Http\Request;
use Jenssegers\Agent\Agent;
use Modules\BlogManagement\Service\Interfaces\BlogCategoryServiceInterface;
use Modules\BlogManagement\Service\Interfaces\BlogServiceInterface;
use Modules\BlogManagement\Service\Interfaces\BlogSettingServiceInterface;

class BlogController extends Controller
{
    protected $blogService;
    protected $blogSettingService;
    protected $blogCategoryService;

    public function __construct(BlogServiceInterface $blogService, BlogSettingServiceInterface $blogSettingService, BlogCategoryServiceInterface $blogCategoryService)
    {
        $this->blogService = $blogService;
        $this->blogSettingService = $blogSettingService;
        $this->blogCategoryService = $blogCategoryService;
    }

    public function index(Request $request)
    {
        $data = $this->commonData($request);

        return view('blog.index', $data);
    }


    public function category(Request $request, $slug)
    {
        $data = $this->commonData($request, $slug);
        if (!empty($data['category'])) {
            $data['category']->increment('click_count', 1);
        }

        return view('blog.category', $data);

    }

    public function details(Request $request, $slug)
    {
        $isEnabled = $this->blogSettingService->findOneBy(criteria: ['key_name' => 'is_enabled', 'settings_type' => BLOG_PAGE])?->value;

        if (empty($isEnabled)) {
            Toastr::error(message: BLOG_DISABLE['message'], title: translate(BLOG_DISABLE['response_code']));

            return redirect('/');
        }

        $blogCriteria = [];

        if (!array_key_exists('preview', $request->all())) {
            $blogCriteria = ['status' => 1, ['published_at', '<', now()], 'is_published' => 1];
        }
        $data['blog'] = $this->blogService->findOneBy(criteria: array_merge($blogCriteria, ['slug' => $slug]), relations: ['category', 'draft']);

        if (array_key_exists('preview', $request->all()) && $request->preview == 'drafted')
        {
            $data['blog'] = $data['blog']->draft;
        }

        if (!$data['blog'])
        {
            Toastr::error(message: BLOG_NOT_FOUND['message'], title: translate(BLOG_NOT_FOUND['response_code']));

            return redirect()->back();
        }

        if (!array_key_exists('preview', $request->all())) {
            $data['blog']->increment('click_count');
        }
        $data['popularBlogs'] = $this->blogService->getBy(criteria: $blogCriteria, orderBy: ['click_count' => 'desc'], limit: 3);
        $data['customerAndroidAppLink'] = businessConfig(key: CUSTOMER_APP_VERSION_CONTROL_FOR_ANDROID, settingsType: APP_VERSION)?->value;
        $data['customerIosAppLink'] = businessConfig(key: CUSTOMER_APP_VERSION_CONTROL_FOR_IOS, settingsType: APP_VERSION)?->value;
        $data['driverAndroidAppLink'] = businessConfig(key: DRIVER_APP_VERSION_CONTROL_FOR_ANDROID, settingsType: APP_VERSION)?->value;
        $data['driverIosAppLink'] = businessConfig(key: DRIVER_APP_VERSION_CONTROL_FOR_IOS, settingsType: APP_VERSION)?->value;
        $data['driverAppContent'] = $this->blogSettingService->findOneBy(criteria: ['key_name' => DRIVER_APP_CONTENTS, 'settings_type' => APP_DOWNLOAD_SETUP])?->value;
        $data['customerAppContent'] = $this->blogSettingService->findOneBy(criteria: ['key_name' => CUSTOMER_APP_CONTENTS, 'settings_type' => APP_DOWNLOAD_SETUP])?->value;
        $data['blogDescriptionAndSection'] = processArticleH2($data['blog']->description);
        $data['isAppDownloadSetupEnabled'] = $this->blogSettingService->findOneBy(criteria: ['key_name' => 'is_enabled', 'settings_type' => APP_DOWNLOAD_SETUP])?->value;

        return view('blog.details', $data);
    }

    public function search(Request $request)
    {
        $isEnabled = $this->blogSettingService->findOneBy(criteria: ['key_name' => 'is_enabled', 'settings_type' => BLOG_PAGE])?->value;

        if (empty($isEnabled)) {
            Toastr::error(message: BLOG_DISABLE['message'], title: translate(BLOG_DISABLE['response_code']));

            return redirect('/');
        }

        $data['blogPageTitle'] = $this->blogSettingService->findOneBy(criteria: ['key_name' => 'title', 'settings_type' => BLOG_PAGE])?->value;
        $data['blogPageSubtitle'] = $this->blogSettingService->findOneBy(criteria: ['key_name' => 'subtitle', 'settings_type' => BLOG_PAGE])?->value;
        $blogOrderBy = $this->blogSettingService->findOneBy(['key_name' => 'blog_sorting', 'settings_type' => PRIORITY_SETUP])?->value ?? ['created_at' => 'desc'];
        $categoryOrderBy = $this->blogSettingService->findOneBy(['key_name' => 'category_sorting', 'settings_type' => PRIORITY_SETUP])?->value ?? ['created_at' => 'desc'];
        $blogCriteria = [
            'status' => 1,
            'is_published' => 1,
            ['published_at', '<', now()]
        ];
        if (array_key_exists('search', $request->all())) {
            $blogCriteria = array_merge($blogCriteria, $request->all());
        }

        $data['blogs'] = $this->blogService->search(criteria: $blogCriteria, relations: ['category'], orderBy: sorting($blogOrderBy), limit: paginationLimit(), offset: $request['page'] ?? 1);
        $data['blogCategories'] = $this->blogCategoryService->getBy(criteria: ['status' => 1], orderBy: sortingBlogCategory($categoryOrderBy));

        return view('blog.search', $data);
    }


    public function customerAppDownload(Request $request)
    {
        $userAgent = new Agent();
        $playStoreUrl = businessConfig(key: CUSTOMER_APP_VERSION_CONTROL_FOR_ANDROID, settingsType: APP_VERSION)?->value['app_url'];
        $appStoreUrl = businessConfig(key: CUSTOMER_APP_VERSION_CONTROL_FOR_IOS, settingsType: APP_VERSION)?->value['app_url'];

        if ($userAgent->isAndroidOS() && !empty($playStoreUrl)) {
            return redirect()->away($playStoreUrl);
        }

        if ($userAgent->isiOS() && !empty($appStoreUrl)) {
            return redirect()->away($appStoreUrl);
        }

        Toastr::error(message: INVALID_URL['message'], title: translate(INVALID_URL['response_code']));

        return redirect('/');
    }

    public function driverAppDownload(Request $request)
    {
        $userAgent = new Agent();
        $playStoreUrl = businessConfig(key: DRIVER_APP_VERSION_CONTROL_FOR_ANDROID, settingsType: APP_VERSION)?->value['app_url'];
        $appStoreUrl = businessConfig(key: DRIVER_APP_VERSION_CONTROL_FOR_IOS, settingsType: APP_VERSION)?->value['app_url'];

        if ($userAgent->isAndroidOS() && !empty($playStoreUrl)) {
            return redirect()->away($playStoreUrl);
        }

        if ($userAgent->isiOS() && !empty($appStoreUrl)) {
            return redirect()->away($appStoreUrl);
        }

        Toastr::error(message: INVALID_URL['message'], title: translate(INVALID_URL['response_code']));

        return redirect('/');
    }

    public function popularBlogs(Request $request)
    {
        $isEnabled = $this->blogSettingService->findOneBy(criteria: ['key_name' => 'is_enabled', 'settings_type' => BLOG_PAGE])?->value;

        if (empty($isEnabled)) {
            Toastr::error(message: BLOG_DISABLE['message'], title: translate(BLOG_DISABLE['response_code']));

            return redirect('/');
        }
        $blogCriteria = [
            'status' => 1,
            'is_published' => 1,
            ['published_at', '<', now()]
        ];
        $categoryOrderBy = $this->blogSettingService->findOneBy(['key_name' => 'category_sorting', 'settings_type' => PRIORITY_SETUP])?->value ?? ['created_at' => 'desc'];
        $data['blogPageTitle'] = translate('Popular Blogs');
        $data['blogCategories'] = $this->blogCategoryService->getBy(criteria: ['status' => 1], orderBy: sortingBlogCategory($categoryOrderBy));
        $data['blogs'] = $this->blogService->getBy(criteria: $blogCriteria, relations: ['category'], orderBy: ['click_count' => 'desc'], limit: paginationLimit(), offset: $request['page'] ?? 1);

        return view('blog.popular-blogs', $data);
    }

    protected function commonData(Request $request, ?string $slug = null)
    {
        $isEnabled = $this->blogSettingService->findOneBy(criteria: ['key_name' => 'is_enabled', 'settings_type' => BLOG_PAGE])?->value;

        if (empty($isEnabled)) {
            Toastr::error(message: BLOG_DISABLE['message'], title: translate(BLOG_DISABLE['response_code']));

            return redirect('/');
        }
        $blogOrderBy = $this->blogSettingService->findOneBy(['key_name' => 'blog_sorting', 'settings_type' => PRIORITY_SETUP])?->value ?? ['created_at' => 'desc'];
        $categoryOrderBy = $this->blogSettingService->findOneBy(['key_name' => 'category_sorting', 'settings_type' => PRIORITY_SETUP])?->value ?? ['created_at' => 'desc'];
        $blogCriteria = [
            'status' => 1,
            'is_published' => 1,
            ['published_at', '<', now()]
        ];
        if (!empty($slug) && $slug != 'all') {
            $data['category'] = $this->blogCategoryService->findOneBy(criteria: ['slug' => $slug]);
            $blogCriteria = array_merge($blogCriteria, ['blog_category_id' => $data['category']->id]);
        }
        $data['blogPageTitle'] = $this->blogSettingService->findOneBy(criteria: ['key_name' => 'title', 'settings_type' => BLOG_PAGE])?->value;
        $data['blogPageSubtitle'] = $this->blogSettingService->findOneBy(criteria: ['key_name' => 'subtitle', 'settings_type' => BLOG_PAGE])?->value;
        $data['blogCategories'] = $this->blogCategoryService->getBy(criteria: ['status' => 1], orderBy: sortingBlogCategory($categoryOrderBy));
        $data['blogs'] = $this->blogService->getBy(criteria: $blogCriteria, relations: ['category'], orderBy: sorting($blogOrderBy), limit: paginationLimit(), offset: $request['page'] ?? 1);
        $data['recentBlogs'] = $this->blogService->getBy(criteria: $blogCriteria, orderBy: ['created_at' => 'desc'], limit: 10);
        $data['isAppDownloadSetupEnabled'] = $this->blogSettingService->findOneBy(criteria: ['key_name' => 'is_enabled', 'settings_type' => APP_DOWNLOAD_SETUP])?->value;
        $data['customerAndroidAppLink'] = businessConfig(key: CUSTOMER_APP_VERSION_CONTROL_FOR_ANDROID, settingsType: APP_VERSION)?->value;
        $data['customerIosAppLink'] = businessConfig(key: CUSTOMER_APP_VERSION_CONTROL_FOR_IOS, settingsType: APP_VERSION)?->value;
        $data['driverAndroidAppLink'] = businessConfig(key: DRIVER_APP_VERSION_CONTROL_FOR_ANDROID, settingsType: APP_VERSION)?->value;
        $data['driverIosAppLink'] = businessConfig(key: DRIVER_APP_VERSION_CONTROL_FOR_IOS, settingsType: APP_VERSION)?->value;
        $data['driverAppContent'] = $this->blogSettingService->findOneBy(criteria: ['key_name' => DRIVER_APP_CONTENTS, 'settings_type' => APP_DOWNLOAD_SETUP])?->value;
        $data['customerAppContent'] = $this->blogSettingService->findOneBy(criteria: ['key_name' => CUSTOMER_APP_CONTENTS, 'settings_type' => APP_DOWNLOAD_SETUP])?->value;

        return $data;
    }
}
