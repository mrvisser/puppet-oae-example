class munin::client {
  class { 'munin::repos': }
  package { 'munin-node': ensure => installed }
}