<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class AgentInspectionController extends Controller
{
    /**
     * Get upcoming inspections count for the authenticated agent
     */
    public function getUpcomingCount(Request $request)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Count upcoming inspections (scheduled for future dates)
            $upcomingCount = DB::table('inspections')
                ->where('agent_id', $agent->agent_id)
                ->where('inspection_date', '>=', now())
                ->whereIn('status', ['scheduled', 'confirmed'])
                ->count();

            return response()->json([
                'success' => true,
                'data' => [
                    'upcoming_count' => $upcomingCount
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to fetch upcoming inspections count: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while loading inspection counts. Please try again later.'
            ], 500);
        }
    }

    /**
     * Get all inspections for the authenticated agent
     */
    public function getInspections(Request $request)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $status = $request->input('status'); // upcoming, completed, cancelled
            $perPage = $request->input('per_page', 20);

            $query = DB::table('inspections')
                ->select(
                    'inspections.*',
                    'cribs_users.user_id',
                    'cribs_users.first_name',
                    'cribs_users.last_name',
                    'cribs_users.phone',
                    'cribs_users.email',
                    'cribs_users.profile_picture_url',
                    'properties.property_id',
                    'properties.title',
                    'properties.address',
                    'properties.location'
                )
                ->leftJoin('cribs_users', 'inspections.user_id', '=', 'cribs_users.user_id')
                ->leftJoin('properties', 'inspections.property_id', '=', 'properties.property_id')
                ->where('inspections.agent_id', $agent->agent_id);

            // Filter by status if provided
            if ($status === 'upcoming') {
                $query->where('inspections.inspection_date', '>=', now())
                    ->whereIn('inspections.status', ['scheduled', 'confirmed']);
            } elseif ($status === 'completed') {
                $query->where('inspections.status', 'completed');
            } elseif ($status === 'cancelled') {
                $query->where('inspections.status', 'cancelled');
            }

            $inspections = $query->orderBy('inspections.inspection_date', 'desc')
                ->paginate($perPage);

            // Transform the data to nest user and property objects
            $transformedData = collect($inspections->items())->map(function ($inspection) {
                // Build full profile picture URL
                $profilePictureUrl = null;
                if ($inspection->profile_picture_url) {
                    // Check if it's already a full URL
                    if (str_starts_with($inspection->profile_picture_url, 'http')) {
                        $profilePictureUrl = $inspection->profile_picture_url;
                    } else {
                        // Prepend storage URL
                        $profilePictureUrl = url('storage/' . $inspection->profile_picture_url);
                    }
                }

                return [
                    'id' => $inspection->id,
                    'inspection_date' => $inspection->inspection_date,
                    'inspection_time' => $inspection->inspection_time,
                    'status' => $inspection->status,
                    'amount' => $inspection->amount,
                    'payment_status' => $inspection->payment_status,
                    'reason_cancellation' => $inspection->reason_cancellation,
                    'reschedule_date' => $inspection->reschedule_date,
                    'reschedule_time' => $inspection->reschedule_time,
                    'created_at' => $inspection->created_at,
                    'updated_at' => $inspection->updated_at,
                    'user' => [
                        'user_id' => $inspection->user_id,
                        'first_name' => $inspection->first_name,
                        'last_name' => $inspection->last_name,
                        'phone' => $inspection->phone,
                        'email' => $inspection->email,
                        'profile_picture_url' => $profilePictureUrl,
                    ],
                    'property' => $inspection->property_id ? [
                        'property_id' => $inspection->property_id,
                        'title' => $inspection->title,
                        'address' => $inspection->address,
                        'location' => $inspection->location,
                    ] : null,
                ];
            });

            return response()->json([
                'success' => true,
                'data' => [
                    'current_page' => $inspections->currentPage(),
                    'data' => $transformedData,
                    'per_page' => $inspections->perPage(),
                    'total' => $inspections->total(),
                    'last_page' => $inspections->lastPage(),
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to fetch inspections: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while loading your inspections. Please try again later.'
            ], 500);
        }
    }

    /**
     * Get inspection details
     */
    public function getInspectionDetails(Request $request, $inspectionId)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $inspection = DB::table('inspections')
                ->where('inspection_id', $inspectionId)
                ->where('agent_id', $agent->agent_id)
                ->first();

            if (!$inspection) {
                return response()->json([
                    'success' => false,
                    'message' => 'Inspection not found'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $inspection
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to fetch inspection details: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while loading inspection details. Please try again later.'
            ], 500);
        }
    }

    /**
     * Update inspection status
     */
    public function updateInspectionStatus(Request $request, $inspectionId)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $request->validate([
                'status' => 'required|in:scheduled,confirmed,completed,cancelled'
            ]);

            $updated = DB::table('inspections')
                ->where('inspection_id', $inspectionId)
                ->where('agent_id', $agent->agent_id)
                ->update([
                    'status' => $request->status,
                    'updated_at' => now()
                ]);

            if ($updated) {
                return response()->json([
                    'success' => true,
                    'message' => 'Inspection status updated successfully'
                ], 200);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Inspection not found'
                ], 404);
            }

        } catch (\Exception $e) {
            Log::error('Failed to update inspection status: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating the inspection status. Please try again later.'
            ], 500);
        }
    }

    /**
     * Reschedule an inspection
     */
    public function rescheduleInspection(Request $request, $inspectionId)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $request->validate([
                'inspection_date' => 'required|date|after_or_equal:today',
                'inspection_time' => 'required|date_format:H:i:s',
            ]);

            // Check if inspection belongs to this agent
            $inspection = DB::table('inspections')
                ->where('id', $inspectionId)
                ->where('agent_id', $agent->agent_id)
                ->first();

            if (!$inspection) {
                return response()->json([
                    'success' => false,
                    'message' => 'Inspection not found or does not belong to you'
                ], 404);
            }

            // Update inspection with new date and time
            $updated = DB::table('inspections')
                ->where('id', $inspectionId)
                ->update([
                    'reschedule_date' => $request->inspection_date,
                    'reschedule_time' => $request->inspection_time,
                    'status' => 'rescheduled',
                    'updated_at' => now()
                ]);

            if ($updated) {
                return response()->json([
                    'success' => true,
                    'message' => 'Inspection rescheduled successfully',
                    'data' => [
                        'inspection_id' => $inspectionId,
                        'reschedule_date' => $request->inspection_date,
                        'reschedule_time' => $request->inspection_time,
                        'status' => 'rescheduled'
                    ]
                ], 200);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to reschedule inspection'
                ], 500);
            }

        } catch (\Exception $e) {
            Log::error('Failed to reschedule inspection: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while rescheduling the inspection. Please try again later.'
            ], 500);
        }
    }
}
