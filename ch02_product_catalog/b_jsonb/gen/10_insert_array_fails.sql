-- expect-error: attrs_is_object
-- attrs に配列を入れようとすると、CHECK (attrs IS JSON OBJECT) が断る
INSERT INTO products (kind, name, price, attrs)
VALUES ('book', 'book-x', 1000, '[1, 2]');
