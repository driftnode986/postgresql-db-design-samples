-- 案A が元データと同じ中身であることを検査する。全行の先頭列が 0 になる。
--
-- 🔴 元データが空でないことも同時に見る。空どうしを比べると差が 0 になり、
--    「一致した」と読み誤る。
SELECT
  (SELECT count(*) FROM (
     (SELECT tenant_id, id, customer_id, title, amount, created_at FROM ch13_a.deals
      EXCEPT
      SELECT tenant_id, id, customer_id, title, amount, created_at FROM ch13_r.src_deal)
     UNION ALL
     (SELECT tenant_id, id, customer_id, title, amount, created_at FROM ch13_r.src_deal
      EXCEPT
      SELECT tenant_id, id, customer_id, title, amount, created_at FROM ch13_a.deals)
   ) d) AS deal_diff_must_be_zero,
  (SELECT count(*) FROM (
     (SELECT tenant_id, id, email, name FROM ch13_a.customers
      EXCEPT
      SELECT tenant_id, id, email, name FROM ch13_r.src_customer)
     UNION ALL
     (SELECT tenant_id, id, email, name FROM ch13_r.src_customer
      EXCEPT
      SELECT tenant_id, id, email, name FROM ch13_a.customers)
   ) c) AS customer_diff_must_be_zero,
  (SELECT CASE WHEN count(*) = 0 THEN 1 ELSE 0 END FROM ch13_r.src_deal)
    AS source_empty_must_be_zero,
  (SELECT count(*) FROM ch13_a.deals) AS deals;
