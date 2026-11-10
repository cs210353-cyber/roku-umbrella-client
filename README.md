# Roku Umbrella Client

A lightweight, on-demand media browsing interface for Roku devices, modeled after the Kodi / Umbrella layout.

## Features
- **Kodi/Umbrella Style UI**: Clean category tabs, poster grid, dynamic backdrop preview, and rich metadata panel.
- **On-Demand Catalog**: Background `TmdbFetcherTask` for holiday specials, trending titles, and curated media.
- **Multi-Source Stream Resolver**: Emulates multi-provider scraping (`StreamResolverTask`) resolving direct MP4 and HLS streams.
- **Direct Play Video Engine**: Embedded SceneGraph `Video` player with automatic format detection.

## Architecture
```
roku-umbrella-client/
├── manifest
├── Makefile
├── source/
│   ├── main.brs
│   └── utils.brs
├── components/
│   ├── MainScene.xml / .brs
│   ├── CategoryItem.xml / .brs
│   ├── MediaDetailsDialog.xml / .brs
│   ├── TmdbFetcherTask.xml / .brs
│   └── StreamResolverTask.xml / .brs
└── images/
```

## Build & Sideload
```bash
# Package zip artifact
make package

# Deploy directly to local Roku device
make deploy ROKU_DEV_TARGET=192.168.4.72 ROKU_DEV_PASSWORD=1224
```
