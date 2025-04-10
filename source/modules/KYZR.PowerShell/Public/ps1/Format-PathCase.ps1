function Format-PathCase {
    param (
        [parameter(Mandatory=$true)][string]$FilePath
    )

    if (-not ((Test-Path $FilePath -PathType Leaf) -or (Test-Path $FilePath -PathType Container))){
        # Requested file does not exist
        return $null
    }

    $newPath = ""
    foreach ($segment in $FilePath.Split("\")) {
        if ($newPath -eq ""){ # Identifying that the loop has not yet iterated, meaning index 0, meaning directory root.
            $newPath = $segment.ToUpper() + "\"
            continue
        }
        $newPath = [System.IO.Directory]::GetFileSystemEntries($newPath, $segment)[0] # Iteratively growing $newPath by current $segment
    }
    return $newPath
}