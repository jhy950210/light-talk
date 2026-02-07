#!/usr/bin/env python3
"""Generate Light Talk app icon - clean minimal design"""
from PIL import Image, ImageDraw
import os

SIZE = 1024
img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Clean gradient: brand blue top -> deeper blue bottom
top = (74, 144, 217)      # #4A90D9 primary
bottom = (36, 100, 180)   # deeper blue

corner_radius = 220
for y in range(SIZE):
    t = y / SIZE
    r = int(top[0] + (bottom[0] - top[0]) * t)
    g = int(top[1] + (bottom[1] - top[1]) * t)
    b = int(top[2] + (bottom[2] - top[2]) * t)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b, 255))

mask = Image.new('L', (SIZE, SIZE), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, SIZE-1, SIZE-1], radius=corner_radius, fill=255)
img.putalpha(mask)

# Single clean white chat bubble
bubble = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
bd = ImageDraw.Draw(bubble)

bx1, by1 = 190, 210
bx2, by2 = SIZE - 190, SIZE - 280

bd.rounded_rectangle([bx1, by1, bx2, by2], radius=85, fill=(255, 255, 255, 255))

# Clean tail
tail_points = [
    (bx1 + 70, by2 - 5),
    (bx1 + 20, by2 + 65),
    (bx1 + 150, by2 - 5),
]
bd.polygon(tail_points, fill=(255, 255, 255, 255))

img = Image.alpha_composite(img, bubble)
draw = ImageDraw.Draw(img)

# Three dots - brand blue, evenly spaced
dot_y = (by1 + by2) // 2
dot_spacing = 85
dot_r = 24
cx = (bx1 + bx2) // 2

for i in range(-1, 2):
    x = cx + i * dot_spacing
    draw.ellipse([x - dot_r, dot_y - dot_r, x + dot_r, dot_y + dot_r], fill=(74, 144, 217))

# Save & export all sizes
output = '/Users/jungwheeyoung/IdeaProjects/light-talk/assets/icon/app_icon.png'
os.makedirs(os.path.dirname(output), exist_ok=True)
img.save(output, 'PNG')

# Flatten for iOS (no transparency)
flat = Image.new('RGB', (SIZE, SIZE), bottom)
flat.paste(img, mask=img.split()[3])

ios_dir = '/Users/jungwheeyoung/IdeaProjects/light-talk/frontend/ios/Runner/Assets.xcassets/AppIcon.appiconset'
for name, s in [('Icon-App-20x20@1x.png',20),('Icon-App-20x20@2x.png',40),('Icon-App-20x20@3x.png',60),
    ('Icon-App-29x29@1x.png',29),('Icon-App-29x29@2x.png',58),('Icon-App-29x29@3x.png',87),
    ('Icon-App-40x40@1x.png',40),('Icon-App-40x40@2x.png',80),('Icon-App-40x40@3x.png',120),
    ('Icon-App-60x60@2x.png',120),('Icon-App-60x60@3x.png',180),('Icon-App-76x76@1x.png',76),
    ('Icon-App-76x76@2x.png',152),('Icon-App-83.5x83.5@2x.png',167),('Icon-App-1024x1024@1x.png',1024)]:
    flat.resize((s,s), Image.LANCZOS).save(os.path.join(ios_dir, name), 'PNG')

android_dir = '/Users/jungwheeyoung/IdeaProjects/light-talk/frontend/android/app/src/main/res'
for fp, s in [('mipmap-mdpi/ic_launcher.png',48),('mipmap-hdpi/ic_launcher.png',72),
    ('mipmap-xhdpi/ic_launcher.png',96),('mipmap-xxhdpi/ic_launcher.png',144),('mipmap-xxxhdpi/ic_launcher.png',192)]:
    p = os.path.join(android_dir, fp); os.makedirs(os.path.dirname(p), exist_ok=True)
    flat.resize((s,s), Image.LANCZOS).save(p, 'PNG')

web_dir = '/Users/jungwheeyoung/IdeaProjects/light-talk/frontend/web'
flat.resize((32,32), Image.LANCZOS).save(os.path.join(web_dir, 'favicon.png'), 'PNG')
for s, n in [(192,'Icon-192.png'),(512,'Icon-512.png'),(192,'Icon-maskable-192.png'),(512,'Icon-maskable-512.png')]:
    flat.resize((s,s), Image.LANCZOS).save(os.path.join(web_dir, 'icons', n), 'PNG')

print("Done!")
