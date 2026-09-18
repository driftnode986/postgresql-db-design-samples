-- expect-error: apparel_required
-- 衣料なのに size が無い
INSERT INTO products (kind, name, price, attrs)
VALUES ('apparel', 'apparel-x', 1000,
        '{"color": "black", "material": "cotton"}');
