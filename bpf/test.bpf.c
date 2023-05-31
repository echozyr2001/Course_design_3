#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>
#include <bpf/bpf_core_read.h>

char LICENSE[] SEC("license") = "Dual BSD/GPL";

#define MAX_ENTRIES (2 << 16)

typedef struct lookup_attr_key {
    /* node id */
    uint64_t nodeid;
} lookup_attr_key_t;

typedef struct lookup_attr_value {
	uint32_t stale;
	/* node attr */
  //  struct fuse_attr_out out;
} lookup_attr_val_t;

/* number of entries in hash lookup table */

struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__type(key, lookup_attr_key_t);
	__type(value, lookup_attr_val_t);
	__uint(max_entries, MAX_ENTRIES);
} attr_map SEC(".maps");

SEC("kprobe/fuse_getattr")
int BPF_KPROBE(do_unlinkat, int dfd, struct filename *name)
{
	 lookup_attr_key_t key = {0};
	 lookup_attr_val_t *attr = bpf_map_lookup_elem(&attr_map, &key);
	bpf_printk("key: %d", *key);	
 return 0;
}
