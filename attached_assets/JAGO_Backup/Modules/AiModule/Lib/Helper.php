<?php

if (!function_exists('aiImageFullPath'))
{
    function aiImageFullPath($imageName)
    {
        if (in_array(request()->ip(), ['127.0.0.1', '::1'])) {
            return [
                'image_name' => $imageName,
                'image_full_path' => asset(path: 'storage/app/public/blog/ai-image/' . $imageName),
            ];
        }

        return [
            'image_name' => $imageName,
            'image_full_path' => asset(path: 'storage/app/public/blog/ai-image/' . $imageName)
        ];
    }
}
