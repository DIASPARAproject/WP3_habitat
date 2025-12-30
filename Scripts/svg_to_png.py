from pathlib import Path
import cairosvg

def batch_convert(root_dir):
    root_dir = Path(root_dir)

    for svg_file in root_dir.rglob("R/images/*.svg"):
        out_file = svg_file.with_suffix(".png")
        cairosvg.svg2png(
            url=str(svg_file),
            write_to=str(out_file)
        )
        print(f"{svg_file} → {out_file}")

batch_convert("D:/workspace/DIASPARA_WP3_habitat")
