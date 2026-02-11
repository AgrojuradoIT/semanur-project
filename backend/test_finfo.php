<?php
if (class_exists('finfo')) {
    echo "finfo class exists\n";
    $finfo = new finfo(FILEINFO_MIME_TYPE);
    echo "finfo created successfully\n";
} else {
    echo "finfo class NOT found\n";
    echo "Core extensions: " . implode(', ', get_loaded_extensions()) . "\n";
}
