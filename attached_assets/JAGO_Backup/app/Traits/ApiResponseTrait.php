<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;

trait ApiResponseTrait
{
    protected function success($data = null, string $message = 'Success', int $code = 200): JsonResponse
    {
        return response()->json(responseFormatter(constant: DEFAULT_200, content: $data), $code);
    }

    protected function created($data = null): JsonResponse
    {
        return response()->json(responseFormatter(constant: DEFAULT_STORE_200, content: $data), 201);
    }

    protected function updated($data = null): JsonResponse
    {
        return response()->json(responseFormatter(constant: DEFAULT_UPDATE_200, content: $data), 200);
    }

    protected function deleted(): JsonResponse
    {
        return response()->json(responseFormatter(constant: DEFAULT_DELETE_200), 200);
    }

    protected function notFound(string $constant = null): JsonResponse
    {
        return response()->json(responseFormatter(constant: $constant ?? DEFAULT_404), 404);
    }

    protected function forbidden(string $constant = null): JsonResponse
    {
        return response()->json(responseFormatter(constant: $constant ?? DEFAULT_400), 403);
    }

    protected function validationError($validator): JsonResponse
    {
        return response()->json(responseFormatter(constant: DEFAULT_400, errors: errorProcessor($validator)), 422);
    }

    protected function error(string $message, int $code = 400, ?array $errors = null): JsonResponse
    {
        $response = [
            'response_code' => 'default_' . $code,
            'message' => translate($message),
        ];
        if ($errors) {
            $response['errors'] = $errors;
        }
        return response()->json($response, $code);
    }
}
