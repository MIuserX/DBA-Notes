# 头脑风暴

* select类型
    * DISTINCT
    * 非聚合函数
    * 非窗口聚合函数
    * 窗口聚合函数
    * Set-Returning Functions



# SELECT 的子句

* select list
* distinct
* from
* where
* group by
* having
* sort by
* (offset) limit





## Distinct



## Group By



## Sort By



## (offset) Limit 



# 逐渐复杂的 SELECT

```sql
-- 
select x, y from tbl;

-- 
select x, y from tbl where x = 0;

-- 
select x, y from tbl where x = 0 order by y;

-- 
select x, y from tbl where x = 0 order by y limit 10;

-- aggregate functions

```



# 怎么写一个 SELECT ？

1. 首先看需求，确定 SELECT list
2. SELECT list 中是否有 聚合？有的话去 x ，否则去 3
3. 开始写 FROM 子句，将所有需要的表关联起来



