' ==============================================================================
' Roku Umbrella Client - Application Entry Point
' ==============================================================================
' Initializes the roSGScreen and main SceneGraph context for Umbrella on-demand
' media browser interface.
' ==============================================================================

sub Main()
    LogMasterPromptHeader("New Roku Umbrella Client Project Setup", 87)
    print "[Umbrella] Initializing Roku Umbrella Client application..."

    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.SetMessagePort(m.port)

    scene = screen.CreateScene("MainScene")
    screen.Show()

    print "[Umbrella] SceneGraph MainScene displayed. Entering event loop."

    while true
        msg = wait(0, m.port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed()
                print "[Umbrella] Screen closed. Terminating application."
                exit while
            end if
        end if
    end while

    LogMasterPromptFooter("SUCCESS", 87, "Umbrella MainScene session terminated normally.")
end sub
