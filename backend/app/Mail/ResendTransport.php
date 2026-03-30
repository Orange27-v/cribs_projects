<?php

namespace App\Mail;

use Resend;
use Symfony\Component\Mailer\SentMessage;
use Symfony\Component\Mailer\Transport\AbstractTransport;
use Symfony\Component\Mime\MessageConverter;

class ResendTransport extends AbstractTransport
{
    protected $resend;

    public function __construct()
    {
        parent::__construct();
        $this->resend = Resend::client(config('services.resend.key'));
    }

    protected function doSend(SentMessage $message): void
    {
        $email = MessageConverter::toEmail($message->getOriginalMessage());

        $payload = [
            'from' => config('mail.from.address'),
            'to' => collect($email->getTo())->map->getAddress()->toArray(),
            'subject' => $email->getSubject(),
        ];

        // Add HTML body if available
        if ($email->getHtmlBody()) {
            $payload['html'] = $email->getHtmlBody();
        }

        // Add text body if available
        if ($email->getTextBody()) {
            $payload['text'] = $email->getTextBody();
        }

        $this->resend->emails->send($payload);
    }

    public function __toString(): string
    {
        return 'resend';
    }
}
