class munin::plugins::dom0 {
  munin::plugin::deploy {
    [ 'xen', 'xen-cpu', 'xen_memory', 'xen_mem',
      'xen_vm', 'xen_vbd', 'xen_traffic_all' ]:
      config => 'user root';
  }
}
