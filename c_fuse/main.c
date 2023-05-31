#define FUSE_USE_VERSION 26

#include <stdio.h>
#include <string.h>
#include <fuse.h>

static int ou_readdir(const char* path, void* buf, fuse_fill_dir_t filler,
                      off_t offset, struct fuse_file_info* fi)
{
    return filler(buf, "hello-world", NULL, 0);
}

static int ou_getattr(const char* path, struct stat* st)
{
    memset(st, 0, sizeof(struct stat));

    if (strcmp(path, "/") == 0)
        st->st_mode = 0755 | S_IFDIR;
    else
        st->st_mode = 0644 | S_IFREG;

    return 0;
}

static struct fuse_operations oufs_ops = {
    .readdir    =   ou_readdir,
    .getattr    =   ou_getattr,
};

int main(int argc, char* argv[])
{
    return fuse_main(argc, argv, &oufs_ops, NULL);
}
