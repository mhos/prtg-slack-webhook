Param(
    [string]$SlackWebHook,
    [string]$SlackChannel,
    [string]$SiteName,
    [string]$Device,
    [string]$Name,
    [string]$Status,
    [string]$Down,
    [string]$DateTime,
    [string]$LinkDevice,
    [string]$SensorID,
    [string]$PRTGServer,
    [string]$APIToken,
    [string]$Message,
    [switch]$Debug
)

# Debug logging function
function Write-DebugLog {
    param([string]$Message)
    if ($Debug) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $Message" | Add-Content -Path "C:\prtgslackdebug.log"
    }
}

Write-DebugLog "Script started with parameters:"
Write-DebugLog "SlackWebHook: $SlackWebHook"
Write-DebugLog "SlackChannel: $SlackChannel"
Write-DebugLog "Name: $Name"
Write-DebugLog "Status: $Status"
Write-DebugLog "LinkDevice: $LinkDevice"
Write-DebugLog "SensorID: $SensorID"
Write-DebugLog "PRTGServer: $PRTGServer"

# Can set one of the if statements to your needs by commenting one or the other out.
# Slack can get busy if you monitor a lot of servers.
# Do NOT send notifications if Name contains excluded terms
#if (-not ($Name -match "APT|Backup|Update")) {
# Only send notifications if Name contains the terms
if ($Name -match "HTTP|Load") {
    Write-DebugLog "Name matches condition, proceeding with alert"
    $acknowledgeUrl = "$($PRTGServer)/api/acknowledgealarm.htm?id=$($SensorID)&ackmsg=Acknowledged+via+Slack&targeturl=/sensor.htm?id=$($SensorID)&apitoken=$($APIToken)"
    $pauseUrl = "$($PRTGServer)/api/pauseobject.htm?id=$($SensorID)&action=1&apitoken=$($APIToken)"
    $resumeUrl = "$($PRTGServer)/api/pauseobject.htm?id=$($SensorID)&action=0&apitoken=$($APIToken)"
    
    Write-DebugLog "Generated URLs:"
    Write-DebugLog "Acknowledge URL: $acknowledgeUrl"
    Write-DebugLog "Pause URL: $pauseUrl"
    Write-DebugLog "Resume URL: $resumeUrl"

    $postSlackMessage = @{
        channel      = $SlackChannel
        unfurl_links = "true"
        username     = "PRTG"
        icon_url     = "https://prtgicons.paessler.com/prtgx/led_red_big.png"
        blocks       = @(
            @{
                type = "section"
                text = @{
                    type = "mrkdwn"
                    text = "*Time:* $($DateTime)`n*Device:* <$($LinkDevice)|$($Name)>`n*Status:* $($Status) $($Down)`n*Message:* $($Message)"
                }
            }
            @{
                type = "actions"
                elements = @(
                    @{
                        type = "button"
                        text = @{
                            type = "plain_text"
                            text = "Acknowledge"
                        }
                        style = "primary"
                        url = $acknowledgeUrl
                    }
                    @{
                        type = "button"
                        text = @{
                            type = "plain_text"
                            text = "Pause Monitor"
                        }
                        style = "danger"
                        url = $pauseUrl
                    }
                    @{
                        type = "button"
                        text = @{
                            type = "plain_text"
                            text = "Resume Monitor"
                        }
                        url = $resumeUrl
                    }
                )
            }
        )
    }

    $jsonMessage = $postSlackMessage | ConvertTo-Json -Depth 10
    Write-DebugLog "Prepared Slack message JSON:"
    Write-DebugLog $jsonMessage

    try {
        Write-DebugLog "Attempting to send Slack message..."
        Invoke-RestMethod -Method Post -ContentType 'application/json' -Uri $SlackWebHook -Body $jsonMessage
        Write-DebugLog "Slack message sent successfully"
    }
    catch {
        Write-DebugLog "Error sending Slack message: $($_.Exception.Message)"
        Write-DebugLog "Full error details: $($_)"
    }
}
else {
    Write-DebugLog "Name does not match condition, skipping alert"
}

Write-DebugLog "Script execution completed"
