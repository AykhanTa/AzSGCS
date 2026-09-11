#!/usr/bin/env python3
"""
AZERBAIJAN OFFLINE DTED ELEVATION SERVER (QGC Copernicus carpet format)
Primary source: LOCAL DTED (.dt2) tiles (offline, real data)

- Pure Python + numpy (NO GDAL required)
- Reads DTED records correctly (signed-magnitude 16-bit elevations)
- Returns QGroundControl-compatible "carpet" JSON

DTED facts used here:
- File starts with: UHL (80) + DSI (648) + ACC (2700) = 3428 bytes
- Each DATA record begins with 8-byte preamble, ends with 4-byte checksum
- Elevations are signed-magnitude int16 (not two's complement)
"""

# from flask import Flask, request, jsonify
# from flask_cors import CORS
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs
import json

import numpy as np
import threading
import os
import time
import logging
import math
from dataclasses import dataclass
from collections import OrderedDict
from typing import Optional, Dict, List, Tuple

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger("qgc-dted")

# app = Flask(__name__)
# CORS(app)

# -----------------------------
# CONFIG
# -----------------------------
GRID_SIZE_DEFAULT = int(os.getenv("GRID_SIZE", "36"))

# DTED header sizes (bytes)
UHL_SIZE = 80
DSI_SIZE = 648
ACC_SIZE = 2700
DTED_HEADER_SIZE = UHL_SIZE + DSI_SIZE + ACC_SIZE  # 3428

# DTED void (null) elevation commonly appears as -32767 (all bits set in signed-magnitude: 0xFFFF)
DTED_NULL_ELEV = -32767

# RAM cache settings (tile metadata + optional recent profiles)
DTED_RAM_CACHE_TILES = int(os.getenv("DTED_RAM_CACHE_TILES", "64"))
PROFILE_CACHE_MAX = int(os.getenv("DTED_PROFILE_CACHE_MAX", "256"))  # per-process small LRU

# Optional response cache (pickle grids per bbox)
CACHE_DIR = os.path.join(os.path.dirname(__file__), "elevation_cache")
CACHE_ENABLED = os.getenv("CACHE_ENABLED", "1").strip() not in ("0", "false", "False")
CACHE_MAX_AGE_HOURS = float(os.getenv("CACHE_MAX_AGE_HOURS", "24"))

if CACHE_ENABLED:
    os.makedirs(CACHE_DIR, exist_ok=True)

# Where to look for .dt2 tiles
DTED_SEARCH_DIRS = [
    os.getenv("DTED_DIR", "").strip(),
    os.getenv("HGT_DIR", "").strip(),  # allow reuse of old env var
    os.path.join(os.path.dirname(__file__), "dted_tiles"),
    os.path.join(os.path.dirname(__file__), "dt2"),
    os.path.expanduser("~/dted_tiles"),
    os.path.expanduser("~/DTED"),
    "/data/dted_tiles",
    r"C:\QGC-Elevation-Server\dted_tiles",
]

DTED_SCAN_RECURSIVE = os.getenv("DTED_SCAN_RECURSIVE", "1").strip() not in ("0", "false", "False")


# -----------------------------
# Helpers: caching grids
# -----------------------------
def _cache_key(lat_min: float, lon_min: float, lat_max: float, lon_max: float, grid: int) -> str:
    return f"dted_{lat_min:.6f}_{lon_min:.6f}_{lat_max:.6f}_{lon_max:.6f}_{grid}"

def _cache_path(key: str) -> str:
    return os.path.join(CACHE_DIR, f"{hash(key)}.pkl")

def cache_load_grid(key: str) -> Optional[np.ndarray]:
    if not CACHE_ENABLED:
        return None
    import pickle
    p = _cache_path(key)
    if not os.path.exists(p):
        return None
    try:
        with open(p, "rb") as f:
            obj = pickle.load(f)
        ts = float(obj.get("ts", 0))
        if (time.time() - ts) > (CACHE_MAX_AGE_HOURS * 3600.0):
            return None
        arr = obj.get("grid")
        if isinstance(arr, np.ndarray):
            logger.info(f"Cache hit: {key} (age: {(time.time()-ts)/3600.0:.1f}h)")
            return arr
    except Exception:
        return None
    return None

def cache_save_grid(key: str, grid: np.ndarray) -> None:
    if not CACHE_ENABLED:
        return
    import pickle
    p = _cache_path(key)
    try:
        with open(p, "wb") as f:
            pickle.dump({"ts": time.time(), "grid": grid}, f, protocol=pickle.HIGHEST_PROTOCOL)
    except Exception as e:
        logger.warning(f"Cache save failed: {e}")


# -----------------------------
# Helpers: coordinate parsing (handles QGC weird scaling like 404.42)
# -----------------------------
def _try_scale_points(vals: Tuple[float, float, float, float], scale: float) -> Optional[Tuple[float, float, float, float]]:
    lat1, lon1, lat2, lon2 = vals
    lat1 *= scale; lon1 *= scale; lat2 *= scale; lon2 *= scale
    if (-90 <= lat1 <= 90) and (-90 <= lat2 <= 90) and (-180 <= lon1 <= 180) and (-180 <= lon2 <= 180):
        return (lat1, lon1, lat2, lon2)
    return None

def parse_and_normalize_points(points_str: str) -> Tuple[Tuple[float, float, float, float], Dict]:
    parts = [p.strip() for p in points_str.split(",")]
    if len(parts) != 4:
        raise ValueError("Need exactly 4 coordinates: lat1,lon1,lat2,lon2")

    raw = tuple(map(float, parts))  # (lat1,lon1,lat2,lon2)
    info = {"raw": list(raw), "mode": "deg", "scale": 1.0, "swap": False}

    # Already valid
    if _try_scale_points(raw, 1.0) is not None:
        return raw, info

    # Common scalings from buggy callers: x10, x100, x1000, microdegrees, etc.
    for s in (0.1, 0.01, 0.001, 1e-4, 1e-5, 1e-6):
        scaled = _try_scale_points(raw, s)
        if scaled is not None:
            info["mode"] = "scaled_deg"
            info["scale"] = 1.0 / (1.0 / s)  # just to show applied factor
            info["selected_scale"] = s
            info["parsed"] = list(scaled)
            return scaled, info

    # Try swapping lat/lon pairs then scaling
    swapped = (raw[1], raw[0], raw[3], raw[2])
    for s in (1.0, 0.1, 0.01, 0.001, 1e-4, 1e-5, 1e-6):
        scaled = _try_scale_points(swapped, s)
        if scaled is not None:
            info["mode"] = "swap_and_scale"
            info["swap"] = True
            info["selected_scale"] = s
            info["parsed"] = list(scaled)
            return scaled, info

    raise ValueError("Latitude/Longitude out of range (even after scaling attempts)")

def validate_bbox(lat_min: float, lon_min: float, lat_max: float, lon_max: float) -> bool:
    if not (-90 <= lat_min <= 90 and -90 <= lat_max <= 90):
        return False
    if not (-180 <= lon_min <= 180 and -180 <= lon_max <= 180):
        return False
    if lat_min >= lat_max or lon_min >= lon_max:
        return False
    # limit insane queries
    if (lat_max - lat_min) > 10 or (lon_max - lon_min) > 10:
        return False
    return True


# -----------------------------
# DTED parsing
# -----------------------------
def _parse_uhl_dms(s: str) -> float:
    """
    UHL stores origin as DDDMMSSH (8 chars):
    - degrees: 3
    - minutes: 2
    - seconds: 2
    - hemisphere: 1 (N/S/E/W)
    """
    s = s.strip()
    if len(s) < 8:
        raise ValueError(f"Bad UHL coord: '{s}'")

    hemi = s[-1].upper()
    digits = s[:-1]
    if len(digits) != 7 or not digits.isdigit():
        raise ValueError(f"Bad UHL coord digits: '{s}'")

    deg = int(digits[0:3])
    minutes = int(digits[3:5])
    sec = int(digits[5:7])

    val = deg + minutes / 60.0 + sec / 3600.0
    if hemi in ("W", "S"):
        val = -val
    return val

def _parse_uhl_interval_seconds(s: str) -> float:
    """
    UHL interval: SSSS with implied decimal after 3rd digit => value / 10.
    Example: "0010" => 1.0 arcsec, "0300" => 30.0 arcsec.
    """
    s = s.strip()
    if not s.isdigit():
        raise ValueError(f"Bad interval: '{s}'")
    return int(s) / 10.0

def _signed_magnitude_u16_to_i32(u16: np.ndarray) -> np.ndarray:
    """
    Convert DTED signed-magnitude 16-bit to signed int32.
    sign bit: 0x8000, magnitude: 0x7FFF
    """
    u16 = u16.astype(np.uint16, copy=False)
    sign = (u16 & 0x8000) != 0
    mag = (u16 & 0x7FFF).astype(np.int32, copy=False)
    mag[sign] *= -1
    return mag

@dataclass
class DTEDTileMeta:
    path: str
    origin_lat: float
    origin_lon: float
    lat_interval_deg: float
    lon_interval_deg: float
    lat_points: int
    lon_lines: int
    data_offset: int
    record_size: int
    lat_max: float
    lon_max: float

    def contains(self, lat: float, lon: float) -> bool:
        eps = 1e-12
        return (self.origin_lat - eps) <= lat <= (self.lat_max + eps) and (self.origin_lon - eps) <= lon <= (self.lon_max + eps)

def _infer_counts_from_filesize(file_size: int, lat_points_hint: Optional[int]) -> Tuple[int, int]:
    """
    Infer (lon_lines, lat_points) from file size:
    data bytes = file_size - DTED_HEADER_SIZE
    record_size = 8 + (lat_points*2) + 4
    lon_lines = data_bytes / record_size
    """
    if file_size <= DTED_HEADER_SIZE:
        raise ValueError("File too small to be DTED")

    data_bytes = file_size - DTED_HEADER_SIZE

    # candidate lat_points for DTED levels
    candidates = []
    if lat_points_hint and lat_points_hint > 0:
        candidates.append(lat_points_hint)
    # Typical DTED sizes
    candidates.extend([3601, 1201, 601, 901, 121])

    for lat_points in candidates:
        record_size = 8 + (lat_points * 2) + 4
        if record_size <= 0:
            continue
        if data_bytes % record_size == 0:
            lon_lines = data_bytes // record_size
            if lon_lines > 0:
                return int(lon_lines), int(lat_points)

    raise ValueError("Unable to infer DTED dimensions from file size")

def read_dted_meta(fpath: str) -> Optional[DTEDTileMeta]:
    try:
        file_size = os.path.getsize(fpath)
        if file_size <= DTED_HEADER_SIZE:
            return None

        with open(fpath, "rb") as f:
            uhl = f.read(UHL_SIZE)
        if len(uhl) != UHL_SIZE:
            return None

        try:
            uhl_txt = uhl.decode("ascii", errors="ignore")
        except Exception:
            return None

        if not uhl_txt.startswith("UHL"):
            return None

        # UHL fields are 1-indexed in spec; convert to 0-index slices
        lon_str = uhl_txt[4:12]    # bytes 5-12
        lat_str = uhl_txt[12:20]   # bytes 13-20
        lon_int_str = uhl_txt[20:24]  # bytes 21-24
        lat_int_str = uhl_txt[24:28]  # bytes 25-28
        lon_lines_str = uhl_txt[47:51]  # bytes 48-51
        lat_points_str = uhl_txt[51:55] # bytes 52-55

        origin_lon = _parse_uhl_dms(lon_str)
        origin_lat = _parse_uhl_dms(lat_str)

        lon_interval_sec = _parse_uhl_interval_seconds(lon_int_str)
        lat_interval_sec = _parse_uhl_interval_seconds(lat_int_str)
        lon_interval_deg = lon_interval_sec / 3600.0
        lat_interval_deg = lat_interval_sec / 3600.0

        lon_lines_hint = int(lon_lines_str.strip() or "0")
        lat_points_hint = int(lat_points_str.strip() or "0")

        # If hints are missing/zero, infer from file size
        if lon_lines_hint <= 0 or lat_points_hint <= 0:
            lon_lines, lat_points = _infer_counts_from_filesize(file_size, lat_points_hint if lat_points_hint > 0 else None)
        else:
            lon_lines, lat_points = lon_lines_hint, lat_points_hint
            # Validate against file size; if mismatch, re-infer
            record_size = 8 + (lat_points * 2) + 4
            data_bytes = file_size - DTED_HEADER_SIZE
            if record_size <= 0 or data_bytes % record_size != 0:
                lon_lines, lat_points = _infer_counts_from_filesize(file_size, lat_points)

        record_size = 8 + (lat_points * 2) + 4
        lat_max = origin_lat + lat_interval_deg * (lat_points - 1)
        lon_max = origin_lon + lon_interval_deg * (lon_lines - 1)

        return DTEDTileMeta(
            path=fpath,
            origin_lat=origin_lat,
            origin_lon=origin_lon,
            lat_interval_deg=lat_interval_deg,
            lon_interval_deg=lon_interval_deg,
            lat_points=lat_points,
            lon_lines=lon_lines,
            data_offset=DTED_HEADER_SIZE,
            record_size=record_size,
            lat_max=lat_max,
            lon_max=lon_max,
        )
    except Exception as e:
        logger.debug(f"DTED meta read failed for {fpath}: {e}")
        return None


# -----------------------------
# Tile discovery & index
# -----------------------------
DTED_ROOT = ""
DTED_TILES: List[DTEDTileMeta] = []
DTED_INDEX: Dict[Tuple[int, int], List[DTEDTileMeta]] = {}
_TILE_META_LRU = OrderedDict()  # path -> DTEDTileMeta

def _index_key_for_tile(tile: DTEDTileMeta) -> Tuple[int, int]:
    # group by integer-degree cell of SW corner
    return (math.floor(tile.origin_lat), math.floor(tile.origin_lon))

def discover_dt2_root() -> str:
    for d in DTED_SEARCH_DIRS:
        if not d or not os.path.isdir(d):
            continue
        # quick check: exists at least 1 .dt2 somewhere
        if DTED_SCAN_RECURSIVE:
            for root, _, files in os.walk(d):
                if any(f.lower().endswith(".dt2") for f in files):
                    return d
        else:
            if any(f.lower().endswith(".dt2") for f in os.listdir(d)):
                return d
    return ""

def scan_tiles(root_dir: str) -> None:
    global DTED_TILES, DTED_INDEX
    DTED_TILES = []
    DTED_INDEX = {}

    if not root_dir:
        return

    paths = []
    if DTED_SCAN_RECURSIVE:
        for r, _, files in os.walk(root_dir):
            for fn in files:
                if fn.lower().endswith(".dt2"):
                    paths.append(os.path.join(r, fn))
    else:
        for fn in os.listdir(root_dir):
            if fn.lower().endswith(".dt2"):
                paths.append(os.path.join(root_dir, fn))

    for p in sorted(paths):
        meta = read_dted_meta(p)
        if not meta:
            continue
        DTED_TILES.append(meta)
        k = _index_key_for_tile(meta)
        DTED_INDEX.setdefault(k, []).append(meta)
        logger.info(
            f"Found DTED tile: {os.path.basename(p)} | "
            f"SW=({meta.origin_lat:.6f},{meta.origin_lon:.6f}) "
            f"NE=({meta.lat_max:.6f},{meta.lon_max:.6f}) "
            f"grid={meta.lon_lines}x{meta.lat_points} "
            f"step=({meta.lat_interval_deg*3600.0:.1f}\", {meta.lon_interval_deg*3600.0:.1f}\")"
        )

def get_tile_for_point(lat: float, lon: float) -> Optional[DTEDTileMeta]:
    if not DTED_TILES:
        return None

    lat0 = math.floor(lat)
    lon0 = math.floor(lon)

    # try same cell + neighbors (boundary safe)
    cand_keys = [
        (lat0, lon0),
        (lat0 - 1, lon0),
        (lat0, lon0 - 1),
        (lat0 - 1, lon0 - 1),
    ]

    for k in cand_keys:
        for tile in DTED_INDEX.get(k, []):
            if tile.contains(lat, lon):
                return tile

    # fallback brute (should be rare)
    for tile in DTED_TILES:
        if tile.contains(lat, lon):
            return tile
    return None


# -----------------------------
# Profile cache (small)
# -----------------------------
_PROFILE_CACHE = OrderedDict()  # (path, lon_idx) -> np.ndarray

def _profile_cache_get(path: str, lon_idx: int) -> Optional[np.ndarray]:
    key = (path, lon_idx)
    if key in _PROFILE_CACHE:
        arr = _PROFILE_CACHE.pop(key)
        _PROFILE_CACHE[key] = arr
        return arr
    return None

def _profile_cache_put(path: str, lon_idx: int, profile: np.ndarray) -> None:
    key = (path, lon_idx)
    _PROFILE_CACHE[key] = profile
    while len(_PROFILE_CACHE) > PROFILE_CACHE_MAX:
        _PROFILE_CACHE.popitem(last=False)


def read_profile(tile: DTEDTileMeta, f, lon_idx: int) -> Optional[np.ndarray]:
    if lon_idx < 0 or lon_idx >= tile.lon_lines:
        return None

    cached = _profile_cache_get(tile.path, lon_idx)
    if cached is not None:
        return cached

    off = tile.data_offset + lon_idx * tile.record_size
    f.seek(off)
    buf = f.read(tile.record_size)
    if len(buf) != tile.record_size:
        return None

    # DATA record preamble: 8 bytes (first byte should be 0xAA=170 for SRTM DTED) 
    sentinel = buf[0]
    if sentinel != 170:
        # Some producers may vary; warn but still try parse
        logger.debug(f"Unexpected DTED record sentinel={sentinel} in {os.path.basename(tile.path)} at lon_idx={lon_idx}")

    # Read elevations (signed-magnitude) from bytes 8..(8 + 2*lat_points)
    u16 = np.frombuffer(buf, dtype=">u2", count=tile.lat_points, offset=8)
    i32 = _signed_magnitude_u16_to_i32(u16)
    prof = i32.astype(np.float32, copy=False)

    # Replace nulls with 0.0 (QGC wants numbers)
    prof[prof == DTED_NULL_ELEV] = 0.0

    _profile_cache_put(tile.path, lon_idx, prof)
    return prof


# -----------------------------
# Grid generation
# -----------------------------
def tile_coverage_for_bbox(lat_min: float, lon_min: float, lat_max: float, lon_max: float) -> float:
    # Approximate: sample corners and midpoints to see if tiles exist
    samples = [
        (lat_min, lon_min),
        (lat_min, lon_max),
        (lat_max, lon_min),
        (lat_max, lon_max),
        ((lat_min + lat_max) / 2, (lon_min + lon_max) / 2),
    ]
    have = sum(1 for (la, lo) in samples if get_tile_for_point(la, lo) is not None)
    return have / len(samples)

def elevation_at(lat: float, lon: float) -> Optional[float]:
    tile = get_tile_for_point(lat, lon)
    if tile is None:
        return None

    # Convert to indices using origin and intervals
    lon_idx = int(round((lon - tile.origin_lon) / tile.lon_interval_deg))
    lat_idx = int(round((lat - tile.origin_lat) / tile.lat_interval_deg))

    lon_idx = max(0, min(lon_idx, tile.lon_lines - 1))
    lat_idx = max(0, min(lat_idx, tile.lat_points - 1))

    try:
        with open(tile.path, "rb") as f:
            prof = read_profile(tile, f, lon_idx)
            if prof is None:
                return None
            return float(prof[lat_idx])
    except Exception:
        return None

def get_elevation_grid(lat_min: float, lon_min: float, lat_max: float, lon_max: float, grid_size: int) -> np.ndarray:
    lat_points = np.linspace(lat_min, lat_max, grid_size)
    lon_points = np.linspace(lon_min, lon_max, grid_size)

    grid = np.zeros((grid_size, grid_size), dtype=np.float32)
    missing = 0

    # Group requests per tile, then per lon_idx
    per_tile: Dict[str, List[Tuple[int, int, int, int, DTEDTileMeta]]] = {}

    for i in range(grid_size):
        for j in range(grid_size):
            la = float(lat_points[i])
            lo = float(lon_points[j])
            tile = get_tile_for_point(la, lo)
            if tile is None:
                missing += 1
                continue

            lon_idx = int(round((lo - tile.origin_lon) / tile.lon_interval_deg))
            lat_idx = int(round((la - tile.origin_lat) / tile.lat_interval_deg))

            lon_idx = max(0, min(lon_idx, tile.lon_lines - 1))
            lat_idx = max(0, min(lat_idx, tile.lat_points - 1))

            per_tile.setdefault(tile.path, []).append((i, j, lon_idx, lat_idx, tile))

    # Read only needed profiles
    for path, pts in per_tile.items():
        tile = pts[0][4]
        try:
            with open(path, "rb") as f:
                by_lon: Dict[int, List[Tuple[int, int, int]]] = {}
                for (i, j, lon_idx, lat_idx, _) in pts:
                    by_lon.setdefault(lon_idx, []).append((i, j, lat_idx))

                for lon_idx, ijl in by_lon.items():
                    prof = read_profile(tile, f, lon_idx)
                    if prof is None:
                        for (i, j, _) in ijl:
                            missing += 1
                        continue

                    for (i, j, lat_idx) in ijl:
                        grid[i, j] = prof[lat_idx]
        except Exception as e:
            logger.warning(f"Failed reading tile {os.path.basename(path)}: {e}")
            for (i, j, *_rest) in pts:
                grid[i, j] = 0.0
                missing += 1

    if missing:
        logger.warning(f"DTED filled {grid_size*grid_size - missing}/{grid_size*grid_size} (missing={missing})")

    return np.round(grid, 1)


# -----------------------------
# API endpoints
# -----------------------------
# @app.route("/")
# def home():
#     return jsonify({
#         "status": "running",
#         "service": "Azerbaijan DTED2 Elevation Server",
#         "data_source": "Local DTED .dt2 files",
#         "dted_root": DTED_ROOT if DTED_ROOT else "NOT FOUND",
#         "tiles_found": len(DTED_TILES),
#         "scan_recursive": DTED_SCAN_RECURSIVE,
#         "cache": {
#             "enabled": CACHE_ENABLED,
#             "dir": CACHE_DIR if CACHE_ENABLED else "",
#             "max_age_hours": CACHE_MAX_AGE_HOURS,
#         },
#         "endpoints": {
#             "carpet": "/api/v1/carpet?points=lat1,lon1,lat2,lon2",
#             "test_baku": "/test/baku",
#             "check_tiles": "/check_tiles",
#             "point": "/point/<lat>/<lon>",
#             "debug_parse": "/debug/parse?points=...",
#             "health": "/health",
#         }
#     })

# @app.route("/debug/parse")
# def debug_parse():
#     points = request.args.get("points", "")
#     if not points:
#         return jsonify({"status": "error", "message": "Missing points"}), 400
#     try:
#         parsed, info = parse_and_normalize_points(points)
#         lat1, lon1, lat2, lon2 = parsed
#         lat_min, lat_max = min(lat1, lat2), max(lat1, lat2)
#         lon_min, lon_max = min(lon1, lon2), max(lon1, lon2)
#         return jsonify({
#             "status": "success",
#             "input_transform": info,
#             "normalized_bbox": {
#                 "sw": [lat_min, lon_min],
#                 "ne": [lat_max, lon_max],
#             },
#         })
#     except Exception as e:
#         return jsonify({"status": "error", "message": str(e)}), 400

# @app.route("/api/v1/carpet", methods=["GET"])
# def api_carpet():
#     t0 = time.time()
#     points = request.args.get("points", "")
#     if not points:
#         return jsonify({"status": "error", "message": "Missing 'points' parameter"}), 400

#     try:
#         parsed, info = parse_and_normalize_points(points)
#         lat1, lon1, lat2, lon2 = parsed

#         lat_min, lat_max = min(lat1, lat2), max(lat1, lat2)
#         lon_min, lon_max = min(lon1, lon2), max(lon1, lon2)

#         if not validate_bbox(lat_min, lon_min, lat_max, lon_max):
#             return jsonify({"status": "error", "message": "Invalid coordinates or area too large"}), 400

#         grid_size = int(request.args.get("grid", GRID_SIZE_DEFAULT))
#         grid_size = max(2, min(grid_size, 100))

#         key = _cache_key(lat_min, lon_min, lat_max, lon_max, grid_size)
#         cached = cache_load_grid(key)
#         if cached is not None:
#             elevation_grid = cached
#         else:
#             cov = tile_coverage_for_bbox(lat_min, lon_min, lat_max, lon_max)
#             if cov < 1.0:
#                 logger.warning(f"Tile coverage (sampled) {cov:.0%} for bbox [{lat_min:.4f},{lon_min:.4f}]..[{lat_max:.4f},{lon_max:.4f}]")
#             elevation_grid = get_elevation_grid(lat_min, lon_min, lat_max, lon_max, grid_size)
#             cache_save_grid(key, elevation_grid)

#         stats = {
#             "min": float(np.min(elevation_grid)),
#             "max": float(np.max(elevation_grid)),
#             "avg": float(np.mean(elevation_grid)),
#             "std": float(np.std(elevation_grid)),
#         }

#         elapsed = time.time() - t0
#         logger.info(
#             f"Request ok in {elapsed:.3f}s | "
#             f"bbox=[{lat_min:.6f},{lon_min:.6f}]..[{lat_max:.6f},{lon_max:.6f}] "
#             f"grid={grid_size} | elev {stats['min']:.1f}..{stats['max']:.1f}"
#         )

#         return jsonify({
#             "status": "success",
#             "data": {
#                 "bounds": {
#                     "sw": [round(lat_min, 6), round(lon_min, 6)],
#                     "ne": [round(lat_max, 6), round(lon_max, 6)],
#                 },
#                 "stats": stats,
#                 "carpet": elevation_grid.tolist(),
#             },
#             "meta": {
#                 "grid_size": grid_size,
#                 "processing_time": round(elapsed, 3),
#                 "input_transform": info,
#             }
#         })

#     except ValueError as e:
#         return jsonify({"status": "error", "message": str(e)}), 400
#     except Exception as e:
#         logger.error(f"Server error: {e}", exc_info=True)
#         return jsonify({"status": "error", "message": "Internal server error"}), 500

# @app.route("/point/<lat>/<lon>")
# def point(lat: str, lon: str):
#     try:
#         la = float(lat)
#         lo = float(lon)
#         h = elevation_at(la, lo)
#         if h is None:
#             return jsonify({"status": "not_found", "elevation_m": None}), 404
#         return jsonify({"status": "success", "lat": la, "lon": lo, "elevation_m": round(h, 1)})
#     except Exception as e:
#         return jsonify({"status": "error", "message": str(e)}), 400

# @app.route("/shutdown", methods=["POST"])
# def shutdown():
#     # Yalnız lokal kompüterdən icazə ver
#     if request.remote_addr not in ("127.0.0.1", "::1"):
#         return jsonify({"status": "forbidden"}), 403

#     # Flask dev server-də ən stabil çıxış: prosesi sərt bağlamaq
#     def _die():
#         os._exit(0)

#     threading.Timer(0.2, _die).start()
#     return jsonify({"status": "ok"})


# @app.route("/test/baku")
# def test_baku():
#     # Same bbox you used before
#     lat_min, lon_min = 40.4093, 49.8671
#     lat_max, lon_max = 40.4193, 49.8771
#     g = get_elevation_grid(lat_min, lon_min, lat_max, lon_max, 10)
#     return jsonify({
#         "status": "success",
#         "location": "Baku, Azerbaijan",
#         "bounds": {"sw": [lat_min, lon_min], "ne": [lat_max, lon_max]},
#         "grid_size": 10,
#         "stats": {
#             "min": float(np.min(g)),
#             "max": float(np.max(g)),
#             "avg": float(np.mean(g)),
#         },
#         "sample_5x5": g[:5, :5].tolist()
#     })

# @app.route("/check_tiles")
# def check_tiles():
#     tiles = []
#     for t in DTED_TILES[:200]:
#         tiles.append({
#             "file": os.path.relpath(t.path, DTED_ROOT) if DTED_ROOT else os.path.basename(t.path),
#             "sw": [round(t.origin_lat, 6), round(t.origin_lon, 6)],
#             "ne": [round(t.lat_max, 6), round(t.lon_max, 6)],
#             "grid": [t.lon_lines, t.lat_points],
#             "step_arcsec": [round(t.lat_interval_deg * 3600.0, 2), round(t.lon_interval_deg * 3600.0, 2)],
#             "size_mb": round(os.path.getsize(t.path) / (1024 * 1024), 2),
#         })
#     return jsonify({
#         "status": "success",
#         "dted_root": DTED_ROOT if DTED_ROOT else "NOT FOUND",
#         "tiles_found": len(DTED_TILES),
#         "showing": len(tiles),
#         "tiles": tiles,
#         "note": "Showing first 200 tiles"
#     })

# @app.route("/health")
# def health():
#     return jsonify({
#         "status": "healthy",
#         "tiles_found": len(DTED_TILES),
#         "dted_root_found": bool(DTED_ROOT),
#         "cache_enabled": CACHE_ENABLED,
#         "profile_cache_entries": len(_PROFILE_CACHE),
#     })

# -----------------------------
# API endpoints (NO FLASK)
# -----------------------------

def _json_bytes(obj) -> bytes:
    return json.dumps(obj, ensure_ascii=False).encode("utf-8")

def _qs_get(qs, key, default=""):
    v = qs.get(key, [])
    return v[0] if v else default

def _handle_home():
    return 200, {
        "status": "running",
        "service": "Azerbaijan DTED2 Elevation Server",
        "data_source": "Local DTED .dt2 files",
        "dted_root": DTED_ROOT if DTED_ROOT else "NOT FOUND",
        "tiles_found": len(DTED_TILES),
        "scan_recursive": DTED_SCAN_RECURSIVE,
        "cache": {
            "enabled": CACHE_ENABLED,
            "dir": CACHE_DIR if CACHE_ENABLED else "",
            "max_age_hours": CACHE_MAX_AGE_HOURS,
        },
        "endpoints": {
            "carpet": "/api/v1/carpet?points=lat1,lon1,lat2,lon2",
            "test_baku": "/test/baku",
            "check_tiles": "/check_tiles",
            "point": "/point/<lat>/<lon>",
            "debug_parse": "/debug/parse?points=...",
            "health": "/health",
        }
    }

def _handle_debug_parse(qs):
    points = _qs_get(qs, "points", "")
    if not points:
        return 400, {"status": "error", "message": "Missing points"}
    try:
        parsed, info = parse_and_normalize_points(points)
        lat1, lon1, lat2, lon2 = parsed
        lat_min, lat_max = min(lat1, lat2), max(lat1, lat2)
        lon_min, lon_max = min(lon1, lon2), max(lon1, lon2)
        return 200, {
            "status": "success",
            "input_transform": info,
            "normalized_bbox": {"sw": [lat_min, lon_min], "ne": [lat_max, lon_max]},
        }
    except Exception as e:
        return 400, {"status": "error", "message": str(e)}

def _handle_api_carpet(qs):
    t0 = time.time()
    points = _qs_get(qs, "points", "")
    if not points:
        return 400, {"status": "error", "message": "Missing 'points' parameter"}

    try:
        parsed, info = parse_and_normalize_points(points)
        lat1, lon1, lat2, lon2 = parsed

        lat_min, lat_max = min(lat1, lat2), max(lat1, lat2)
        lon_min, lon_max = min(lon1, lon2), max(lon1, lon2)

        if not validate_bbox(lat_min, lon_min, lat_max, lon_max):
            return 400, {"status": "error", "message": "Invalid coordinates or area too large"}

        grid_raw = _qs_get(qs, "grid", str(GRID_SIZE_DEFAULT))
        try:
            grid_size = int(grid_raw)
        except Exception:
            grid_size = GRID_SIZE_DEFAULT
        grid_size = max(2, min(grid_size, 100))

        key = _cache_key(lat_min, lon_min, lat_max, lon_max, grid_size)
        cached = cache_load_grid(key)
        if cached is not None:
            elevation_grid = cached
        else:
            cov = tile_coverage_for_bbox(lat_min, lon_min, lat_max, lon_max)
            if cov < 1.0:
                logger.warning(f"Tile coverage (sampled) {cov:.0%} for bbox [{lat_min:.4f},{lon_min:.4f}]..[{lat_max:.4f},{lon_max:.4f}]")
            elevation_grid = get_elevation_grid(lat_min, lon_min, lat_max, lon_max, grid_size)
            cache_save_grid(key, elevation_grid)

        stats = {
            "min": float(np.min(elevation_grid)),
            "max": float(np.max(elevation_grid)),
            "avg": float(np.mean(elevation_grid)),
            "std": float(np.std(elevation_grid)),
        }

        elapsed = time.time() - t0
        logger.info(
            f"Request ok in {elapsed:.3f}s | "
            f"bbox=[{lat_min:.6f},{lon_min:.6f}]..[{lat_max:.6f},{lon_max:.6f}] "
            f"grid={grid_size} | elev {stats['min']:.1f}..{stats['max']:.1f}"
        )

        return 200, {
            "status": "success",
            "data": {
                "bounds": {
                    "sw": [round(lat_min, 6), round(lon_min, 6)],
                    "ne": [round(lat_max, 6), round(lon_max, 6)],
                },
                "stats": stats,
                "carpet": elevation_grid.tolist(),
            },
            "meta": {
                "grid_size": grid_size,
                "processing_time": round(elapsed, 3),
                "input_transform": info,
            }
        }

    except ValueError as e:
        return 400, {"status": "error", "message": str(e)}
    except Exception as e:
        logger.error(f"Server error: {e}", exc_info=True)
        return 500, {"status": "error", "message": "Internal server error"}

def _handle_point(path):
    # /point/<lat>/<lon>
    parts = path.strip("/").split("/")
    if len(parts) != 3:
        return 404, {"status": "error", "message": "Bad point path"}
    try:
        la = float(parts[1])
        lo = float(parts[2])
        h = elevation_at(la, lo)
        if h is None:
            return 404, {"status": "not_found", "elevation_m": None}
        return 200, {"status": "success", "lat": la, "lon": lo, "elevation_m": round(h, 1)}
    except Exception as e:
        return 400, {"status": "error", "message": str(e)}

def _handle_test_baku():
    lat_min, lon_min = 40.4093, 49.8671
    lat_max, lon_max = 40.4193, 49.8771
    g = get_elevation_grid(lat_min, lon_min, lat_max, lon_max, 10)
    return 200, {
        "status": "success",
        "location": "Baku, Azerbaijan",
        "bounds": {"sw": [lat_min, lon_min], "ne": [lat_max, lon_max]},
        "grid_size": 10,
        "stats": {"min": float(np.min(g)), "max": float(np.max(g)), "avg": float(np.mean(g))},
        "sample_5x5": g[:5, :5].tolist()
    }

def _handle_check_tiles():
    tiles = []
    for t in DTED_TILES[:200]:
        tiles.append({
            "file": os.path.relpath(t.path, DTED_ROOT) if DTED_ROOT else os.path.basename(t.path),
            "sw": [round(t.origin_lat, 6), round(t.origin_lon, 6)],
            "ne": [round(t.lat_max, 6), round(t.lon_max, 6)],
            "grid": [t.lon_lines, t.lat_points],
            "step_arcsec": [round(t.lat_interval_deg * 3600.0, 2), round(t.lon_interval_deg * 3600.0, 2)],
            "size_mb": round(os.path.getsize(t.path) / (1024 * 1024), 2),
        })
    return 200, {
        "status": "success",
        "dted_root": DTED_ROOT if DTED_ROOT else "NOT FOUND",
        "tiles_found": len(DTED_TILES),
        "showing": len(tiles),
        "tiles": tiles,
        "note": "Showing first 200 tiles"
    }

def _handle_health():
    return 200, {
        "status": "healthy",
        "tiles_found": len(DTED_TILES),
        "dted_root_found": bool(DTED_ROOT),
        "cache_enabled": CACHE_ENABLED,
        "profile_cache_entries": len(_PROFILE_CACHE),
    }

class Handler(BaseHTTPRequestHandler):
    def _send_json(self, status_code: int, obj: dict):
        body = _json_bytes(obj)
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        u = urlparse(self.path)
        path = u.path
        qs = parse_qs(u.query)

        if path == "/":
            code, payload = _handle_home()
            return self._send_json(code, payload)

        if path == "/debug/parse":
            code, payload = _handle_debug_parse(qs)
            return self._send_json(code, payload)

        if path == "/api/v1/carpet":
            code, payload = _handle_api_carpet(qs)
            return self._send_json(code, payload)

        if path.startswith("/point/"):
            code, payload = _handle_point(path)
            return self._send_json(code, payload)

        if path == "/test/baku":
            code, payload = _handle_test_baku()
            return self._send_json(code, payload)

        if path == "/check_tiles":
            code, payload = _handle_check_tiles()
            return self._send_json(code, payload)

        if path == "/health":
            code, payload = _handle_health()
            return self._send_json(code, payload)

        return self._send_json(404, {"status": "error", "message": "Not found"})

    def log_message(self, fmt, *args):
        # HTTP server-in default print-lərini logger-ə yönləndirək
        logger.info("%s - %s" % (self.address_string(), fmt % args))





# -----------------------------
# Startup
# -----------------------------
# def print_banner():
#     print("=" * 70)
#     print("AZERBAIJAN DTED2 ELEVATION SERVER (QGC Copernicus carpet)")
#     print("=" * 70)
#     print("Primary source: Local .dt2 DTED files (offline)")
#     print(f"Scan recursive: {DTED_SCAN_RECURSIVE}")
#     print(f"Cache enabled: {CACHE_ENABLED} | dir: {CACHE_DIR if CACHE_ENABLED else '-'}")
#     print("-" * 70)
#     print("Endpoints:")
#     print("  GET  /")
#     print("  GET  /api/v1/carpet?points=lat1,lon1,lat2,lon2")
#     print("  GET  /debug/parse?points=...")
#     print("  GET  /test/baku")
#     print("  GET  /check_tiles")
#     print("  GET  /point/<lat>/<lon>")
#     print("  GET  /health")
#     print("=" * 70)

# if __name__ == "__main__":
#     DTED_ROOT = discover_dt2_root()
#     if not DTED_ROOT:
#         logger.warning("No DTED (.dt2) root directory found. Set DTED_DIR env var or put files in ./dted_tiles/")
#     else:
#         logger.info(f"Using DTED root: {DTED_ROOT}")

#     scan_tiles(DTED_ROOT)
#     print_banner()

    # app.run(
    #     host=os.getenv("HOST", "0.0.0.0"),
    #     port=int(os.getenv("PORT", "8080")),
    #     debug=os.getenv("DEBUG", "false").lower() == "true",
    #     threaded=True
    # )


    # -----------------------------
# Startup
# -----------------------------
def print_banner():
    print("=" * 70)
    print("AZERBAIJAN DTED2 ELEVATION SERVER (QGC Copernicus carpet)")
    print("=" * 70)
    print("Primary source: Local .dt2 DTED files (offline)")
    print(f"Scan recursive: {DTED_SCAN_RECURSIVE}")
    print(f"Cache enabled: {CACHE_ENABLED} | dir: {CACHE_DIR if CACHE_ENABLED else '-'}")
    print("-" * 70)
    print("Endpoints:")
    print("  GET  /")
    print("  GET  /api/v1/carpet?points=lat1,lon1,lat2,lon2")
    print("  GET  /debug/parse?points=...")
    print("  GET  /test/baku")
    print("  GET  /check_tiles")
    print("  GET  /point/<lat>/<lon>")
    print("  GET  /health")
    print("=" * 70)

if __name__ == "__main__":
    DTED_ROOT = discover_dt2_root()
    if not DTED_ROOT:
        logger.warning("No DTED (.dt2) root directory found. Set DTED_DIR env var or put files in ./dted_tiles/")
    else:
        logger.info(f"Using DTED root: {DTED_ROOT}")

    scan_tiles(DTED_ROOT)
    print_banner()

    host = os.getenv("HOST", "127.0.0.1")   # G20 üçün localhost
    port = int(os.getenv("PORT", "8080"))

    logger.info(f"Listening on http://{host}:{port}")
    ThreadingHTTPServer((host, port), Handler).serve_forever()
