"""Rebuild small original MIT test art. No downloaded models or textures."""
import hashlib
import json
import math
import struct
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "stages/02_imported_alpha_vegetation/demo/fixtures"


def glb():
    binary = bytearray()
    views, accessors = [], []

    def accessor(values, components, code, component_type, shape):
        while len(binary) % 4:
            binary.append(0)
        offset = len(binary)
        flat = [v for row in values for v in row] if components > 1 else values
        binary.extend(struct.pack("<" + code * len(flat), *flat))
        views.append(dict(buffer=0, byteOffset=offset, byteLength=len(binary) - offset))
        item = dict(bufferView=len(views) - 1, componentType=component_type, count=len(values), type=shape)
        if shape == "VEC3":
            item.update(min=[min(row[i] for row in values) for i in range(3)],
                        max=[max(row[i] for row in values) for i in range(3)])
        accessors.append(item)
        return len(accessors) - 1

    def primitive(points, material):
        return dict(attributes={
            "POSITION": accessor(points, 3, "f", 5126, "VEC3"),
            "NORMAL": accessor([(0, 0, 1)] * len(points), 3, "f", 5126, "VEC3"),
            "TANGENT": accessor([(1, 0, 0, 1)] * len(points), 4, "f", 5126, "VEC4"),
            "TEXCOORD_0": accessor([(0, 1), (1, 1), (1, 0), (0, 0)], 2, "f", 5126, "VEC2")},
            indices=accessor([0, 1, 2, 0, 2, 3], 1, "H", 5123, "SCALAR"), material=material)

    stem = primitive([(-0.055, 0, 0), (0.055, 0, 0), (0.045, 1.1, 0), (-0.045, 1.1, 0)], 0)
    left = primitive([(-0.6, 0.55, 0), (0, 0.4, 0), (0, 0.85, 0), (-0.6, 1.0, 0)], 1)
    right = primitive([(0, 0.7, 0), (0.65, 0.8, 0), (0.65, 1.15, 0), (0, 1.0, 0)], 2)
    document = dict(asset={"version": "2.0", "generator": "GO_FLORA original fixture generator"},
        scene=0, scenes=[{"nodes": [0]}],
        nodes=[dict(name="OriginalPlant", children=[1], translation=[0.1, -0.15, -0.1]),
               dict(name="NestedPivot", children=[2, 3], translation=[0, 0.15, 0],
                    rotation=[0, math.sin(math.pi / 12), 0, math.cos(math.pi / 12)], scale=[1.1, 0.8, 1.3]),
               dict(name="Stem", mesh=0), dict(name="LeafPair", mesh=1, translation=[0.05, 0.1, 0.05])],
        meshes=[{"name": "StemMesh", "primitives": [stem]}, {"name": "TwoSurfaceLeaves", "primitives": [left, right]}],
        materials=[dict(name=name, doubleSided=True, pbrMetallicRoughness={"baseColorFactor": color, "metallicFactor": 0, "roughnessFactor": 1})
                   for name, color in [("StemBrown", [0.25, 0.12, 0.03, 1]), ("LeafGreen", [0.15, 0.65, 0.12, 1]), ("LeafLime", [0.55, 0.8, 0.08, 1])]],
        buffers=[{"byteLength": len(binary)}], bufferViews=views, accessors=accessors)
    encoded = json.dumps(document, separators=(",", ":")).encode()
    encoded += b" " * (-len(encoded) % 4)
    binary += b"\0" * (-len(binary) % 4)
    payload = struct.pack("<II", len(encoded), 0x4E4F534A) + encoded + struct.pack("<II", len(binary), 0x004E4942) + binary
    (OUT / "original_plant.glb").write_bytes(struct.pack("<III", 0x46546C67, 2, 12 + len(payload)) + payload)


def textures():
    grass = Image.new("RGBA", (128, 128), (35, 115, 25, 0))
    draw = ImageDraw.Draw(grass)
    for index, (tip_x, tip_y) in enumerate([(9, 29), (24, 9), (45, 20), (64, 3), (84, 13), (109, 25), (122, 48)]):
        base = 58 + index * 2
        draw.polygon([(base - 5, 126), (tip_x, tip_y), (base + 5, 126)], fill=(45 + index * 8, 145 + index * 8, 30, 255))
    grass.save(OUT / "grass.png")
    grass.save(OUT / "grass.webp", lossless=True, exact=True)
    flower = Image.new("RGBA", (128, 128), (80, 140, 30, 0))
    draw = ImageDraw.Draw(flower)
    draw.polygon([(61, 126), (64, 25), (68, 126)], fill=(75, 155, 35, 255))
    draw.polygon([(64, 85), (21, 49), (26, 77), (64, 100)], fill=(65, 165, 30, 255))
    draw.polygon([(65, 64), (106, 36), (100, 65), (65, 78)], fill=(105, 180, 40, 255))
    for angle in range(0, 360, 60):
        x, y = 64 + math.cos(math.radians(angle)) * 13, 25 + math.sin(math.radians(angle)) * 13
        draw.ellipse((x - 10, y - 10, x + 10, y + 10), fill=(245, 190, 225, 255))
    draw.ellipse((56, 17, 72, 33), fill=(245, 195, 35, 255))
    flower.save(OUT / "flower.png")
    atlas = Image.new("RGBA", (272, 144), (0, 0, 0, 0))
    atlas.paste(grass, (4, 8))
    atlas.paste(flower, (140, 8))
    atlas.save(OUT / "atlas.png")
    # Exact green/transparent/red-neighbour test texture, with an 8px atlas gutter.
    diagnostic = Image.new("RGBA", (128, 64), (255, 0, 0, 255))
    draw = ImageDraw.Draw(diagnostic)
    draw.rectangle((0, 0, 71, 63), fill=(0, 255, 0, 0))
    draw.rectangle((8, 8, 31, 55), fill=(0, 255, 0, 255))
    diagnostic.save(OUT / "pixel_atlas.png")
    diagnostic.save(OUT / "pixel_atlas.webp", lossless=True, exact=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    glb()
    textures()
    hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.iterdir()) if p.suffix in {".png", ".webp", ".glb", ".gd", ".tscn"}}
    (OUT / "manifest.json").write_text(json.dumps(dict(license="MIT, root LICENSE", provenance="Original GO_FLORA mathematical fixtures; no third-party art", files=hashes), indent=2) + "\n", encoding="utf-8")
    print("PASS original GLB/PNG/WebP fixtures", len(hashes))


if __name__ == "__main__":
    main()
