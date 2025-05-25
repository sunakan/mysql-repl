-- reset
use hoge;
drop table if exists hoge;
-- ここから

-- datadogで観察
CREATE TABLE hoge (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO hoge VALUES (),(),();
DELETE FROM hoge WHERE id = (SELECT max_id FROM (SELECT MAX(id) AS max_id FROM hoge) AS tmp);
INSERT INTO hoge VALUES (),(),();
DELETE FROM hoge WHERE id = (SELECT max_id FROM (SELECT MAX(id) AS max_id FROM hoge) AS tmp);
