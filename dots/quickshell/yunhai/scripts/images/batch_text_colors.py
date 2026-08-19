#!/usr/bin/env python3
# batch color detection: one python start for all regions instead of N
# reads JSON from stdin: {"image": "/path/to/img", "regions": [{"x":0,"y":0,"w":100,"h":50}, ...]}
# outputs: [{"background": "#hex", "text": "#hex"}, ...]

import cv2
import numpy as np
import json
import sys

def to_hex(color):
    return "#{:02x}{:02x}{:02x}".format(int(color[0]), int(color[1]), int(color[2]))

def detect_color(img_rgb, x, y, w, h):
    ih, iw = img_rgb.shape[:2]
    # clamp to image bounds
    x1 = max(0, int(x))
    y1 = max(0, int(y))
    x2 = min(iw, int(x + w))
    y2 = min(ih, int(y + h))
    if x2 <= x1 or y2 <= y1:
        return {"background": "#000000", "text": "#ffffff"}

    crop = img_rgb[y1:y2, x1:x2]
    ch, cw = crop.shape[:2]
    if ch < 2 or cw < 2:
        return {"background": "#000000", "text": "#ffffff"}

    corners = np.array([
        crop[0, 0], crop[0, cw-1],
        crop[ch-1, 0], crop[ch-1, cw-1]
    ])
    bg_color = np.median(corners, axis=0).astype(int)

    pixels = crop.reshape(-1, 3).astype(int)
    distances = np.linalg.norm(pixels - bg_color, axis=1)
    threshold = np.percentile(distances, 95)
    text_pixels = pixels[distances >= threshold]

    if len(text_pixels) == 0:
        text_color = [255, 255, 255]
    else:
        text_color = np.median(text_pixels, axis=0).astype(int)

    return {"background": to_hex(bg_color), "text": to_hex(text_color)}

def main():
    data = json.loads(sys.stdin.read())
    image_path = data["image"]
    regions = data["regions"]

    img = cv2.imread(image_path)
    if img is None:
        print(json.dumps([{"background": "#000000", "text": "#ffffff"}] * len(regions)))
        return

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    results = [detect_color(img_rgb, r["x"], r["y"], r["w"], r["h"]) for r in regions]
    print(json.dumps(results))

if __name__ == "__main__":
    main()
