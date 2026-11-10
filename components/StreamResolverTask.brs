' ==============================================================================
' StreamResolverTask - Kodi/Umbrella Style Scraper & Stream Resolver
' ==============================================================================

sub init()
    m.top.functionName = "resolveStream"
end sub

sub resolveStream()
    m.top.status = "RESOLVING"
    tmdbId = m.top.tmdbId
    title = m.top.mediaTitle
    year = m.top.mediaYear

    print "[StreamResolverTask] Resolving on-demand stream sources for: " + title + " (" + year.ToStr() + ")"

    sources = []

    ' Source mapping based on TMDB ID
    if tmdbId = 13187 or Instr(1, LCase(title), "charlie brown") > 0
        sources.push({
            name: "ArchiveOrg [Direct MP4]",
            quality: "720p HD",
            provider: "ArchiveOrg",
            url: "https://archive.org/download/a-charlie-brown-christmas-jingle-bells-weird-crazy-1965-replace-version/A%20Charlie%20Brown%20Christmas%20-%20Jingle%20Bells%20%28Weird%20Crazy%29%20%281965%29%20%28Replace%20Version%29.mp4"
        })
        sources.push({
            name: "ErsatzTV Playout Relay [HLS]",
            quality: "1080p FHD",
            provider: "LocalRelay",
            url: "http://192.168.4.78:8409/iptv/session/67.2/hls.m3u8"
        })
    else
        ' Default sample stream for other titles
        sources.push({
            name: "Public CDN Stream [HLS]",
            quality: "1080p FHD",
            provider: "PublicCDN",
            url: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        })
    end if

    if sources.Count() > 0
        best = sources[0]
        m.top.resolvedStreamUrl = best.url
        m.top.streamQuality = best.quality
        m.top.streamProvider = best.provider
        m.top.streamSources = sources
        m.top.status = "RESOLVED"
        print "[StreamResolverTask] Selected primary source: " + best.name + " (" + best.url + ")"
    else
        m.top.status = "FAILED"
        print "[StreamResolverTask] Failed to locate stream sources for: " + title
    end if
end sub
