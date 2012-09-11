#
# = Class cassandra::common
#

class cassandra::common {

	$release = $operatingsystem ? {
		/CentOS|RedHat/ => $lsbmajdistrelease,
		/Amazon|Linux/ => '6'
	}

	yumrepo { "datastax":
		name => "datastax",
		baseurl => "http://rpm.datastax.com/community",
		enabled => '1',
		gpgcheck => '0',
	}

	package { 'dsc1.1':
		ensure => installed,
		require => Yumrepo['datastax'],
	}

  file { 'cassandra.yaml': 
    path => '/etc/cassandra/conf/cassandra.yaml', 
    ensure => present,
    mode => 0640,
    owner => 'cassandra',
    group => 'cassandra',
    content => template('cassandra/cassandra.erb'),
  }
}
