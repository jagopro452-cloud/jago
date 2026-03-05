<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class DatabaseBackup extends Command
{
    protected $signature = 'database:backup {--verify : Verify backup integrity after creation}';

    protected $description = 'Automated daily database backup with retention policy and integrity verification';

    private int $retentionDays = 7;

    public function handle(): int
    {
        $startTime = microtime(true);
        $backupDir = storage_path('backups');

        if (!is_dir($backupDir)) {
            mkdir($backupDir, 0755, true);
        }

        $timestamp = date('Y-m-d_H-i-s');
        $filename = "jago_backup_{$timestamp}.sql";
        $filepath = "{$backupDir}/{$filename}";

        $this->info("Starting database backup: {$filename}");
        Log::channel('single')->info("Database backup started: {$filename}");

        try {
            $host = config('database.connections.pgsql.host');
            $port = config('database.connections.pgsql.port');
            $database = config('database.connections.pgsql.database');
            $username = config('database.connections.pgsql.username');
            $password = config('database.connections.pgsql.password');

            putenv("PGPASSWORD={$password}");

            $command = sprintf(
                'pg_dump -h %s -p %s -U %s -d %s --no-owner --no-privileges --clean --if-exists -F p -f %s 2>&1',
                escapeshellarg($host),
                escapeshellarg($port),
                escapeshellarg($username),
                escapeshellarg($database),
                escapeshellarg($filepath)
            );

            exec($command, $output, $exitCode);

            putenv("PGPASSWORD=");

            if ($exitCode !== 0) {
                $error = implode("\n", $output);
                Log::channel('single')->error("Database backup failed: {$error}");
                $this->error("Backup failed: {$error}");
                return Command::FAILURE;
            }

            $fileSize = filesize($filepath);
            $fileSizeMB = round($fileSize / 1024 / 1024, 2);

            if ($fileSize < 1024) {
                Log::channel('single')->error("Backup file suspiciously small ({$fileSize} bytes), may be corrupted");
                $this->error("Backup file too small ({$fileSize} bytes) - possible corruption");
                @unlink($filepath);
                return Command::FAILURE;
            }

            $gzFilepath = "{$filepath}.gz";
            $gzCommand = sprintf('gzip -9 %s 2>&1', escapeshellarg($filepath));
            exec($gzCommand, $gzOutput, $gzExitCode);

            if ($gzExitCode === 0 && file_exists($gzFilepath)) {
                $compressedSize = round(filesize($gzFilepath) / 1024 / 1024, 2);
                $this->info("Compressed: {$fileSizeMB}MB -> {$compressedSize}MB");
                $finalPath = $gzFilepath;
            } else {
                $finalPath = $filepath;
                $compressedSize = $fileSizeMB;
            }

            if ($this->option('verify')) {
                $this->info("Verifying backup integrity...");
                $tableCount = DB::select("SELECT COUNT(*) as count FROM information_schema.tables WHERE table_schema = 'public'")[0]->count;
                $this->info("Database has {$tableCount} tables");

                if (str_ends_with($finalPath, '.gz')) {
                    $checkCmd = sprintf('zgrep -c "CREATE TABLE" %s 2>/dev/null', escapeshellarg($finalPath));
                } else {
                    $checkCmd = sprintf('grep -c "CREATE TABLE" %s 2>/dev/null', escapeshellarg($finalPath));
                }
                $backupTableCount = (int) trim(shell_exec($checkCmd) ?? '0');

                if ($backupTableCount < ($tableCount * 0.8)) {
                    $this->warn("Backup may be incomplete: {$backupTableCount} tables in backup vs {$tableCount} in database");
                    Log::channel('single')->warning("Backup integrity warning: {$backupTableCount}/{$tableCount} tables");
                } else {
                    $this->info("Integrity check passed: {$backupTableCount} tables in backup");
                    Log::channel('single')->info("Backup integrity verified: {$backupTableCount}/{$tableCount} tables");
                }
            }

            $this->cleanOldBackups($backupDir);

            $elapsed = round(microtime(true) - $startTime, 2);
            $this->info("Backup completed in {$elapsed}s: {$compressedSize}MB");
            Log::channel('single')->info("Database backup completed: {$filename}.gz ({$compressedSize}MB) in {$elapsed}s");

            $this->writeBackupLog($backupDir, $filename, $compressedSize, $elapsed);

            return Command::SUCCESS;

        } catch (\Exception $e) {
            Log::channel('single')->error("Database backup exception: " . $e->getMessage());
            $this->error("Backup exception: " . $e->getMessage());
            @unlink($filepath);
            return Command::FAILURE;
        }
    }

    private function cleanOldBackups(string $backupDir): void
    {
        $cutoffTime = time() - ($this->retentionDays * 86400);
        $files = glob("{$backupDir}/jago_backup_*.sql*");
        $deleted = 0;

        foreach ($files as $file) {
            if (filemtime($file) < $cutoffTime) {
                @unlink($file);
                $deleted++;
            }
        }

        if ($deleted > 0) {
            $this->info("Cleaned {$deleted} old backup(s) older than {$this->retentionDays} days");
            Log::channel('single')->info("Backup cleanup: removed {$deleted} files older than {$this->retentionDays} days");
        }
    }

    private function writeBackupLog(string $backupDir, string $filename, float $sizeMB, float $elapsed): void
    {
        $logFile = "{$backupDir}/backup_log.json";
        $log = [];

        if (file_exists($logFile)) {
            $log = json_decode(file_get_contents($logFile), true) ?? [];
        }

        $log[] = [
            'timestamp' => now()->toIso8601String(),
            'filename' => $filename . '.gz',
            'size_mb' => $sizeMB,
            'duration_seconds' => $elapsed,
            'status' => 'success',
        ];

        $log = array_slice($log, -30);

        file_put_contents($logFile, json_encode($log, JSON_PRETTY_PRINT));
    }
}
