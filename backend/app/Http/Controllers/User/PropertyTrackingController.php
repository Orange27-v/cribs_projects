<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class PropertyTrackingController extends Controller
{
    /**
     * Increment property view count
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function incrementViewCount(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'property_id' => 'required|integer|exists:properties,property_id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $propertyId = $request->property_id;

            // Increment view count using primary key 'id'
            DB::table('properties')
                ->where('property_id', $propertyId)
                ->increment('view_count');

            // Get updated count
            $property = DB::table('properties')
                ->where('property_id', $propertyId)
                ->select('view_count', 'inspection_booking_count', 'leads_count')
                ->first();

            return response()->json([
                'success' => true,
                'message' => 'View count incremented successfully',
                'data' => [
                    'property_id' => $propertyId,
                    'view_count' => $property->view_count,
                    'inspection_booking_count' => $property->inspection_booking_count,
                    'leads_count' => $property->leads_count,
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to increment view count: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating property view count.'
            ], 500);
        }
    }

    /**
     * Increment property inspection booking count
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function incrementInspectionBookingCount(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'property_id' => 'required|integer|exists:properties,property_id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $propertyId = $request->property_id;

            // Increment inspection booking count
            DB::table('properties')
                ->where('property_id', $propertyId)
                ->increment('inspection_booking_count');

            // Get updated count
            $property = DB::table('properties')
                ->where('property_id', $propertyId)
                ->select('view_count', 'inspection_booking_count', 'leads_count')
                ->first();

            return response()->json([
                'success' => true,
                'message' => 'Inspection booking count incremented successfully',
                'data' => [
                    'property_id' => $propertyId,
                    'view_count' => $property->view_count,
                    'inspection_booking_count' => $property->inspection_booking_count,
                    'leads_count' => $property->leads_count,
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to increment inspection booking count: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating property inspection count.'
            ], 500);
        }
    }

    /**
     * Increment property leads count
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function incrementLeadsCount(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'property_id' => 'required|integer|exists:properties,property_id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $propertyId = $request->property_id;

            // Increment leads count
            DB::table('properties')
                ->where('property_id', $propertyId)
                ->increment('leads_count');

            // Get updated count
            $property = DB::table('properties')
                ->where('property_id', $propertyId)
                ->select('view_count', 'inspection_booking_count', 'leads_count')
                ->first();

            return response()->json([
                'success' => true,
                'message' => 'Leads count incremented successfully',
                'data' => [
                    'property_id' => $propertyId,
                    'view_count' => $property->view_count,
                    'inspection_booking_count' => $property->inspection_booking_count,
                    'leads_count' => $property->leads_count,
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to increment leads count: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating property leads count.'
            ], 500);
        }
    }

    /**
     * Decrement property leads count (when property is unsaved)
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function decrementLeadsCount(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'property_id' => 'required|integer|exists:properties,property_id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $propertyId = $request->property_id;

            // Decrement leads count (minimum 0)
            DB::table('properties')
                ->where('property_id', $propertyId)
                ->where('leads_count', '>', 0)
                ->decrement('leads_count');

            // Get updated count
            $property = DB::table('properties')
                ->where('property_id', $propertyId)
                ->select('view_count', 'inspection_booking_count', 'leads_count')
                ->first();

            return response()->json([
                'success' => true,
                'message' => 'Leads count decremented successfully',
                'data' => [
                    'property_id' => $propertyId,
                    'view_count' => $property->view_count,
                    'inspection_booking_count' => $property->inspection_booking_count,
                    'leads_count' => $property->leads_count,
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to decrement leads count: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating property leads count.'
            ], 500);
        }
    }

    /**
     * Get property tracking statistics
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getPropertyStats(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'property_id' => 'required|integer|exists:properties,property_id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $propertyId = $request->property_id;

            $property = DB::table('properties')
                ->where('property_id', $propertyId)
                ->select('view_count', 'inspection_booking_count', 'leads_count')
                ->first();

            if (!$property) {
                return response()->json([
                    'success' => false,
                    'message' => 'Property not found'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'message' => 'Property statistics retrieved successfully',
                'data' => [
                    'property_id' => $propertyId,
                    'view_count' => $property->view_count,
                    'inspection_booking_count' => $property->inspection_booking_count,
                    'leads_count' => $property->leads_count,
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to retrieve property statistics: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while retrieving property statistics.'
            ], 500);
        }
    }
}
