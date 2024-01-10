<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class TestTask extends Command
{
    protected $signature = 'test:task';

    protected $description = 'Test task executed every minute';

    public function handle()
    {
        $message = 'Hello, this is a test task running at ' . now();
        Log::info($message);
        $this->info('Task executed successfully.');
    }
}
