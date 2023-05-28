ARCH = "amd64"
FILE_SYSTEM_DIR = "fs"
FILE_SYSTEM_RELEASE = "bullseye"
IMG_SIZE = "10G"
IMG_TYPE =
IMG = 
ifndef IMG_TYPE
	IMG_TYPE = "raw"
	IMG = "rootfs.img"
else
	IMG = "rootfs.$(IMG_TYPE)"
endif

# TODO：整理
check-%:
	@if [ "$($*)" = "" ]; \
	then \
		echo "dsdsdsd"; \
	else \
		echo "$*"; \
	fi

__test:
	echo "test"

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
			@# 挂载row类型
			@ sudo mount -o loop $(IMG) $(FILE_SYSTEM_DIR)
		else \
			@# 挂载qcow2类型
			@ sudo modprobe nbd max_part=8
			@ sudo qemu-nbd -c /dev/nbd0 $(IMG)
			@ sudo mount /dev/nbd0 $(FILE_SYSTEM_DIR)
		fi
endef

define install_fs
	@ sudo debootstrap --arch $(ARCH) $(FILE_SYSTEM_RELEASE) $(FILE_SYSTEM_DIR)
endef

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
	@ git clone --depth=1 git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git

build:
	@# 复制config文件
	@ cp .config linux
	@# 开始编译内核
	@ cd linux 
	@ make -j$(nproc)