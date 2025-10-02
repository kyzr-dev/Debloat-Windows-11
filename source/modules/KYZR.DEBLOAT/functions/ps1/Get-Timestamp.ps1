function Get-Timestamp {
    $ts = (Get-Date).ToString("HH:mm:ss")
    return $ts
}