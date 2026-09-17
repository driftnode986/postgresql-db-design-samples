-- 中くらいの頻度の値（色が yellow でサイズが XL）の衣料を、新しい順に 20 件（採取した案の問い合わせのまま）
EXPLAIN (ANALYZE)
SELECT p.id, p.name, p.price, p.created_at
FROM products AS p
WHERE p.kind = 'apparel'
  AND EXISTS (
    SELECT 1 FROM product_attributes AS pa
    JOIN attribute_defs AS ad ON ad.id = pa.attribute_def_id
    WHERE pa.product_id = p.id AND ad.code = 'color' AND pa.value_text = 'yellow')
  AND EXISTS (
    SELECT 1 FROM product_attributes AS pa
    JOIN attribute_defs AS ad ON ad.id = pa.attribute_def_id
    WHERE pa.product_id = p.id AND ad.code = 'size' AND pa.value_text = 'XL')
ORDER BY p.created_at DESC
LIMIT 20;
