#!/usr/bin/env python3
"""ldoc - search the local Zig / C3 docs and std source, print chunks to paste into an LLM.

Installed as `zdoc` (Zig) and `c3doc` (C3); the language comes from the name it's run as.
Docs come from whatever `zig` / `c3c` is on PATH, so upgrading the compiler upgrades the docs.
Override with ZDOC_ZIG=/path/to/zig or C3DOC_C3C=/path/to/c3c.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "ldoc"


def die(msg):
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------- language setup

class Lang:
    name = ""
    version = ""
    std_dir = None
    exts = ()

    def doc_sections(self):
        raise NotImplementedError

    def note_sections(self):
        raise NotImplementedError


class Zig(Lang):
    name = "Zig"
    exts = (".zig",)

    def __init__(self):
        exe = os.environ.get("ZDOC_ZIG") or shutil.which("zig")
        if not exe:
            die("zig not found on PATH (or set ZDOC_ZIG)")
        out = subprocess.run([exe, "env"], capture_output=True, text=True).stdout
        lib = re.search(r'\.lib_dir\s*=\s*"([^"]+)"', out)
        ver = re.search(r'\.version\s*=\s*"([^"]+)"', out)
        if not lib or not ver:
            die(f"could not parse `{exe} env`")
        self.version = ver.group(1)
        self.std_dir = Path(lib.group(1)) / "std"
        self.langref = Path(lib.group(1)).parent / "doc" / "langref.html"

    def doc_sections(self):
        langref = self.langref
        if not langref.exists():
            # Zig built from source (MacPorts, distro packages) ships no
            # langref.html; fetch the same page from ziglang.org once.
            if "dev" in self.version:
                die(f"langref not found at {langref} (no online copy for dev builds)")
            langref = CACHE / f"zig-{self.version}-langref.html"
            if not langref.exists():
                url = f"https://ziglang.org/documentation/{self.version}/"
                print(f"downloading {url} (once) ...", file=sys.stderr)
                CACHE.mkdir(parents=True, exist_ok=True)
                try:
                    with urllib.request.urlopen(url, timeout=30) as r:
                        langref.write_bytes(r.read())
                except Exception as e:
                    die(f"langref not found at {self.langref} and download failed: {e}")
        return cached(f"zig-{self.version}-langref", langref, lambda t: html_sections(t))

    def note_sections(self):
        if "dev" in self.version:
            die(f"no release notes for dev build {self.version}")
        dest = CACHE / f"zig-{self.version}-release-notes.html"
        if not dest.exists():
            url = f"https://ziglang.org/download/{self.version}/release-notes.html"
            print(f"downloading {url} (once) ...", file=sys.stderr)
            CACHE.mkdir(parents=True, exist_ok=True)
            try:
                with urllib.request.urlopen(url, timeout=30) as r:
                    dest.write_bytes(r.read())
            except Exception as e:
                die(f"download failed: {e}")
        return cached(f"zig-{self.version}-notes", dest, lambda t: html_sections(t))


class C3(Lang):
    name = "C3"
    exts = (".c3", ".c3i")

    def __init__(self):
        exe = os.environ.get("C3DOC_C3C") or shutil.which("c3c")
        if not exe:
            die("c3c not found on PATH (or set C3DOC_C3C)")
        root = Path(exe).resolve().parent
        out = subprocess.run([exe, "--version"], capture_output=True, text=True).stdout
        ver = re.search(r"Version:\s*(\S+)", out)
        self.version = ver.group(1) if ver else root.parent.name
        self.std_dir = root / "lib" / "std"
        self.manual = root / "MANUAL.md"
        self.notes = root / "releasenotes.md"

    def doc_sections(self):
        if not self.manual.exists():
            die(f"manual not found at {self.manual}")
        secs = cached(f"c3-{self.version}-manual", self.manual, md_sections)
        return [s for s in secs if s["title"].lower() != "table of contents"]

    def note_sections(self):
        if not self.notes.exists():
            die(f"release notes not found at {self.notes}")
        return cached(f"c3-{self.version}-notes", self.notes, md_sections)


def cached(key, src, parse):
    """Parse a doc file into sections once, keep the result in ~/.cache/ldoc."""
    dest = CACHE / f"{key}.json"
    if dest.exists() and dest.stat().st_mtime >= src.stat().st_mtime:
        return json.loads(dest.read_text())
    secs = parse(src.read_text(errors="replace"))
    CACHE.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(secs))
    return secs


# ---------------------------------------------------------------- doc parsing

class _HtmlSections(HTMLParser):
    HEADINGS = {"h2": 2, "h3": 3, "h4": 4}
    BLOCKS = {"p", "div", "tr", "table", "ul", "ol", "dl", "dt", "dd", "figure",
              "figcaption", "blockquote", "h1", "h5", "h6"}
    SKIP = {"script", "style", "nav", "head"}

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.sections = []
        self.out = None          # list of text pieces for the current section
        self.heading = None      # (level, pieces) while inside a heading
        self.pre = 0
        self.code = 0
        self.skip = 0

    def handle_starttag(self, tag, attrs):
        if tag in self.SKIP:
            self.skip += 1
        elif self.skip:
            return
        elif tag in self.HEADINGS:
            self.heading = (self.HEADINGS[tag], [])
        elif tag == "pre":
            self.pre += 1
            self.emit("\n```\n")
        elif tag in ("code", "samp") and not self.pre:
            self.code += 1
            self.emit("`")
        elif tag == "li":
            self.emit("\n- ")
        elif tag == "br" or tag in self.BLOCKS:
            self.emit("\n")

    def handle_endtag(self, tag):
        if tag in self.SKIP:
            self.skip = max(0, self.skip - 1)
        elif self.skip:
            return
        elif tag in self.HEADINGS and self.heading:
            level, pieces = self.heading
            self.heading = None
            title = re.sub(r"\s+", " ", "".join(pieces)).replace("§", "").strip()
            self.flush()
            self.out = []
            self.sections.append({"title": title, "level": level, "body": ""})
        elif tag == "pre":
            self.pre = max(0, self.pre - 1)
            self.emit("\n```\n")
        elif tag in ("code", "samp") and self.code:
            self.code -= 1
            self.emit("`")
        elif tag in self.BLOCKS:
            self.emit("\n")

    def handle_data(self, data):
        if self.skip:
            return
        if self.heading:
            self.heading[1].append(data)
        elif self.pre:
            self.emit(data)
        else:
            self.emit(re.sub(r"\s+", " ", data))

    def emit(self, s):
        if self.out is not None and not self.heading:
            self.out.append(s)

    def flush(self):
        if self.out is not None and self.sections:
            body = "".join(self.out)
            body = re.sub(r"[ \t]+\n", "\n", body)
            body = re.sub(r"\n{3,}", "\n\n", body)
            self.sections[-1]["body"] = body.strip()


def html_sections(text):
    p = _HtmlSections()
    p.feed(text)
    p.flush()
    return p.sections


def md_sections(text):
    sections, cur, fence = [], None, False
    for line in text.splitlines():
        if re.match(r"\s*(```|~~~)", line):
            fence = not fence
        m = None if fence else re.match(r"(#{1,6})\s+(.*)", line)
        if m:
            cur = {"title": m.group(2).strip(), "level": len(m.group(1)), "body": []}
            sections.append(cur)
        elif cur is not None:
            cur["body"].append(line)
    for s in sections:
        s["body"] = re.sub(r"\n{3,}", "\n\n", "\n".join(s["body"])).strip()
    return sections


# ---------------------------------------------------------------- doc search

def words(s):
    return re.findall(r"[a-z0-9_@$]+", s.lower())


def wcount(text, q):
    """Occurrences of q as a whole word (so `io` doesn't match `information`)."""
    return len(re.findall(r"(?<![\w@$])" + re.escape(q) + r"(?!\w)", text))


def score_section(sec, query):
    ql, qw = query.lower(), words(query)
    title, body = sec["title"].lower(), sec["body"].lower()
    if not all(wcount(title, w) or wcount(body, w) for w in qw):
        return 0
    title_words = set(words(title))
    s = 0
    if title.strip() == ql:
        s += 1000
    elif wcount(title, ql):
        s += 300
    s += 60 * sum(w in title_words for w in qw)
    n = wcount(body, ql)
    if n:
        s += 20 + 5 * min(n, 30)
    s += sum(min(wcount(body, w), 20) for w in qw)
    return s


def search_sections(secs, query, n):
    ranked = sorted(((score_section(s, query), i) for i, s in enumerate(secs)
                     if s["title"].lower() != "table of contents"), reverse=True)
    return [secs[i] for sc, i in ranked[:n] if sc > 0]


def format_section(sec, label, max_chars):
    body = sec["body"]
    if len(body) > max_chars:
        body = body[:max_chars].rsplit("\n", 1)[0] + "\n... (section truncated)"
    return f"### {sec['title']}  [{label}]\n\n{body}\n"


# ---------------------------------------------------------------- std source search

def zig_decl(line):
    m = re.match(r"\s*pub\s+(?:(?:inline|extern|export|noinline)\s+)*(?:fn|const|var)\s+([A-Za-z_]\w*)", line)
    return m.group(1) if m else None


def zig_parent(line):
    m = re.match(r"\s*(?:pub\s+)?(?:const\s+(\w+)\s*=\s*(?:extern\s+|packed\s+)?(?:struct|union|enum|opaque)\b"
                 r"|fn\s+(\w+)\s*\(.*\)\s*type\s*\{)", line)
    return (m.group(1) or m.group(2)) if m else None


C3_FN = re.compile(r"\s*(?:fn|macro)\s+(?:.*?\s+)?([A-Za-z_@$][\w]*(?:\.[A-Za-z_@$]\w*)?)\s*\(")
C3_TYPE = re.compile(r"\s*(?:struct|union|enum|bitstruct|interface|typedef|alias|constset|faultdef)\s+([A-Za-z_]\w*)")
C3_CONST = re.compile(r"\s*const\s+(?:[^=]*?\s+)?([A-Za-z_]\w*)\s*=")


def c3_decl(line):
    m = C3_FN.match(line) or C3_TYPE.match(line) or C3_CONST.match(line)
    return m.group(1) if m else None


def search_c3_notes(path, query, max_chars):
    """Grep C3 release-note bullets, newest version first, grouped by version."""
    qw = words(query)
    groups, version = [], None
    for line in path.read_text(errors="replace").splitlines():
        m = re.match(r"##\s+(\S+)", line)
        if m and not line.startswith("###"):
            version = m.group(1)
            continue
        low = line.lower()
        if version and line.strip().startswith(("-", "*")) and all(wcount(low, w) for w in qw):
            if not groups or groups[-1][0] != version:
                groups.append((version, []))
            groups[-1][1].append(line.strip())
    out, used = [], 0
    for version, items in groups:
        chunk = f"### C3 {version} release notes\n\n" + "\n".join(items) + "\n"
        if used + len(chunk) > max_chars and out:
            break
        out.append(chunk)
        used += len(chunk)
    return out


def indent_of(line):
    return len(line.expandtabs(4)) - len(line.expandtabs(4).lstrip())


def strip_code(line, lang):
    """Remove strings, chars and comments so brace counting isn't fooled."""
    s = line.strip()
    if lang == "Zig" and s.startswith("\\\\"):
        return ""
    s = re.sub(r'"(?:\\.|[^"\\])*"', '""', s)
    s = re.sub(r"'(?:\\.|[^'\\])+'", "''", s)
    s = s.split("//", 1)[0]
    return s


def decl_end(lines, i, lang):
    """Index one past the end of the declaration starting at line i."""
    depth, started = 0, False
    for j in range(i, len(lines)):
        s = strip_code(lines[j], lang)
        for ch in s:
            if ch == "{":
                depth += 1
                started = True
            elif ch == "}":
                depth -= 1
        if started and depth <= 0:
            return j + 1
        if not started and s.rstrip().endswith(";"):
            return j + 1
    return len(lines)


def doc_start(lines, i, lang):
    """Walk back over the doc comment above line i."""
    j = i
    if lang == "Zig":
        while j > 0 and lines[j - 1].strip().startswith("///"):
            j -= 1
    else:
        k = j - 1
        while k >= 0 and lines[k].strip().startswith("@"):  # attributes above the decl
            k -= 1
        if k >= 0 and lines[k].strip().endswith("*>"):
            while k >= 0 and "<*" not in lines[k]:
                k -= 1
            j = max(k, 0)
    return j


def signature(lines, i):
    """The decl line plus continuation lines, up to its `{` or `;`."""
    out = []
    for j in range(i, min(i + 12, len(lines))):
        out.append(lines[j].strip())
        t = lines[j].rstrip()
        if t.endswith("{") or t.endswith(";") or "=>" in t:
            break
    sig = " ".join(out).replace("( ", "(").replace(", )", ")")
    return re.sub(r"\s*\{$", "", sig)


def outline(lines, start, end, lang, rel, max_depth=2):
    """List the public members in lines[start:end] as one-line signatures."""
    decl = zig_decl if lang == "Zig" else c3_decl
    found = [(j, indent_of(lines[j])) for j in range(start, end) if decl(lines[j])]
    if not found:
        return ""
    base = min(ind for _, ind in found)
    step = 4
    rows = []
    for j, ind in found:
        if ind > base + step * (max_depth - 1):
            continue
        doc = ""
        if lang == "Zig" and j > 0 and lines[j - 1].strip().startswith("///"):
            k = j
            while k > 0 and lines[k - 1].strip().startswith("///"):
                k -= 1
            doc = "  // " + lines[k].strip()[3:].strip()
        pad = "  " * ((ind - base) // step)
        rows.append(f"{pad}{signature(lines, j)}{doc}   (line {j + 1})")
    return "\n".join(rows)


def iter_std_files(lang):
    for p in sorted(lang.std_dir.rglob("*")):
        if p.suffix in lang.exts and p.is_file():
            yield p


def search_std(lang, query, n, max_lines):
    parts = [p for p in re.split(r"\.|::", query) if p]
    if parts and parts[0] == "std":
        parts = parts[1:]
    if not parts:
        return []
    target, quals = parts[-1], [q.lower().replace("_", "") for q in parts[:-1]]
    decl = zig_decl if lang.name == "Zig" else c3_decl
    hits = []
    for path in iter_std_files(lang):
        try:
            lines = path.read_text(errors="replace").splitlines()
        except OSError:
            continue
        rel = path.relative_to(lang.std_dir).as_posix()
        path_ctx = {x.lower().replace("_", "") for x in re.split(r"[/_.]", rel[: -len(path.suffix)])}
        path_ctx.add(rel[: -len(path.suffix)].replace("/", "").replace("_", "").lower())
        stack = []
        for i, line in enumerate(lines):
            name = decl(line)
            if lang.name == "Zig":
                ind = indent_of(line)
                if name or zig_parent(line):
                    while stack and stack[-1][0] >= ind:
                        stack.pop()
                parent = zig_parent(line)
            if not name:
                if lang.name == "Zig" and parent:
                    stack.append((ind, parent))
                continue
            short = name.rsplit(".", 1)[-1]
            if short != target and name != target:
                if short.lower() != target.lower():
                    if lang.name == "Zig" and parent:
                        stack.append((ind, parent))
                    continue
            score = 100 if short == target or name == target else 60
            ctx = set(path_ctx)
            ctx.update(x.lower() for _, x in stack)
            if "." in name:
                ctx.add(name.split(".")[0].lower())
            if lang.name == "C3":
                mod = next((l for l in lines[:40] if l.startswith("module ")), "")
                ctx.update(x.lower() for x in re.findall(r"\w+", mod))
            matched = sum(q in ctx for q in quals)
            score += 50 * matched
            if quals and not matched:
                score -= 80
            score -= rel.count("/") * 2          # prefer shallow, central files
            if "/test" in rel or rel.startswith("test"):
                score -= 30
            owner = stack[-1][1] if stack else (name.split(".")[0] if "." in name else "")
            hits.append((score, rel, i, lines, owner))
            if lang.name == "Zig" and parent:
                stack.append((ind, parent))
    hits.sort(key=lambda h: (-h[0], h[1], h[2]))
    out = []
    for score, rel, i, lines, owner in hits[:n]:
        start, end = doc_start(lines, i, lang.name), decl_end(lines, i, lang.name)
        if end - start <= max_lines:
            body = "\n".join(lines[start:end])
        else:
            members = outline(lines, i + 1, end, lang.name, rel)
            head = "\n".join(lines[start:i + 1])
            body = head + (f"\n    // ... {end - i - 1} lines; public members:\n" + indent_block(members, "    // ")
                           if members else f"\n    // ... {end - i - 1} more lines (see file)")
        fence = "zig" if lang.name == "Zig" else "c3"
        where = f"  (in {owner})" if owner else ""
        out.append(f"### std/{rel}:{i + 1}{where}\n\n```{fence}\n{body.rstrip()}\n```\n")
    return out


def indent_block(text, prefix):
    return "\n".join(prefix + l for l in text.splitlines())


def file_outline(lang, name):
    cand = name.replace("std.", "", 1) if name.startswith("std.") else name
    cand = cand.replace("::", "/")
    options = [cand, cand.replace(".", "/")]
    for o in list(options):
        options += [o + e for e in lang.exts]
    for o in options:
        p = lang.std_dir / o
        if p.is_file():
            break
    else:
        matches = [p for p in iter_std_files(lang) if p.stem.lower() == Path(cand.replace(".", "/")).name.lower()]
        if not matches:
            die(f"no std file matching '{name}' under {lang.std_dir}")
        p = min(matches, key=lambda m: len(m.parts))
    lines = p.read_text(errors="replace").splitlines()
    rel = p.relative_to(lang.std_dir).as_posix()
    top = ""
    if lang.name == "Zig":
        doc = [l.strip()[3:].strip() for l in lines if l.startswith("//!")]
        top = ("\n".join(doc) + "\n\n") if doc else ""
    return f"### std/{rel} (public API outline)\n\n{top}```\n{outline(lines, 0, len(lines), lang.name, rel)}\n```\n"


# ---------------------------------------------------------------- output

def copy_to_clipboard(text):
    for cmd in (["wl-copy"], ["xclip", "-selection", "clipboard"], ["xsel", "-b", "-i"]):
        if shutil.which(cmd[0]):
            subprocess.run(cmd, input=text, text=True)
            return cmd[0]
    return None


def main():
    prog = Path(sys.argv[0]).name
    default = "c3" if "c3" in prog else "zig"
    ap = argparse.ArgumentParser(
        prog=prog,
        description="Search the official docs + std source of your installed Zig/C3 "
                    "and print chunks to paste into a local LLM.",
        epilog=f"examples:\n  {prog} ArrayList           docs + std matches\n"
               f"  {prog} -s Io.Writer.print   std source only\n"
               f"  {prog} -f Io.Writer         outline of a std file's public API\n"
               f"  {prog} -r 'std.Io'          release notes\n"
               f"  {prog} -c for loop          copy result to clipboard",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("query", nargs="*")
    ap.add_argument("--lang", choices=["zig", "c3"], default=default)
    g = ap.add_mutually_exclusive_group()
    g.add_argument("-d", "--docs", action="store_true", help="language docs only")
    g.add_argument("-s", "--std", action="store_true", help="std library source only")
    g.add_argument("-r", "--notes", action="store_true", help="release notes")
    g.add_argument("-f", "--file", metavar="STDFILE", help="outline a std file, e.g. Io.Writer or collections/list")
    g.add_argument("-l", "--list", action="store_true", help="list doc section titles")
    ap.add_argument("-n", type=int, default=3, help="results per source (default 3)")
    ap.add_argument("-m", "--max-chars", type=int, default=16000, help="total output budget (default 16000 ~ 4k tokens)")
    ap.add_argument("--lines", type=int, default=80, help="max lines of a std decl before outlining it")
    ap.add_argument("-c", "--copy", action="store_true", help="copy to clipboard instead of printing")
    a = ap.parse_args()

    lang = Zig() if a.lang == "zig" else C3()
    query = " ".join(a.query)
    label = f"{lang.name} {lang.version}"

    if a.list:
        for s in lang.doc_sections():
            print("  " * (s["level"] - 2 if lang.name == "Zig" else s["level"] - 1) + s["title"])
        return
    if not query and not a.file:
        ap.print_help()
        return

    chunks = []
    if a.file:
        chunks.append(file_outline(lang, a.file))
    elif a.notes:
        if lang.name == "C3":
            if not lang.notes.exists():
                die(f"release notes not found at {lang.notes}")
            chunks += search_c3_notes(lang.notes, query, a.max_chars)
        else:
            chunks += [format_section(s, f"{label} release notes", a.max_chars)
                       for s in search_sections(lang.note_sections(), query, a.n)]
    else:
        if not a.std:
            src = "langref" if lang.name == "Zig" else "manual"
            chunks += [format_section(s, f"{label} {src}", a.max_chars // 2)
                       for s in search_sections(lang.doc_sections(), query, a.n)]
        if not a.docs and " " not in query.strip():
            chunks += search_std(lang, query, a.n, a.lines)

    if not chunks:
        die(f"nothing found for '{query or a.file}' in {label}")

    text, used = [], 0
    for c in chunks:
        if used + len(c) > a.max_chars and text:
            text.append(f"... ({len(chunks) - len(text)} more results cut; raise -m)\n")
            break
        text.append(c)
        used += len(c)
    header = (f"Reference from the official {label} docs/std source. "
              f"Use this instead of memory; older {lang.name} APIs may differ.\n\n")
    result = header + "\n".join(text)

    if a.copy:
        tool = copy_to_clipboard(result)
        if not tool:
            print(result)
            die("no clipboard tool (install wl-clipboard); printed instead")
        print(f"copied {len(result)} chars (~{len(result) // 4} tokens) via {tool}", file=sys.stderr)
    else:
        print(result)
        print(f"-- {len(result)} chars, ~{len(result) // 4} tokens", file=sys.stderr)


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        pass
