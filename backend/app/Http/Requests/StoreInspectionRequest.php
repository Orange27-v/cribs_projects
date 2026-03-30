<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;

class StoreInspectionRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     *
     * @return bool
     */
    public function authorize()
    {
        return true; // Authorize all authenticated requests
    }

    /**
     * Prepare the data for validation.
     *
     * @return void
     */
    protected function prepareForValidation()
    {
        // If property_id is empty or not present, ensure it is null
        if (empty($this->property_id)) {
            $this->merge([
                'property_id' => null,
            ]);
        }
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, mixed>
     */
    public function rules()
    {
        return [
            'agent_id' => 'required|exists:cribs_agents,id',
            'property_id' => 'nullable|exists:properties,id',
            'inspection_date' => 'required|date',
            'inspection_time' => 'required|date_format:H:i',
            'payment_method' => 'required|string',
            'payment_status' => 'required|in:pending,paid,refunded',
            'amount' => 'required|numeric',
            'transaction_ref' => 'required|string',
        ];
    }
}
