-- expect-error: watt_is_number
-- 数値の属性に文字列が入っている
INSERT INTO products (kind, name, price, attrs)
VALUES ('appliance', 'appliance-x', 1000,
        '{"watt": "1200W", "voltage": 100, "warranty_months": 12}');
