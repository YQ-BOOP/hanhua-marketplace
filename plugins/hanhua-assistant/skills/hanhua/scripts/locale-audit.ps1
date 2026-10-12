[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Reference,

    [Parameter(Mandatory = $true)]
    [string]$Target,

    [string]$ReferenceLocale = 'en',
    [string]$TargetLocale = 'zh-CN',
    [string]$OutputPath,
    [switch]$FailOnIssues
)

$ErrorActionPreference = 'Stop'

function Get-JsonValue {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "JSON file not found: $Path"
    }
    $raw = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path).Path)
    try {
        return $raw | ConvertFrom-Json
    }
    catch {
        throw "Invalid JSON in '$Path': $($_.Exception.Message)"
    }
}

function Add-FlattenedValue {
    param(
        [Parameter(Mandatory = $true)] $Value,
        [string]$Prefix = '',
        [Parameter(Mandatory = $true)] [AllowEmptyCollection()] [System.Collections.Generic.List[object]]$Result
    )

    if ($null -eq $Value) {
        $Result.Add([pscustomobject]@{ Key = $Prefix; Value = $null; ValueType = 'Null' }) | Out-Null
        return
    }

    if ($Value -is [pscustomobject]) {
        foreach ($property in $Value.PSObject.Properties) {
            $childKey = if ([string]::IsNullOrEmpty($Prefix)) { $property.Name } else { "$Prefix.$($property.Name)" }
            Add-FlattenedValue -Value $property.Value -Prefix $childKey -Result $Result
        }
        return
    }

    if ($Value -is [System.Array]) {
        for ($i = 0; $i -lt $Value.Count; $i++) {
            $childKey = if ([string]::IsNullOrEmpty($Prefix)) { "[$i]" } else { "$Prefix[$i]" }
            Add-FlattenedValue -Value $Value[$i] -Prefix $childKey -Result $Result
        }
        return
    }

    $typeName = $Value.GetType().Name
    $text = [string]$Value
    $Result.Add([pscustomobject]@{ Key = $Prefix; Value = $text; ValueType = $typeName }) | Out-Null
}

function Get-FlatMap {
    param($Json)
    $items = New-Object 'System.Collections.Generic.List[object]'
    Add-FlattenedValue -Value $Json -Result $items
    $map = @{}
    foreach ($item in $items) { $map[$item.Key] = $item }
    return $map
}

function Get-Placeholders {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return @() }
    $patterns = @(
        '\{\{[^{}]+\}\}',
        '\$\{[^{}]+\}',
        '\{[^{}]+\}',
        '%[0-9]+\$[sdif]',
        '%[sdif]',
        '%[0-9]+',
        '(?<![A-Za-z0-9]):[A-Za-z_][A-Za-z0-9_]*'
    )
    $matches = New-Object 'System.Collections.Generic.List[string]'
    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($Text, $pattern)) {
            $matches.Add($match.Value)
        }
    }
    return @($matches | Sort-Object)
}

function Get-EscapeCounts {
    param([string]$Text)
    return [ordered]@{
        newline = if ($null -eq $Text) { 0 } else { ([regex]::Matches($Text, '\r\n|\n|\r')).Count + ([regex]::Matches($Text, '\\n')).Count }
        tab = if ($null -eq $Text) { 0 } else { ([regex]::Matches($Text, '\t')).Count + ([regex]::Matches($Text, '\\t')).Count }
        carriageReturn = if ($null -eq $Text) { 0 } else { ([regex]::Matches($Text, '\\r')).Count }
    }
}

function Values-Differ {
    param($Left, $Right)
    if ($null -eq $Left -and $null -eq $Right) { return $false }
    if ($null -eq $Left -or $null -eq $Right) { return $true }
    return ([string]$Left) -cne ([string]$Right)
}

function Add-Issue {
    param(
        [Parameter(Mandatory = $true)] [AllowEmptyCollection()] [System.Collections.Generic.List[object]]$Issues,
        [Parameter(Mandatory = $true)] [string]$Type,
        [Parameter(Mandatory = $true)] [string]$Key,
        [Parameter(Mandatory = $true)] [string]$Message,
        $SourceValue = $null,
        $TargetValue = $null,
        [string]$Severity = 'Error'
    )
    $Issues.Add([pscustomobject]@{
        type = $Type
        key = $Key
        severity = $Severity
        message = $Message
        sourceValue = $SourceValue
        targetValue = $TargetValue
    }) | Out-Null
}

$referenceJson = Get-JsonValue -Path $Reference
$targetJson = Get-JsonValue -Path $Target
$referenceMap = Get-FlatMap -Json $referenceJson
$targetMap = Get-FlatMap -Json $targetJson
$issues = New-Object 'System.Collections.Generic.List[object]'

foreach ($key in ($referenceMap.Keys | Sort-Object)) {
    if (-not $targetMap.ContainsKey($key)) {
        Add-Issue -Issues $issues -Type 'missing-key' -Key $key -Message 'Target resource is missing this key.' -SourceValue $referenceMap[$key].Value
        continue
    }

    $sourceItem = $referenceMap[$key]
    $targetItem = $targetMap[$key]
    $sourceText = [string]$sourceItem.Value
    $targetText = [string]$targetItem.Value

    if ([string]::IsNullOrWhiteSpace($targetText)) {
        Add-Issue -Issues $issues -Type 'empty-translation' -Key $key -Message 'Target value is empty or whitespace.' -SourceValue $sourceText -TargetValue $targetText
        continue
    }

    if ($sourceItem.ValueType -eq 'String' -and $targetItem.ValueType -eq 'String' -and -not (Values-Differ $sourceText $targetText)) {
        Add-Issue -Issues $issues -Type 'possibly-untranslated' -Key $key -Message 'Target value is identical to the source value.' -SourceValue $sourceText -TargetValue $targetText -Severity 'Warning'
    }

    $sourcePlaceholders = @(Get-Placeholders -Text $sourceText)
    $targetPlaceholders = @(Get-Placeholders -Text $targetText)
    if (($sourcePlaceholders -join '|') -cne ($targetPlaceholders -join '|')) {
        Add-Issue -Issues $issues -Type 'placeholder-mismatch' -Key $key -Message "Placeholder mismatch. Source: [$($sourcePlaceholders -join ', ')] Target: [$($targetPlaceholders -join ', ')]" -SourceValue $sourceText -TargetValue $targetText
    }

    $sourceEscapes = Get-EscapeCounts -Text $sourceText
    $targetEscapes = Get-EscapeCounts -Text $targetText
    foreach ($escapeName in @('newline', 'tab', 'carriageReturn')) {
        if ($sourceEscapes[$escapeName] -ne $targetEscapes[$escapeName]) {
            Add-Issue -Issues $issues -Type 'escape-mismatch' -Key $key -Message "Escape count differs for '$escapeName'. Source: $($sourceEscapes[$escapeName]) Target: $($targetEscapes[$escapeName])" -SourceValue $sourceText -TargetValue $targetText
        }
    }
}

foreach ($key in ($targetMap.Keys | Sort-Object)) {
    if (-not $referenceMap.ContainsKey($key)) {
        Add-Issue -Issues $issues -Type 'extra-key' -Key $key -Message 'Target resource has a key that is absent from the reference.' -TargetValue $targetMap[$key].Value -Severity 'Warning'
    }
}

$summary = [ordered]@{
    referenceLocale = $ReferenceLocale
    targetLocale = $TargetLocale
    referenceFile = (Resolve-Path -LiteralPath $Reference).Path
    targetFile = (Resolve-Path -LiteralPath $Target).Path
    referenceKeys = $referenceMap.Count
    targetKeys = $targetMap.Count
    totalIssues = $issues.Count
    errors = @($issues | Where-Object { $_.severity -eq 'Error' }).Count
    warnings = @($issues | Where-Object { $_.severity -eq 'Warning' }).Count
    byType = [ordered]@{}
}

foreach ($group in ($issues | Group-Object type | Sort-Object Name)) {
    $summary.byType[$group.Name] = $group.Count
}

$report = [ordered]@{
    summary = $summary
    issues = $issues.ToArray()
}

$json = $report | ConvertTo-Json -Depth 12
Write-Output $json

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $parent = Split-Path -Parent $OutputPath
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    [System.IO.File]::WriteAllText($OutputPath, $json, (New-Object System.Text.UTF8Encoding($false)))
}

if ($FailOnIssues -and $issues.Count -gt 0) {
    exit 1
}