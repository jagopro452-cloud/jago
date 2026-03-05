<?php

namespace Modules\BlogManagement\Observers;

use Illuminate\Support\Str;
use Modules\BlogManagement\Entities\Blog;

class BlogObserver
{
    public function creating(Blog $blog): void
    {
        $slug = Str::slug($blog->title);
        while (Blog::where('slug', $slug)->whereNot('id', $blog->id)->exists()) {
            $slug = Str::slug($blog->title) . '-' . rand(1000, 9999);
        }
        $readableId = Blog::select('readable_id')->withTrashed()->orderBy('readable_id', 'desc')->first()?->readable_id ?? 1000;

        $blog->readable_id = $readableId + 1;
        $blog->slug = $slug;
    }

    /**
     * Handle the Blog "saving" event.
     */
    public function saving(Blog $blog): void
    {
        $slug = Str::slug($blog->title);
        while (Blog::where('slug', $slug)->whereNot('id', $blog->id)->exists()) {
            $slug = Str::slug($blog->title) . '-' . rand(1000, 9999);
        }

        $blog->slug = $slug;
    }

}
