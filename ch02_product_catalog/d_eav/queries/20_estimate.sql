-- 見積もりの行数（rows=）と実際の行数（actual rows=）を比べる。LIMIT を付けずに、条件に合う商品を全部取る
EXPLAIN (ANALYZE)
SELECT p.id
FROM products AS p
WHERE p.kind = 'apparel'
  AND EXISTS (
    SELECT 1 FROM product_attributes AS pa
    JOIN attribute_defs AS ad ON ad.id = pa.attribute_def_id
    WHERE pa.product_id = p.id AND ad.code = 'color' AND pa.value_text = 'black')
  AND EXISTS (
    SELECT 1 FROM product_attributes AS pa
    JOIN attribute_defs AS ad ON ad.id = pa.attribute_def_id
    WHERE pa.product_id = p.id AND ad.code = 'size' AND pa.value_text = 'M');
EXPLAIN (ANALYZE)
SELECT p.id
FROM products AS p
WHERE p.kind = 'apparel'
  AND EXISTS (
    SELECT 1 FROM product_attributes AS pa
    JOIN attribute_defs AS ad ON ad.id = pa.attribute_def_id
    WHERE pa.product_id = p.id AND ad.code = 'color' AND pa.value_text = 'yellow')
  AND EXISTS (
    SELECT 1 FROM product_attributes AS pa
    JOIN attribute_defs AS ad ON ad.id = pa.attribute_def_id
    WHERE pa.product_id = p.id AND ad.code = 'size' AND pa.value_text = 'XL');
EXPLAIN (ANALYZE)
SELECT p.id
FROM products AS p
WHERE p.kind = 'apparel'
  AND EXISTS (
    SELECT 1 FROM product_attributes AS pa
    JOIN attribute_defs AS ad ON ad.id = pa.attribute_def_id
    WHERE pa.product_id = p.id AND ad.code = 'color' AND pa.value_text = 'teal')
  AND EXISTS (
    SELECT 1 FROM product_attributes AS pa
    JOIN attribute_defs AS ad ON ad.id = pa.attribute_def_id
    WHERE pa.product_id = p.id AND ad.code = 'size' AND pa.value_text = 'XXS');
