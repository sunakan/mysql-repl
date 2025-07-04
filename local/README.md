## スニペット

```sql
select table_name, row_format, table_collation, table_type from information_schema.tables where table_schema = 'employees';

-- 様子見
select
  table_name as "テーブル名"
  , row_format as "ROW_FORMAT"
  , table_rows as "行数"
  , avg_row_length as "1行の大きさ平均(bytes)"
  , data_length + index_length as "総容量(bytes)"
  , case
    when (data_length+index_length) > (1024*1024*1024) then concat(round((data_length+index_length)/(1024*1024*1024), 2), " GB")
    when (data_length+index_length) > (1024*1024) then concat(round((data_length+index_length)/(1024*1024), 2), " MB")
    when (data_length+index_length) > (1024) then concat(round((data_length+index_length)/(1024), 2), " KB")
    else concat((data_length+index_length), " B")
  end as "総容量"
  , data_length as "データ量(bytes)"
  , case
    when (data_length) > (1024*1024*1024) then concat(round((data_length)/(1024*1024*1024), 2), " GB")
    when (data_length) > (1024*1024) then concat(round((data_length)/(1024*1024), 2), " MB")
    when (data_length) > (1024) then concat(round((data_length)/(1024), 2), " KB")
    else concat((data_length), " B")
  end as "データ量"
  , index_length as "インデックス容量(bytes)"
  , case
    when (index_length) > (1024*1024*1024) then concat(round((index_length)/(1024*1024*1024), 2), " GB")
    when (index_length) > (1024*1024) then concat(round((index_length)/(1024*1024), 2), " MB")
    when (index_length) > (1024) then concat(round((index_length)/(1024), 2), " KB")
    else concat((index_length), " B")
  end as "インデックス容量"
  , table_collation        as "照合順序"
from information_schema.tables
where table_schema = 'airportdb' and table_type != 'VIEW'
order by table_name
;
-- 1行版
mysql -B -uroot -e "select table_name as \"テーブル名\", row_format as \"ROW_FORMAT\", table_rows as \"行数\", avg_row_length as \"1行の大きさ平均(bytes)\", data_length + index_length as \"総容量(bytes)\", case when (data_length+index_length) > (1024*1024*1024) then concat(round((data_length+index_length)/(1024*1024*1024), 2), \" GB\") when (data_length+index_length) > (1024*1024) then concat(round((data_length+index_length)/(1024*1024), 2), \" MB\") when (data_length+index_length) > (1024) then concat(round((data_length+index_length)/(1024), 2), \" KB\") else concat((data_length+index_length), \" B\") end as \"総容量\", data_length as \"データ量(bytes)\", case when (data_length) > (1024*1024*1024) then concat(round((data_length)/(1024*1024*1024), 2), \" GB\") when (data_length) > (1024*1024) then concat(round((data_length)/(1024*1024), 2), \" MB\") when (data_length) > (1024) then concat(round((data_length)/(1024), 2), \" KB\") else concat((data_length), \" B\") end as \"データ量\", index_length as \"インデックス容量(bytes)\", case when (index_length) > (1024*1024*1024) then concat(round((index_length)/(1024*1024*1024), 2), \" GB\") when (index_length) > (1024*1024) then concat(round((index_length)/(1024*1024), 2), \" MB\") when (index_length) > (1024) then concat(round((index_length)/(1024), 2), \" KB\") else concat((index_length), \" B\") end as \"インデックス容量\", table_collation as \"照合順序\" from information_schema.tables where table_schema = 'airportdb' and table_type != 'VIEW' order by table_name;"  | tr '\t' ','



-- DYNAMICへ

mysql -uroot -e 'SELECT NOW() + INTERVAL 9 HOUR as 時間; ALTER TABLE airportdb.booking ROW_FORMAT=DYNAMIC, ALGORITHM=INPLACE, LOCK=NONE; SELECT NOW() + INTERVAL 9 HOUR as 時間;'

-- indexを貼る/落とす
ALTER TABLE hoge ADD INDEX idx_created_at (created_at);
ALTER TABLE hoge DROP INDEX idx_created_at;

-- カラムの追加
ALTER TABLE hoge ADD COLUMN num BIGINT;
ALTER TABLE hoge DROP COLUMN num;
```
