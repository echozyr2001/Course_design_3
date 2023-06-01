typedef struct lookup_attr_key {
  uint64_t nodeid;
} lookup_attr_key_t;

typedef struct lookup_attr_value {
  struct fuse_attr_out out;
} lookup_attr_val_t;

