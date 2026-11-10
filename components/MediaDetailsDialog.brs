' ==============================================================================
' MediaDetailsDialog Component Script
' ==============================================================================

sub init()
    m.dialogPoster = m.top.findNode("dialogPoster")
    m.dialogTitle = m.top.findNode("dialogTitle")
    m.dialogMetaBadge = m.top.findNode("dialogMetaBadge")
    m.dialogOverview = m.top.findNode("dialogOverview")
    m.sourcesList = m.top.findNode("sourcesList")

    m.sourcesList.observeField("itemSelected", "onSourceSelected")
    m.resolvedUrls = []
end sub

sub onMediaItemChanged()
    item = m.top.mediaItem
    if item = invalid then return

    m.dialogTitle.text = item.title
    if item.HDPOSTERURL <> invalid and item.HDPOSTERURL <> ""
        m.dialogPoster.uri = item.HDPOSTERURL
    else if item.posterUrl <> invalid
        m.dialogPoster.uri = item.posterUrl
    end if

    yearStr = ""
    if item.year <> invalid then yearStr = item.year.ToStr()
    ratingStr = "TV-G"
    if item.rating <> invalid and item.rating <> "" then ratingStr = item.rating
    durStr = "26m"
    if item.duration <> invalid then durStr = item.duration.ToStr() + "m"
    genresStr = ""
    if item.genres <> invalid then genresStr = " • " + item.genres

    m.dialogMetaBadge.text = yearStr + " • " + ratingStr + " • " + durStr + genresStr
    m.dialogOverview.text = item.description

    ' Trigger stream resolver
    resolver = CreateObject("roSGNode", "StreamResolverTask")
    resolver.tmdbId = item.id.ToInt()
    resolver.mediaTitle = item.title
    if item.year <> invalid then resolver.mediaYear = item.year else resolver.mediaYear = 1965
    resolver.observeField("status", "onResolverStatusChanged")
    resolver.control = "RUN"
    m.resolver = resolver
end sub

sub onResolverStatusChanged()
    if m.resolver.status = "RESOLVED"
        sources = m.resolver.streamSources
        m.resolvedUrls = []
        content = CreateObject("roSGNode", "ContentNode")
        for each src in sources
            node = content.createChild("ContentNode")
            node.title = "[" + src.provider + "] " + src.quality + " - " + src.name
            m.resolvedUrls.push(src.url)
        end for
        m.sourcesList.content = content
        m.sourcesList.setFocus(true)
    end if
end sub

sub onSourceSelected()
    index = m.sourcesList.itemFocused
    if index < 0 then index = m.sourcesList.itemSelected
    if index >= 0 and index < m.resolvedUrls.Count()
        m.top.selectedStreamUrl = m.resolvedUrls[index]
        m.top.playRequested = true
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "back"
        m.top.closeRequested = true
        return true
    else if key = "OK" or key = "select"
        onSourceSelected()
        return true
    end if
    return false
end function
