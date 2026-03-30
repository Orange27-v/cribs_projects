<?php

namespace App\Console\Commands;

use App\Services\FCMService;
use Illuminate\Console\Command;

class GetFCMTokenCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'fcm:get-token';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Retrieves and displays the FCM access token.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        try {
            $fcmService = new FCMService();
            $token = $fcmService->getAccessToken();
            $this->info('FCM Access Token:');
            $this->info($token);
        } catch (\Exception $e) {
            $this->error('Error retrieving FCM token: ' . $e->getMessage());
        }
    }
}