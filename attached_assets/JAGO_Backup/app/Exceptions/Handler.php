<?php

namespace App\Exceptions;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Symfony\Component\HttpKernel\Exception\MethodNotAllowedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\TooManyRequestsHttpException;
use Throwable;

class Handler extends ExceptionHandler
{
    protected $dontReport = [
        //
    ];

    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    public function register()
    {
        $this->reportable(function (Throwable $e) {
            //
        });

        $this->renderable(function (TooManyRequestsHttpException $e, $request) {
            if ($request->wantsJson() || $request->is('api/*')) {
                return response()->json([
                    'response_code' => 'too_many_requests_429',
                    'message' => 'Too many requests. Please try again later.',
                    'content' => null,
                    'errors' => []
                ], 429);
            }
        });

        $this->renderable(function (AuthenticationException $e, $request) {
            if ($request->wantsJson() || $request->is('api/*')) {
                return response()->json([
                    'response_code' => 'unauthenticated_401',
                    'message' => 'Unauthenticated.',
                    'content' => null,
                    'errors' => []
                ], 401);
            }
        });

        $this->renderable(function (ModelNotFoundException $e, $request) {
            if ($request->wantsJson() || $request->is('api/*')) {
                return response()->json([
                    'response_code' => 'resource_not_found_404',
                    'message' => 'The requested resource was not found.',
                    'content' => null,
                    'errors' => []
                ], 404);
            }
        });

        $this->renderable(function (NotFoundHttpException $e, $request) {
            if ($request->wantsJson() || $request->is('api/*')) {
                return response()->json(responseFormatter(DEFAULT_404), 404);
            }
        });

        $this->renderable(function (MethodNotAllowedHttpException $e, $request) {
            if ($request->wantsJson() || $request->is('api/*')) {
                return response()->json([
                    'response_code' => 'method_not_allowed_405',
                    'message' => 'The request method is not allowed.',
                    'content' => null,
                    'errors' => []
                ], 405);
            }
        });

        $this->renderable(function (ValidationException $e, $request) {
            if ($request->wantsJson() || $request->is('api/*')) {
                return response()->json([
                    'response_code' => 'validation_error_422',
                    'message' => 'The given data was invalid.',
                    'content' => null,
                    'errors' => $e->errors()
                ], 422);
            }
        });

        $this->renderable(function (QueryException $e, $request) {
            if ($request->wantsJson() || $request->is('api/*')) {
                \Log::error('Database error: ' . $e->getMessage());
                return response()->json([
                    'response_code' => 'server_error_500',
                    'message' => 'A database error occurred. Please try again.',
                    'content' => null,
                    'errors' => []
                ], 500);
            }
        });

        $this->renderable(function (HttpException $e, $request) {
            if ($request->wantsJson() || $request->is('api/*')) {
                return response()->json([
                    'response_code' => $e->getStatusCode(),
                    'message' => $e->getMessage() ?: 'An error occurred.',
                    'content' => null,
                    'errors' => []
                ], $e->getStatusCode());
            }
        });

        $this->renderable(function (Throwable $e, $request) {
            if ($request->wantsJson() || $request->is('api/*')) {
                \Log::error('Unhandled API exception: ' . $e->getMessage(), [
                    'exception' => get_class($e),
                    'file' => $e->getFile(),
                    'line' => $e->getLine(),
                ]);
                return response()->json([
                    'response_code' => 'server_error_500',
                    'message' => 'Something went wrong. Please try again later.',
                    'content' => null,
                    'errors' => []
                ], 500);
            }
        });
    }
}
