# VibeSweep QR Code Generation

This directory contains scripts for generating QR codes for waste bins used in the VibeSweep app.

## Overview

The QR codes contain JSON payloads with bin information:
- `bin_id`: Unique identifier for the bin
- `category`: Waste category (recycle, organic, landfill, ewaste, hazardous)
- `latitude`: GPS latitude coordinate
- `longitude`: GPS longitude coordinate  
- `geohash`: Geohash for spatial indexing
- `generated_at`: Timestamp of generation
- `version`: Payload format version

## Setup

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Generate QR codes:
```bash
# Generate test bins (5 bins for development)
python generate_bin_qr_codes.py --test-only

# Generate all bins (50 bins for production)
python generate_bin_qr_codes.py

# Custom output directory and format
python generate_bin_qr_codes.py --output-dir ./custom_qr --format PNG
```

## Output

The script generates:
- QR code images (PNG format by default)
- `bin_manifest.json` with all bin information
- Console output showing generation progress

## Example QR Code Payload

```json
{
  "bin_id": "BIN_001_RECYCLE",
  "category": "recycle",
  "latitude": 37.7749,
  "longitude": -122.4194,
  "geohash": "9q8yyk8y",
  "generated_at": "2025-01-19T10:30:00.000Z",
  "version": "1.0"
}
```

## Usage in Flutter App

1. Use `mobile_scanner` package to scan QR codes
2. Parse JSON payload from scanned data
3. Extract bin information for inventory matching
4. No QR generation logic needed in the app

## Testing

Print or display generated QR codes on devices for testing the Flutter app's scanning functionality.