#include <vmlinux.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

#define MAX_ENTRIES 10240
#define TASK_COMM_LEN 16

struct event {
 unsigned int pid;
 unsigned int tpid;
 int sig;
 int ret;
 char comm[TASK_COMM_LEN];
};

struct {
 __uint(type, BPF_MAP_TYPE_ARRAY);
 __uint(max_entries, 1);
 __type(key, __u32);
 __type(value, __u64);
} values SEC(".maps");

SEC("tracepoint/syscalls/sys_enter_open")
int count_open(struct trace_event_raw_sys_enter *ctx)
{
  u32 key = 0;
  u64 *value = bpf_map_lookup_elem(&values, &key);
//  if(value)
//  {
//    bpf_map_update_elem(&values, key, 1, BPF_ANY);
    bpf_printk("count: %d", *value);
//  } else {
//    bpf_map_update_elem(&values, key, 1, BPF_ANY);
//  }

  return 0;
}

char LICENSE[] SEC("license") = "Dual BSD/GPL";
