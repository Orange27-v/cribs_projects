<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use App\Models\Agent;
use App\Models\AgentInformation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use App\Helpers\ChatSyncHelper;

class AgentProfileController extends Controller
{
    /**
     * Get agent profile information
     * Checks if agent_information exists, if not creates a default entry
     */
    public function getAgentProfile(Request $request)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Check if agent information exists
            $agentInfo = AgentInformation::where('agent_id', $agent->agent_id)->first();

            // If doesn't exist, create default entry
            if (!$agentInfo) {
                $agentInfo = AgentInformation::create([
                    'agent_id' => $agent->agent_id,
                    'booking_fees' => 0,
                    'bio' => null,
                    'gender' => null,
                    'is_licensed' => false,
                    'agent_rank' => 0,
                    'experience_years' => 0,
                    'profile_picture_url' => null,
                    'member_since' => now(),
                    'average_response_time_minutes' => null,
                    'total_sales' => 0,
                    'average_rating' => 0.0,
                    'total_reviews' => 0,
                    'active_areas' => null,
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Agent profile retrieved successfully',
                'data' => [
                    'agent' => [
                        'agent_id' => $agent->agent_id,
                        'first_name' => $agent->first_name,
                        'last_name' => $agent->last_name,
                        'email' => $agent->email,
                        'phone' => $agent->phone,
                        'area' => $agent->area,
                        'role' => $agent->role,
                    ],
                    'agent_information' => $agentInfo
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to retrieve agent profile: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while retrieving your profile details. Please try again later.'
            ], 500);
        }
    }

    /**
     * Update agent profile information
     * Creates or updates agent_information record
     */
    public function updateAgentProfile(Request $request)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Validate request
            $validator = Validator::make($request->all(), [
                'bio' => 'nullable|string|max:1000',
                'gender' => 'nullable|string|in:Male,Female',
                'is_licensed' => 'nullable|boolean',
                'experience_years' => 'nullable|integer|min:0|max:50',
                'booking_fees' => 'nullable|numeric|min:0|max:10000',
                'active_areas' => 'nullable|array|max:20',
                'active_areas.*' => 'string|max:255',
                'profile_picture' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Check if agent information exists
            $agentInfo = AgentInformation::where('agent_id', $agent->agent_id)->first();

            // Prepare data for update/create
            $data = [
                'agent_id' => $agent->agent_id,
            ];

            if ($request->has('bio')) {
                $data['bio'] = $request->bio;
            }

            if ($request->has('gender')) {
                $data['gender'] = $request->gender;
            }

            if ($request->has('is_licensed')) {
                $data['is_licensed'] = filter_var($request->is_licensed, FILTER_VALIDATE_BOOLEAN);
            }

            if ($request->has('experience_years')) {
                $data['experience_years'] = (int) $request->experience_years;
            }

            if ($request->has('booking_fees')) {
                $data['booking_fees'] = (float) $request->booking_fees;
            }

            if ($request->has('active_areas')) {
                $data['active_areas'] = $request->active_areas;
            }

            // Handle profile picture upload
            if ($request->hasFile('profile_picture')) {
                $file = $request->file('profile_picture');

                // Delete old profile picture if exists
                if ($agentInfo && $agentInfo->profile_picture_url) {
                    // Extract path from URL and delete
                    $oldPath = str_replace(url('storage/'), '', $agentInfo->profile_picture_url);
                    if (Storage::disk('public')->exists($oldPath)) {
                        Storage::disk('public')->delete($oldPath);
                    }
                }

                // Store new profile picture
                $path = $file->store('agent_pictures', 'public');
                $data['profile_picture_url'] = $path; // Store relative path only
            }

            // Update or create agent information
            if ($agentInfo) {
                $agentInfo->update($data);
                $message = 'Agent profile updated successfully';
            } else {
                // Set default values for new record
                $data = array_merge([
                    'agent_rank' => 0,
                    'member_since' => now(),
                    'average_response_time_minutes' => null,
                    'total_sales' => 0,
                    'average_rating' => 0.0,
                    'total_reviews' => 0,
                    'active_areas' => null,
                ], $data);

                $agentInfo = AgentInformation::create($data);
                $message = 'Agent profile created successfully';
            }

            // Sync with ChatDB
            ChatSyncHelper::syncProfile(
                "agent_{$agent->agent_id}",
                "{$agent->first_name} {$agent->last_name}",
                $agentInfo->profile_picture_url
            );

            return response()->json([
                'success' => true,
                'message' => $message,
                'data' => [
                    'agent_information' => $agentInfo
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to update agent profile: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating your profile. Please try again later.'
            ], 500);
        }
    }

    /**
     * Check if agent has completed profile
     */
    public function checkProfileCompletion(Request $request)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $agentInfo = AgentInformation::where('agent_id', $agent->agent_id)->first();

            $isComplete = false;
            $missingFields = [];

            if ($agentInfo) {
                // Check required fields
                if (empty($agentInfo->bio)) {
                    $missingFields[] = 'bio';
                }
                if (empty($agentInfo->gender)) {
                    $missingFields[] = 'gender';
                }
                if ($agentInfo->experience_years === null || $agentInfo->experience_years === 0) {
                    $missingFields[] = 'experience_years';
                }
                if ($agentInfo->booking_fees === null || $agentInfo->booking_fees === 0) {
                    $missingFields[] = 'booking_fees';
                }

                $isComplete = empty($missingFields);
            } else {
                $missingFields = ['bio', 'gender', 'experience_years', 'booking_fees'];
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'is_complete' => $isComplete,
                    'missing_fields' => $missingFields,
                    'has_profile' => $agentInfo !== null
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to check profile completion: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while checking profile completion. Please try again later.'
            ], 500);
        }
    }
}
