"""Extract vocabulary entries from the My Word Book PDF (pdftotext -raw output)."""
import json, re, sys
raw = open(sys.argv[1], encoding='utf-8').read().split('\n')
skip = re.compile(r'^(My Word Book( • page \d+)?|Grade [12] Words)$')
entries, grade, expect, cur, buf = [], 0, 1, None, []
def flush():
    global cur, buf
    if cur is None: return
    text = ' '.join(buf).strip()
    m = re.match(r'^(.*?)\s*“(.*)”\s*$', text)
    if not m: raise SystemExit(f'Could not split entry {cur}: {text!r}')
    cur['meaning'], cur['example'] = m.group(1).strip(), m.group(2).strip()
    entries.append(cur); cur, buf = None, []
for line in raw:
    s = line.strip()
    if s == 'Grade 1 Words': flush(); grade, expect = 1, 1; continue
    if s == 'Grade 2 Words': flush(); grade, expect = 2, 1; continue
    if not grade or not s or skip.match(s): continue
    m = re.match(r'^(\d+) (.+)$', s)
    if m and int(m.group(1)) == expect:
        flush(); cur = {'grade': grade, 'order': expect, 'word': m.group(2).strip()}; expect += 1; continue
    if cur is not None: buf.append(s)
flush()
out = []
for e in entries:
    out.append({'id': f"g{e['grade']}_{e['order']:04d}", 'grade': e['grade'], 'order': e['order'],
                'word': e['word'], 'meaning': e['meaning'], 'example': e['example']})
json.dump(out, open(sys.argv[2], 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
print(len(out), sum(1 for e in out if e['grade']==1), sum(1 for e in out if e['grade']==2))
