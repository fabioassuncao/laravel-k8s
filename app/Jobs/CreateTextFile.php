<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Storage;

class CreateTextFile implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public function handle()
    {
        sleep(rand(5, 30));

        $filePath = 'local/textfile.txt';
        $content = 'Date and Time: ' . now() . "\n";

        // Append existing content if file exists
        if (Storage::exists($filePath)) {
            $existingContent = Storage::get($filePath);
            $content .= $existingContent;
        }

        // Write content to the file
        Storage::put($filePath, $content);
    }
}
