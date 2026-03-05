<?php

namespace Modules\AdminModule\Providers;

use Illuminate\Support\ServiceProvider;
use Kreait\Firebase\Factory;

class FirebaseServiceProvider extends ServiceProvider
{
    /**
     * Register the service provider.
     */
    public function register(): void
    {
        $this->app->singleton('firebase.firestore', function ($app) {
            $serviceAccountKey = $this->getServiceAccountKey();
            if (!empty($serviceAccountKey) && !empty($serviceAccountKey['project_id'] ?? null)) {
                return (new Factory)
                    ->withServiceAccount($serviceAccountKey)
                    ->createMessaging();
            }
            return false;
        });

        $this->app->singleton('firebase.messaging', function ($app) {
            $serviceAccountKey = $this->getServiceAccountKey();
            if (!empty($serviceAccountKey) && !empty($serviceAccountKey['project_id'] ?? null)) {
                return (new Factory)
                    ->withServiceAccount($serviceAccountKey)
                    ->createMessaging();
            }
            return false;
        });
    }

    private function getServiceAccountKey(): array
    {
        try {
            $config = businessConfig(key: SERVER_KEY, settingsType: NOTIFICATION_SETTINGS);
            if (!$config || empty($config->value)) {
                return [];
            }
            $value = $config->value;
            if (is_string($value)) {
                return json_decode($value, true) ?? [];
            }
            if (is_array($value)) {
                return $value;
            }
            return [];
        } catch (\Exception $e) {
            return [];
        }
    }

    /**
     * Get the services provided by the provider.
     */
    public function provides(): array
    {
        return [];
    }
}
