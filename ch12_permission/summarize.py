#!/usr/bin/env python3
"""results/ のログから、中央値と幅（(最大-最小)/中央値）を求める。

  python3 ch12_permission/summarize.py ch12_permission/results S

🔴 数値を自分で計算しない。ログに現れた `Time: N ms` を読んで中央値と幅を出すだけである。
   ログを取り直したら、これも流し直す。

🔴 「5 回」の区間は `\\echo` の見出し（=== ... 5 回 ... ===）で区切られる。
   見出しが変わったら、この抽出も変える。
"""
import re
import statistics
import sys
from pathlib import Path

results = Path(sys.argv[1])
size = sys.argv[2] if len(sys.argv) > 2 else 'S'

TIME = re.compile(r'^Time: ([\d.]+) ms')
HEAD = re.compile(r'^(?:=== |--- )(.+?)(?: ===| ---)\s*$')
EXEC = re.compile(r'Execution Time: ([\d.]+) ms')


RUNSQL = re.compile(r'^(?:-- )?run-as: (\w+)')
FILEHINT = re.compile(r'^-- (?:案[A-C]|深さ)')


def sections(path):
    """見出しごとに、その下に出た Time: の一覧を返す。

    🔴 1 つの results ファイルに複数の SQL ファイルの出力が append されるので、
       同じ見出し（「利用者7 素の実行 5 回」など）が何度も出る。
       どの SQL の区間かを見分けるため、直前に出た「書き方」の手がかりを拾って付ける。
    """
    out, hint = [], ''
    if not path.exists():
        return out
    for line in path.read_text(encoding='utf-8', errors='replace').split('\n'):
        # 各 SQL ファイルの冒頭の説明から、どの書き方かを拾う
        if '書き方(1)' in line or '関数を WHERE に置く' in line:
            hint = '[案A 関数]'
        elif '書き方(2)' in line or '集合として作り、結合' in line:
            hint = '[案A 集合(再帰CTE)]'
        elif '書き方(3)' in line or 'ltree の経路' in line:
            hint = '[案A ltree]'
        m = HEAD.match(line)
        if m:
            out.append((f'{hint} {m.group(1)}'.strip(), []))
            continue
        m = TIME.match(line)
        if m and out:
            out[-1][1].append(float(m.group(1)))
    return out


def report(label, path, want='5 回', prefix=''):
    secs = sections(path)
    hit = False
    for head, times in secs:
        if want not in head:
            continue
        # psql は \echo 自身の Time: も出すので、ごく短いものは落とす
        vals = [t for t in times if t >= 0.05]
        if len(vals) < 3:
            continue
        # 🔴 見出しの後に「5 回」以外の文（count(*) など）が続くことがある。
        #    その Time: を混ぜると幅が 2358% のような値になる（実際に出た）。
        #    5 回と書いてある区間は先頭 5 件だけを使う。
        m = re.search(r'(\d+) 回', head)
        if m:
            vals = vals[:int(m.group(1))]
        hit = True
        med = statistics.median(vals)
        spread = (max(vals) - min(vals)) / med * 100
        # 🔴 見出しが章のどの節のものか分かるように接頭辞を付ける。
        #    行レベルセキュリティの節は見出しが「利用者7 素の実行」で、
        #    案A・案B・案C の節と同じ文字列になる。接頭辞が無いと
        #    図の JSON などから 1 件に絞れない（sync-chart-values.py が弾く）。
        tag = prefix + ' ' if prefix else ''
        print(f'  {tag}{head}')
        print(f'    n={len(vals)}  中央値 {med:.3f} ms  '
              f'幅 {spread:.1f}%  値 {[round(v, 3) for v in vals]}')
    if not hit:
        print(f'  （{path.name} に「{want}」の区間が見つからない）')
    return hit


print(f'# 第12章 測定のまとめ（SIZE={size}）')
print('#')
print('# 🔴 幅 (最大-最小)/中央値 より小さい差は主張しない')
print('#    （docs/measurement-rules.yml の claims）')
print()

# 節ごとの接頭辞。見出しが他の節と同じ文字列になる節にだけ付ける
PREFIX = {'■ 行レベルセキュリティのポリシー': '[ポリシー]'}

for label, fn in [
    ('■ 案A の 3 つの書き方（関数 / 集合 / ltree）', f'func_vs_set_{size}.txt'),
    ('■ 案B の一覧', f'read_b_{size}.txt'),
    ('■ 行レベルセキュリティのポリシー', f'rls_{size}.txt'),
    ('■ 案C の読み取り', f'read_c_{size}.txt'),
    ('■ 階層の深さ', f'depth_{size}.txt'),
]:
    print(label)
    report(label, results / fn, prefix=PREFIX.get(label, ''))
    print()

print('■ EXPLAIN (ANALYZE) の Execution Time（3 回の中央値）')
for fn in sorted(results.glob(f'*_{size}.txt')):
    txt = fn.read_text(encoding='utf-8', errors='replace')
    vals = [float(m) for m in EXEC.findall(txt)]
    if vals:
        print(f'  {fn.name}: n={len(vals)} 中央値 {statistics.median(vals):.3f} ms '
              f'（最小 {min(vals):.3f} / 最大 {max(vals):.3f}）')
