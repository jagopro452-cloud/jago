<?php

if (!function_exists('isReverbRunning')) {
    function isReverbRunning(): bool
    {
        $host = config('reverb.servers.reverb.host', '127.0.0.1');
        $port = config('reverb.servers.reverb.port', 6001);

        $connection = @fsockopen($host, $port, $errno, $errstr, 0.2);

        if (is_resource($connection)) {
            fclose($connection);
            return true;
        }

        return false;
    }
}

use Pusher\Pusher;

if (!function_exists('isPusherRunning')) {
    function isPusherRunning(): bool
    {
        try {
            $pusher = new Pusher(
                config('broadcasting.connections.pusher.key'),
                config('broadcasting.connections.pusher.secret'),
                config('broadcasting.connections.pusher.app_id'),
                [
                    'cluster' => config('broadcasting.connections.pusher.options.cluster'),
                    'useTLS' => config('broadcasting.connections.pusher.options.scheme', 'https') === 'https',
                    'host' => config('broadcasting.connections.pusher.options.host'),
                    'port' => config('broadcasting.connections.pusher.options.port'),
                    'scheme' => config('broadcasting.connections.pusher.options.scheme', 'https'),
                ]
            );
            return true;
        } catch (\Exception $e) {
            return false;
        }
    }
}



if (!function_exists('isBroadcastDriverRunning')) {
    function isBroadcastDriverRunning(): bool
    {
        $driver = config('broadcasting.default');

        return match ($driver) {
            'reverb' => isReverbRunning(),
            'pusher' => isPusherRunning(),
            default => false, // strict: any unknown driver is "not running"
        };
    }
}

if (!function_exists('areAllBroadcastServicesRunning')) {
    function areAllBroadcastServicesRunning(): bool
    {
        return isReverbRunning() && isPusherRunning();
    }
}




