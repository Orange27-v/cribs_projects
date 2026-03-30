<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Property extends Model
{
    use HasFactory;

    protected $table = 'properties';

    protected $fillable = [
        'property_id',
        'agent_id',
        'title',
        'type',
        'location',
        'listing_type',
        'price',
        'beds',
        'baths',
        'sqft',
        'description',
        'address',
        'inspection_fee',
        'status',
        'images',
        'is_featured',
        'is_verified',
    ];

    protected $casts = [
        'images' => 'array',
        'is_featured' => 'boolean',
        'is_verified' => 'boolean',
    ];

    public function getImagesAttribute($value)
    {
        // Handle NULL or empty string directly
        if (empty($value)) {
            return [];
        }

        // Try to decode as JSON array
        $images = json_decode($value, true);

        // If decoding was successful and it's an array, process it
        if (is_array($images)) {
            // Filter out any empty strings that might result from malformed JSON arrays
            $images = array_filter($images, fn($img) => !empty($img));
            return array_map(function ($image) {
                // If already a full URL, return as is
                if (filter_var($image, FILTER_VALIDATE_URL)) {
                    return $image;
                }

                // Use asset() instead of Storage::url() to avoid triggering Flysystem's finfo dependency
                return asset('storage/property_images/' . $image);
            }, $images);
        }

        // If it's not a JSON array, check if it's a single valid URL string
        if (is_string($value) && filter_var($value, FILTER_VALIDATE_URL)) {
            return [$value]; // Return it as an array with a single element
        }

        // If all checks fail (e.g., malformed non-JSON string), return an empty array
        return [];
    }

    public function agent()
    {
        return $this->belongsTo(Agent::class, 'agent_id', 'agent_id');
    }
}