-- 元データを作る。各案の load.sql より先に実行する。
-- SIZE=S はスレッド 1 万ノード、M は 100 万ノード（カテゴリは S 1,257 / M 39,921）
--
-- 深さ 20 の木を「どの段でも分岐 2」で作ろうとすると、100 万ノードに達した時点で
-- 深さが 14 にしかならない（2^14 > 100 万）。深さを伸ばすには、序盤を広くして早く
-- 幅を稼ぎ、途中から枝を絞って 1 本道で伸ばす必要がある。この作り方そのものが
-- 「現実のスレッドは深いノードほど数が少ない」ことの裏返しになっている。
--
-- 段ごとに INSERT する（再帰 CTE では子の id を採番できないため）。親は必ず子より
-- 小さい id を持つので、各案はこの順に写せば外部キーの順序で困らない。
SELECT CASE :'size' WHEN 'S' THEN 10000 WHEN 'M' THEN 1000000 END AS n_thread \gset
SELECT CASE :'size' WHEN 'S' THEN '{8,6,5,4}' WHEN 'M' THEN '{20,15,12,10}' END AS fan \gset
SELECT :n_thread AS thread_nodes_to_load;  -- S・M 以外なら、ここで構文エラーになって止まる

\timing on
TRUNCATE ch04_r.src_cat;
TRUNCATE ch04_r.src_thread;
SELECT setseed(0.42);

-- psql の変数は $$ … $$ の中では展開されないので、手続きに渡す値はここで一時表に置く
DROP TABLE IF EXISTS ch04_r.gen_params;
CREATE TABLE ch04_r.gen_params AS
SELECT :'fan'::int[] AS fan, :n_thread::bigint AS n_thread;

-- ── カテゴリ型（深さ 5・分岐が広い・移動がある想定）
DO $$
DECLARE
  fan int[] := (SELECT p.fan FROM ch04_r.gen_params p);
  d   int;
BEGIN
  INSERT INTO ch04_r.src_cat (id, parent_id, name, depth, pos)
  VALUES (1, NULL, 'cat-1-1', 1, 1);

  FOR d IN 1..4 LOOP
    INSERT INTO ch04_r.src_cat (id, parent_id, name, depth, pos)
    SELECT (SELECT max(id) FROM ch04_r.src_cat)
             + row_number() OVER (ORDER BY p.id, g.i),
           p.id,
           'cat-' || (d + 1) || '-' || g.i,
           d + 1,
           g.i
    FROM ch04_r.src_cat p
         CROSS JOIN LATERAL generate_series(1, fan[d]) AS g(i)
    WHERE p.depth = d;
  END LOOP;
END $$;

-- ── スレッド型（深さ 20・追記が中心）
--
-- 必ず深さ 20 まで作る。序盤を広げて幅を稼ぎ、以降は枝の一部だけを伸ばして先細りにする。
-- 深さは件数に依存せず常に 20 になる（S と M で木の形が変わらないので、結論を比べられる）。
--   深さ 1〜wide     分岐 fan で広げる
--   深さ wide より下  各段の先頭 keep 件だけが子を 1 つ持つ。keep を段ごとに 3 割ずつ減らす
-- 3 つの値は、自然に出来る木が目標の件数をわずかに下回るように選んである
--   S: wide=5 fan=6  keep0=4,096   ->   9,946 ノード（残り 54 を葉で足す）
--   M: wide=7 fan=9  keep0=120,000 -> 993,987 ノード（残り 6,013 を葉で足す）
-- 足りないぶんは、深い段のノードへ順繰りに葉を配る（1 つの親に集中させない）。
DO $$
DECLARE
  big    bool := (SELECT p.n_thread FROM ch04_r.gen_params p) >= 1000000;
  target bigint := (SELECT p.n_thread FROM ch04_r.gen_params p);
  wide   int  := CASE WHEN big THEN 7 ELSE 5 END;
  fan    int  := CASE WHEN big THEN 9 ELSE 6 END;
  keep0  int  := CASE WHEN big THEN 120000 ELSE 4096 END;
  d      int := 1;
  total  bigint := 1;
  added  bigint;
  keep   int;
  pad    bigint;
BEGIN
  INSERT INTO ch04_r.src_thread (id, parent_id, body, depth, pos)
  VALUES (1, NULL, 'comment 1', 1, 1);

  WHILE d < 20 LOOP
    -- 広げ終わったら、子を持つ親の数を段ごとに 3 割ずつ減らす（返信は深くなるほど続かない）
    keep := GREATEST(1, (power(0.7, GREATEST(0, d - wide)) * keep0)::int);

    INSERT INTO ch04_r.src_thread (id, parent_id, body, depth, pos)
    SELECT total + row_number() OVER (ORDER BY p.id, g.i),
           p.id,
           'comment body ' || p.id || '-' || g.i,
           d + 1,
           g.i
    FROM (
      SELECT x.id, x.depth
      FROM ch04_r.src_thread x
      WHERE x.depth = d
      ORDER BY x.id
      LIMIT CASE WHEN d < wide THEN NULL ELSE keep END
    ) p
         CROSS JOIN LATERAL
           generate_series(1, CASE WHEN d < wide THEN fan ELSE 1 END) AS g(i);

    GET DIAGNOSTICS added = ROW_COUNT;
    EXIT WHEN added = 0;
    total := total + added;
    d := d + 1;
  END LOOP;

  -- 件数を目標に寄せる。深さ 8 以上のノードへ順繰りに配るので、1 つの親に葉が集中しない
  pad := target - total;
  IF pad > 0 THEN
    CREATE TEMP TABLE pad_parents ON COMMIT DROP AS
    SELECT row_number() OVER (ORDER BY x.id) - 1 AS k, x.id, x.depth
    FROM ch04_r.src_thread x
    WHERE x.depth BETWEEN 8 AND 18;

    INSERT INTO ch04_r.src_thread (id, parent_id, body, depth, pos)
    SELECT total + g.i,
           p.id,
           'comment filler ' || g.i,
           p.depth + 1,
           ((g.i - 1) / (SELECT count(*) FROM pad_parents))::int + 1
    FROM generate_series(1, pad::int) AS g(i)
    JOIN pad_parents p
      ON p.k = (g.i - 1) % (SELECT count(*) FROM pad_parents);
  END IF;
END $$;

DROP TABLE ch04_r.gen_params;

-- 統計が無いと、各案の投入で計画が変わって桁違いに遅くなる（第3章 §0 の事故）
ANALYZE ch04_r.src_cat;
ANALYZE ch04_r.src_thread;
