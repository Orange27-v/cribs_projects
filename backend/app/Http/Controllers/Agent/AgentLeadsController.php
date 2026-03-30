<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class AgentLeadsController extends Controller
{
    public function index(Request $request)
    {
        $agent = $request->user();

        try {
            $leads = DB::table('saved_properties')
                ->join('cribs_users', 'saved_properties.user_id', '=', 'cribs_users.id')
                ->join('properties', 'saved_properties.property_id', '=', 'properties.property_id')
                ->where('saved_properties.agent_id', $agent->agent_id)
                ->select(
                    'saved_properties.id as lead_id',
                    'saved_properties.created_at',
                    'cribs_users.id as user_pk',
                    'cribs_users.user_id as user_public_id',
                    'cribs_users.first_name',
                    'cribs_users.last_name',
                    'cribs_users.email',
                    'cribs_users.phone',
                    'cribs_users.profile_picture_url',
                    'properties.property_id as property_public_id',
                    'properties.title',
                    'properties.address',
                    'properties.price',
                    'properties.images'
                )
                ->orderBy('saved_properties.created_at', 'desc')
                ->get();

            $formattedLeads = $leads->map(function ($lead) {
                $images = json_decode($lead->images, true);
                // Handle various image formats (string or array)
                if (is_string($images)) {
                    $images = json_decode($images, true);
                }
                $mainImage = (!empty($images) && is_array($images)) ? $images[0] : null;

                // Ensure price is a string
                $price = $lead->price;

                return [
                    'id' => $lead->lead_id,
                    'user_id' => $lead->user_public_id,
                    'property_id' => $lead->property_public_id,
                    'user' => [
                        'id' => $lead->user_pk,
                        'user_id' => $lead->user_public_id,
                        'first_name' => $lead->first_name,
                        'last_name' => $lead->last_name,
                        'email' => $lead->email,
                        'phone' => $lead->phone,
                        'profile_picture_url' => $lead->profile_picture_url,
                    ],
                    'property' => [
                        'id' => $lead->property_public_id,
                        'title' => $lead->title,
                        'address' => $lead->address,
                        'price' => $price,
                        'main_image_url' => $mainImage,
                    ]
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $formattedLeads
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch leads: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while loading your leads. Please try again later.'
            ], 500);
        }
    }
}
