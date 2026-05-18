#!/usr/bin/env python3
import argparse
import json
import math
import os
import re
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError as error:
    raise SystemExit(
        "Pillow is required to generate App Store frames. "
        "Install it in the local Python environment or use the bundled environment that provides PIL."
    ) from error


PROJECT_DIR = Path(__file__).resolve().parents[1]
DEFAULT_INPUT_DIR = PROJECT_DIR / "app-store" / "raw-screenshots"
DEFAULT_OUTPUT_DIR = PROJECT_DIR / "app-store" / "final-screenshots"
DEFAULT_COPY_SOURCE = PROJECT_DIR / "Core" / "Screenshot" / "ScreenshotSupport.swift"

DEVICE_FAMILIES = ("iphone", "ipad")
LOCALES = ("en-US", "en-GB", "pt-BR", "pt-PT", "es-ES", "fr-FR", "nl-NL", "de-DE")
FRAMES = ("dashboard", "themes", "transactions", "periods", "categories")
SMOKE_LOCALES = ("en-US", "pt-PT", "de-DE")
SMOKE_FRAMES = ("dashboard", "transactions", "categories")

BRAND = {
    "background": (13, 17, 23),
    "card": (22, 27, 34),
    "primary": (139, 126, 200),
    "secondary": (196, 139, 160),
    "tertiary": (124, 168, 196),
    "text": (248, 250, 252),
    "muted": (199, 209, 217),
    "border": (58, 64, 78),
}

FRAME_CONFIG = {
    "dashboard": {
        "output": "01-dashboard.png",
        "copy_state": "01-dashboard-nebula",
        "raw_states": ("01-dashboard-nebula",),
        "style": "nebula",
    },
    "themes": {
        "output": "02-themes.png",
        "copy_state": "02-dashboard-electric-neon",
        "raw_states": ("01-dashboard-nebula", "02-dashboard-electric-neon", "03-dashboard-tropical"),
        "style": "electric",
    },
    "transactions": {
        "output": "03-transactions.png",
        "copy_state": "04-transactions",
        "raw_states": ("04-transactions",),
        "style": "nebula",
    },
    "periods": {
        "output": "04-periods.png",
        "copy_state": "05-period-configuration",
        "raw_states": ("05-period-configuration",),
        "style": "tropical",
    },
    "categories": {
        "output": "05-categories.png",
        "copy_state": "06-categories",
        "raw_states": ("06-categories",),
        "style": "nebula",
    },
}

LOCALE_TOKENS = {
    "enUS": "en-US",
    "enGB": "en-GB",
    "ptBR": "pt-BR",
    "ptPT": "pt-PT",
    "esES": "es-ES",
    "frFR": "fr-FR",
    "nlNL": "nl-NL",
    "deDE": "de-DE",
}

STATE_TOKENS = {
    "dashboardNebula": "01-dashboard-nebula",
    "dashboardElectricNeon": "02-dashboard-electric-neon",
    "dashboardTropical": "03-dashboard-tropical",
    "transactions": "04-transactions",
    "periodConfiguration": "05-period-configuration",
    "categories": "06-categories",
}

FONT_CANDIDATES = {
    "title": (
        "/Library/Fonts/SF-Pro-Display-Semibold.otf",
        "/Library/Fonts/SF-Pro-Text-Semibold.otf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    ),
    "body": (
        "/Library/Fonts/SF-Pro-Text-Regular.otf",
        "/Library/Fonts/SF-Pro.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ),
}


def main() -> int:
    args = parse_args()
    selected_devices, selected_locales, selected_frames = selected_values(args)
    frame_copy = parse_frame_copy(args.copy_source)

    total = 0
    for device in selected_devices:
        for locale in selected_locales:
            for frame_key in selected_frames:
                generate_frame(
                    device=device,
                    locale=locale,
                    frame_key=frame_key,
                    frame_copy=frame_copy,
                    input_dir=args.input_dir,
                    output_dir=args.output_dir,
                    font_path=args.font_path,
                )
                total += 1

    print(f"Generated App Store frame screenshots: {total}")
    print(f"Output directory: {args.output_dir}")
    return 0


def parse_args():
    parser = argparse.ArgumentParser(description="Generate PiggyPulse App Store framed screenshots from raw simulator PNGs.")
    parser.add_argument("--smoke", action="store_true", help="Generate the representative smoke subset.")
    parser.add_argument("--device-family", choices=DEVICE_FAMILIES, help="Generate only iphone or ipad frames.")
    parser.add_argument("--locale", choices=LOCALES, help="Generate only one locale.")
    parser.add_argument("--frame", choices=FRAMES, help="Generate only one final frame.")
    parser.add_argument("--input-dir", type=Path, default=DEFAULT_INPUT_DIR, help="Raw screenshot directory.")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR, help="Final screenshot output directory.")
    parser.add_argument("--copy-source", type=Path, default=DEFAULT_COPY_SOURCE, help="Swift screenshot copy source.")
    parser.add_argument(
        "--font-path",
        default=os.environ.get("APPSTORE_FRAME_FONT_PATH", ""),
        help="Optional font path. Defaults to macOS system fonts. Can also be set with APPSTORE_FRAME_FONT_PATH.",
    )
    return parser.parse_args()


def selected_values(args):
    if args.smoke:
        devices = ("iphone",)
        locales = SMOKE_LOCALES
        frames = SMOKE_FRAMES
    else:
        devices = DEVICE_FAMILIES
        locales = LOCALES
        frames = FRAMES

    if args.device_family:
        devices = (args.device_family,)
    if args.locale:
        locales = (args.locale,)
    if args.frame:
        frames = (args.frame,)

    return devices, locales, frames


def parse_frame_copy(path: Path):
    if not path.is_file():
        raise SystemExit(f"Missing screenshot copy source: {path}")

    source = path.read_text(encoding="utf-8")
    match = re.search(
        r"static let frameCopy:\s*\[ScreenshotLocaleID:\s*\[ScreenshotStateID:\s*ScreenshotFrameCopy\]\]\s*=\s*\[(.*?)\n\s*\]",
        source,
        re.DOTALL,
    )
    if not match:
        raise SystemExit("Could not find ScreenshotDemoBuilder.frameCopy in Swift source.")

    frame_copy = {}
    for locale_token, body in re.findall(r"\.(\w+):\s*\[(.*?)\](?:,|$)", match.group(1), re.DOTALL):
        locale = LOCALE_TOKENS.get(locale_token)
        if not locale:
            continue
        frame_copy[locale] = {}
        for state_token, title, subtitle in re.findall(
            r"\.(\w+):\s*\.init\(title:\s*\"((?:[^\"\\]|\\.)*)\",\s*subtitle:\s*\"((?:[^\"\\]|\\.)*)\"\)",
            body,
        ):
            state = STATE_TOKENS.get(state_token)
            if state:
                frame_copy[locale][state] = {
                    "title": decode_swift_string(title),
                    "subtitle": decode_swift_string(subtitle),
                }

    missing = []
    for locale in LOCALES:
        for frame in FRAMES:
            state = FRAME_CONFIG[frame]["copy_state"]
            copy = frame_copy.get(locale, {}).get(state)
            if not copy or not copy.get("title") or not copy.get("subtitle"):
                missing.append(f"{locale}/{state}")
    if missing:
        raise SystemExit("Missing localized frame copy: " + ", ".join(missing))

    return frame_copy


def decode_swift_string(value: str) -> str:
    return json.loads(f'"{value}"')


def generate_frame(device, locale, frame_key, frame_copy, input_dir: Path, output_dir: Path, font_path: str):
    config = FRAME_CONFIG[frame_key]
    copy = frame_copy[locale][config["copy_state"]]
    raw_images = []

    for raw_state in config["raw_states"]:
        raw_path = input_dir / device / locale / f"{raw_state}.png"
        if not raw_path.is_file():
            raise SystemExit(f"Missing raw screenshot: {raw_path}")
        raw_images.append((raw_state, Image.open(raw_path).convert("RGB")))

    canvas_size = raw_images[0][1].size
    for raw_state, image in raw_images:
        if image.size != canvas_size:
            raise SystemExit(
                f"Raw screenshot dimensions must match for {device}/{locale}/{frame_key}: "
                f"{raw_state} is {image.size[0]}x{image.size[1]}, expected {canvas_size[0]}x{canvas_size[1]}"
            )

    canvas = create_background(canvas_size, config["style"])
    draw = ImageDraw.Draw(canvas)
    title_font, subtitle_font = text_fonts(canvas_size, copy["title"], copy["subtitle"], font_path)
    text_bottom = draw_header(draw, canvas_size, copy["title"], copy["subtitle"], title_font, subtitle_font, config["style"])

    if frame_key == "themes":
        draw_themes_composition(canvas, raw_images, text_bottom)
    else:
        draw_standard_composition(canvas, raw_images[0][1], text_bottom, config["style"])

    output_path = output_dir / device / locale / config["output"]
    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(output_path, "PNG", optimize=True)


def create_background(size, style):
    width, height = size
    base = Image.new("RGB", size, BRAND["background"])
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))

    style_accents = {
        "nebula": ((139, 126, 200, 110), (124, 168, 196, 70), (196, 139, 160, 45)),
        "electric": ((103, 232, 249, 105), (255, 79, 216, 75), (139, 126, 200, 55)),
        "tropical": ((77, 210, 166, 95), (255, 184, 107, 70), (124, 168, 196, 55)),
    }
    accents = style_accents.get(style, style_accents["nebula"])
    odraw = ImageDraw.Draw(overlay)

    ellipse_specs = (
        (-width * 0.18, -height * 0.12, width * 0.62, height * 0.28, accents[0]),
        (width * 0.52, height * 0.10, width * 1.16, height * 0.58, accents[1]),
        (-width * 0.15, height * 0.58, width * 0.48, height * 1.05, accents[2]),
    )
    for left, top, right, bottom, color in ellipse_specs:
        odraw.ellipse((left, top, right, bottom), fill=color)

    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=max(60, int(width * 0.06))))
    base = Image.alpha_composite(base.convert("RGBA"), overlay)

    grain = Image.new("RGBA", size, (255, 255, 255, 0))
    gdraw = ImageDraw.Draw(grain)
    spacing = 34 if width < 1500 else 44
    for y in range(0, height, spacing):
        alpha = 9 if (y // spacing) % 2 == 0 else 5
        gdraw.line((0, y, width, y), fill=(255, 255, 255, alpha), width=1)
    return Image.alpha_composite(base, grain)


def text_fonts(size, title, subtitle, font_path):
    width, _height = size
    title_size = 86 if width < 1600 else 104
    subtitle_size = 38 if width < 1600 else 46
    max_width = int(width * 0.86)

    while title_size >= 48:
        title_font = load_font("title", title_size, font_path)
        subtitle_font = load_font("body", subtitle_size, font_path)
        title_lines = wrap_text(title, title_font, max_width)
        subtitle_lines = wrap_text(subtitle, subtitle_font, max_width)
        if len(title_lines) <= 3 and len(subtitle_lines) <= 2:
            return title_font, subtitle_font
        title_size -= 4
        subtitle_size = max(28, subtitle_size - 2)

    return load_font("title", title_size, font_path), load_font("body", subtitle_size, font_path)


def load_font(kind, size, explicit_path=""):
    candidates = [explicit_path] if explicit_path else []
    candidates.extend(FONT_CANDIDATES[kind])

    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return ImageFont.truetype(candidate, size=size)

    return ImageFont.load_default(size=size)


def draw_header(draw, size, title, subtitle, title_font, subtitle_font, style):
    width, height = size
    max_width = int(width * 0.86)
    top = int(height * 0.075)
    center_x = width // 2

    title_lines = wrap_text(title, title_font, max_width)
    subtitle_lines = wrap_text(subtitle, subtitle_font, max_width)

    y = top
    for line in title_lines:
        bbox = draw.textbbox((0, 0), line, font=title_font)
        draw.text((center_x - (bbox[2] - bbox[0]) / 2, y), line, font=title_font, fill=BRAND["text"])
        y += int((bbox[3] - bbox[1]) * 1.18)

    y += int(height * 0.018)
    for line in subtitle_lines:
        bbox = draw.textbbox((0, 0), line, font=subtitle_font)
        draw.text((center_x - (bbox[2] - bbox[0]) / 2, y), line, font=subtitle_font, fill=BRAND["muted"])
        y += int((bbox[3] - bbox[1]) * 1.35)

    accent = accent_for_style(style)
    pill_width = int(width * 0.16)
    pill_height = max(6, int(height * 0.004))
    pill_y = y + int(height * 0.028)
    draw.rounded_rectangle(
        (center_x - pill_width / 2, pill_y, center_x + pill_width / 2, pill_y + pill_height),
        radius=pill_height,
        fill=accent,
    )
    return int(pill_y + pill_height)


def wrap_text(text, font, max_width):
    probe = Image.new("RGB", (1, 1))
    draw = ImageDraw.Draw(probe)
    words = text.split(" ")
    lines = []
    current = ""

    for word in words:
        candidate = word if not current else f"{current} {word}"
        if text_width(draw, candidate, font) <= max_width:
            current = candidate
            continue

        if current:
            lines.append(current)
        current = fit_word(word, draw, font, max_width)

    if current:
        lines.append(current)

    return lines


def fit_word(word, draw, font, max_width):
    if text_width(draw, word, font) <= max_width:
        return word

    chunks = []
    current = ""
    for char in word:
        candidate = current + char
        if text_width(draw, candidate, font) <= max_width:
            current = candidate
        else:
            if current:
                chunks.append(current)
            current = char
    if current:
        chunks.append(current)
    return "\n".join(chunks)


def text_width(draw, text, font):
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0]


def draw_standard_composition(canvas, screenshot, text_bottom, style):
    width, height = canvas.size
    y = max(int(height * 0.29), text_bottom + int(height * 0.055))
    bottom_margin = int(height * 0.055)
    max_box = (
        int(width * (0.78 if width < 1600 else 0.74)),
        height - y - bottom_margin,
    )
    image_size = fit_size(screenshot.size, max_box)
    x = (width - image_size[0]) // 2

    draw_device_card(canvas, screenshot, (x, y), image_size, accent_for_style(style))


def draw_themes_composition(canvas, raw_images, text_bottom):
    width, height = canvas.size
    y = max(int(height * 0.34), text_bottom + int(height * 0.08))
    max_height = height - y - int(height * 0.08)
    center_width = int(width * 0.36)
    side_width = int(width * 0.31)
    aspect = raw_images[0][1].size[1] / raw_images[0][1].size[0]
    center_height = int(center_width * aspect)
    side_height = int(side_width * aspect)

    if center_height > max_height:
        center_height = max_height
        center_width = int(center_height / aspect)
        side_width = int(center_width * 0.86)
        side_height = int(side_width * aspect)

    center_x = (width - center_width) // 2
    side_y = y + int(height * 0.055)
    left_x = max(int(width * 0.045), center_x - int(side_width * 0.68))
    right_x = min(width - side_width - int(width * 0.045), center_x + center_width - int(side_width * 0.32))
    accents = {
        "01-dashboard-nebula": (139, 126, 200),
        "02-dashboard-electric-neon": (103, 232, 249),
        "03-dashboard-tropical": (77, 210, 166),
    }

    placements = (
        (0, left_x, side_y, side_width, side_height),
        (2, right_x, side_y, side_width, side_height),
        (1, center_x, y, center_width, center_height),
    )

    for index, x, item_y, item_width, item_height in placements:
        raw_state, image = raw_images[index]
        draw_device_card(
            canvas,
            image,
            (x, item_y),
            (item_width, item_height),
            accents.get(raw_state, BRAND["primary"]),
            compact=True,
        )


def draw_device_card(canvas, screenshot, origin, image_size, accent, compact=False):
    x, y = origin
    image_width, image_height = image_size
    radius = int(image_width * (0.075 if compact else 0.07))
    padding = max(8, int(image_width * (0.022 if compact else 0.026)))
    card_box = (
        x - padding,
        y - padding,
        x + image_width + padding,
        y + image_height + padding,
    )

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle(
        shifted(card_box, dy=max(16, image_width // 24)),
        radius=radius + padding,
        fill=(0, 0, 0, 150),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=max(18, image_width // 28)))
    canvas.alpha_composite(shadow)

    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.rounded_rectangle(card_box, radius=radius + padding, outline=(*accent, 155), width=max(3, image_width // 110))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=max(6, image_width // 70)))
    canvas.alpha_composite(glow)

    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle(card_box, radius=radius + padding, fill=BRAND["card"], outline=(*BRAND["border"], 210), width=max(2, image_width // 180))

    resized = screenshot.resize(image_size, Image.Resampling.LANCZOS)
    mask = Image.new("L", image_size, 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.rounded_rectangle((0, 0, image_width, image_height), radius=radius, fill=255)
    canvas.paste(resized, (x, y), mask)


def shifted(box, dx=0, dy=0):
    left, top, right, bottom = box
    return (left + dx, top + dy, right + dx, bottom + dy)


def fit_size(source_size, max_size):
    source_width, source_height = source_size
    max_width, max_height = max_size
    scale = min(max_width / source_width, max_height / source_height)
    return (max(1, int(source_width * scale)), max(1, int(source_height * scale)))


def accent_for_style(style):
    if style == "electric":
        return (103, 232, 249)
    if style == "tropical":
        return (77, 210, 166)
    return BRAND["primary"]


if __name__ == "__main__":
    raise SystemExit(main())
