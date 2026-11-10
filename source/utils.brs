' ==============================================================================
' Roku Umbrella Client - Utilities & Telemetry Loggers
' ==============================================================================

sub LogMasterPromptHeader(taskSummary as String, promptNumber as Dynamic)
    numStr = Box(promptNumber).ToStr()
    cleanSummary = UCase(taskSummary)
    border = "================================================================================"
    print ""
    print border
    print "  PROMPT #" + numStr + " INITIATED: " + cleanSummary
    print border
    print "  [SESSION TRACKER] Sequence: #" + numStr + " | Target: Roku Umbrella Client"
    print "  [TASK CONTEXT]    " + taskSummary
    print border
    print ""
end sub

sub LogMasterPromptFooter(status as String, promptNumber as Dynamic, details as String)
    numStr = Box(promptNumber).ToStr()
    border = "================================================================================"
    print ""
    print border
    print "  PROMPT #" + numStr + " COMPLETE: [" + status + "]"
    if details <> ""
        print "  Details:   " + details
    end if
    print border
    print ""
end sub

function FormatMinutesToDuration(minutes as Integer) as String
    if minutes <= 0 then return "-- min"
    hrs = Int(minutes / 60)
    mins = minutes MOD 60
    if hrs > 0
        return hrs.ToStr() + "h " + mins.ToStr() + "m"
    else
        return mins.ToStr() + "m"
    end if
end function

function SafeString(value as Dynamic, defaultVal = "" as String) as String
    if value = invalid then return defaultVal
    return Box(value).ToStr()
end function
