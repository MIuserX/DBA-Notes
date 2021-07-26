

## Contents

* REDO 定义
* PostgreSQL 的 REDO 定义
* PostgreSQL 使用的关键结构
* PostgreSQL 实现的优点 & 缺点
* Oracle 的 REDO 实现
* Oracle 实现的优点 & 缺点
* PostgreSQL 的改进
* 一个改进的方法的细节



## REDO 定义

* REDO 日志包含了数据库变化的所有历史
* REDO 日志文件被用于
    * 数据恢复
    * 增量备份 与 时间点恢复
    * 主从复制
* 对于数据库的每个改变被写入 REDO 日志文件，在写入数据文件之前
* REDO 日志缓冲区被写入 REDO 日志文件，在 COMMIT 执行时
* 一个后台日志写入进程将 REDO　刷写，在数据库设置是REDO应该被批量写入
* 临时表不需要　REDO



## PostgreSQL 的 REDO 定义

### 术语

* **WAL**（Write Ahead Log）

    预写式日志。它被应用于事务日志文件的语境中。

* **Xlog**（Transaction Log）

    事务日志。它被应用于事务日志缓冲区的语境中。

* **LSN**（Log sequence number）

    事务日志序号。这被用来标记一个事务日志在页中的位置。

* **Bgwriter**（Background writer）

    后台事务日志写入进程。这个进程被用来将 shared buffers 的数据刷新到磁盘并执行 checkpoint。

* **Clog**（Commit log）

    提交日志。它被用于事务状态缓冲区的语境中。

* **Partial Page Write**

    这发生在当 OS 能写磁盘上的可能造成X的部分页的时候。



### PostgreSQL 的 REDO 定义

* 在 PostgreSQL 中，REDO 日志广泛称为 WAL，它保证必须在数据页变化之前将 WAL 写入持久存储。
* 要保证上面的，
    * 每个数据页(无论是 heap 还是 index) 被最新的影响这个页的 XLOG 记录的 LSN 标记
    * 在 bufmgr 可以将脏页写到磁盘之前，必须保证 xlog 早已被写入到磁盘，至少到这个页的 LSN
* 这个低层次相互关系通过不等待 WAL I/O 直到必须等待的时候才等待，从而改进了性能
* 临时表操作不会记录 WAL

--- 有个图

### WAL Action 的算法

* 固定并且持有包含被修改的数据页的 buffer 的 exclusive-lock
* 启动临界 section，这个 section 保证：任何在这个 section 结束之前出现的错误应该是一个 PANIC，buffer 可能包含未记录的变化
* 将变化应用到 buffer
* 将这个 buffer 标记为 "脏页"，这保证 bgwriter(checkpoint) 将把这个页写到磁盘，在写 WAL record 之前将 buffer 标记为脏页保证了对于 buffer 内容的少量的争用
* 构建一个记录插入到事务日志缓冲区
* 用将要被 bgwriter 或刷盘操作用的 LSN 更新这个页，来保证相应的日志从缓冲区中写到磁盘
* 结束这个临界 sectoin
* 解锁并解固定这个 buffer



### WAL 中使用的重要的锁

##### WALInsertLock

* 这个锁被用来，插入 事务日志记录 到 事务日志内存缓冲区。首先，这个锁被持有当所有的内容包含全缓冲区(如果 full_page_writes 被打开)被复制到日志缓冲区。
* 其他的使用这个锁的地方
    * 在将日志缓冲区刷写到磁盘的时候，检查是否有其他需要添加到日志缓冲区的内容，自从上次它被决定直到日志缓冲区刷写时间点。
    * 决定 checkpoint redo 位置
    * 在 online 备份期间，强制 Full Page Writes 直到备份完成。
    * 从内置函数获取当前的 WAL 插入位置



##### WALWriteLock



