# Course_design_3

## 宿主机环境搭建

### 获取并编译内核源码

```bash
# 获取最新Linux内核源码
$ git clone --depth=1 git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
# 进入源码目录
$ cd linux
# 指定编译架构
$ export ARCH=x86
# 获取默认配置
$ make x86_64_defconfig
# 启动配置界面
$ make menuconfig

# 关闭地址随机化
    Processor type and features  --->
    [ ]   Randomize the address of the kernel image (KASLR)
# 启用内核debug（这里不同版本内核有区别）
    Kernel hacking  --->
        Compile-time checks and compiler options  --->
            Debug information (Generate DWARF Version 5 debuginfo)  --->
            (X) Generate DWARF Version 5 debuginfo

# 开始编译内核
$ make -j$(nproc)
```

### 制作Debian文件系统

https://www.debian.org/releases/ 在这里查看当前Debian发行版

#### 方法1 使用raw格式镜像

```bash
# 创建raw格式镜像
$ qemu-img create -f raw rootfs.img 10G
# 格式化
$ mkfs.ext4 rootfs.img
# 创建临时挂载目录
$ mkdir fs
# 挂载镜像
$ sudo mount -o loop ./rootfs.img ./fs
# 安装Debian文件，其中bullseye为Debian的版本号，类似Mac的Ventura
$ sudo debootstrap --arch amd64 bullseye ./fs
# 挂载/dev、/proc和/dev/pts
$ sudo mount --bind /dev ./fs/dev
$ sudo mount --bind /dev/pts ./fs/dev/pts
$ sudo mount --bind /proc ./fs/proc
# 进入文件系统
$ sudo chroot fs
# 更新并安装需要的软件
$ apt update
$ apt upgrade
$ pat install vim sudo -y
# 创建用户并赋予sudo权限
$ adduser kn
$ gpasswd -a kn sudo
# 卸载设备
$ sudo umount ./fs/dev
$ sudo umount ./fs/dev/pts
$ sudo umount ./fs/proc
$ sudo umount ./fs
# 权限问题？？？
```

#### 方法2 使用qcow2格式镜像

qcow2是QEMU的一个特性丰富的镜像格式。它支持动态分配，写时复制，以及快照。qcow2 格式的主要缺点是其性能略低于raw格式。

https://zhuanlan.zhihu.com/p/534033659 这里详细介绍了raw格式和qcow2格式的优缺点。

```shell
# 创建raw格式镜像
$ qemu-img create -f raw rootfs.img 10G
# 格式化
$ mkfs.ext4 rootfs.img
# 转换为qcow2格式
$ qemu-img convert -f raw -O qcow2 rootfs.img rootfs.qcow2
# 加载nbd内核模块，设置最大管理分区数为8
$ sudo modprobe nbd max_part=8
# 导出镜像到网络块设备
$ sudo qemu-nbd -c /dev/nbd0 ./rootfs.qcow2
# 创建临时挂载目录
$ mkdir fs
# 挂载设备到目录
$ sudo mount /dev/nbd0 ./fs
# 安装Debian文件，其中bullseye为Debian的版本号，类似Mac的Ventura
$ sudo debootstrap --arch amd64 bullseye ./fs
# 挂载/dev、/proc和/dev/pts
$ sudo mount --bind /dev ./fs/dev
$ sudo mount --bind /dev/pts ./fs/dev/pts
$ sudo mount --bind /proc ./fs/proc
# 进入文件系统
$ sudo chroot fs
# 更新并安装需要的软件
$ apt update
$ apt upgrade
$ pat install vim sudo -y
# 创建用户并赋予sudo权限
$ adduser kn
$ gpasswd -a kn sudo
# 卸载设备
$ sudo umount ./fs/dev
$ sudo umount ./fs/dev/pts
$ sudo umount ./fs/proc
$ sudo umount ./fs
# 将nbd设备释放
$ sudo qemu-nbd -d /dev/nbd0
# 权限问题？？？
```

### 启动qemu

```shell
# qcow2格式镜像
$ qemu-system-x86_64 \
	-smp 1 \
    -m 1024 \
	-kernel ./linux/arch/x86_64/boot/bzImage \
	-drive file="./rootfs.qcow2",format=qcow2,index=1,media=disk,if=virtio \
	-append "root=/dev/sda rw console=ttyS0" \
	-nographic

# raw格式镜像
$ qemu-system-x86_64 \
	-smp 1 \
    -m 1024 \
	-kernel ./linux/arch/x86_64/boot/bzImage \
	-drive file="./rootfs.img",format=raw,index=1,media=disk,if=virtio
	-append "root=/dev/sda rw console=ttyS0" \
	-nographic
```

若遇到文件系统只读的问题，检查qemu启动参数-append后是否有`rw`。若问题依然存在，`mount -o remount,rw /`在虚拟机中执行这条命令尝试重新挂载，一般这条命令执行后会恢复，但是这只是临时的。

## 内核调试步骤

在qemu启动参数后面加上`-s -S`，如下：

```shell
# qcow2格式镜像
$ qemu-system-x86_64 \
	-smp 1 \
    -m 1024 \
	-kernel ./linux/arch/x86_64/boot/bzImage \
	-drive file="./rootfs.qcow2",format=qcow2,index=1,media=disk,if=virtio \
	-append "root=/dev/sda rw console=ttyS0" \
	-nographic -s -S # <===这里
```

启动远程调试

```shell
$ gdb ./linux/vmlinux # 加载程序
(gdb) target remote localhost:1234 # 1234端口是gdb默认的远程调试端口
```


