' ==============================================================================
' CategoryItem Component Script
' ==============================================================================

sub init()
    m.focusBorder = m.top.findNode("focusBorder")
    m.itemCard = m.top.findNode("itemCard")
    m.posterImage = m.top.findNode("posterImage")
    m.titleLabel = m.top.findNode("titleLabel")
end sub

sub onContentChanged()
    item = m.top.itemContent
    if item <> invalid
        m.titleLabel.text = item.title
        if item.HDPOSTERURL <> invalid and item.HDPOSTERURL <> ""
            m.posterImage.uri = item.HDPOSTERURL
        else if item.posterUrl <> invalid and item.posterUrl <> ""
            m.posterImage.uri = item.posterUrl
        end if
    end if
end sub

sub onFocusPercentChanged()
    percent = m.top.focusPercent
    if percent > 0.0
        m.focusBorder.opacity = percent
    else
        m.focusBorder.opacity = 0.0
    end if
end sub
