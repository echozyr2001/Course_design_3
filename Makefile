ARCH = "amd64"
FILE_SYSTEM_DIR = "fs"
FILE_SYSTEM_RELEASE = "bullseye"
IMG_SIZE = "10G"
IMG_TYPE =
IMG =
KERNEL = "linux/arch/x86_64/boot/bzImage"
ifndef IMG_TYPE
	IMG_TYPE = "raw"
	IMG = "rootfs.img"
else
	IMG = "rootfs.$(IMG_TYPE)"
endif

# TODO：暂时只能挂载raw类型
mount:
	@ sudo mount -o loop ./rootfs.img ./fs
	@ sudo mount --bind /dev ./fs/dev
	@ sudo mount --bind /dev/pts ./fs/dev/pts
	@ sudo mount --bind /proc ./fs/proc
	@ sudo chroot fs

umount:
	@ sudo umount ./fs/dev/pts
	@ sudo umount ./fs/dev
	@ sudo umount ./fs/proc
	@ sudo umount ./fs

# TODO：这里需要调整，在创建qcow2类型镜像时出错
build_fs:
	@# 创建目录
	$(call mk_fs)
	@# 创建镜像
	$(call create_img)
	@# 挂载镜像
	$(call mount_img)
	@# 安装Debian文件
	$(call install_fs)
	# TODO：逐步添加

checkout:
	# TODO：逐步添加
	@ sudo apt update
	@ sudo apt install -y flex bison

setup:
	@# 获取内核
	$(call get_kernel)

build:
	@# 复制config文件
	@ cp .config linux
	@# 开始编译内核
	@ cd linux 
	@ make -j$(nproc)

run:
	@ qemu-system-x86_64 \
		-smp 1 \
		-m 1024 \
		-kernel $(KERNEL) \
		-drive file=$(IMG),format=$(IMG_TYPE) \
		-append "root=/dev/sda rw console=ttyS0" \
		-nographic

debug:
	@ qemu-system-x86_64 \
		-smp 1 \
		-m 1024 \
		-kernel $(KERNEL) \
		-drive file=$(IMG),format=$(IMG_TYPE) \
		-append "root=/dev/sda rw console=ttyS0" \
		-nographic -s -S

# define run_debug
# 	@ qemu-system-x86_64 \
# 		-smp 1 \
# 		-m 1024 \
# 		-kernel $(KERNEL) \
# 		-drive file=$(IMG),format=$(IMG_TYPE),index=1,media=disk,if=virtio \
# 		-append "root=/dev/sda rw console=ttyS0" \
# 		-nographic -s -S
# endef

define get_kernel
	@ if [ ! -d "linux" ]; \
		then \
			git clone --depth=1 git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git; \
		else \
			cd linux; \
			git pull; \
		fi
endef

define mk_fs
	@ if [ ! -d $(FILE_SYSTEM_DIR) ]; \
		then \
			mkdir $(FILE_SYSTEM_DIR); \
		fi
endef

define create_img
	@ qemu-img create -f $(IMG_TYPE) $(IMG) $(IMG_SIZE)
	@ mkfs.ext4 $(IMG)
endef

define mount_img
	@ if [ $(IMG_TYPE) == "raw" ]; \
		then \
			sudo mount -o loop $(IMG) $(FILE_SYSTEM_DIR); \
		else \
			sudo modprobe nbd max_part=8; \
			sudo qemu-nbd -c /dev/nbd0 $(IMG); \
			sudo mount /dev/nbd0 $(FILE_SYSTEM_DIR); \
		fi
endef

define install_fs
	@ sudo debootstrap --arch $(ARCH) $(FILE_SYSTEM_RELEASE) $(FILE_SYSTEM_DIR)
endef
