#!/usr/bin/env python3
"""
QR Code Generator for VibeSweep Bin System

This script generates QR codes for waste bins containing JSON payload with:
- bin_id: Unique identifier for the bin
- category: Waste category (recycle, organic, landfill, ewaste, hazardous)
- latitude: GPS latitude coordinate
- longitude: GPS longitude coordinate
- geohash: Geohash for spatial indexing

Usage:
    python generate_bin_qr_codes.py
    python generate_bin_qr_codes.py --output-dir ./qr_codes --format png
"""

import json
import qrcode
import argparse
import os
from typing import List, Dict, Any
import geohash2 as geohash
from datetime import datetime


class BinQRGenerator:
    """Generator for waste bin QR codes with embedded location and category data."""
    
    # Waste categories supported by VibeSweep
    CATEGORIES = ['recycle', 'organic', 'landfill', 'ewaste', 'hazardous']
    
    # Sample bin locations (replace with real coordinates)
    SAMPLE_LOCATIONS = [
        # Downtown area
        {'lat': 37.7749, 'lng': -122.4194, 'name': 'Downtown SF - Market St'},
        {'lat': 37.7849, 'lng': -122.4094, 'name': 'Downtown SF - Union Square'},
        {'lat': 37.7649, 'lng': -122.4294, 'name': 'Downtown SF - SOMA'},
        
        # University area
        {'lat': 37.8719, 'lng': -122.2585, 'name': 'UC Berkeley Campus'},
        {'lat': 37.8619, 'lng': -122.2485, 'name': 'Berkeley Downtown'},
        
        # Park areas
        {'lat': 37.7694, 'lng': -122.4862, 'name': 'Golden Gate Park'},
        {'lat': 37.8024, 'lng': -122.4058, 'name': 'Presidio Park'},
        
        # Residential areas
        {'lat': 37.7849, 'lng': -122.4094, 'name': 'Mission District'},
        {'lat': 37.7949, 'lng': -122.3994, 'name': 'Castro District'},
        {'lat': 37.8049, 'lng': -122.4194, 'name': 'Pacific Heights'},
    ]
    
    def __init__(self, output_dir: str = './qr_codes'):
        """Initialize the QR generator with output directory."""
        self.output_dir = output_dir
        self.ensure_output_dir()
    
    def ensure_output_dir(self):
        """Create output directory if it doesn't exist."""
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)
            print(f"Created output directory: {self.output_dir}")
    
    def generate_bin_id(self, location_idx: int, category: str) -> str:
        """Generate unique bin ID based on location and category."""
        return f"BIN_{location_idx:03d}_{category.upper()}"
    
    def create_bin_payload(self, bin_id: str, category: str, lat: float, lng: float) -> Dict[str, Any]:
        """Create JSON payload for QR code."""
        return {
            'bin_id': bin_id,
            'category': category,
            'latitude': lat,
            'longitude': lng,
            'geohash': geohash.encode(lat, lng, precision=8),
            'generated_at': datetime.utcnow().isoformat(),
            'version': '1.0'
        }
    
    def generate_qr_code(self, payload: Dict[str, Any], filename: str, format: str = 'PNG') -> str:
        """Generate QR code from payload and save to file."""
        # Convert payload to JSON string
        json_data = json.dumps(payload, separators=(',', ':'))
        
        # Create QR code with high error correction for outdoor use
        qr = qrcode.QRCode(
            version=1,  # Auto-adjust size
            error_correction=qrcode.constants.ERROR_CORRECT_H,  # High error correction
            box_size=10,  # Size of each box in pixels
            border=4,  # Border size in boxes
        )
        
        qr.add_data(json_data)
        qr.make(fit=True)
        
        # Create QR code image
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Save image
        filepath = os.path.join(self.output_dir, f"{filename}.{format.lower()}")
        img.save(filepath)
        
        return filepath
    
    def generate_all_bins(self, format: str = 'PNG') -> List[Dict[str, Any]]:
        """Generate QR codes for all bin combinations."""
        generated_bins = []
        
        print(f"Generating QR codes for {len(self.SAMPLE_LOCATIONS)} locations × {len(self.CATEGORIES)} categories...")
        
        for loc_idx, location in enumerate(self.SAMPLE_LOCATIONS):
            for category in self.CATEGORIES:
                # Generate bin data
                bin_id = self.generate_bin_id(loc_idx, category)
                payload = self.create_bin_payload(
                    bin_id=bin_id,
                    category=category,
                    lat=location['lat'],
                    lng=location['lng']
                )
                
                # Generate filename
                safe_name = location['name'].replace(' ', '_').replace('-', '_')
                filename = f"{safe_name}_{category}_{bin_id}"
                
                # Generate QR code
                filepath = self.generate_qr_code(payload, filename, format)
                
                # Store bin info
                bin_info = {
                    **payload,
                    'location_name': location['name'],
                    'qr_file': filepath,
                    'filename': filename
                }
                generated_bins.append(bin_info)
                
                print(f"Generated: {filename}")
        
        return generated_bins
    
    def save_bin_manifest(self, bins: List[Dict[str, Any]]) -> str:
        """Save manifest file with all bin information."""
        manifest_path = os.path.join(self.output_dir, 'bin_manifest.json')
        
        manifest = {
            'generated_at': datetime.utcnow().isoformat(),
            'total_bins': len(bins),
            'categories': self.CATEGORIES,
            'locations_count': len(self.SAMPLE_LOCATIONS),
            'bins': bins
        }
        
        with open(manifest_path, 'w') as f:
            json.dump(manifest, f, indent=2)
        
        print(f"Saved manifest: {manifest_path}")
        return manifest_path
    
    def generate_test_bins(self, count: int = 5, format: str = 'PNG') -> List[Dict[str, Any]]:
        """Generate a small set of test bins for development."""
        test_bins = []
        
        print(f"Generating {count} test bins...")
        
        for i in range(count):
            location = self.SAMPLE_LOCATIONS[i % len(self.SAMPLE_LOCATIONS)]
            category = self.CATEGORIES[i % len(self.CATEGORIES)]
            
            bin_id = f"TEST_{i:03d}_{category.upper()}"
            payload = self.create_bin_payload(
                bin_id=bin_id,
                category=category,
                lat=location['lat'],
                lng=location['lng']
            )
            
            filename = f"test_{i:03d}_{category}_{bin_id}"
            filepath = self.generate_qr_code(payload, filename, format)
            
            bin_info = {
                **payload,
                'location_name': location['name'],
                'qr_file': filepath,
                'filename': filename
            }
            test_bins.append(bin_info)
            
            print(f"Generated test bin: {filename}")
        
        return test_bins


def main():
    """Main function to run QR code generation."""
    parser = argparse.ArgumentParser(description='Generate QR codes for VibeSweep waste bins')
    parser.add_argument('--output-dir', default='./qr_codes', help='Output directory for QR codes')
    parser.add_argument('--format', default='PNG', choices=['PNG', 'JPEG', 'SVG'], help='Output format')
    parser.add_argument('--test-only', action='store_true', help='Generate only test bins (5 bins)')
    parser.add_argument('--count', type=int, default=5, help='Number of test bins to generate')
    
    args = parser.parse_args()
    
    # Initialize generator
    generator = BinQRGenerator(output_dir=args.output_dir)
    
    try:
        if args.test_only:
            # Generate test bins only
            bins = generator.generate_test_bins(count=args.count, format=args.format)
        else:
            # Generate all bins
            bins = generator.generate_all_bins(format=args.format)
        
        # Save manifest
        manifest_path = generator.save_bin_manifest(bins)
        
        print(f"\n✅ Successfully generated {len(bins)} QR codes")
        print(f"📁 Output directory: {args.output_dir}")
        print(f"📄 Manifest file: {manifest_path}")
        print(f"\nTo use in Flutter app:")
        print(f"1. Copy QR code images to test devices or print them")
        print(f"2. Use mobile_scanner package to scan QR codes")
        print(f"3. Parse JSON payload to extract bin information")
        
    except Exception as e:
        print(f"❌ Error generating QR codes: {e}")
        return 1
    
    return 0


if __name__ == '__main__':
    exit(main())