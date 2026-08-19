import sys
import json
import subprocess
import urllib.request
import base64
import csv
import os #dont remvoe after obliterating .txt reading still needed for tmp files unless any otherway which i dont remember
import tempfile
import re
from io import StringIO
from collections import defaultdict

LANG_TO_TESS = {
    "JA": "jpn", "ZH": "chi_sim+chi_tra", "KO": "kor", "EN": "eng", "DE": "deu",
    "FR": "fra", "ES": "spa", "IT": "ita", "PT": "por", "RU": "rus", "NL": "nld",
    "PL": "pol", "UK": "ukr", "AR": "ara", "HI": "hin", "TH": "tha", "VI": "vie",
    "TR": "tur", "EL": "ell", "CS": "ces", "DA": "dan", "FI": "fin", "HU": "hun",
    "ID": "ind", "NB": "nor", "RO": "ron", "SK": "slk", "SV": "swe", "BG": "bul",
    "ET": "est", "LV": "lav", "LT": "lit", "SL": "slv",
}

LANG_TO_GOOGLE = {
    "JA": "ja", "ZH": "zh", "KO": "ko", "EN": "en", "DE": "de", "FR": "fr",
    "ES": "es", "IT": "it", "PT": "pt", "RU": "ru", "NL": "nl", "PL": "pl",
    "UK": "uk", "AR": "ar", "HI": "hi", "TH": "th", "VI": "vi", "TR": "tr",
    "EL": "el", "CS": "cs", "DA": "da", "FI": "fi", "HU": "hu", "ID": "id",
    "NB": "no", "RO": "ro", "SK": "sk", "SV": "sv", "BG": "bg",
}

MIN_DIMENSION = 1000
HAS_REAL_TEXT = re.compile(r'[\w\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]') #this barely works but ok


def get_image_dimensions(image_path):
    result = subprocess.run(
        ["magick", "identify", "-format", "%w %h", image_path],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        try:
            return map(int, result.stdout.strip().split())
        except:
            pass
    return 0, 0

#prepenis
def preprocess_image(input_path, output_path):
    result = subprocess.run(
        ["magick", "identify", "-format", "%w %h", input_path],
        capture_output=True, text=True
    )
    try:
        w, h = map(int, result.stdout.strip().split())
    except:
        subprocess.run(["cp", input_path, output_path])
        return

    needs_resize = min(w, h) < MIN_DIMENSION
    cmd = ["magick", input_path]
    if needs_resize:
        scale_pct = int((MIN_DIMENSION / min(w, h)) * 100)
        cmd.extend(["-resize", f"{scale_pct}%"])
    cmd.extend(["-colorspace", "Gray", "-brightness-contrast", "0x30", "-sharpen", "0x1.0", "-quality", "100", output_path])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        subprocess.run(["cp", input_path, output_path])


def get_tess_lang(source_lang):
    if source_lang and source_lang.upper() != "AUTO":
        base = source_lang.upper().split("-")[0]
        mapped = LANG_TO_TESS.get(base)
        if mapped:
            installed = subprocess.run(["tesseract", "--list-langs"], capture_output=True, text=True).stdout.strip().split("\n")[1:]
            installed = {l.strip() for l in installed}
            available = [p for p in mapped.split("+") if p in installed]
            if available:
                return "+".join(available)
    result = subprocess.run(["bash", "-c", r"tesseract --list-langs 2>/dev/null | awk 'NR>1{print $1}' | tr '\n' '+' | sed 's/+$//'"], capture_output=True, text=True)
    return result.stdout.strip() or "eng"


def ocr_tesseract(image_path, source_lang=None, use_preprocessing=True):
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
        tmp_path = tmp.name
    try:
        orig_w, orig_h = get_image_dimensions(image_path)
        
        if use_preprocessing:
            preprocess_image(image_path, tmp_path)
            proc_w, proc_h = get_image_dimensions(tmp_path)
            needs_resize = min(orig_w, orig_h) < MIN_DIMENSION
            scale_x = (orig_w / proc_w) if needs_resize and proc_w else 1.0
            scale_y = (orig_h / proc_h) if needs_resize and proc_h else 1.0
        else:
            subprocess.run(["cp", image_path, tmp_path])
            scale_x, scale_y = 1.0, 1.0

        tess_lang = get_tess_lang(source_lang)
        is_cjk = any(l in tess_lang for l in ("jpn", "chi_sim", "chi_tra", "kor"))
        psm = "6" if not is_cjk else "3"

        result = subprocess.run(["tesseract", tmp_path, "stdout", "--psm", psm, "-l", tess_lang, "tsv"], capture_output=True, text=True)
        if result.returncode != 0:
            return {"error": f"tesseract failed: {result.stderr}"}

        reader = csv.DictReader(StringIO(result.stdout), delimiter='\t')
        lines = defaultdict(list)
        for row in reader:
            conf = float(row.get("conf", -1))
            text = row.get("text", "").strip()
            if conf < 0 or not text:
                continue
            key = (row["block_num"], row["par_num"], row["line_num"])
            lines[key].append({"text": text, "x": int(row["left"]), "y": int(row["top"]), "w": int(row["width"]), "h": int(row["height"])})

        blocks = []
        for words in lines.values():
            if not words:
                continue
            x = min(w["x"] for w in words)
            y = min(w["y"] for w in words)
            x2 = max(w["x"] + w["w"] for w in words)
            y2 = max(w["y"] + w["h"] for w in words)
            blocks.append({
                "x": int(x * scale_x), "y": int(y * scale_y),
                "w": int((x2 - x) * scale_x), "h": int((y2 - y) * scale_y),
                "original": " ".join(w["text"] for w in words),
            })
        return blocks
    finally:
        try:
            os.unlink(tmp_path)
        except:
            pass


def _call_google_vision(image_path, google_key, source_lang=None):
    with open(image_path, "rb") as f:
        image_data = base64.b64encode(f.read()).decode("utf-8")

    lang_hint = ""
    if source_lang and source_lang.upper() != "AUTO":
        lang_hint = LANG_TO_GOOGLE.get(source_lang.upper().split("-")[0], "")

    body = {"requests": [{"image": {"content": image_data}, "features": [{"type": "DOCUMENT_TEXT_DETECTION"}], **({"imageContext": {"languageHints": [lang_hint]}} if lang_hint else {})}]}
    req = urllib.request.Request(f"https://vision.googleapis.com/v1/images:annotate?key={google_key}", data=json.dumps(body).encode("utf-8"), headers={"Content-Type": "application/json"})

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            result = json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        return {"error": f"google vision failed: {e}"}

    if "error" in result:
        return {"error": f"google vsion api error: {result['error']}"}

    return result


def ocr_google(image_path, google_key, source_lang=None):
    result = _call_google_vision(image_path, google_key, source_lang)
    if isinstance(result, dict) and "error" in result:
        return result

    blocks = []
    annotation = result.get("responses", [{}])[0]
    pages = annotation.get("fullTextAnnotation", {}).get("pages", [])
    for page in pages:
        for block in page.get("blocks", []):
            for para in block.get("paragraphs", []):
                text = "".join("".join(s.get("text", "") for s in word.get("symbols", [])) for word in para.get("words", []))
                text = text.strip()
                if not text or not HAS_REAL_TEXT.search(text) or (len(text) < 2 and not text.isalnum()):
                    continue
                verts = [(v.get("x", 0), v.get("y", 0)) for word in para.get("words", []) for v in word.get("boundingBox", {}).get("vertices", [])]
                if verts:
                    xs, ys = zip(*verts)
                    blocks.append({"x": min(xs), "y": min(ys), "w": max(xs) - min(xs), "h": max(ys) - min(ys), "original": text})
    return blocks


def _reconstruct_para_text(para):
    # just join symbols per word, words with spaces. no embedded newlines/special chars
    words = []
    for word in para.get("words", []):
        w = "".join(sym.get("text", "") for sym in word.get("symbols", []))
        if w:
            words.append(w)
    return " ".join(words).strip()


def ocr_google_rich(image_path, google_key, source_lang=None, confidence_threshold=0.5):
    result = _call_google_vision(image_path, google_key, source_lang)
    if isinstance(result, dict) and "error" in result:
        return result

    paragraphs = []
    annotation = result.get("responses", [{}])[0]
    pages = annotation.get("fullTextAnnotation", {}).get("pages", [])
    for page in pages:
        for block in page.get("blocks", []):
            if block.get("confidence", 1.0) < confidence_threshold:
                continue
            for para in block.get("paragraphs", []):
                text = _reconstruct_para_text(para)
                if not text or not HAS_REAL_TEXT.search(text) or (len(text) < 2 and not text.isalnum()):
                    continue
                verts = para.get("boundingBox", {}).get("vertices", [])
                if len(verts) < 4:
                    continue
                paragraphs.append({
                    "text": text,
                    "boundingBox": {"vertices": [{"x": v.get("x", 0), "y": v.get("y", 0)} for v in verts]},
                })
    return paragraphs


def ocr_tesseract_rich(image_path, source_lang=None, use_preprocessing=True):
    blocks = ocr_tesseract(image_path, source_lang, use_preprocessing)
    if isinstance(blocks, dict) and "error" in blocks:
        return blocks
    paragraphs = []
    for b in blocks:
        x, y, w, h = b["x"], b["y"], b["w"], b["h"]
        paragraphs.append({
            "text": b["original"],
            "boundingBox": {"vertices": [
                {"x": x, "y": y}, {"x": x + w, "y": y},
                {"x": x + w, "y": y + h}, {"x": x, "y": y + h},
            ]},
        })
    return paragraphs


def translate_deepl(texts, api_key, target_lang, source_lang=None):
    if not texts:
        return []
    body = {"text": texts, "target_lang": target_lang.upper()}
    if source_lang and source_lang != "auto":
        body["source_lang"] = source_lang.upper()
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request("https://api-free.deepl.com/v2/translate", data=data, headers={"Authorization": f"DeepL-Auth-Key {api_key}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            result = json.loads(resp.read().decode("utf-8"))
        return [t["text"] for t in result["translations"]]
    except Exception as e:
        return [f"[err: {e}]"] * len(texts)


def translate_trans(texts, target_lang, source_lang=None):
    """Free translation using translate-shell (trans). Runs in parallel."""
    if not texts:
        return []

    from concurrent.futures import ThreadPoolExecutor

    def _translate_one(text):
        cmd = ["trans", "-brief", "-no-bidi", "-target", target_lang.lower()]
        if source_lang and source_lang != "auto":
            cmd.extend(["-source", source_lang.lower()])
        cmd.append(text)
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            return result.stdout.strip()
        return f"[err: {result.stderr}]"

    with ThreadPoolExecutor(max_workers=min(len(texts), 8)) as pool:
        return list(pool.map(_translate_one, texts))


def parse_args(args):
    result = {"image_path": None, "translation_key": None, "target_lang": None, "source_lang": None, "ocr_backend": "google", "translation_engine": "deepl", "google_key": None, "use_preprocessing": True, "rich": False}
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--ocr" and i + 1 < len(args):
            result["ocr_backend"] = args[i + 1]
            i += 2
        elif arg == "--translation-engine" and i + 1 < len(args):
            result["translation_engine"] = args[i + 1]
            i += 2
        elif arg == "--google-key" and i + 1 < len(args):
            result["google_key"] = args[i + 1]
            i += 2
        elif arg == "--translation-key" and i + 1 < len(args):
            result["translation_key"] = args[i + 1]
            i += 2
        elif arg == "--no-preprocess":
            result["use_preprocessing"] = False
            i += 1
        elif arg == "--rich":
            result["rich"] = True
            i += 1
        elif not result["image_path"]:
            result["image_path"] = arg
            i += 1
        elif not result["translation_key"]:
            result["translation_key"] = arg
            i += 1
        elif not result["target_lang"]:
            result["target_lang"] = arg
            i += 1
        elif not result["source_lang"]:
            result["source_lang"] = arg
            i += 1
        else:
            i += 1
    return result

#safgest way to store api keys 100%
def main():
    args = parse_args(sys.argv[1:])
    if not args["image_path"] or not args["target_lang"]:
        print(json.dumps({"error": "usage: screen_translate.py <image> <key> <target> [source] [--ocr tesseract|google] [--translation-engine deepl|trans] [--google-key <key>] [--rich]"}))
        sys.exit(1)

    # translation key not required for trans engine
    if args["translation_engine"] != "trans" and not args["translation_key"]:
        print(json.dumps({"error": "translation key required (or use --translation-engine trans)"}))
        sys.exit(1)

    if args["rich"]:
        return main_rich(args)

    if args["ocr_backend"] == "google":
        if not args["google_key"]:
            print(json.dumps({"error": "google ocr requires --google-key"}))
            sys.exit(1)
        blocks = ocr_google(args["image_path"], args["google_key"], args["source_lang"])
    else:
        blocks = ocr_tesseract(args["image_path"], args["source_lang"], args["use_preprocessing"])

    if isinstance(blocks, dict) and "error" in blocks:
        print(json.dumps(blocks))
        sys.exit(1)
    if not blocks:
        print(json.dumps([]))
        return

    originals = [b["original"] for b in blocks]

    if args["translation_engine"] == "trans":
        translations = translate_trans(originals, args["target_lang"], args["source_lang"])
    else:
        translations = translate_deepl(originals, args["translation_key"], args["target_lang"], args["source_lang"])

    for block, translated in zip(blocks, translations):
        block["translated"] = translated

    print(json.dumps(blocks))


def main_rich(args):
    """Rich output: {paragraphs: [{text, boundingBox: {vertices}}], translations: {orig: translated}}"""
    if args["ocr_backend"] == "google":
        if not args["google_key"]:
            print(json.dumps({"error": "google ocr requires --google-key"}))
            sys.exit(1)
        paragraphs = ocr_google_rich(args["image_path"], args["google_key"], args["source_lang"])
    else:
        paragraphs = ocr_tesseract_rich(args["image_path"], args["source_lang"], args["use_preprocessing"])

    if isinstance(paragraphs, dict) and "error" in paragraphs:
        print(json.dumps(paragraphs))
        sys.exit(1)
    if not paragraphs:
        print(json.dumps({"paragraphs": [], "translations": {}}))
        return

    originals = [p["text"] for p in paragraphs]

    if args["translation_engine"] == "trans":
        translated = translate_trans(originals, args["target_lang"], args["source_lang"])
    else:
        translated = translate_deepl(originals, args["translation_key"], args["target_lang"], args["source_lang"])

    translations = {}
    for orig, tr in zip(originals, translated):
        translations[orig] = tr

    print(json.dumps({"paragraphs": paragraphs, "translations": translations}))


if __name__ == "__main__":
    main()
