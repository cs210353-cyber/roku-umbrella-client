' ==============================================================================
' Roku Umbrella Client - Application Entry Point
' ==============================================================================
' Initializes the roSGScreen and main SceneGraph context for Umbrella on-demand
' media browser interface.
' ==============================================================================

sub Main(args as Dynamic)
    pNum = 100
    if args <> invalid and type(args) = "roAssociativeArray" and args.doesExist("prompt")
        valNum = Val(args.prompt)
        if valNum > 0 then pNum = valNum
    end if
    LogMasterPromptHeader("Roku Umbrella Client Session", pNum)
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

    LogMasterPromptFooter("SUCCESS", pNum, "Umbrella MainScene session terminated normally.")
end sub
