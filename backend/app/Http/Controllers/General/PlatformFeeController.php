<?php

namespace App\Http\Controllers\General;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class PlatformFeeController extends Controller
{
    /**
     * Get the current platform fee
     * 
     * @return \Illuminate\Http\JsonResponse
     */
    public function getPlatformFee()
    {
        try {
            $fee = DB::table('platform_settings')
                ->where('key_name', 'platform_fee')
                ->value('value');

            return response()->json([
                'success' => true,
                'message' => 'Platform fee retrieved successfully',
                'data' => [
                    'platform_fee' => (float) ($fee ?? 0.00)
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to retrieve platform fee: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while retrieving platform fee. Please try again later.'
            ], 500);
        }
    }

    /**
     * Log a collected platform fee
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function logPlatformFee(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'transaction_reference' => 'required|string',
            'amount' => 'required|numeric',
            'source_app' => 'required|in:user_app,agent_app',
            'user_id' => 'nullable|integer',
            'description' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $logId = DB::table('platform_fee_logs')->insertGetId([
                'transaction_reference' => $request->transaction_reference,
                'amount' => $request->amount,
                'source_app' => $request->source_app,
                'user_id' => $request->user_id,
                'description' => $request->description,
                'created_at' => now(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Platform fee logged successfully',
                'data' => [
                    'log_id' => $logId
                ]
            ], 201);

        } catch (\Exception $e) {
            Log::error('Failed to log platform fee: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while logging platform fee. Please try again later.'
            ], 500);
        }
    }
}
