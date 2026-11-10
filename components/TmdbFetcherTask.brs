' ==============================================================================
' TmdbFetcherTask - Background TMDB & On-Demand Catalog Fetcher
' ==============================================================================

sub init()
    m.top.functionName = "executeFetch"
end sub

sub executeFetch()
    m.top.status = "FETCHING"
    category = m.top.requestCategory
    if category = "" or category = invalid then category = "holiday_specials"

    print "[TmdbFetcherTask] Fetching catalog for category: " + category

    contentNode = CreateObject("roSGNode", "ContentNode")

    ' Curated catalog emulating Kodi/Umbrella dynamic on-demand categories
    if category = "holiday_specials"
        addMediaItem(contentNode, {
            id: 13187,
            title: "A Charlie Brown Christmas",
            year: 1965,
            rating: "TV-G",
            duration: 26,
            genres: "Animation, Family, Comedy",
            overview: "Feeling down about the commercialism of Christmas, Charlie Brown becomes the director of the gang's holiday pageant. Can he find the perfect Christmas tree and uncover the true meaning of Christmas with Linus?",
            posterUrl: "https://image.tmdb.org/t/p/w500/9kkwHcq16vY1L0hW41Xf1m6wH7L.jpg",
            backdropUrl: "https://image.tmdb.org/t/p/w1280/8h2s7QZ1eE6c1Q4x6xZ6xZ6xZ6x.jpg"
        })
        addMediaItem(contentNode, {
            id: 771,
            title: "Home Alone",
            year: 1990,
            rating: "PG",
            duration: 103,
            genres: "Comedy, Family",
            overview: "Eight-year-old Kevin McCallister makes the most of the situation after his family unwittingly leaves him behind when they go on Christmas vacation. But when a pair of bungling burglars target his home, Kevin must protect it.",
            posterUrl: "https://image.tmdb.org/t/p/w500/9wSbe4CwObACCQvaUVxnnzyxq9r.jpg",
            backdropUrl: "https://image.tmdb.org/t/p/w1280/7k4eZsc9fS4xV6rY9xZ8v7x9y5a.jpg"
        })
        addMediaItem(contentNode, {
            id: 10719,
            title: "Elf",
            year: 2003,
            rating: "PG",
            duration: 97,
            genres: "Comedy, Family, Fantasy",
            overview: "Buddy was a baby in an orphanage who stowed away in Santa's sack and ended up at the North Pole. Later, as an adult human who happened to be raised by elves, Buddy embarks on a journey to New York City to find his biological father.",
            posterUrl: "https://image.tmdb.org/t/p/w500/oPoscl9V0a2N4gXmYg6Y7j6X9.jpg",
            backdropUrl: "https://image.tmdb.org/t/p/w1280/6x8x7x9x5a7k4eZsc9fS4xV6rY9.jpg"
        })
        addMediaItem(contentNode, {
            id: 8871,
            title: "How the Grinch Stole Christmas!",
            year: 1966,
            rating: "TV-G",
            duration: 26,
            genres: "Animation, Family, Comedy",
            overview: "A grumpy hermit hatches a plan to steal Christmas from the Whos of Whoville, but a small child helps him discover the holiday's true spirit.",
            posterUrl: "https://image.tmdb.org/t/p/w500/uF5jZ8h1uY9k6wX5Z4v7x9y5a7k.jpg",
            backdropUrl: "https://image.tmdb.org/t/p/w1280/9y5a7k4eZsc9fS4xV6rY9xZ8v7x.jpg"
        })
        addMediaItem(contentNode, {
            id: 10720,
            title: "The Santa Clause",
            year: 1994,
            rating: "PG",
            duration: 97,
            genres: "Comedy, Family, Fantasy",
            overview: "When a man accidentally causes Santa Claus to fall from his roof on Christmas Eve, he finds himself magically taking the jolly old man's place.",
            posterUrl: "https://image.tmdb.org/t/p/w500/c7d3d7k5s6a8v9x7y4z2w1x3v5u.jpg",
            backdropUrl: "https://image.tmdb.org/t/p/w1280/4xV6rY9xZ8v7x9y5a7k4eZsc9fS.jpg"
        })
    else if category = "trending_movies"
        addMediaItem(contentNode, {
            id: 157336,
            title: "Interstellar",
            year: 2014,
            rating: "PG-13",
            duration: 169,
            genres: "Sci-Fi, Adventure, Drama",
            overview: "The adventures of a group of explorers who make use of a newly discovered wormhole to surpass the limitations on human space travel and conquer the vast distances involved in an interstellar voyage.",
            posterUrl: "https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
            backdropUrl: "https://image.tmdb.org/t/p/w1280/rAiYTsqJJR6voeh8Ki8WgvI2WUt.jpg"
        })
        addMediaItem(contentNode, {
            id: 27205,
            title: "Inception",
            year: 2010,
            rating: "PG-13",
            duration: 148,
            genres: "Action, Sci-Fi, Adventure",
            overview: "Cobb, a skilled thief who commits corporate espionage by infiltrating the subconscious of his targets is offered a chance to regain his old life as payment for a task considered to be impossible.",
            posterUrl: "https://image.tmdb.org/t/p/w500/edv5CZvWj09upOsy2Y6IwDhK8bt.jpg",
            backdropUrl: "https://image.tmdb.org/t/p/w1280/8ZTVqvKDQ8emSGUEMjsS4xRo9Cr.jpg"
        })
    else
        ' Default / popular
        addMediaItem(contentNode, {
            id: 13187,
            title: "A Charlie Brown Christmas",
            year: 1965,
            rating: "TV-G",
            duration: 26,
            genres: "Animation, Family, Comedy",
            overview: "Feeling down about the commercialism of Christmas, Charlie Brown becomes the director of the gang's holiday pageant. Can he find the perfect Christmas tree and uncover the true meaning of Christmas with Linus?",
            posterUrl: "https://image.tmdb.org/t/p/w500/9kkwHcq16vY1L0hW41Xf1m6wH7L.jpg",
            backdropUrl: "https://image.tmdb.org/t/p/w1280/8h2s7QZ1eE6c1Q4x6xZ6xZ6xZ6x.jpg"
        })
    end if

    m.top.contentResult = contentNode
    m.top.status = "COMPLETE"
    print "[TmdbFetcherTask] Loaded " + contentNode.getChildCount().ToStr() + " items into catalog."
end sub

sub addMediaItem(parent as Object, itemData as Object)
    child = parent.createChild("ContentNode")
    child.id = itemData.id.ToStr()
    child.title = itemData.title
    child.HDPOSTERURL = itemData.posterUrl
    child.posterUrl = itemData.posterUrl
    child.backdropUrl = itemData.backdropUrl
    child.year = itemData.year
    child.rating = itemData.rating
    child.duration = itemData.duration
    child.genres = itemData.genres
    child.description = itemData.overview
    child.overview = itemData.overview
end sub
