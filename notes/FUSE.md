## FSUE基本原理

FUSE 模块其实是一个简单的客户端-服务器协议，它的客户端是内核，用户态的守护进程就是服务端，内核模块会通过 VFS 暴露一个`/dev/fuse`的设备文件[^1]，这个虚拟设备文件就是内核模块和用户程序的数据通过路。

```shell
$ ls -l /dev/fuse
crw-rw-rw- root root 0 B Thu Nov 18 22:24:32 2021 /dev/fuse
```

所谓“用户态文件系统”，是指一个文件系统的 data 和 metadata 都是由用户态的进程提供的（这种进程被称为"**daemon**"）[^2]。

![image](https://github.com/echozyr2001/Course_design_3/raw/main/notes/png/1.png)

用户态文件系统不代表其完全不需要内核的参与，因为在 Linux 中，对文件的访问都是统一通过 VFS 层提供的内核接口进行的[^2]。当一个进程访问文件时，请求首先到达 VFS ，由 VFS 判断其属于某个用户态文件系统，然后将请求转发给内核 FUSE 模块，FUSE模块将请求转换为与 daemon 约定的协议格式，传递给 daemon 进程，daemon 进程处理之后，响应原路返回。

## FUSE协议格式

FUSE协议是客户端-服务器协议，与 http 协议类似，每一个请求都有一个请求头和请求体，每一个响应都有一个响应头和响应体。

### FUSE请求包

请求头的大小是固定的，定义如下：

```c
struct fuse_in_header {
	uint32_t	len; /* 数据长度：包括请求头和请求体 */
	uint32_t	opcode; /* 操作码：区别请求的类型 */
	uint64_t	unique; /* 唯一请求id */
	uint64_t	nodeid; /* 请求针对的文件id */
	uint32_t	uid; /* 请求进程的 uid */
	uint32_t	gid; /* 请求进程的 gid */
	uint32_t	pid; /* 请求进程的 pid */
	uint16_t	total_extlen;
	uint16_t	padding;
};
```

在请求头之后，紧跟着请求体（如果有），请求体长度可变，其具体类型通过`opcode`来确定。

下面以rename操作为例给出数据的解析过程[^1]：

rename 的 buf 结构长这样 `{fuse_in_header}{fuse_rename_in}{oldname}{newname}`

1. 读取 header，直接读取 `fuse_in_header`，类似这样： `struct fuse_in_header *in = (struct fuse_in_header *) buf;`
2. 判断 opcode 为 15，接下来读取 `fuse_rename_in` 类似这样： `buf += sizeof(struct fuse_in_header);struct fuse_rename_in *arg = (struct fuse_read_in *) buf;`
3. 除此之外，它的结构还跟着 oldname 和 newname，分别这样读取 `char* oldname = (((char*)buf) + sizeof(*buf));char* newname = oldname + strlen(oldname) + 1;`

```c
void handle(void *buf) {
  struct fuse_in_header *in = (struct fuse_in_header *) buf;
  if in.opcode == 15 {
    buf += sizeof(struct fuse_in_header);
	  struct fuse_rename_in *arg = (struct fuse_rename_in *) buf;
    char* oldname = (((char*)buf) + sizeof(*buf));
    char* newname = oldname + strlen(oldname) + 1;
    ...
  }
}
```

### FUSE响应包

响应头的大小也是固定的，定义如下：

```C
struct fuse_out_header {
	uint32_t	len; /* 整个响应的字节数长度 */
	int32_t		error; /* 响应错误码，成功返回0 */
	uint64_t	unique; /* 与请求保持一致的唯一id */
};
```

响应头后面紧跟响应体（如果有），如果错误码不为 0，则不应该包含响应体。具体如何处理响应体与处理请求体类似，就不再赘述。

## 执行过程

下图显示了文件系统操作（以unlink为例）是如何在FUSE中执行的[^3]。

```tex
|  "rm /mnt/fuse/file"               |  FUSE filesystem daemon
|                                    |
|                                    |  >sys_read()
|                                    |    >fuse_dev_read()
|                                    |      >request_wait()
|                                    |        [sleep on fc->waitq]
|                                    |
|  >sys_unlink()                     |
|    >fuse_unlink()                  |
|      [get request from             |
|       fc->unused_list]             |
|      >request_send()               |
|        [queue req on fc->pending]  |
|        [wake up fc->waitq]         |        [woken up]
|        >request_wait_answer()      |
|          [sleep on req->waitq]     |
|                                    |      <request_wait()
|                                    |      [remove req from fc->pending]
|                                    |      [copy req to read buffer]
|                                    |      [add req to fc->processing]
|                                    |    <fuse_dev_read()
|                                    |  <sys_read()
|                                    |
|                                    |  [perform unlink]
|                                    |
|                                    |  >sys_write()
|                                    |    >fuse_dev_write()
|                                    |      [look up req in fc->processing]
|                                    |      [remove from fc->processing]
|                                    |      [copy write buffer to req]
|          [woken up]                |      [wake up req->waitq]
|                                    |    <fuse_dev_write()
|                                    |  <sys_write()
|        <request_wait_answer()      |
|      <request_send()               |
|      [add request to               |
|       fc->unused_list]             |
|    <fuse_unlink()                  |
|  <sys_unlink()                     |
```

## 参考文献

[^1]: https://github.com/0voice/kernel_awsome_feature/blob/main/%E8%AF%A6%E8%A7%A3%20FUSE%20%E7%94%A8%E6%88%B7%E6%80%81%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F.md
[^2]: https://zhuanlan.zhihu.com/p/143256077?utm_source=qq&utm_medium=social&utm_oi=730740411601014784
[^3]: https://www.kernel.org/doc/html/next/filesystems/fuse.html