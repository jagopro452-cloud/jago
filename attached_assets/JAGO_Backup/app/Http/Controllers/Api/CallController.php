<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Call;
use App\Models\CallSignal;
use App\Models\CallRecording;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;

class CallController extends Controller
{
    public function startCall(Request $request): JsonResponse
    {
        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'trip_request_id' => 'required|string',
            'caller_type' => 'required|in:customer,driver',
            'caller_id' => 'required|string',
            'callee_type' => 'required|in:customer,driver,support',
            'callee_id' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $tripId = $request->trip_request_id;

        if ($tripId !== 'support') {
            $trip = \Modules\TripManagement\Entities\TripRequest::find($tripId);
            if (!$trip) {
                return response()->json(['error' => 'Trip not found'], 404);
            }

            $activeStatuses = ['accepted', 'ongoing', 'picked_up', 'en_route'];
            if (!in_array($trip->current_status, $activeStatuses)) {
                return response()->json(['error' => 'Call not allowed - trip is not active'], 403);
            }
        }

        $existingCall = Call::whereIn('status', ['initiated', 'ringing'])
            ->where(function ($q) use ($request) {
                $q->where('caller_id', $request->caller_id)
                  ->orWhere('callee_id', $request->caller_id);
            })
            ->first();

        if ($existingCall) {
            return response()->json(['error' => 'Already in a call', 'call_id' => $existingCall->id], 409);
        }

        $call = Call::create([
            'trip_request_id' => $tripId === 'support' ? null : $tripId,
            'caller_type' => $request->caller_type,
            'caller_id' => $request->caller_id,
            'callee_type' => $request->callee_type,
            'callee_id' => $request->callee_id,
            'call_type' => $tripId === 'support' ? 'support' : 'trip',
            'status' => 'initiated',
        ]);

        return response()->json([
            'call_id' => $call->id,
            'status' => 'initiated',
        ]);
    }

    public function sendSignal(Request $request, string $callId): JsonResponse
    {
        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'sender_type' => 'required|in:customer,driver,support',
            'sender_id' => 'required|string',
            'signal_type' => 'required|in:offer,answer,ice,bye,reject',
            'payload' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $call = Call::find($callId);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Invalid call ID'], 400);
        }
        if (!$call) {
            return response()->json(['error' => 'Call not found'], 404);
        }

        if ($call->status === 'ended' || $call->status === 'failed') {
            return response()->json(['error' => 'Call already ended'], 400);
        }

        if ($request->signal_type === 'offer') {
            $call->update(['status' => 'ringing']);
        } elseif ($request->signal_type === 'answer') {
            $call->update(['status' => 'accepted', 'started_at' => now()]);
        } elseif ($request->signal_type === 'bye' || $request->signal_type === 'reject') {
            $endedAt = now();
            $duration = $call->started_at ? $call->started_at->diffInSeconds($endedAt) : 0;
            $call->update([
                'status' => $request->signal_type === 'reject' ? 'rejected' : 'ended',
                'ended_at' => $endedAt,
                'duration_seconds' => $duration,
            ]);
        }

        CallSignal::create([
            'call_id' => $callId,
            'sender_type' => $request->sender_type,
            'sender_id' => $request->sender_id,
            'signal_type' => $request->signal_type,
            'payload' => is_string($request->payload) ? json_decode($request->payload, true) : $request->payload,
        ]);

        return response()->json(['success' => true]);
    }

    public function pollSignals(Request $request, string $callId): JsonResponse
    {
        try {
            $call = Call::find($callId);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Invalid call ID'], 400);
        }
        if (!$call) {
            return response()->json(['error' => 'Call not found'], 404);
        }

        $userId = $request->query('user_id');
        $since = $request->query('since');

        $query = CallSignal::where('call_id', $callId)
            ->where('sender_id', '!=', $userId)
            ->whereNull('consumed_at');

        if ($since) {
            $query->where('created_at', '>', $since);
        }

        $signals = $query->orderBy('created_at', 'asc')->get();

        CallSignal::whereIn('id', $signals->pluck('id'))
            ->update(['consumed_at' => now()]);

        return response()->json([
            'call_status' => $call->fresh()->status,
            'signals' => $signals->map(function ($s) {
                return [
                    'id' => $s->id,
                    'signal_type' => $s->signal_type,
                    'payload' => $s->payload,
                    'created_at' => $s->created_at->toISOString(),
                ];
            }),
        ]);
    }

    public function checkIncoming(Request $request): JsonResponse
    {
        $userId = $request->query('user_id');
        if (!$userId) {
            return response()->json(['incoming' => null]);
        }

        $incomingCall = Call::where('callee_id', $userId)
            ->whereIn('status', ['initiated', 'ringing'])
            ->where('created_at', '>', now()->subSeconds(30))
            ->orderBy('created_at', 'desc')
            ->first();

        if (!$incomingCall) {
            return response()->json(['incoming' => null]);
        }

        $callerName = 'Unknown';
        $caller = \Modules\UserManagement\Entities\User::find($incomingCall->caller_id);
        if ($caller) {
            $callerName = $caller->first_name . ' ' . substr($caller->last_name ?? '', 0, 1) . '.';
        }

        return response()->json([
            'incoming' => [
                'call_id' => $incomingCall->id,
                'caller_type' => $incomingCall->caller_type,
                'caller_name' => $callerName,
                'call_type' => $incomingCall->call_type,
                'trip_request_id' => $incomingCall->trip_request_id,
            ],
        ]);
    }

    public function uploadRecording(Request $request, string $callId): JsonResponse
    {
        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'recording' => 'required|file|max:51200',
            'user_type' => 'required|in:customer,driver,support',
            'user_id' => 'required|string',
            'duration_seconds' => 'nullable|integer',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $call = Call::find($callId);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Invalid call ID'], 400);
        }
        if (!$call) {
            return response()->json(['error' => 'Call not found'], 404);
        }

        $file = $request->file('recording');
        $fileName = $callId . '_' . $request->user_type . '_' . time() . '.webm';
        $path = $file->storeAs('public/call-recordings', $fileName);

        CallRecording::create([
            'call_id' => $callId,
            'user_type' => $request->user_type,
            'user_id' => $request->user_id,
            'file_path' => $path,
            'file_size' => $file->getSize(),
            'duration_seconds' => $request->duration_seconds ?? 0,
        ]);

        return response()->json(['success' => true, 'file' => $fileName]);
    }

    public function getCallStatus(string $callId): JsonResponse
    {
        try {
            $call = Call::find($callId);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Invalid call ID'], 400);
        }
        if (!$call) {
            return response()->json(['error' => 'Call not found'], 404);
        }

        return response()->json([
            'status' => $call->status,
            'duration_seconds' => $call->duration_seconds,
            'started_at' => $call->started_at?->toISOString(),
        ]);
    }

    public function adminCallLogs(Request $request)
    {
        $query = Call::with(['caller', 'callee', 'recordings'])
            ->orderBy('created_at', 'desc');

        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->whereHas('caller', function ($cq) use ($search) {
                    $cq->where('first_name', 'ILIKE', "%{$search}%")
                        ->orWhere('last_name', 'ILIKE', "%{$search}%")
                        ->orWhere('phone', 'ILIKE', "%{$search}%");
                })->orWhereHas('callee', function ($cq) use ($search) {
                    $cq->where('first_name', 'ILIKE', "%{$search}%")
                        ->orWhere('last_name', 'ILIKE', "%{$search}%")
                        ->orWhere('phone', 'ILIKE', "%{$search}%");
                });
            });
        }

        if ($type = $request->get('call_type')) {
            $query->where('call_type', $type);
        }

        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        $calls = $query->paginate(15);

        return view('adminmodule::call-logs', compact('calls'));
    }

    public function playRecording(string $recordingId)
    {
        $recording = CallRecording::findOrFail($recordingId);
        $path = storage_path('app/' . $recording->file_path);

        if (!file_exists($path)) {
            abort(404, 'Recording not found');
        }

        return response()->file($path, [
            'Content-Type' => 'audio/webm',
        ]);
    }
}
