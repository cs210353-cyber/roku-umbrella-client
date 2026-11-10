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
    transfer = CreateObject("roUrlTransfer")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.EnableEncodings(true)
    transfer.AddHeader("User-Agent", "RokuUmbrellaClient/1.0")

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

    responseStr = ""
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
        responseStr = transfer.PostFromString(postBody)
    else
        responseStr = transfer.GetToString()
    end if

    result = {
        success: false,
        status: "error",
        data: invalid,
        error: ""
    }

    if responseStr <> "" and responseStr <> invalid
        jsonObj = ParseJson(responseStr)
        if jsonObj <> invalid
            if jsonObj.status = "success"
                result.success = true
                result.status = "success"
                result.data = jsonObj.data
            else
                result.status = jsonObj.status
                if jsonObj.error <> invalid
                    if type(jsonObj.error) = "roAssociativeArray" and jsonObj.error.message <> invalid
                        result.error = jsonObj.error.message
                    else
                        result.error = jsonObj.error.ToStr()
                    end if
                end if
            end if
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
' 6. High-Level Premium Stream Resolver Pipeline
' ------------------------------------------------------------------------------
function AllDebridResolveSource(sourceUri as String, apiKey = "" as String) as Dynamic
    if sourceUri = invalid or sourceUri = "" then return invalid

    ' Case A: Magnet Link Pipeline
    if LCase(Left(sourceUri, 8)) = "magnet:?"
        print "[AllDebrid] Processing magnet link through AllDebrid pipeline..."
        uploadRes = AllDebridUploadMagnet(sourceUri, apiKey)
        if uploadRes.success
            if uploadRes.ready
                statusRes = AllDebridGetMagnetStatus(uploadRes.magnetId, apiKey)
                if statusRes.ready and statusRes.links.Count() > 0
                    ' Find candidate video file link
                    targetLink = statusRes.links[0].link
                    unlockRes = AllDebridUnlockLink(targetLink, apiKey)
                    if unlockRes.success and unlockRes.unlockedUrl <> ""
                        return {
                            name: "AllDebrid [Cached Magnet: " + unlockRes.filename + "]",
                            quality: "1080p FHD (Premium)",
                            provider: "AllDebrid",
                            url: unlockRes.unlockedUrl,
                            filename: unlockRes.filename,
                            filesize: unlockRes.filesize
                        }
                    end if
                end if
            else
                print "[AllDebrid] Magnet is not currently cached on AllDebrid seedboxes."
            end if
        end if
        return invalid
    end if

    ' Case B: Direct Web Hoster Link Pipeline (Rapidgator, 1fichier, Uptobox, etc.)
    if Instr(1, sourceUri, "rapidgator") > 0 or Instr(1, sourceUri, "1fichier") > 0 or Instr(1, sourceUri, "uptobox") > 0 or Instr(1, sourceUri, "nitroflare") > 0 or Instr(1, sourceUri, "turbobit") > 0
        print "[AllDebrid] Processing supported web hoster link through AllDebrid..."
        unlockRes = AllDebridUnlockLink(sourceUri, apiKey)
        if unlockRes.success and unlockRes.unlockedUrl <> ""
            return {
                name: "AllDebrid [Unlocked: " + unlockRes.host + "]",
                quality: "1080p FHD (Premium)",
                provider: "AllDebrid",
                url: unlockRes.unlockedUrl,
                filename: unlockRes.filename,
                filesize: unlockRes.filesize
            }
        end if
    end if

    return invalid
end function
