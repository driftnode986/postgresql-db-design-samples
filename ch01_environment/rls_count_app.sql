-- テナント 1 として数える。テナント 1 の行は 2 行
SET app.tenant_id = '1';
SELECT current_user, count(*) FROM docs;
