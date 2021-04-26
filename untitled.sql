SELECT
    b.*
FROM
    (
        SELECT
            t.*, @rownum := @rownum + 1 AS rownum
        FROM
            (SELECT @rownum := 0) r,
            (
                SELECT
                    *
                FROM
                    Wechat_user_score
                WHERE
                    kcdm = 08100012 
                ORDER BY
                    cj + '0' DESC
            ) AS t
   
    ) AS b 
WHERE b.school_id = 3160111095   

select count(1) from Wechat_user_score where kcdm = 08100012


-- test 1
SELECT
    count(*)
FROM
    Wechat_user_score
WHERE
    kcdm = 08100012;


-- test 2
select 
    count(*)
from
    (
    SELECT
        t.*, @rownum := @rownum + 1 AS rownum
    FROM
        (SELECT @rownum := 0) r,
        (
            SELECT
                *
            FROM
                Wechat_user_score
            WHERE
                kcdm = 08100012 
            ORDER BY
                cj + '0' DESC
        ) AS t
    ) foo;


-- test 3
SELECT
  b.*, d.*
 FROM
  (
   SELECT
    t.*, @rownum := @rownum + 1 AS rownum
   FROM
    (SELECT @rownum := 0) r,
    (
     SELECT
      *
     FROM
      Wechat_user_score
     WHERE
      kcdm = 08100012
     ORDER BY
      cj + '0' DESC
    ) AS t
  ) AS b
 JOIN (
  SELECT
   count(1)
  FROM
   Wechat_user_score
  WHERE
   kcdm = 08100012
 ) AS d
 WHERE
  b.school_id = 3160111095




　#### 迁移 ####
--- Todo Details ---
Target: l-ologpgvip[1-2].ops.cn5.qunar.com:5432
Target details:


Actions:
1. 发变更
  <1.1> 起草变更内容
  <1.2> TL Review 
  <1.3> 发变更
2. 修改l-ologpgvip2.ops.cn5.qunar.com:5432的配置
  <2.1> archive_command
  <2.2> 
3. 转移备份任务
  <3.1> 检查l-ologpgvip2.ops.cn5.qunar.com:5432备份任务运行情况
  <3.2> 注释crontab任务
  <3.3> 任务部署到l-ologpgvip2.ops.cn5.qunar.com
  <3.4> 转移 realtime 目录

4. stop DB instance: l-ologpgvip2.ops.cn5.qunar.com:5432
5. move vip "l-ologpgvip1.ops.cn5.qunar.com" 
   from l-ologpg1.ops.cn5.qunar.com
   to l-ologpg2.ops.cn5.qunar.com
6. promote l-ologpg2.ops.cn5.qunar.com:5432
   <6.1> promoting
   <6.2> 提醒应用同学检查，无误后继续后续操作
7. edit l-ologpg1.ops.cn5.qunar.com:5432's recovery.conf
8. start DB insstance: l-ologpg1.ops.cn5.qunar.com:5432 as a slave
9. all check


Pre Actions:
<1> write a draft of change
  <1.1> Editing
  <1.2> TL Review
  <1.3> Pulishing
<2> edit l-ologpg2.ops.cn5:5432's postgres.conf
  <2.1> archive_command
  <2.2>  
<3> edit  l-ologpg1.ops.cn5:5432's postgres.conf and recovery.conf
  <3.1> postgres.conf
    - full_page_writes => on(reload生效，可提前操作)
    - autovacuum => off(reload生效，可提前操作)
    - default_transaction_read_only => on
  <3.2> recovery.conf
    - 复制l-ologpg2.ops.cn5:5432's recovery.conf
    - 修改 primary_conninfo 中的链接地址和application_name


Actual Actions:
# 起草变更内容：https://wiki.corp.qunar.com/confluence/pages/viewpage.action?pageId=334732522
# TL Review 变更
# Publishing 变更
# [主库]l-ologpg1.ops.cn5:5432
    = postgres.conf
      - 备份一份(已备份)
      - full_page_writes => on(已修改，已reload)
      - wal_log_hits => on(就是on，无需操作)
      - autovacuum => off(已修改，已reload)
      - default_transaction_read_only => on(目前是注释状态，走默认值off，待关闭前改成on并打开注释，重启时生效)
      - archive_command => /bin/true(未修改，等待关闭时在修改)
    = recovery.conf
      - 已复制l-ologpg2.ops.cn5:5432's recovery.conf
      - 已修改 primary_conninfo 中的链接地址和application_name
      (等待重启时启用)
    = 备份任务
      - 部署(已部署)
# [从库]l-ologpg2.ops.cn5:5432
    = postgres.conf
      - 备份一份(已备份)
      - full_page_writes => on(已修改，已reload)
      - wal_log_hits => on(就是on，无需操作)
      - autovacuum => on(就是on，无需操作)
      - default_transaction_read_only => off(目前是注释状态，走默认值off，无需操作)
      - archive_command => '一串正确的值' (已修改，等待promote时生效)
    = 备份任务
      - 停掉(已注释)
      - basebackup搬运(已复制)
      - realtime搬运(todo...)

todo:
  1> 检查 pg_hba.conf



Next Actions:
1  -> l-ologpg1.ops.cn5:5432
1     - postgresql.conf
1       - synchronous_standby_names => '*'(已修改，已reload)
1 --> 事先10分钟，在qtalk群中通知相关人员
1  -> 关闭zabbix报警:  l-ologpg[1-2].ops.cn5
1 --> 到点通知开始操作，等待亮亮停掉应用
1  -> check l-ologpg1.ops.cn5:5432 是否有来自应用的连接
1  -> l-ologpg1.ops.cn5:5432
1     - postgresql.conf
1       - default_transaction_read_only 改为on, reload 使其生效
1  -> stop: l-ologpg1.ops.cn5:5432
1  -> promote: l-ologpg2.ops.cn5:5432
1  -> l-ologpgvip1.ops.cn5 从 l-ologpg1.ops.cn5 到 l-ologpg2.ops.cn5
1  -> 通知操作完毕，等待应用方反馈无误
1  -> 修改l-ologpg1.ops.cn5:5432
1     - recovery.conf: 已准备好，文件改个名就能用
1 --> start: l-ologpg1.ops.cn5:5432
1  -> 检查是否连接到主库并无延迟
1  -> l-ologpg1.ops.cn5:5432
1     - postgresql.conf
1       - archive_command 改为 /bin/true
1       - default_transaction_read_only 改为off 
1       reload 使其生效
1  -> 结束变更
1  -> 开启zabbix报警:  l-ologpg[1-2].ops.cn5
1  -> l-ologpg1.ops.cn5:5432
1    - postgresql.conf
1      - autovacuum => on(已修改，已reload)
1      - full_page_writes => off(已修改，已reload)
1      - synchronous_standby_names => ''(已修改，已reload)
1  -> l-ologpg2.ops.cn5:5432
1    - postgresql.conf
1      - full_page_writes => off(已修改，已reload)
1  -> 开任务搬 realtime 目录




--- Todo Details ---
Target: l-oadminpgvip[1-3].ops.cn5:5432

Actual Actions:
# 起草变更内容：https://wiki.corp.qunar.com/confluence/pages/viewpage.action?pageId=334732522
# TL Review 变更
# Publishing 变更
# [主库]l-oadminpg1.ops.cn5:5432
    = postgres.conf
      - 备份一份(已备份)
      - full_page_writes => on(已修改，已reload)
      - autovacuum => off(已修改，已reload)
      - default_transaction_read_only => on(目前是注释状态，走默认值off，待关闭前改成on并打开注释，重启时生效)
      - archive_command => /bin/true(未修改)
    = recovery.conf
      - 已复制 l-oadminpg2.ops.cn5:5432's recovery.conf
      - 已修改 primary_conninfo 中的链接地址和application_name
      (等待重启时启用)
# [从库]l-oadminpg2.ops.cn5:5432
    = postgres.conf
      - 备份一份(已备份)
      - full_page_writes => on(已修改，已reload)
      - autovacuum => on(就是on，无需操作)
      - default_transaction_read_only => off(目前是注释状态, 走默认值off，无需操作)
      - archive_command => '一串正确的值'(已修改，等待promote时生效)
# [从库]l-oadminpg3.ops.cn5:5432
    = recovery.conf
      - primary_conninfo 的链接地址改成l-oadminpgvip2.ops.cn5
    ===> 已重启


Next Actions:
1  -> l-oadminpg1.ops.cn5:5432
1     - postgresql.conf
1       - synchronous_standby_names => '*'(已修改，已reload)
1 --> 上一个集群搞完后，等一会儿，在qtalk群中通知相关人员
1  -> 关闭zabbix报警：
1     - 关闭 l-oadminpg[1-3].ops.cn5 报警
1  -> 通知亮亮停掉应用
1 --> check l-oadminpg1.ops.cn5:5432 是否有来自应用的连接
1  -> l-oadminpg1.ops.cn5:5432
1     - postgresql.conf
1       - default_transaction_read_only 改为on(已修改，已reload)
1  -> stop: l-oadminpg1.ops.cn5:5432
1  -> promote: l-oadminpg2.ops.cn5:5432
1  -> l-oadminpgvip1.ops.cn5 从 l-oadminpg1.ops.cn5 到 l-oadminpg2.ops.cn5
1  -> 通知操作完毕，等待应用方反馈无误
1  -> 结束变更
1  -> 修改l-oadminpg1.ops.cn5:5432
1     - recovery.conf
1       - 已准备好，文件改个名就能用
1  -> start: l-oadminpg1.ops.cn5:5432
1  -> 检查是否连接到主库并无延迟
1  -> l-oadminpg1.ops.cn5:5432
1     - postgresql.conf
1       - archive_command 改为 /bin/true(已修改，已reload)
1       - default_transaction_read_only 改为off(已修改，已reload)
1       - autovacuum => on(已修改，已reload)
1       - full_page_writes => off(已修改，已reload)
1       - synchronous_standby_names => ''(已修改，已reload)
1  -> l-oadminpg2.ops.cn5:5432
1    - postgresql.conf
1      - full_page_writes => off(已修改，已reload)  
1  -> 开启zabbix报警：
1     - 开启 l-oadminpg[1-3].ops.cn5 报警
  END





update qpoi set  alias =  '"新国展"=>"1","新国际展览中心"=>"1","展览中心新馆"=>"1","北京国际展览中心（新馆）"=>"1","北京国际会展中心新馆"=>"1","中国国际展览馆新馆"=>"1","中国国际展览中心新馆"=>"1","北京国际展览中心新馆"=>"1","新中国国际展览中心"=>"1","中国国际展览中心(新馆)"=>"1",""中国国际展览中心 • 新馆""=>"1","国展中心新馆"=>"1","新国展中心"=>"1","国展新馆"=>"1","国际展览中心新馆"=>"1","中国国际展览中心顺义新馆"=>"1","新国际会展中心"=>"1"', last_mod = now()  where  id = 5694729;






