## FUSE协议格式[^1]

### FUSE请求包

FUSE请求包分为两部分：

1. `Header`：这是所有请求共用的，所有请求的头部至少都有这个结构体，`Header`结构体用于描述整个FUSE请求，通过其中的字段来区分请求类型；
2.  `Payload`：该结构体每个IO类型是不同的，如`read`请不包含该结构体，`write`请求包含该结构体，因为`write`请求是携带数据的；

```c
type inHeader struct {
  Len    uint32
  Opcode uint32
  Unique uint64
  Nodeid uint64
  Uid    uint32
  Gid    uint32
  Pid    uint32
  _      uint32
}
```

* Len：整个请求的字节数长度（`Header` + `Payload`）；
* Opcode：请求的类型，如`read`、`write`等；
* Unique：请求唯一标识；
* Nodeid：请求针对的文件nodeid；
* Uid：文件/文件夹操作的进程的用户 ID；
* Gid：文件/文件夹操作的进程的用户组 ID；
* Pid：文件/文件夹操作的进程的进程 ID；

### FUSE响应包

FUSE响应包也包含`Header`和`Payload`两部分，与FUSE请求包基本相同：

1. `Header`：这是所有请求共用的，所有请求的头部至少都有这个结构体，`Header`结构体用于描述整个FUSE请求，通过其中的字段来区分请求类型；
2.  `Payload`：该结构体每个IO类型是不同的，如`read`请不包含该结构体，`write`请求包含该结构体，因为`write`请求是携带数据的；

```C
type outHeader struct {
  Len    uint32
  Error  int32
  Unique uint64
}
```

- Len：整个响应的字节数长度（ `Header` + `Payload` ）；
- Error：响应错误码，成功返回 0；
- Unique：对应者请求的唯一标识，和请求对应；





## 参考文献

[^1]: https://zhuanlan.zhihu.com/p/378429806
