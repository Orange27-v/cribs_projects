<?php

namespace App\Http\Controllers\User;

use App\Models\Inspection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use App\Http\Controllers\Controller;
use App\Jobs\SendInspectionNotification;
use Illuminate\Support\Facades\Log;

class InspectionController extends Controller
{
    public function getUserBookings(Request $request)
    {
        try {
            $user = Auth::user();
            $bookings = Inspection::where('user_id', $user->user_id)
                ->with(['agent.information', 'property'])
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json($bookings);
        } catch (\Exception $e) {
            Log::error('Failed to fetch user bookings: ' . $e->getMessage(), [
                'exception' => $e,
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id(),
            ]);
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while loading your bookings. Please try again later.'
            ], 500);
        }
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'agent_id' => 'required|exists:cribs_agents,agent_id',
                'property_id' => 'nullable|exists:properties,property_id',
                'transaction_id' => 'required|exists:transactions,id',
                'inspection_date' => 'required|date',
                'inspection_time' => 'required|date_format:H:i',
                'amount' => 'required|numeric',
                'payment_status' => 'required|string',
                'payment_method' => 'required|string',
            ]);

            if ($validator->fails()) {
                return response()->json($validator->errors(), 422);
            }

            $user = Auth::user();

            $inspection = Inspection::create([
                'user_id' => $user->user_id, // Changed: use user_id
                'agent_id' => $request->agent_id,
                'property_id' => $request->property_id,
                'transaction_id' => $request->transaction_id,
                'inspection_date' => $request->inspection_date,
                'inspection_time' => $request->inspection_time,
                'amount' => $request->amount,
                'payment_status' => $request->payment_status,
                'payment_method' => $request->payment_method,
            ]);

            return response()->json($inspection, 201);
        } catch (\Exception $e) {
            Log::error('Failed to store inspection: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while scheduling the inspection. Please try again later.'
            ], 500);
        }
    }

    public function updateStatus(Request $request, Inspection $inspection)
    {
        try {
            $user = Auth::user();

            // Ensure the inspection belongs to the authenticated user
            if ($inspection->user_id !== $user->user_id) { // Changed: use user_id
                return response()->json(['message' => 'Unauthorized'], 403);
            }

            $validator = Validator::make($request->all(), [
                'status' => 'required|string|in:scheduled,confirmed,cancelled,completed,rescheduled',
                'reschedule_date' => 'required_if:status,rescheduled|date',
                'reschedule_time' => 'required_if:status,rescheduled|date_format:H:i',
                'reason_cancellation' => 'nullable|string|max:255',
            ]);

            if ($validator->fails()) {
                return response()->json($validator->errors(), 422);
            }

            $inspection->status = $request->status;

            if ($request->status === 'rescheduled') {
                // Update the main inspection date and time
                $inspection->inspection_date = $request->reschedule_date;
                $inspection->inspection_time = $request->reschedule_time;

                // Also log the reschedule date for historical tracking
                $inspection->reschedule_date = $request->reschedule_date;
                $inspection->reschedule_time = $request->reschedule_time;
            }

            if ($request->has('reason_cancellation')) {
                $inspection->reason_cancellation = $request->reason_cancellation;
            }

            $inspection->save();

            // Send notifications based on status change
            $inspection->load(['agent', 'property']);
            $agent = $inspection->agent;
            $property = $inspection->property;
            $userName = "{$user->first_name} {$user->last_name}";
            $agentName = $agent ? "{$agent->first_name} {$agent->last_name}" : "the agent";

            switch ($request->status) {
                case 'cancelled':
                    // Dispatch notifications asynchronously to prevent timeout
                    SendInspectionNotification::dispatch(
                        'user',
                        $user->user_id,
                        null,
                        'inspection_cancelled',
                        'Inspection Cancelled',
                        "Your inspection with {$agentName} has been cancelled.",
                        [
                            'inspection_id' => $inspection->id,
                            'agent_id' => $inspection->agent_id,
                            'reason' => $request->reason_cancellation ?? 'No reason provided',
                        ]
                    );

                    if ($agent) {
                        SendInspectionNotification::dispatch(
                            'agent',
                            null,
                            $agent->agent_id,
                            'inspection_cancelled',
                            'Inspection Cancelled',
                            "{$userName} has cancelled their inspection scheduled for {$inspection->inspection_date}.",
                            [
                                'inspection_id' => $inspection->id,
                                'user_id' => $user->user_id,
                                'user_name' => $userName,
                                'reason' => $request->reason_cancellation ?? 'No reason provided',
                            ]
                        );
                    }
                    break;

                case 'rescheduled':
                    // Dispatch notifications asynchronously to prevent timeout
                    SendInspectionNotification::dispatch(
                        'user',
                        $user->user_id,
                        null,
                        'inspection_rescheduled',
                        'Inspection Rescheduled',
                        "Your inspection with {$agentName} has been rescheduled to {$request->reschedule_date} at {$request->reschedule_time}.",
                        [
                            'inspection_id' => $inspection->id,
                            'agent_id' => $inspection->agent_id,
                            'new_date' => $request->reschedule_date,
                            'new_time' => $request->reschedule_time,
                        ]
                    );

                    if ($agent) {
                        SendInspectionNotification::dispatch(
                            'agent',
                            null,
                            $agent->agent_id,
                            'inspection_rescheduled',
                            'Inspection Rescheduled',
                            "{$userName} has rescheduled their inspection to {$request->reschedule_date} at {$request->reschedule_time}.",
                            [
                                'inspection_id' => $inspection->id,
                                'user_id' => $user->user_id,
                                'user_name' => $userName,
                                'new_date' => $request->reschedule_date,
                                'new_time' => $request->reschedule_time,
                            ]
                        );
                    }
                    break;

                case 'completed':
                    // Update total_sales count in agent_information table
                    \DB::table('agent_information')
                        ->where('agent_id', $inspection->agent_id)
                        ->increment('total_sales');

                    // === ESCROW RELEASE: Move funds from pending to available ===
                    $transaction = \DB::table('transactions')->where('id', $inspection->transaction_id)->first();

                    if ($transaction && $transaction->escrow_status == 1) {
                        $amount = $inspection->amount;

                        // Get agent wallet
                        $wallet = \DB::table('wallets')
                            ->where('user_id', $inspection->agent_id)
                            ->where('user_type', 'agent')
                            ->first();

                        if ($wallet) {
                            // Create escrow_release wallet transaction
                            $releaseReference = 'ESC_REL_' . uniqid() . '_' . time();
                            \DB::table('wallet_transactions')->insert([
                                'wallet_id' => $wallet->id,
                                'user_id' => $inspection->agent_id,
                                'user_type' => 'agent',
                                'transaction_type' => 'escrow_release',
                                'amount' => $amount,
                                'fee' => 0,
                                'net_amount' => $amount,
                                'balance_before' => $wallet->available_balance,
                                'balance_after' => $wallet->available_balance + $amount,
                                'currency' => 'NGN',
                                'reference' => $releaseReference,
                                'related_transaction_id' => $transaction->id,
                                'related_inspection_id' => $inspection->id,
                                'status' => 'success',
                                'description' => 'Inspection completed - escrow released',
                                'metadata' => json_encode([
                                    'user_name' => $userName,
                                    'completed_date' => now()->toDateString(),
                                ]),
                                'created_at' => now(),
                                'updated_at' => now(),
                            ]);

                            // Update wallet: move from pending to available, add to total_earned
                            \DB::table('wallets')
                                ->where('id', $wallet->id)
                                ->update([
                                    'pending_balance' => \DB::raw("pending_balance - $amount"),
                                    'available_balance' => \DB::raw("available_balance + $amount"),
                                    'total_earned' => \DB::raw("total_earned + $amount"),
                                    'updated_at' => now(),
                                ]);

                            // Update escrow_hold transaction status to success
                            \DB::table('wallet_transactions')
                                ->where('related_inspection_id', $inspection->id)
                                ->where('transaction_type', 'escrow_hold')
                                ->update([
                                    'status' => 'success',
                                    'updated_at' => now(),
                                ]);

                            // Update transaction escrow_status to released
                            \DB::table('transactions')
                                ->where('id', $transaction->id)
                                ->update([
                                    'escrow_status' => 2, // Released
                                    'updated_at' => now(),
                                ]);

                            // Dispatch payment notification asynchronously
                            if ($agent) {
                                SendInspectionNotification::dispatch(
                                    'agent',
                                    null,
                                    $agent->agent_id,
                                    'payment_received',
                                    'Payment Received',
                                    "₦" . number_format((float) $amount, 2) . " has been added to your wallet for the completed inspection.",
                                    [
                                        'inspection_id' => $inspection->id,
                                        'amount' => $amount,
                                        'wallet_balance' => $wallet->available_balance + $amount,
                                    ]
                                );
                            }
                        }
                    }

                    // Dispatch notifications asynchronously to prevent timeout
                    SendInspectionNotification::dispatch(
                        'user',
                        $user->user_id,
                        null,
                        'inspection_completed',
                        'Inspection Completed',
                        "Your inspection with {$agentName} has been marked as completed.",
                        [
                            'inspection_id' => $inspection->id,
                            'agent_id' => $inspection->agent_id,
                            'property_id' => $inspection->property_id,
                        ]
                    );

                    if ($agent) {
                        SendInspectionNotification::dispatch(
                            'agent',
                            null,
                            $agent->agent_id,
                            'inspection_completed',
                            'Inspection Completed',
                            "Inspection with {$userName} has been marked as completed.",
                            [
                                'inspection_id' => $inspection->id,
                                'user_id' => $user->user_id,
                                'user_name' => $userName,
                                'property_id' => $inspection->property_id,
                            ]
                        );
                    }
                    break;

            }

            return response()->json($inspection);
        } catch (\Exception $e) {
            Log::error('Failed to update inspection status: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while updating the inspection status. Please try again later.'
            ], 500);
        }
    }
}
