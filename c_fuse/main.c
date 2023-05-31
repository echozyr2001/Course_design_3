#define FUSE_USE_VERSION 26

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fuse.h>

#include "list.h"

static struct list_node entries;

static int ou_readdir(const char* path, void* buf, fuse_fill_dir_t filler,
                      off_t offset, struct fuse_file_info* fi)
{
  struct list_node* n;

  filler(buf, ".", NULL, 0);
  filler(buf, "..", NULL, 0);

  list_for_each(n, &entries)
  {
    struct out_entry* o = list_entry(n, struct out_entry, node);
    filler(buf, o->name, NULL, 0);
  }

  return 0;
}

static int ou_getattr(const char* path, struct stat* st)
{
  struct list_node* n;

  memset(st, 0, sizeof(struct stat));

  if (strcmp(path, "/") == 0) {
    st->st_mode = 0755 | S_IFDIR;
    st->st_nlink = 2;
    st->st_size = 0;

    list_for_each (n, &entries) {
        struct ou_entry* o = list_entry(n, struct ou_entry, node);
        ++st->st_nlink;
        st->st_size += strlen(o->name);
    }

    return 0;
  }

  list_for_each (n, &entries) {
    struct ou_entry* o = list_entry(n, struct ou_entry, node);
    if (strcmp(path + 1, o->name) == 0) {
        st->st_mode = o->mode;
        st->st_nlink = 1;
        return 0;
    }
  }

  return -ENOENT;
}

static int ou_create(const char* path, mode_t mode, struct fuse_file_info* fi)
{
  struct ou_entry* o;
  struct list_node* n;

  if (strlen(path + 1) > MAX_NAMELEN)
}

static int ou_unlink(const char* path)
{
  struct list_node *n, *p;

  list_for_each_safe (n, p, &entries)
  {
    struct ou_entry* o = list_entry (n, struct ou_entry, node);
    if (strcmp(path + 1, o->name) == 0)
    {
      __list_del(n);
      free(o);
      return 0;
    }
  }
}

static struct fuse_operations oufs_ops = {
  .readdir    =   ou_readdir,
  .getattr    =   ou_getattr,
  .create     =   ou_create,
  .unlink     =   ou_unlink,
};

int main(int argc, char* argv[])
{
  list_init(&entries);
  return fuse_main(argc, argv, &oufs_ops, NULL);
}
