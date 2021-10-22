# About `with` syntax

对于复杂的 SQL，可能需要 `with` 子句。`with` 子句会构建出一个临时表，但这个表没有索引，后续如果用这表进行 JOIN 运算，可能会很慢。

具体要看数据情况，如果 `with` 得出的表小的话，可能速度会比较快，



# About PostGIS Functions

PostGIS 的很多函数似乎会耗费大量的 CPU，单次计算时间就很长，一定要注意，不能让其冗余计算。



# Overview

## 优化层次 维度

```sql
-- 单点

业务
---------------------------------------------
SQL & index
---------------------------------------------
table & database structure
---------------------------------------------
PostgreSQL configures & PostgreSQL Feature
---------------------------------------------
OS
---------------------------------------------
Hardware


-- 集群
读写分离；
多活；
高可用；
链接池；
```

### SQL & index 层

这一层主要优化

* 如何写出用索引的 SQL？

    * 哪些语法会走索引？
    * 哪些操作符和函数会走索引？

* 如何根据 SQL 建立索引？

    不存在 SQL 的表，建索引没有意义。

* 优化 SQL 结构，避免冗余 CPU和I/O ，最简化流程得出结果



#### 头脑风暴

* 字符串匹配走索引
    * 避免 `like '%x%'`，尽量 `like 'x%'`
    * 或者使用 FullTextSearch
    * 数量大时使用 ES，Solr
* 避免使用 in & not in，不走索引，如果是子查询，使用 exists 代替
* 尽量避免使用 `or`，会导致放弃索引进行全表扫描
* 避免 NULL 值判断，会导致放弃索引进行全表扫描
* 尽量避免



#### 具体SQL

##### SELECT

###### From

* **多表关联查询时，小表在前，大表在后**

    在 MySQL 中，执行 from 后的表关联查询是从左往右执行的(Oracle 相反)，第一张表会涉及到全表扫描。

    所以将小表放在前面，先扫小表，扫描快效率较高，在扫描后面的大表，或许只扫描大表的前 100 行就符合返回条件并 return 了。

    例如：表 1 有 50 条数据，表 2 有 30 亿条数据;如果全表扫描表 2，你品，那就先去吃个饭再说吧是吧。

* **使用表的别名**

    当在 SQL 语句中连接多个表时，请使用表的别名并把别名前缀于每个列名上。这样就可以减少解析的时间并减少哪些友列名歧义引起的语法错误。

* **用 where 字句替换 HAVING 字句**

    避免使用 HAVING 字句，因为 HAVING 只会在检索出所有记录之后才对结果集进行过滤，而 where 则是在聚合前刷选记录，如果能通过 where  字句限制记录的数目，那就能减少这方面的开销。

    HAVING 中的条件一般用于聚合函数的过滤，除此之外，应该将条件写在 where 字句中。

    where 和 having 的区别：where 后面不能使用组函数。

* **调整 Where 字句中的连接顺序**

    MySQL 采用从左往右，自上而下的顺序解析 where 子句。根据这个原理，应将过滤数据多的条件往前放，最快速度缩小结果集。

###### Where

* 避免使用 in & not in，不走索引，如果是子查询，使用 exists 代替

* 尽量避免使用 `or`，会导致放弃索引进行全表扫描

* 避免 NULL 值判断，会导致放弃索引进行全表扫描

* 避免 `like '%x%'`，尽量 `like 'x%'`

* 尽量避免在 where 条件中等号的左侧进行表达式、函数操作，会导致数据库引擎放弃索引进行全表扫描

* **当数据量大时，避免使用 where 1=1 的条件**

* **查询条件不能用 <> 或者 !=**

    使用索引列作为条件进行查询时，需要避免使用<>或者!=等判断条件。

    如确实业务需要，使用到不等于符号，需要在重新评估索引建立，避免在此字段上建立索引，改由查询条件中其他索引字段代替。

* **where 条件仅包含复合索引非前置列**

    如下：复合(联合)索引包含 key_part1，key_part2，key_part3 三列，但 SQL  语句没有包含索引前置列"key_part1"，按照 MySQL 联合索引的最左匹配原则，不会走联合索引。

    ```sql
    select col1 from table where key_part2=1 and key_part3=2 
    ```

* **隐式类型转换造成不使用索引**

    如下 SQL 语句由于索引对列类型为 varchar，但给定的值为数值，涉及隐式类型转换，造成不能正确走索引。

    ```sql
    select col1 from table where col_varchar=123;  
    ```

* **order by 条件要与 where 中条件一致，否则 order by 不会利用索引进行排序**

    ```sql
    -- 不走age索引 
    SELECT * FROM t order by age;  
    -- 走age索引 
    SELECT * FROM t where age > 0 order by age; 
    ```

    对于上面的语句，数据库的处理顺序是：

    - 第一步：根据 where 条件和统计信息生成执行计划，得到数据。
    - 第二步：将得到的数据排序。当执行处理数据(order by)时，数据库会先查看第一步的执行计划，看 order by  的字段是否在执行计划中利用了索引。如果是，则可以利用索引顺序而直接取得已经排好序的数据。如果不是，则重新进行排序操作。
    - 第三步：返回排序后的数据。

    当 order by 中的字段出现在 where 条件中时，才会利用索引而不再二次排序，更准确的说，order by  中的字段在执行计划中利用了索引时，不用排序操作。

    这个结论不仅对 order by 有效，对其他需要排序的操作也有效。比如 group by 、union 、distinct 等。

* **正确使用 hint 优化语句**

    MySQL 中可以使用 hint 指定优化器在执行时选择或忽略特定的索引。

    一般而言，处于版本变更带来的表结构索引变化，更建议避免使用 hint，而是通过 Analyze table 多收集统计信息。

    但在特定场合下，指定 hint 可以排除其他索引干扰而指定更优的执行计划：

    - USE INDEX 在你查询语句中表名的后面，添加 USE INDEX 来提供希望 MySQL 去参考的索引列表，就可以让 MySQL  不再考虑其他可用的索引。

    例子: SELECT col1 FROM table USE INDEX (mod_time, name)...

    - IGNORE INDEX 如果只是单纯的想让 MySQL 忽略一个或者多个索引，可以使用 IGNORE INDEX 作为 Hint。

    例子: SELECT col1 FROM table IGNORE INDEX (priority) ...

    - FORCE INDEX 为强制 MySQL 使用一个特定的索引，可在查询中使用FORCE INDEX 作为 Hint。

    例子: SELECT col1 FROM table FORCE INDEX (mod_time) ...

    在查询的时候，数据库系统会自动分析查询语句，并选择一个最合适的索引。但是很多时候，数据库系统的查询优化器并不一定总是能使用最优索引。

    如果我们知道如何选择索引，可以使用 FORCE INDEX 强制查询使用指定的索引。

    例如：

    ```
    SELECT * FROM students FORCE INDEX (idx_class_id) WHERE class_id = 1 ORDER BY id DESC; 
    ```

* 的



##### Group by

* group by 字段最好带索引



##### Select list

* 只写需要的字段，避免多余的 I/O
* 避免 `select *`，会带来额外的 CPU、I/O、内存消耗



##### Order by

* order by 字段最好带索引



#### INSERT

* **批量插入记录：多条 INSERT 表 INSERT 多个值。**

    * 减少 SQL 语句解析的操作，MySQL 没有类似 Oracle 的 share pool，采用方法二，只需要解析一次就能进行数据的插入操作。
    * 在特定场景可以减少对 DB 连接次数。
    * SQL 语句较短，可以减少网络传输的 IO。

* **适当使用 commit**

    适当使用 commit 可以释放事务占用的资源而减少消耗，commit 后能释放的资源如下：

    - 事务占用的 undo 数据块。
    - 事务在 redo log 中记录的数据块。
    - 释放事务施加的，减少锁争用影响性能。特别是在需要使用 delete 删除大量数据的时候，必须分解删除量并定期 commit。

* **避免重复查询更新的数据**

    针对业务中经常出现的更新行同时又希望获得改行信息的需求，MySQL 并不支持 PostgreSQL 那样的 UPDATE RETURNING 语法，在  MySQL 中可以通过变量实现。

    例如，更新一行记录的时间戳，同时希望查询当前记录中存放的时间戳是什么?

    简单方法实现：

    ```
    Update t1 set time=now() where col1=1;   Select time from t1 where id =1; 
    ```

    使用变量，可以重写为以下方式：

    ```
    Update t1 set time=now () where col1=1 and @now: = now ();   Select @now;  
    ```

    前后二者都需要两次网络来回，但使用变量避免了再次访问数据表，特别是当 t1 表数据量较大时，后者比前者快很多。

* **查询优先还是更新(insert、update、delete)优先**

    MySQL  还允许改变语句调度的优先级，它可以使来自多个客户端的查询更好地协作，这样单个客户端就不会由于锁定而等待很长时间。改变优先级还可以确保特定类型的查询被处理得更快。

    我们首先应该确定应用的类型，判断应用是以查询为主还是以更新为主的，是确保查询效率还是确保更新的效率，决定是查询优先还是更新优先。

    下面我们提到的改变调度策略的方法主要是针对只存在表锁的存储引擎，比如 MyISAM 、MEMROY、MERGE，对于 Innodb  存储引擎，语句的执行是由获得行锁的顺序决定的。

    MySQL 的默认的调度策略可用总结如下：

    - 写入操作优先于读取操作。
    - 对某张数据表的写入操作某一时刻只能发生一次，写入请求按照它们到达的次序来处理。
    - 对某张数据表的多个读取操作可以同时地进行。

    MySQL 提供了几个语句调节符，允许你修改它的调度策略：

    - LOW_PRIORITY 关键字应用于 DELETE、INSERT、LOAD DATA、REPLACE 和 UPDATE。
    - HIGH_PRIORITY 关键字应用于 SELECT 和 INSERT 语句。
    - DELAYED 关键字应用于 INSERT 和 REPLACE 语句。

    如果写入操作是一个 LOW_PRIORITY(低优先级)请求，那么系统就不会认为它的优先级高于读取操作。

    在这种情况下，如果写入者在等待的时候，第二个读取者到达了，那么就允许第二个读取者插到写入者之前。

    只有在没有其它的读取者的时候，才允许写入者开始操作。这种调度修改可能存在 LOW_PRIORITY 写入操作永远被阻塞的情况。

    SELECT 查询的 HIGH_PRIORITY(高优先级)关键字也类似。它允许 SELECT  插入正在等待的写入操作之前，即使在正常情况下写入操作的优先级更高。

    另外一种影响是，高优先级的 SELECT 在正常的 SELECT 语句之前执行，因为这些语句会被写入操作阻塞。

    如果希望所有支持 LOW_PRIORITY 选项的语句都默认地按照低优先级来处理，那么请使用--low-priority-updates  选项来启动服务器。

    通过使用 INSERTHIGH_PRIORITY 来把 INSERT 语句提高到正常的写入优先级，可以消除该选项对单个 INSERT 语句的影响。



#### UPDATE



#### DELETE

* 用 truncate 代替 delete 全表
* 



#### Alter Table





### Table structure

* 水平分表
* 垂直分表



* **尽量使用数字型字段**

    如性别，男：1 女：2，若只含数值信息的字段尽量不要设计为字符型，这会降低查询和连接的性能，并会增加存储开销。这是因为引擎在处理查询和连接时会 逐个比较字符串中每一个字符，而对于数字型而言只需要比较一次就够了。

* **查询数据量大的表 会造成查询缓慢**

    主要的原因是扫描行数过多。这个时候可以通过程序，分段分页进行查询，循环遍历，将结果合并处理进行展示。

    要查询 100000 到 100050 的数据，如下：

    ```sql
    SELECT * FROM (SELECT ROW_NUMBER() OVER(ORDER BY ID ASC) AS rowid,*     FROM infoTab)t WHERE t.rowid > 100000 AND t.rowid <= 100050 
    ```

* **用 varchar/nvarchar 代替 char/nchar**

    尽可能的使用 varchar/nvarchar 代替 char/nchar  ，因为首先变长字段存储空间小，可以节省存储空间，其次对于查询来说，在一个相对较小的字段内搜索效率显然要高些。

    不要以为 NULL 不需要空间，比如：char(100) 型，在字段建立时，空间就固定了， 不管是否插入值(NULL 也包含在内)，都是占用 100  个字符的空间的，如果是 varchar 这样的变长字段， null 不占用空间。







## 应用链 维度

```
DB <-> Application
```



## CPU & Memory & Disk I/O & Network I/O





## 成本

优化成本：硬件>系统配置>数据库表结构>SQL 及索引。

优化效果：硬件<系统配置<数据库表结构



## SQL 优化



* 最大化利用索引
* 尽量避免全表扫描
* 较少无效数据查询

### SELECT

#### From 子句

* 表的顺序
* Where 中的条件上提到这里来写



#### Where 子句

* 涉及的字段建索引
* (如果由左向右处理) 多个条件，过滤多的写前面



#### SELECT list

* 尽量不要 select 不需要的字段



### INSERT

* 批量插入用单个 INSERT 
    * 减少 SQL 解析的 cost
    * 可能会减少与 DB 交互次数
    * 减少网络传输的数据量
* 
