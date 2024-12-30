if (-not $BUCKET) {
    $BUCKET=${env:BUCKET}
}

$KEYS=250
$COUNT=0

aws s3 rm "s3://$BUCKET" --recursive | Out-Null
do {
    $NEXT_MARKER=@()
    if ($LIST_OBJECT_VERSIONS) {
        $NEXT_MARKER+=@(
            "--key-marker"
            $($LIST_OBJECT_VERSIONS.NextKeyMarker)
        )
        $NEXT_MARKER+=@(
            "--version-id-marker"
            $($LIST_OBJECT_VERSIONS.NextVersionIdMarker)
        )
    }
    $LIST_OBJECT_VERSIONS=aws s3api list-object-versions `
        --bucket $BUCKET `
        --output=json `
        --max-keys $KEYS `
        @NEXT_MARKER | ConvertFrom-Json
    $OBJECTS=@()
    foreach ($VERSION in $LIST_OBJECT_VERSIONS.Versions) {
        $OBJECTS+=@{
            "Key" = $VERSION.Key
            "VersionId" = $VERSION.VersionId
        }
    }
    foreach ($DELETE_MARKER in $LIST_OBJECT_VERSIONS.DeleteMarkers) {
        $OBJECTS+=@{
            "Key" = $DELETE_MARKER.Key
            "VersionId" = $DELETE_MARKER.VersionId
        }
    }

    $COUNT+=$OBJECTS.Count
    if ($OBJECTS.Count -ne 0) {
        $BATCH=@()
        foreach ($OBJECT in $OBJECTS) {
            $BATCH+=$OBJECT
            if ($BATCH.Count % 50 -eq 0) {
                "DELETE OBJECTS: $BUCKET $($BATCH.Count)"
                aws s3api delete-objects `
                --bucket $BUCKET `
                --delete "$($(ConvertTo-Json -Compress @{"Objects"=$BATCH}) | ConvertTo-Json)" | Out-Null
                $BATCH=@()
            }
        }
    }

} while($LIST_OBJECT_VERSIONS.NextKeyMarker -and $LIST_OBJECT_VERSIONS.NextVersionIdMarker)
