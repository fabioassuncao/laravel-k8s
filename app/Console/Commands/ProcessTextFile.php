<?php

namespace App\Console\Commands;

use App\Jobs\CreateTextFile;
use Illuminate\Console\Command;

class ProcessTextFile extends Command
{
    protected $signature = 'process:textfile';

    protected $description = 'Process text file by triggering a job';

    public function handle()
    {
        dispatch(new CreateTextFile());
        $this->info('Text file processing job pushed to the queue.');
    }
}
