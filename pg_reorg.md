[TOC]

#### 测试1：实例不存在的情况

```
[root@l-pgdba.vc.beta.cn0 ``/export/qpg_reorg/bin``]``# sudo -iu postgres /export/qpg_reorg/bin/pg_reorg -p 7433 -d b2c_product -U postgres``ERROR: could not connect to database with ``"dbname=b2c_product port=7433 user=postgres "``: could not connect to server: No such ``file` `or directory``  ``Is the server running locally and accepting``  ``connections on Unix domain socket ``"/tmp/.s.PGSQL.7433"``?``[root@l-pgdba.vc.beta.cn0 ``/export/qpg_reorg/bin``]``#
```



#### 测试2：database 不存在的情况

```
[root@l-pgdba.vc.beta.cn0 ``/export/qpg_reorg/bin``]``# sudo -iu postgres /export/qpg_reorg/bin/pg_reorg -p 7432 -d b2c_product_bad -U postgres``ERROR: could not connect to database with ``"dbname=b2c_product_bad port=7432 user=postgres "``: FATAL: database ``"b2c_product_bad"` `does not exist``[root@l-pgdba.vc.beta.cn0 ``/export/qpg_reorg/bin``]``#
```



#### 测试3：用户不存在的情况

```
[root@l-pgdba.vc.beta.cn0 ``/export/qpg_reorg/bin``]``# sudo -iu postgres /export/qpg_reorg/bin/pg_reorg -p 7432 -d b2c_product -U postgres_bad``ERROR: could not connect to database with ``"dbname=b2c_product port=7432 user=postgres_bad "``: FATAL: role ``"postgres_bad"` `does not exist``[root@l-pgdba.vc.beta.cn0 ``/export/qpg_reorg/bin``]``#
```



#### 测试4：表不存在的情况

```
[root@l-pgdba.vc.beta.cn0 ``/export/qpg_reorg/bin``]``# sudo -iu postgres /export/qpg_reorg/bin/pg_reorg -p 7432 -d b2c_product -U postgres -t not_found -o id``ERROR: pg_reorg is not installed``[root@l-pgdba.vc.beta.cn0 ``/export/qpg_reorg/bin``]``#
```



#### 测试5：列不存在的情况

```
[root@l-pgdba.vc.beta.cn0 ``/export/qpg_reorg/bin``]``# sudo -iu postgres /export/qpg_reorg/bin/pg_reorg -p 7432 -d b2c_product -U postgres -t b2c_flight_detail -o not_found``INFO: ---- reorganize one table with 9 steps. ----``INFO: target table name  : b2c_flight_detail``INFO: ---- STEP1. setup ----``INFO: This needs EXCLUSIVE LOCK against the target table.``INFO: ---- STEP2. copy tuples into temp table----``ERROR: query failed: ERROR: column ``"not_found"` `does not exist``LINE 1: ...,operate_time FROM ONLY b2c_flight_detail ORDER BY not_found``                               ``^``DETAIL: query was: CREATE TABLE reorg.table_25928 WITH (oids=``false``) TABLESPACE pg_default AS SELECT ``id``,flight_id,flight_type,``seq``,dep_airport,dep_city,arr_airport,arr_city,dep_time,arr_time,plane_type,flight_no,arr_time_flag,stop_flag,stop_comment,operator,operate_time FROM ONLY b2c_flight_detail ORDER BY not_found``[root@l-pgdba.vc.beta.cn0 ``/export/qpg_reorg/bin``]``#
```



#### 测试6：指定一个由 1 列构成的唯一索引

```
b2c_product=# \d b2c_answer``                   ``Table` `"public.b2c_answer"``  ``Column`  `|      Type       |            Modifiers            ``--------------+-----------------------------+---------------------------------------------------------`` ``id      | ``integer`           `| ``not` `null` `default` `nextval(``'b2c_answer_id_seq'``::regclass)`` ``supplier_id | ``integer`           `| ``not` `null`` ``question_id | ``integer`           `| ``not` `null`` ``answer    | text            | `` ``answer_user | ``character` `varying``(64)    | `` ``answer_time | ``timestamp` `without ``time` `zone | ``default` `(timeofday())::``timestamp` `without ``time` `zone`` ``operator   | ``character` `varying``(255)   | `` ``operate_time | ``timestamp` `without ``time` `zone | ``default` `(timeofday())::``timestamp` `without ``time` `zone`` ``is_deleted  | boolean           | ``Indexes:``  ``"b2c_answer_pkey"` `PRIMARY` `KEY``, btree (id)``  ``"b2c_answer_question_id_idx"` `btree (question_id)``Foreign``-``key` `constraints:``  ``"b2c_answer_question_id_fkey"` `FOREIGN` `KEY` `(question_id) ``REFERENCES` `b2c_question(id) ``ON` `UPDATE` `CASCADE` `ON` `DELETE` `CASCADE``  ``"b2c_answer_supplier_id_fkey"` `FOREIGN` `KEY` `(supplier_id) ``REFERENCES` `b2c_supplier_info(id) ``ON` `UPDATE` `CASCADE
```



```
[root@l-pgdba.vc.beta.cn0 ``/export/qpg_reorg/bin``]``# sudo -iu postgres /export/qpg_reorg/bin/pg_reorg -p 7432 -d b2c_product -U postgres -t b2c_answer -o id``INFO: ---- reorganize one table with 9 steps. ----``INFO: target table name  : b2c_answer``INFO: ---- STEP1. setup ----``INFO: This needs EXCLUSIVE LOCK against the target table.``INFO: ---- STEP2. copy tuples into temp table----``INFO: ---- STEP3. create indexes ----``INFO: ---- STEP4. apply logs ----``INFO: ---- STEP5. analyze the new table ----``INFO: ``test` `analyze ANALYZE reorg.table_25605``INFO: ---- STEP6. apply logs ----``INFO: ---- STEP7. swap tables ----``INFO: This needs EXCLUSIVE LOCK against the target table.``INFO: ---- STEP8. drop old table----``INFO: ---- STEP9. analyze ----
```





#### 测试7：指定一个由多列构成的唯一索引

```
b2c_product=# \d b2c_flight_detail``                    ``Table` `"public.b2c_flight_detail"``  ``Column`   `|      Type       |              Modifiers              ``---------------+-----------------------------+----------------------------------------------------------------`` ``id      | ``integer`           `| ``not` `null` `default` `nextval(``'b2c_flight_detail_id_seq'``::regclass)`` ``flight_id   | ``integer`           `| ``not` `null`` ``flight_type  | ``integer`           `| ``not` `null` `default` `0`` ``seq      | ``integer`           `| ``not` `null` `default` `1`` ``dep_airport  | ``character` `varying``(64)    | ``not` `null`` ``dep_city   | ``character` `varying``(64)    | ``not` `null`` ``arr_airport  | ``character` `varying``(64)    | ``not` `null`` ``arr_city   | ``character` `varying``(64)    | ``not` `null`` ``dep_time   | ``character` `varying``(5)    | ``not` `null`` ``arr_time   | ``character` `varying``(5)    | ``not` `null`` ``plane_type  | ``character` `varying``(32)    | `` ``flight_no   | ``character` `varying``(16)    | ``not` `null`` ``arr_time_flag | ``smallint`          `| ``not` `null` `default` `0`` ``stop_flag   | ``smallint`          `| ``not` `null` `default` `0`` ``stop_comment | ``character` `varying``(256)   | `` ``operator   | ``character` `varying``(128)   | ``not` `null`` ``operate_time | ``timestamp` `without ``time` `zone | ``not` `null` `default` `now()``Indexes:``  ``"b2c_flight_detail_pkey"` `PRIMARY` `KEY``, btree (id)``  ``"b2c_flight_detail_flight_id_flight_type_seq_idx"` `UNIQUE``, btree (flight_id, flight_type, seq)``Foreign``-``key` `constraints:``  ``"b2c_flight_detail_flight_id_fkey"` `FOREIGN` `KEY` `(flight_id) ``REFERENCES` `b2c_flight_warehouse(id)
```



```
[root@l-pgdba.vc.beta.cn0 ``/export/qpg_reorg/bin``]``# sudo -iu postgres /export/qpg_reorg/bin/pg_reorg -p 7432 -d b2c_product -U postgres -t b2c_flight_detail -o flight_id, flight_type, seq``ERROR: too many arguments``[root@l-pgdba.vc.beta.cn0 ``/export/qpg_reorg/bin``]``# sudo -iu postgres /export/qpg_reorg/bin/pg_reorg -p 7432 -d b2c_product -U postgres -t b2c_flight_detail -o flight_id,flight_type,seq``INFO: ---- reorganize one table with 9 steps. ----``INFO: target table name  : b2c_flight_detail``INFO: ---- STEP1. setup ----``INFO: This needs EXCLUSIVE LOCK against the target table.``INFO: ---- STEP2. copy tuples into temp table----``INFO: ---- STEP3. create indexes ----``INFO: ---- STEP4. apply logs ----``INFO: ---- STEP5. analyze the new table ----``INFO: ``test` `analyze ANALYZE reorg.table_25928``INFO: ---- STEP6. apply logs ----``INFO: ---- STEP7. swap tables ----``INFO: This needs EXCLUSIVE LOCK against the target table.``INFO: ---- STEP8. drop old table----``INFO: ---- STEP9. analyze ----``[root@l-pgdba.vc.beta.cn0 ``/export/qpg_reorg/bin``]``#
```