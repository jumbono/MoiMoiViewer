"""
moi-moi.jp から「出演者の歴史」と「過去の月歌」を収集し、
アプリが読み込む data/latest.json (MoiMoiDataPayload 互換) を生成する。

礼儀として:
- User-Agent にアプリ名と連絡先を明記する
- リクエスト間に間隔を空ける
- 取得したページの内容は正規化するのみで、画像やHTMLそのものは再配布しない
  （出典URLを各エンティティに必ず残す）
"""
from __future__ import annotations

import json
import re
import sys
import time
import unicodedata
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

BASE = "http://moi-moi.jp/"
USER_AGENT = (
    "MoiMoiViewerBot/1.0 (+https://github.com/jumbono/MoiMoiViewer; "
    "personal fan-app data sync; contact via GitHub issues)"
)
REQUEST_DELAY_SECONDS = 1.5

ROLE_MAP = {
    "歌のお兄さん": "singing",
    "歌のお姉さん": "singing",
    "体操のお兄さん": "gymnastics",
    "体操のお姉さん": "gymnastics",
    "うたのお兄さん": "singing",
    "うたのお姉さん": "singing",
}


def fetch(path_or_url: str) -> str:
    url = path_or_url if path_or_url.startswith("http") else BASE + path_or_url
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=20) as resp:
        raw = resp.read()
    time.sleep(REQUEST_DELAY_SECONDS)
    return raw.decode("shift_jis", errors="replace")


def to_halfwidth(text: str) -> str:
    return unicodedata.normalize("NFKC", text)


def performer_id_from_href(href: str) -> str | None:
    m = re.search(r"an_([a-zA-Z0-9]+)\.html", href)
    return m.group(1) if m else None


# ---------------------------------------------------------------------------
# 出演者の歴史 (an_history.html)
# ---------------------------------------------------------------------------

def parse_performers(html: str) -> list[dict]:
    from bs4 import BeautifulSoup

    soup = BeautifulSoup(html, "html.parser")

    # "年度" を含む見出し行を探し、その行が属する表を対象にする
    header_tr = None
    for tr in soup.find_all("tr"):
        first_td = tr.find("td")
        if first_td and to_halfwidth(first_td.get_text(strip=True)) == "年度":
            header_tr = tr
            break
    if header_tr is None:
        return []

    year_tds = header_tr.find_all("td")[1:]
    years: list[int] = []
    for td in year_tds:
        text = to_halfwidth(td.get_text(strip=True))
        m = re.search(r"(\d{4})", text)
        years.append(int(m.group(1)) if m else (years[-1] - 1 if years else 0))
    current_year = years[0] if years else None

    performers: dict[str, dict] = {}

    for tr in header_tr.find_next_siblings("tr"):
        tds = tr.find_all("td", recursive=False)
        if not tds:
            continue
        role_label = to_halfwidth(tds[0].get_text(strip=True))
        # セクション見出し行 (colspan=40 等) や空行はスキップ
        if len(tds) < 2 or not role_label or role_label in ("",):
            continue
        role = ROLE_MAP.get(role_label, "other")

        cum = 0
        for cell in tds[1:]:
            colspan_attr = cell.get("colspan", "1")
            try:
                colspan = int(colspan_attr)
            except ValueError:
                colspan = 1
            block_years = years[cum: cum + colspan] if years else []
            cum += colspan

            for link in cell.find_all("a", href=re.compile(r"an_[a-zA-Z0-9]+\.html")):
                pid = performer_id_from_href(link["href"])
                if not pid:
                    continue
                name = to_halfwidth(link.get_text(strip=True))
                if not name:
                    continue

                cell_text = to_halfwidth(cell.get_text(" ", strip=True))
                gen_match = re.search(r"第(\d+)代目", cell_text)
                generation = int(gen_match.group(1)) if gen_match else None

                newest = max(block_years) if block_years else None
                oldest = min(block_years) if block_years else None
                tenure_start = f"{oldest}-04-01T00:00:00Z" if oldest else None
                is_current = current_year is not None and newest == current_year
                tenure_end = None if is_current else (f"{newest}-03-31T00:00:00Z" if newest else None)

                existing = performers.get(pid)
                if existing is None:
                    performers[pid] = {
                        "id": pid,
                        "name": name,
                        "kana": "",
                        "role": role,
                        "generation": generation,
                        "tenureStart": tenure_start,
                        "tenureEnd": tenure_end,
                        "biography": "",
                        "photoURLString": None,
                        "sourceURLString": BASE + f"an_{pid}.html",
                    }
                else:
                    # 同一人物が複数ブロックにまたがる場合は在籍期間を広げる
                    if tenure_start and (existing["tenureStart"] is None or tenure_start < existing["tenureStart"]):
                        existing["tenureStart"] = tenure_start
                    if tenure_end is None:
                        existing["tenureEnd"] = None
                    elif existing["tenureEnd"] is not None and tenure_end > existing["tenureEnd"]:
                        existing["tenureEnd"] = tenure_end

    return list(performers.values())


def enrich_performer_biography(performer: dict) -> None:
    try:
        html = fetch(performer["sourceURLString"])
    except Exception as exc:  # noqa: BLE001
        print(f"  ! {performer['id']} の取得に失敗: {exc}", file=sys.stderr)
        return

    from bs4 import BeautifulSoup

    soup = BeautifulSoup(html, "html.parser")
    text = to_halfwidth(soup.get_text("\n"))
    m = re.search(r"おかあさんといっしょ[：:]\s*([^\n]+)", text)
    if m:
        performer["biography"] = m.group(1).strip()


# ---------------------------------------------------------------------------
# 過去の月歌 (tsukiuta.html)
# ---------------------------------------------------------------------------

def parse_songs(html: str) -> list[dict]:
    from bs4 import BeautifulSoup

    soup = BeautifulSoup(html, "html.parser")
    songs: list[dict] = []

    for tr in soup.find_all("tr"):
        tds = tr.find_all("td", recursive=False)
        if len(tds) < 5:
            continue
        head_text = to_halfwidth(tds[0].get_text(" ", strip=True))
        m = re.match(r"(\d{4})年\s*(\d{1,2})月", head_text)
        if not m:
            continue
        year, month = int(m.group(1)), int(m.group(2))

        title_tag = tds[1].find("b")
        title = to_halfwidth(title_tag.get_text(strip=True)) if title_tag else ""
        if not title:
            continue

        credit_text = to_halfwidth(tds[2].get_text("\n", strip=True)) if len(tds) > 2 else ""
        lyricist = _extract_credit(credit_text, "作詞")
        composer = _extract_credit(credit_text, "作曲")

        singer_names = _extract_names(tds[3]) if len(tds) > 3 else []
        cast_names = _extract_names(tds[4]) if len(tds) > 4 else []

        anchor = tr.find("a", attrs={"name": True})
        fragment = anchor["name"] if anchor else f"{year}{_MONTH_EN.get(month, month)}"

        songs.append({
            "id": f"song-{year:04d}-{month:02d}",
            "title": title,
            "category": "monthlySong",
            "yearMonth": f"{year:04d}-{month:02d}-01T00:00:00Z",
            "composer": composer,
            "lyricist": lyricist,
            "singerNames": singer_names or cast_names,
            "songDescription": "",
            "sourceURLString": BASE + f"tsukiuta.html#{fragment}",
        })

    return songs


_MONTH_EN = {
    1: "january", 2: "february", 3: "march", 4: "april", 5: "may", 6: "june",
    7: "july", 8: "august", 9: "september", 10: "october", 11: "november", 12: "december",
}


def _extract_credit(text: str, label: str) -> str:
    m = re.search(rf"【{label}】\s*\n?\s*([^\n【]+)", text)
    return m.group(1).strip() if m else ""


def _extract_names(td) -> list[str]:
    text = to_halfwidth(td.get_text("\n"))
    names = []
    for line in text.split("\n"):
        line = line.strip().lstrip("●").strip()
        if line and len(line) <= 12:
            names.append(line)
    return names


# ---------------------------------------------------------------------------
# 放送予定と結果 (index.html の #55 セクション / broadcast.html)
# ---------------------------------------------------------------------------

_ANCHOR = re.compile(r'<A\s+name="([^"]+)"\s*/?>(?:\s*</A>)?', re.IGNORECASE)
_DATE_HEADER = re.compile(
    r"^\s*(\d{4})/(\d{2})/(\d{2})\(([月火水木金土日])[^)]*\)\s*(.*?)<BR>",
    re.DOTALL | re.IGNORECASE,
)
_RERUN_REF = re.compile(r'再[（(]\s*<A\s+href="#(b_\d{8})[^"]*"', re.IGNORECASE)
_TAG = re.compile(r"<[^>]+>")
_LEGEND_SECTION = re.compile(r"【表記】((?:.*?<BR>\s*){3})", re.DOTALL)


def _clean_line(raw: str) -> str:
    text = to_halfwidth(_TAG.sub("", raw))
    return re.sub(r"\s+", " ", text).strip()


def _strip_tags_keep_spacing(raw: str) -> str:
    """曲名と出演者コードの境目 (2文字以上の空白) を残したままタグだけ除去する"""
    return to_halfwidth(_TAG.sub("", raw))


def parse_legend(index_html: str) -> dict[str, str]:
    """『Ｙ：ゆういちろう兄　Ｍ：まや姉…』という凡例をコード→名前の辞書にする"""
    section = _LEGEND_SECTION.search(index_html)
    if not section:
        return {}
    text = to_halfwidth(_TAG.sub(" ", section.group(1)))
    legend: dict[str, str] = {}
    for code, name in re.findall(r"([^\s：:　]{1,4})[：:]([^\s　]{1,8})", text):
        if code in ("♪", "★", "New", "＠", "再", "@"):
            continue
        legend[code] = name
    return legend


_LATIN_CODE = re.compile(r"[A-Za-zファ][A-Za-zァ-ヶー]{0,3}$")
_TRAILING_CODE_PAREN = re.compile(r"[（(][A-Za-zファ][A-Za-zァ-ヶー]{0,2}$")
_NON_TITLE_WORDS = {"new"}


def _clean_song_candidate(candidate: str) -> str | None:
    candidate = candidate.strip().strip(")）")
    candidate = _TRAILING_CODE_PAREN.sub("", candidate).strip()
    if not candidate or candidate.lower() in _NON_TITLE_WORDS:
        return None
    return candidate


def _extract_song_titles(text: str, legend: dict[str, str]) -> list[str]:
    """テキスト中の ♪ の直後にある曲名候補を抽出する。
    多行の内訳表記（♪曲名　　Ｙ Ｍ …）と、1行サマリ内の
    「♪曲名、他のコーナー」形式の両方に対応する。
    Ｙ♪Ｍ♪ のような出演者ごとの合いの手♪は曲名としては扱わない。
    """
    titles: list[str] = []
    seen: set[str] = set()
    for raw in re.findall(r"♪([^、♪\n]+)", text):
        tokens = raw.strip().split()
        if not tokens:
            continue
        candidate = _clean_song_candidate(tokens[0])
        if not candidate or candidate in legend:
            continue
        if _LATIN_CODE.fullmatch(candidate):
            continue
        if candidate not in seen:
            seen.add(candidate)
            titles.append(candidate)
    return titles


def _code_pattern(legend: dict[str, str]) -> re.Pattern:
    codes = sorted(legend.keys(), key=len, reverse=True)
    if not codes:
        return re.compile(r"(?!)")  # 何にもマッチしない
    return re.compile("|".join(re.escape(c) for c in codes))


def parse_broadcasts(html: str, source_url: str, legend: dict[str, str]) -> list[dict]:
    code_pattern = _code_pattern(legend)
    anchors = list(_ANCHOR.finditer(html))
    broadcasts: dict[str, dict] = {}

    for i, anchor in enumerate(anchors):
        name = anchor.group(1)
        date_match = re.match(r"b_(\d{8})", name)
        if not date_match:
            continue
        anchor_digits = date_match.group(1)

        block_start = anchor.end()
        block_end = anchors[i + 1].start() if i + 1 < len(anchors) else len(html)
        block = html[block_start:block_end]

        header_match = _DATE_HEADER.match(block)
        if not header_match:
            continue
        year, month, day, _weekday, header_raw = header_match.groups()
        date_str = f"{year}-{month}-{day}"
        if f"{year}{month}{day}" != anchor_digits:
            continue

        rerun_match = _RERUN_REF.search(header_raw)
        rerun_of_id = None
        if rerun_match:
            d = rerun_match.group(1)[2:]  # "b_20260722" -> "20260722"
            rerun_of_id = f"broadcast-{d[0:4]}-{d[4:6]}-{d[6:8]}"

        header_clean = _clean_line(header_raw)
        is_special = any(k in header_clean for k in ("スペシャル", "ファミコン"))

        body = block[header_match.end():]
        corner_lines: list[str] = []
        performer_codes: set[str] = set()
        searchable_texts = [_strip_tags_keep_spacing(header_raw)]

        for raw_line in re.split(r"<BR>", body, flags=re.IGNORECASE):
            normalized = to_halfwidth(raw_line)
            stripped = normalized.strip().lstrip("　 ")
            if not stripped:
                continue
            marker = stripped[0]
            if marker not in ("♪", "●"):
                continue
            clean = _clean_line(stripped[1:])
            if not clean:
                continue
            if marker == "●":
                corner_lines.append(clean)
            spaced = _TAG.sub("", stripped[1:])
            searchable_texts.append(("♪" if marker == "♪" else "") + spaced)
            performer_codes.update(code_pattern.findall(clean))

        song_titles = _extract_song_titles("\n".join(searchable_texts), legend)

        note_parts = [p for p in [header_clean] if p]
        note_parts += [f"♪{t}" for t in song_titles]
        note_parts += [f"●{c}" for c in corner_lines]

        broadcasts[date_str] = {
            "id": f"broadcast-{date_str}",
            "date": f"{date_str}T00:00:00Z",
            "title": "",
            "performerNames": sorted({legend[c] for c in performer_codes if c in legend}),
            "songTitles": song_titles,
            "resultNote": "\n".join(note_parts),
            "isSpecialEpisode": is_special,
            "sourceURLString": f"{source_url}#b_{anchor_digits}",
            "rerunOfBroadcastID": rerun_of_id,
        }

    return list(broadcasts.values())


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

def main() -> None:
    out_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[2] / "data" / "latest.json"

    print("出演者の歴史を取得中...", file=sys.stderr)
    history_html = fetch("an_history.html")
    performers = parse_performers(history_html)
    print(f"  {len(performers)} 人の出演者を検出", file=sys.stderr)

    print("各出演者ページから経歴を補完中...", file=sys.stderr)
    for i, performer in enumerate(performers, 1):
        print(f"  ({i}/{len(performers)}) {performer['name']}", file=sys.stderr)
        enrich_performer_biography(performer)

    print("過去の月歌を取得中...", file=sys.stderr)
    songs_html = fetch("tsukiuta.html")
    songs = parse_songs(songs_html)
    print(f"  {len(songs)} 曲を検出", file=sys.stderr)

    print("放送予定と結果を取得中...", file=sys.stderr)
    index_html = fetch("index.html")
    broadcast_html = fetch("broadcast.html")
    legend = parse_legend(index_html)
    print(f"  出演者コード凡例: {legend}", file=sys.stderr)
    broadcasts_by_date: dict[str, dict] = {}
    for b in parse_broadcasts(broadcast_html, BASE + "broadcast.html", legend):
        broadcasts_by_date[b["date"]] = b
    for b in parse_broadcasts(index_html, BASE + "index.html", legend):
        broadcasts_by_date[b["date"]] = b  # 直近分は index.html を優先
    broadcasts = sorted(broadcasts_by_date.values(), key=lambda b: b["date"], reverse=True)
    print(f"  {len(broadcasts)} 件の放送を検出", file=sys.stderr)

    payload = {
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "performers": performers,
        "songs": songs,
        "broadcasts": broadcasts,
    }

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"書き出し完了: {out_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
