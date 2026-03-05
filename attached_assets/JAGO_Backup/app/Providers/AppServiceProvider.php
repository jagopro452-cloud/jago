<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Pagination\Paginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register()
    {
        //
    }

    public function boot()
    {
        RateLimiter::for('auth', function (Request $request) {
            return Limit::perMinute(10)->by($request->ip());
        });

        if($this->app->environment('live') || $this->app->environment('production')) {
            URL::forceScheme('https');
        }
        Paginator::useBootstrap();

        Model::preventLazyLoading(!$this->app->isProduction());

        if ($this->app->isProduction()) {
            Model::handleLazyLoadingViolationUsing(function ($model, $relation) {
                Log::warning("Lazy loading {$relation} on " . get_class($model));
            });
        }
    }
}
