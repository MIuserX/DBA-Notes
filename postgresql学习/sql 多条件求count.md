```sql
# 有 3 个 count 的 SQL 如下：
# 现在想把他们合成一条．
#
 
b2c_product=# select count(*) from b2c_wish_order where candidate_sids @> '{1}';
 count
-------
    47
(1 row)
 
b2c_product=# select count(*) from b2c_wish_order where bid_sid = 1;
 count
-------
    41
(1 row)
 
b2c_product=# select count(*) from b2c_wish_order where bid_sid=1 and status=10;
 count
-------
     5
(1 row)
 
 
# 思来想去，觉得 count() 函数应该可以按条件计数吧，
# 数据库里查了一番，有这么个 count():
 
      function     | argument type | return type |                           description
-------------------+---------------+-------------+---------------------------------------------------------------------
 count(expression) |     any       |   bigint    | number of input rows for which the value of expression is not null
 
# 上述 count() 当 expression 为 非NULL 时计数，NULL 时不计数
# 这时，我们需要的是写出一个表达式，使其满足：满足我们的计数条件时返回非NULL，不满足我们的计数条件时返回NULL．
# case when 语法可以完成这个需求．
# 我们可以用 case when 语法将逻辑设计为：满足表达式就返回１，不满足表达式就返回NULL．
 
b2c_product=# select count(case when candidate_sids @> '{1}' then 1 else NULL end) as ct1, count(case when (bid_sid = 1) then 1 else null end) as ct2,count(case when bid_sid=1 and status=10  then 1 else NULL end)as ct3  from b2c_wish_order;
 ct1 | ct2 | ct3
-----+-----+-----
  47 |  41 |   5
(1 row)
 
# 经过实验发现：
# false and NULL == 非NULL
# true and NULL == NULL
 
b2c_product=# select 't'::boolean and NULL is null;
 ?column?
----------
 t
(1 row)
 
b2c_product=# select 'f'::boolean and NULL is null;
 ?column?
----------
 f
(1 row)
 
#
# 利用上述特性我们还可以这样写：
 
b2c_product=# select count(not (candidate_sids @> '{1}') and null) as ct1, count(not (bid_sid = 1) and null) as ct2, count(not (bid_sid=1 and status=10) and null ) as ct3 from b2c_wish_order;
 ct1 | ct2 | ct3
-----+-----+-----
  47 |  41 |   5
(1 row)
 
 
#
# 后来发散了一下思维，觉得 sum 函数结合 case when 语法也可以完成我们的要求．
 
b2c_product=# select sum(case when candidate_sids @> '{1}' then 1 else 0 end) as ct1, sum(case when bid_sid = 1 then 1 else 0 end) as ct2, sum(case when bid_sid=1 and status=10 then 1 else 0 end) as ct3 from b2c_wish_order;
 ct1 | ct2 | ct3
-----+-----+-----
  47 |  41 |   5
(1 row)
 
#
# 看上面这个表达式，觉得 boolean 表达式可以直接强转为 int 类型：
 
b2c_product=# select 't'::boolean::int;
 int4
------
    1
(1 row)
 
b2c_product=# select 'f'::boolean::int;
 int4
------
    0
(1 row)
 
#
# 我们想要的逻辑是：表达式为真计数（计数器加 1 ），表达式为假不计数（也就是说计数器加 0 ）
# 这样我们就可以写：
 
b2c_product=# select sum((candidate_sids @> '{1}')::int) as ct1, sum((bid_sid = 1)::int) as ct2, sum((bid_sid=1 and status=10)::int)as ct3  from b2c_wish_order;
 ct1 | ct2 | ct3
-----+-----+-----
  47 |  41 |   5
(1 row)
 
#
# 写成上面这样终于满意了
```

