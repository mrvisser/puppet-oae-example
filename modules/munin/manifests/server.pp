class munin::server {

  class { 'munin::repos': }
  
  package { 'munin-node': ensure => installed }
  package { 'munin': ensure => installed }
}