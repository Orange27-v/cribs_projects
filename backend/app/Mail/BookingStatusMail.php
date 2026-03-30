<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class BookingStatusMail extends Mailable
{
    use Queueable, SerializesModels;

    public $bookingData;
    public $status; // 'rescheduled', 'completed', 'cancelled'
    public $recipientType; // 'user' or 'agent'

    /**
     * Create a new message instance.
     */
    public function __construct($bookingData, $status, $recipientType = 'user')
    {
        $this->bookingData = $bookingData;
        $this->status = $status;
        $this->recipientType = $recipientType;
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        $subjects = [
            'rescheduled' => 'Inspection Rescheduled - Cribs Arena',
            'completed' => 'Inspection Completed - Cribs Arena',
            'cancelled' => 'Inspection Cancelled - Cribs Arena',
        ];

        return new Envelope(
            subject: $subjects[$this->status] ?? 'Inspection Update - Cribs Arena',
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            html: 'emails.booking-status',
        );
    }

    /**
     * Get the attachments for the message.
     *
     * @return array<int, \Illuminate\Mail\Mailables\Attachment>
     */
    public function attachments(): array
    {
        return [];
    }
}
