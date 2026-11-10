' ==============================================================================
' Roku Umbrella Client - MainScene Controller
' ==============================================================================
' Implements Kodi/Umbrella style on-demand media browser layout:
'   - Category tabs selection
'   - Poster markup grid navigation
'   - Dynamic backdrop image sync
'   - Media details inspection and stream playback launch
' ==============================================================================

sub init()
    m.backdropPoster = m.top.findNode("backdropPoster")
    m.previewTitle = m.top.findNode("previewTitle")
    m.previewMeta = m.top.findNode("previewMeta")
    m.previewOverview = m.top.findNode("previewOverview")
    m.categoryTabs = m.top.findNode("categoryTabs")
    m.mediaGrid = m.top.findNode("mediaGrid")
    m.statusLabel = m.top.findNode("statusLabel")
    m.detailsDialog = m.top.findNode("detailsDialog")
    m.videoPlayer = m.top.findNode("videoPlayer")

    ' Event observers
    m.mediaGrid.observeField("itemFocused", "onGridItemFocused")
    m.mediaGrid.observeField("itemSelected", "onGridItemSelected")
    m.categoryTabs.observeField("itemSelected", "onCategorySelected")
    m.detailsDialog.observeField("playRequested", "onPlayRequested")
    m.detailsDialog.observeField("closeRequested", "onDialogCloseRequested")
    m.videoPlayer.observeField("state", "onVideoStateChanged")

    initCategoryTabs()
    loadCategory("holiday_specials")
end sub

sub initCategoryTabs()
    tabs = ["Holiday Specials", "Trending Movies", "Popular"]
    tabContent = CreateObject("roSGNode", "ContentNode")
    for each tab in tabs
        item = tabContent.createChild("ContentNode")
        item.title = tab
    end for
    m.categoryTabs.content = tabContent
    m.currentCategory = "holiday_specials"
end sub

sub onCategorySelected()
    idx = m.categoryTabs.itemSelected
    if idx = 0
        loadCategory("holiday_specials")
    else if idx = 1
        loadCategory("trending_movies")
    else
        loadCategory("popular")
    end if
end sub

sub loadCategory(categoryName as String)
    m.currentCategory = categoryName
    m.statusLabel.text = "Loading " + categoryName + "..."

    fetcher = CreateObject("roSGNode", "TmdbFetcherTask")
    fetcher.requestCategory = categoryName
    fetcher.observeField("status", "onFetcherStatusChanged")
    fetcher.control = "RUN"
    m.fetcher = fetcher
end sub

sub onFetcherStatusChanged()
    if m.fetcher.status = "COMPLETE"
        content = m.fetcher.contentResult
        m.mediaGrid.content = content
        m.mediaGrid.setFocus(true)
        m.statusLabel.text = "Loaded " + content.getChildCount().ToStr() + " items. [OK] Select Title  |  [UP] Category Tabs"
        if content.getChildCount() > 0
            updatePreview(content.getChild(0))
        end if
    end if
end sub

sub onGridItemFocused()
    idx = m.mediaGrid.itemFocused
    if m.mediaGrid.content <> invalid and idx >= 0 and idx < m.mediaGrid.content.getChildCount()
        item = m.mediaGrid.content.getChild(idx)
        updatePreview(item)
    end if
end sub

sub updatePreview(item as Object)
    if item = invalid then return
    m.previewTitle.text = item.title

    yearStr = ""
    if item.year <> invalid then yearStr = item.year.ToStr()
    ratingStr = "TV-G"
    if item.rating <> invalid and item.rating <> "" then ratingStr = item.rating
    durStr = "26m"
    if item.duration <> invalid then durStr = item.duration.ToStr() + "m"
    genresStr = ""
    if item.genres <> invalid then genresStr = " • " + item.genres

    m.previewMeta.text = yearStr + " • " + ratingStr + " • " + durStr + genresStr
    m.previewOverview.text = item.description

    if item.backdropUrl <> invalid and item.backdropUrl <> ""
        m.backdropPoster.uri = item.backdropUrl
    end if
end sub

sub onGridItemSelected()
    idx = m.mediaGrid.itemSelected
    if m.mediaGrid.content <> invalid and idx >= 0 and idx < m.mediaGrid.content.getChildCount()
        item = m.mediaGrid.content.getChild(idx)
        m.detailsDialog.mediaItem = item
        m.detailsDialog.visible = true
        m.detailsDialog.setFocus(true)
    end if
end sub

sub onDialogCloseRequested()
    m.detailsDialog.visible = false
    m.mediaGrid.setFocus(true)
end sub

sub onPlayRequested()
    url = m.detailsDialog.selectedStreamUrl
    if url <> "" and url <> invalid
        print "[MainScene] Starting stream playback for: " + url
        m.detailsDialog.visible = false
        
        videoContent = CreateObject("roSGNode", "ContentNode")
        videoContent.url = url
        videoContent.title = m.detailsDialog.mediaItem.title
        videoContent.streamFormat = "mp4"
        if Instr(1, url, ".m3u8") > 0
            videoContent.streamFormat = "hls"
        end if

        m.videoPlayer.content = videoContent
        m.videoPlayer.visible = true
        m.videoPlayer.setFocus(true)
        m.videoPlayer.control = "play"
    end if
end sub

sub onVideoStateChanged()
    state = m.videoPlayer.state
    print "[MainScene] Video player state: " + state
    if state = "finished" or state = "error"
        m.videoPlayer.visible = false
        m.mediaGrid.setFocus(true)
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if m.videoPlayer.visible
        if key = "back"
            m.videoPlayer.control = "stop"
            m.videoPlayer.visible = false
            m.mediaGrid.setFocus(true)
            return true
        end if
    else if m.detailsDialog.visible
        ' Handled by detailsDialog
        return false
    else
        if key = "up" and m.mediaGrid.hasFocus()
            m.categoryTabs.setFocus(true)
            return true
        else if key = "down" and m.categoryTabs.hasFocus()
            m.mediaGrid.setFocus(true)
            return true
        end if
    end if
    return false
end function
