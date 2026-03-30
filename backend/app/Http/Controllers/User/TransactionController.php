<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class TransactionController extends Controller
{
    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'payer_id' => 'required|exists:cribs_users,user_id', // Now validates against user_id (bigint)
                'payee_id' => 'required|exists:cribs_agents,agent_id',
                'amount' => 'required|numeric',
                'payment_reference' => 'required|string',
                'status' => 'required|string',
                'channel' => 'required|string',
            ]);

            if ($validator->fails()) {
                return response()->json($validator->errors(), 422);
            }

            $transaction = Transaction::create($request->all());

            return response()->json($transaction, 201);
        } catch (\Exception $e) {
            Log::error('Failed to store transaction: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while saving your transaction. Please try again later.'
            ], 500);
        }
    }
}
