# About `with` syntax

对于复杂的 SQL，可能需要 `with` 子句。`with` 子句会构建出一个临时表，但这个表没有索引，后续如果用这表进行 JOIN 运算，可能会很慢。

具体要看数据情况，如果 `with` 得出的表小的话，可能速度会比较快，



# About PostGIS Functions

PostGIS 的很多函数似乎会耗费大量的 CPU，单次计算时间就很长，一定要注意，不能让其冗余计算。



# Overview

## 优化层次 维度

```sql
-- 单点

SQL & index
---------------------------------------------
table structure
---------------------------------------------
PostgreSQL configures & PostgreSQL Feature
---------------------------------------------
OS
---------------------------------------------
Hardware


-- 集群
读写分离；
```



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
* d

