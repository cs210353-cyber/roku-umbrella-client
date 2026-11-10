' ==============================================================================
' AllDebrid Service Module (AllDebridService.brs)
' ==============================================================================
' Provides high-performance REST client bindings for the AllDebrid v4 API:
'   - API key management via Roku registry (roRegistrySection)
'   - Torrent / magnet instant cloud availability and upload (/v4/magnet/upload)
'   - Magnet transfer and stream readiness tracking (/v4/magnet/status)
'   - Web hoster / premium stream link unlocking (/v4/link/unlock)
'   - Direct, uncompressed high-bitrate stream resolver pipeline
' ==============================================================================

' ------------------------------------------------------------------------------
' 1. Registry API Key Management
' ------------------------------------------------------------------------------
function GetAllDebridApiKey() as String
    sec = CreateObject("roRegistrySection", "AllDebrid")
    if sec.Exists("apiKey")
        return sec.Read("apiKey")
    else if sec.Exists("api_key")
        return sec.Read("api_key")
    end if
    return ""
end function

function SetAllDebridApiKey(apiKey as String) as Boolean
    if apiKey = invalid then apiKey = ""
    sec = CreateObject("roRegistrySection", "AllDebrid")
    sec.Write("apiKey", apiKey)
    return sec.Flush()
end function

' ------------------------------------------------------------------------------
' 2. Device Pairing / PIN Flow (/v4/pin/get & /v4/pin/check)
' ------------------------------------------------------------------------------
function AllDebridGetPin() as Object
    result = {
        success: false,
        pin: "",
        check: "",
        expires_in: 0,
        user_url: "https://alldebrid.com/pin/",
        check_url: "",
        error: ""
    }

    apiRes = AllDebridRequest("pin/get", "GET", invalid, invalid, "")
    if apiRes.success and apiRes.data <> invalid
        data = apiRes.data
        result.success = true
        if data.pin <> invalid then result.pin = data.pin
        if data.check <> invalid then result.check = data.check
        if data.expires_in <> invalid then result.expires_in = data.expires_in
        if data.user_url <> invalid then result.user_url = data.user_url
        if data.check_url <> invalid then result.check_url = data.check_url
        print "[AllDebrid] Device Pairing PIN generated: " + result.pin + " (Authorize at: " + result.user_url + ")"
        return result
    end if

    if apiRes.error <> ""
        result.error = apiRes.error
    else
        result.error = "Failed to generate AllDebrid device pairing PIN"
    end if

    return result
end function

function AllDebridCheckPin(check as String, pin as String) as Object
    result = {
        success: false,
        activated: false,
        apikey: "",
        expires_in: 0,
        error: ""
    }

    if check = invalid or check = "" or pin = invalid or pin = ""
        result.error = "Missing check or pin parameter"
        return result
    end if

    queryParams = {
        "check": check,
        "pin": pin
    }

    apiRes = AllDebridRequest("pin/check", "GET", queryParams, invalid, "")
    if apiRes.success and apiRes.data <> invalid
        data = apiRes.data
        result.success = true
        if data.activated <> invalid then result.activated = (data.activated = true)
        if data.apikey <> invalid then result.apikey = data.apikey
        if data.expires_in <> invalid then result.expires_in = data.expires_in

        if result.activated and result.apikey <> ""
            print "[AllDebrid] Device successfully authorized! Saving API key to registry..."
            SetAllDebridApiKey(result.apikey)
        end if

        return result
    end if

    if apiRes.error <> ""
        result.error = apiRes.error
    else
        result.error = "PIN authorization pending or failed"
    end if

    return result
end function

' ------------------------------------------------------------------------------
' 3. Internal HTTP Transport Helper (roUrlTransfer)
' ------------------------------------------------------------------------------
function AllDebridRequest(endpoint as String, method as String, queryParams as Object, postParams as Object, apiKey = "" as String) as Object
    if apiKey = "" or apiKey = invalid
        apiKey = GetAllDebridApiKey()
    end if

    baseUrl = "https://api.alldebrid.com/v4/" + endpoint
    if Left(endpoint, 5) = "v4.1/"
        baseUrl = "https://api.alldebrid.com/" + endpoint
    end if
    msgPort = CreateObject("roMessagePort")
    transfer = CreateObject("roUrlTransfer")
    transfer.SetPort(msgPort)
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.EnableEncodings(true)
    transfer.AddHeader("User-Agent", "RokuUmbrellaClient/1.0")

    ' Prompt #104: Explicit 5-second transfer timeout guard to prevent worker thread lockups
    transfer.SetMinimumTransferRate(100, 5)

    ' Build Query String
    qs = "agent=RokuUmbrellaClient"
    if apiKey <> ""
        qs = qs + "&apikey=" + transfer.Escape(apiKey)
    end if

    if queryParams <> invalid
        for each k in queryParams
            val = queryParams[k]
            if val <> invalid
                qs = qs + "&" + transfer.Escape(k) + "=" + transfer.Escape(val.ToStr())
            end if
        end for
    end if

    fullUrl = baseUrl + "?" + qs
    transfer.SetUrl(fullUrl)

    result = {
        success: false,
        status: "error",
        data: invalid,
        error: ""
    }

    responseStr = ""
    timeoutMs = 5000 ' 5-second max wait threshold

    if UCase(method) = "POST"
        postBody = ""
        transfer.AddHeader("Content-Type", "application/x-www-form-urlencoded")
        if postParams <> invalid
            first = true
            for each pk in postParams
                pval = postParams[pk]
                if pval <> invalid
                    if not first then postBody = postBody + "&"
                    postBody = postBody + transfer.Escape(pk) + "=" + transfer.Escape(pval.ToStr())
                    first = false
                end if
            end for
        end if

        asyncStarted = transfer.AsyncPostFromString(postBody)
        if asyncStarted
            msg = wait(timeoutMs, msgPort)
            if type(msg) = "roUrlEvent"
                httpCode = msg.GetResponseCode()
                if httpCode >= 200 and httpCode < 400
                    responseStr = msg.GetString()
                else
                    result.error = "HTTP error " + httpCode.ToStr() + ": " + msg.GetFailureReason()
                end if
            else
                transfer.AsyncCancel()
                result.error = "AllDebrid POST request timed out after 5000ms"
                print "[AllDebrid] POST request timed out (5s guard) for: " + fullUrl
            end if
        else
            result.error = "Failed to initiate async POST transfer"
        end if
    else
        asyncStarted = transfer.AsyncGetToString()
        if asyncStarted
            msg = wait(timeoutMs, msgPort)
            if type(msg) = "roUrlEvent"
                httpCode = msg.GetResponseCode()
                if httpCode >= 200 and httpCode < 400
                    responseStr = msg.GetString()
                else
                    result.error = "HTTP error " + httpCode.ToStr() + ": " + msg.GetFailureReason()
                end if
            else
                transfer.AsyncCancel()
                result.error = "AllDebrid GET request timed out after 5000ms"
                print "[AllDebrid] GET request timed out (5s guard) for: " + fullUrl
            end if
        else
            result.error = "Failed to initiate async GET transfer"
        end if
    end if

    ' Prompt #105: Fix Response Type Safety - guard against Integer status code or non-string types causing Type Mismatch
    if responseStr <> invalid
        respType = type(responseStr)
        if respType = "Integer" or respType = "roInt" or respType = "LongInteger" or respType = "Float" or respType = "Double"
            print "[AllDebrid] Notice: responseStr received numeric type (" + respType + "): " + responseStr.ToStr() + ", safely converting to string."
            responseStr = responseStr.ToStr()
        else if respType <> "String" and respType <> "roString"
            responseStr = ""
        end if
    else
        responseStr = ""
    end if

    if responseStr <> ""
        jsonObj = ParseJson(responseStr)
        if jsonObj <> invalid and type(jsonObj) = "roAssociativeArray"
            if jsonObj.status = "success"
                result.success = true
                result.status = "success"
                result.data = jsonObj.data
            else
                if jsonObj.status <> invalid
                    result.status = jsonObj.status.ToStr()
                else
                    result.status = "error"
                end if
                if jsonObj.error <> invalid
                    if type(jsonObj.error) = "roAssociativeArray" and jsonObj.error.message <> invalid
                        result.error = jsonObj.error.message.ToStr()
                    else
                        result.error = jsonObj.error.ToStr()
                    end if
                end if
            end if
        else if jsonObj <> invalid and (type(jsonObj) = "Integer" or type(jsonObj) = "roInt")
            result.status = "HTTP_" + jsonObj.ToStr()
            result.error = "Received numeric status payload: " + jsonObj.ToStr()
        else
            result.error = "Invalid JSON payload received"
        end if
    else
        result.error = "Empty HTTP response from AllDebrid API"
    end if

    return result
end function

' ------------------------------------------------------------------------------
' 3. Magnet Upload / Instant Availability Check (/v4/magnet/upload)
' ------------------------------------------------------------------------------
function AllDebridUploadMagnet(magnetUri as String, apiKey = "" as String) as Object
    result = {
        success: false,
        ready: false,
        magnetId: 0,
        hash: "",
        name: "",
        size: 0,
        error: ""
    }

    if magnetUri = invalid or magnetUri = ""
        result.error = "Missing magnet URI"
        return result
    end if

    postParams = {
        "magnets[]": magnetUri
    }

    apiRes = AllDebridRequest("magnet/upload", "POST", invalid, postParams, apiKey)
    if apiRes.success and apiRes.data <> invalid
        magnets = apiRes.data.magnets
        if magnets <> invalid and type(magnets) = "roArray" and magnets.Count() > 0
            mag = magnets[0]
            result.success = true
            if mag.ready <> invalid then result.ready = (mag.ready = true)
            if mag.id <> invalid then result.magnetId = mag.id
            if mag.hash <> invalid then result.hash = mag.hash
            if mag.name <> invalid then result.name = mag.name
            if mag.size <> invalid then result.size = mag.size
            print "[AllDebrid] Magnet uploaded: " + result.name + " | Instant Cache Ready: " + result.ready.ToStr()
            return result
        end if
    end if

    if apiRes.error <> ""
        result.error = apiRes.error
    else
        result.error = "Failed to upload magnet to AllDebrid"
    end if

    print "[AllDebrid] Magnet upload error: " + result.error
    return result
end function

' ------------------------------------------------------------------------------
' 4. Magnet Status Check (/v4/magnet/status)
' ------------------------------------------------------------------------------
function AllDebridGetMagnetStatus(magnetId as Dynamic, apiKey = "" as String) as Object
    result = {
        success: false,
        ready: false,
        statusCode: 0,
        statusText: "",
        links: [],
        filename: "",
        error: ""
    }

    if magnetId = invalid or magnetId = 0 or magnetId = ""
        result.error = "Missing magnet ID"
        return result
    end if

    queryParams = {
        "id": magnetId.ToStr()
    }

    apiRes = AllDebridRequest("v4.1/magnet/status", "GET", queryParams, invalid, apiKey)
    if apiRes.success and apiRes.data <> invalid
        magnets = apiRes.data.magnets
        targetMag = invalid

        if type(magnets) = "roArray" and magnets.Count() > 0
            targetMag = magnets[0]
        else if type(magnets) = "roAssociativeArray"
            targetMag = magnets
        end if

        if targetMag <> invalid
            result.success = true
            if targetMag.statusCode <> invalid then result.statusCode = targetMag.statusCode
            if targetMag.status <> invalid then result.statusText = targetMag.status
            if targetMag.filename <> invalid then result.filename = targetMag.filename

            ' statusCode == 4 signifies Ready on AllDebrid
            if result.statusCode = 4 or UCase(result.statusText) = "READY"
                result.ready = true
            end if

            if targetMag.links <> invalid and type(targetMag.links) = "roArray"
                for each lnk in targetMag.links
                    result.links.push({
                        link: lnk.link,
                        filename: lnk.filename,
                        size: lnk.size
                    })
                end for
            end if

            print "[AllDebrid] Magnet status for ID " + magnetId.ToStr() + ": " + result.statusText + " (Links: " + result.links.Count().ToStr() + ")"
            return result
        end if
    end if

    if apiRes.error <> ""
        result.error = apiRes.error
    else
        result.error = "Failed to query magnet status"
    end if

    return result
end function

' ------------------------------------------------------------------------------
' 5. Direct Web Hoster Link Unlocking (/v4/link/unlock)
' ------------------------------------------------------------------------------
function AllDebridUnlockLink(hosterUrl as String, apiKey = "" as String) as Object
    result = {
        success: false,
        unlockedUrl: "",
        filename: "",
        filesize: 0,
        host: "",
        streams: [],
        error: ""
    }

    if hosterUrl = invalid or hosterUrl = ""
        result.error = "Missing hoster URL"
        return result
    end if

    queryParams = {
        "link": hosterUrl
    }

    apiRes = AllDebridRequest("link/unlock", "GET", queryParams, invalid, apiKey)
    if apiRes.success and apiRes.data <> invalid
        data = apiRes.data
        result.success = true
        if data.link <> invalid then result.unlockedUrl = data.link
        if data.filename <> invalid then result.filename = data.filename
        if data.filesize <> invalid then result.filesize = data.filesize
        if data.host <> invalid then result.host = data.host

        ' Parse stream variants if available
        if data.streams <> invalid and type(data.streams) = "roArray"
            for each s in data.streams
                result.streams.push({
                    id: s.id,
                    ext: s.ext,
                    quality: s.quality,
                    link: s.link
                })
            end for
            ' Prefer highest quality stream link if unlockedUrl is empty
            if result.unlockedUrl = "" and result.streams.Count() > 0
                result.unlockedUrl = result.streams[0].link
            end if
        end if

        print "[AllDebrid] Link unlocked: " + result.filename + " -> " + result.unlockedUrl
        return result
    end if

    if apiRes.error <> ""
        result.error = apiRes.error
    else
        result.error = "Failed to unlock link with AllDebrid"
    end if

    print "[AllDebrid] Link unlock failed: " + result.error
    return result
end function

' ------------------------------------------------------------------------------
' 6. Release & Torrent File Preference Scorer (Prompt #106)
' ------------------------------------------------------------------------------
function PickBestDebridTorrentFile(links as Object) as Object
    if links = invalid or type(links) <> "roArray" or links.Count() = 0
        return invalid
    end if

    bestLink = invalid
    bestScore = -1

    for each item in links
        if item <> invalid and item.filename <> invalid and item.link <> invalid
            fn = LCase(item.filename)
            ' Check for video extension
            isVideo = (Right(fn, 4) = ".mkv" or Right(fn, 4) = ".mp4" or Right(fn, 5) = ".m2ts" or Right(fn, 3) = ".ts" or Right(fn, 4) = ".avi")

            ' Ignore samples and extras
            if isVideo and Instr(1, fn, "sample") = 0 and Instr(1, fn, "trailer") = 0
                score = 100
                ' 4K UHD / 2160p weighting
                if Instr(1, fn, "2160p") > 0 or Instr(1, fn, "4k") > 0 or Instr(1, fn, "uhd") > 0
                    score = score + 5000
                end if
                ' REMUX weighting (lossless direct BD disc dump)
                if Instr(1, fn, "remux") > 0
                    score = score + 3000
                end if
                ' Lossless audio weighting (DTS-HD MA, TrueHD, Atmos, FLAC)
                if Instr(1, fn, "dts-hd") > 0 or Instr(1, fn, "truehd") > 0 or Instr(1, fn, "atmos") > 0 or Instr(1, fn, "flac") > 0
                    score = score + 1500
                end if
                ' 1080p weighting
                if Instr(1, fn, "1080p") > 0
                    score = score + 1000
                end if
                ' HDR / Dolby Vision weighting
                if Instr(1, fn, "hdr") > 0 or Instr(1, fn, "dv") > 0 or Instr(1, fn, "dovi") > 0
                    score = score + 500
                end if
                ' Filesize bonus (larger files = higher uncompressed bitrate)
                if item.size <> invalid and Val(item.size.ToStr()) > 0
                    mb = Val(item.size.ToStr()) / (1024 * 1024)
                    score = score + Int(mb)
                end if

                if score > bestScore
                    bestScore = score
                    bestLink = item
                end if
            end if
        end if
    end for

    ' Fallback to first link if no video file matched
    if bestLink = invalid and links.Count() > 0
        bestLink = links[0]
    end if

    return bestLink
end function

function DetermineStreamQualityLabel(filename as String, defaultQuality = "1080p FHD" as String) as String
    if filename = invalid or filename = "" then return defaultQuality
    fn = LCase(filename)
    is4K = (Instr(1, fn, "2160p") > 0 or Instr(1, fn, "4k") > 0 or Instr(1, fn, "uhd") > 0)
    isRemux = (Instr(1, fn, "remux") > 0)
    isLossless = (Instr(1, fn, "dts-hd") > 0 or Instr(1, fn, "truehd") > 0 or Instr(1, fn, "atmos") > 0 or Instr(1, fn, "flac") > 0)
    is1080p = (Instr(1, fn, "1080p") > 0)

    if is4K
        if isRemux and isLossless
            return "4K UHD Remux (Lossless Audio)"
        else if isRemux
            return "4K UHD Remux"
        else if isLossless
            return "4K UHD (Lossless Audio)"
        else
            return "4K UHD (2160p HDR)"
        end if
    else if is1080p
        if isRemux and isLossless
            return "1080p Remux (Lossless Audio)"
        else if isRemux
            return "1080p Remux"
        else
            return "1080p FHD"
        end if
    end if

    return defaultQuality
end function

' ------------------------------------------------------------------------------
' 7. High-Level Premium Stream Resolver Pipeline
' ------------------------------------------------------------------------------
function AllDebridResolveSource(sourceUri as String, apiKey = "" as String) as Dynamic
    if sourceUri = invalid or sourceUri = "" then return invalid

    try
        ' Case A: Magnet Link Pipeline
        if LCase(Left(sourceUri, 8)) = "magnet:?"
            print "[AllDebrid] Processing magnet link through AllDebrid pipeline..."
            uploadRes = AllDebridUploadMagnet(sourceUri, apiKey)
            if uploadRes <> invalid and uploadRes.success
                if uploadRes.ready
                    statusRes = AllDebridGetMagnetStatus(uploadRes.magnetId, apiKey)
                    if statusRes <> invalid and statusRes.ready and statusRes.links <> invalid and statusRes.links.Count() > 0
                        ' Select highest-bitrate 4K / Remux / Lossless video link
                        bestItem = PickBestDebridTorrentFile(statusRes.links)
                        if bestItem <> invalid and bestItem.link <> invalid
                            targetLink = bestItem.link
                            unlockRes = AllDebridUnlockLink(targetLink, apiKey)
                            if unlockRes <> invalid and unlockRes.success and unlockRes.unlockedUrl <> ""
                                qualityLabel = DetermineStreamQualityLabel(unlockRes.filename, "1080p FHD (Premium)")
                                return {
                                    name: "AllDebrid [" + qualityLabel + ": " + unlockRes.filename + "]",
                                    quality: qualityLabel,
                                    provider: "AllDebrid",
                                    url: unlockRes.unlockedUrl,
                                    filename: unlockRes.filename,
                                    filesize: unlockRes.filesize
                                }
                            end if
                        end if
                    end if
                else
                    print "[AllDebrid] Magnet is not currently cached on AllDebrid seedboxes."
                end if
            else if uploadRes <> invalid and uploadRes.error <> ""
                print "[AllDebrid] Warning: Magnet upload failed - " + uploadRes.error
            end if
            return invalid
        end if

        ' Case B: Direct Web Hoster Link Pipeline (Rapidgator, 1fichier, Uptobox, etc.)
        if Instr(1, sourceUri, "rapidgator") > 0 or Instr(1, sourceUri, "1fichier") > 0 or Instr(1, sourceUri, "uptobox") > 0 or Instr(1, sourceUri, "nitroflare") > 0 or Instr(1, sourceUri, "turbobit") > 0
            print "[AllDebrid] Processing supported web hoster link through AllDebrid..."
            unlockRes = AllDebridUnlockLink(sourceUri, apiKey)
            if unlockRes <> invalid and unlockRes.success and unlockRes.unlockedUrl <> ""
                qualityLabel = DetermineStreamQualityLabel(unlockRes.filename, "1080p FHD (Premium)")
                return {
                    name: "AllDebrid [" + qualityLabel + ": " + unlockRes.host + "]",
                    quality: qualityLabel,
                    provider: "AllDebrid",
                    url: unlockRes.unlockedUrl,
                    filename: unlockRes.filename,
                    filesize: unlockRes.filesize
                }
            else if unlockRes <> invalid and unlockRes.error <> ""
                print "[AllDebrid] Warning: Web hoster unlock failed - " + unlockRes.error
            end if
        end if
    catch e
        print "[AllDebrid] Warning: Exception caught during AllDebridResolveSource: " + e.message
    end try

    return invalid
end function
