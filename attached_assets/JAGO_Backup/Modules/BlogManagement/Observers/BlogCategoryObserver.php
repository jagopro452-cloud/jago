<?php

namespace Modules\BlogManagement\Observers;

use Illuminate\Support\Str;
use Modules\BlogManagement\Entities\BlogCategory;

class BlogCategoryObserver
{
    public function creating(BlogCategory $blogCategory): void
    {
        $slug = Str::slug($blogCategory->name);
        while (BlogCategory::where('slug', $slug)->whereNot('id', $blogCategory->id)->exists()) {
            $slug = Str::slug($blogCategory->name) . '-' . rand(1000, 9999);
        }

        $blogCategory->slug = $slug;
    }

    /**
     * Handle the BlogCategory "saving" event.
     */
    public function saving(BlogCategory $blogCategory): void
    {
        $slug = Str::slug($blogCategory->name);
        while (BlogCategory::where('slug', $slug)->whereNot('id', $blogCategory->id)->exists()) {
            $slug = Str::slug($blogCategory->name) . '-' . rand(1000, 9999);
        }

        $blogCategory->slug = $slug;
    }

}
