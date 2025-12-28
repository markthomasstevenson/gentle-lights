#!/usr/bin/env python3
"""
Generate app icons for iOS and Android from a single source PNG image.
"""

import os
import sys
from PIL import Image

# Android icon sizes (in pixels) for different densities
ANDROID_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

# iOS icon sizes (in points, need to multiply by scale factor)
# Format: (size_name, size_in_points, scale_factor)
IOS_SIZES = [
    # iPhone
    ('20pt@2x', 20, 2),      # 40x40
    ('20pt@3x', 20, 3),      # 60x60
    ('29pt@2x', 29, 2),      # 58x58
    ('29pt@3x', 29, 3),      # 87x87
    ('40pt@2x', 40, 2),      # 80x80
    ('40pt@3x', 40, 3),      # 120x120
    ('60pt@2x', 60, 2),      # 120x120
    ('60pt@3x', 60, 3),      # 180x180
    # iPad
    ('20pt@1x', 20, 1),      # 20x20
    ('29pt@1x', 29, 1),      # 29x29
    ('40pt@1x', 40, 1),      # 40x40
    ('76pt@1x', 76, 1),      # 76x76
    ('76pt@2x', 76, 2),      # 152x152
    ('83.5pt@2x', 83.5, 2),  # 167x167
    # App Store
    ('1024pt@1x', 1024, 1),  # 1024x1024
]


def generate_android_icons(source_image_path, output_dir):
    """Generate Android app icons in all required densities."""
    print("Generating Android icons...")
    
    with Image.open(source_image_path) as img:
        # Ensure the image is square and RGB
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Make sure it's square by cropping to center
        width, height = img.size
        if width != height:
            size = min(width, height)
            left = (width - size) // 2
            top = (height - size) // 2
            img = img.crop((left, top, left + size, top + size))
        
        # Generate icons for each density
        for density, size in ANDROID_SIZES.items():
            density_dir = os.path.join(output_dir, 'android', 'app', 'src', 'main', 'res', density)
            os.makedirs(density_dir, exist_ok=True)
            
            # Resize image
            resized = img.resize((size, size), Image.Resampling.LANCZOS)
            
            # Save as ic_launcher.png
            output_path = os.path.join(density_dir, 'ic_launcher.png')
            resized.save(output_path, 'PNG', optimize=True)
            print(f"  Created {output_path} ({size}x{size})")
            
            # Also create round icon if needed (same as regular for now)
            round_output_path = os.path.join(density_dir, 'ic_launcher_round.png')
            resized.save(round_output_path, 'PNG', optimize=True)
            print(f"  Created {round_output_path} ({size}x{size})")


def generate_ios_icons(source_image_path, output_dir):
    """Generate iOS app icons in all required sizes."""
    print("Generating iOS icons...")
    
    with Image.open(source_image_path) as img:
        # Ensure the image is square and RGB
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Make sure it's square by cropping to center
        width, height = img.size
        if width != height:
            size = min(width, height)
            left = (width - size) // 2
            top = (height - size) // 2
            img = img.crop((left, top, left + size, top + size))
        
        # Create Assets.xcassets/AppIcon.appiconset directory
        iconset_dir = os.path.join(output_dir, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
        os.makedirs(iconset_dir, exist_ok=True)
        
        # Generate icons for each size
        contents_images = []
        
        for size_name, points, scale in IOS_SIZES:
            pixels = int(points * scale)
            
            # Resize image
            resized = img.resize((pixels, pixels), Image.Resampling.LANCZOS)
            
            # Save icon
            filename = f'icon-{size_name}.png'
            output_path = os.path.join(iconset_dir, filename)
            resized.save(output_path, 'PNG', optimize=True)
            print(f"  Created {output_path} ({pixels}x{pixels})")
            
            # Add to Contents.json
            contents_images.append({
                'filename': filename,
                'idiom': 'universal',
                'scale': f'{scale}x',
                'size': f'{points}x{points}'
            })
        
        # Create Contents.json
        contents_json = {
            'images': contents_images,
            'info': {
                'author': 'xcode',
                'version': 1
            }
        }
        
        import json
        contents_path = os.path.join(iconset_dir, 'Contents.json')
        with open(contents_path, 'w') as f:
            json.dump(contents_json, f, indent=2)
        print(f"  Created {contents_path}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python generate_app_icons.py <source_image.png> [output_dir]")
        print("  source_image.png: Path to source PNG image (ideally 1024x1024 or larger)")
        print("  output_dir: Project root directory (default: current directory)")
        sys.exit(1)
    
    source_image_path = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else os.getcwd()
    
    if not os.path.exists(source_image_path):
        print(f"Error: Source image not found: {source_image_path}")
        sys.exit(1)
    
    print(f"Source image: {source_image_path}")
    print(f"Output directory: {output_dir}")
    print()
    
    try:
        generate_android_icons(source_image_path, output_dir)
        print()
        generate_ios_icons(source_image_path, output_dir)
        print()
        print("All app icons generated successfully!")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()

