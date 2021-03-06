###########################################################################
#
# Nodes
#
# This is an example of how to set up a Sakai OAE Cluster with puppet.
#
# The example cluster consists of the following:
#
# Web Tier
# Apache 10.168.199.125
#
# App tier - 2 OAE application nodes
# Appservers (ELB in front):
# DNS(ELB) -> OAE-AppServers-365563856.us-west-1.elb.amazonaws.com
# App1 DNS for ssh(not sticky, don't use for config) -> ec2-50-18-147-148.us-west-1.compute.amazonaws.com
# App2 DNS for ssh(not sticky, don't use for config) -> ec2-204-236-168-81.us-west-1.compute.amazonaws.com
# SSH Port 22
#
# Preview (ELB in front): 
# DNS(ELB) -> OAE-Preview-2008250595.us-west-1.elb.amazonaws.com
# SSH Port 2022
#
# Search tier - 1 solr master
# SOLR (ELB in front):
# DNS(ELB) -> OAE-SOLR-426995740.us-west-1.elb.amazonaws.com
# SSH Port 2022
#
# Storage tier - One Postgres database node.
# Postgres (ELB in front):
# DNS(ELB) -> OAE-Postgres-566174176.us-west-1.elb.amazonaws.com
# SSH Port 2022

# If you use csshx to connect to all of the nodes here's the current command.

# export OAE_ACCOUNT=efroese
# csshx $OAE_ACCOUNT@oae-performance.sakaiproject.org \
#   $OAE_ACCOUNT@ec2-50-18-147-148.us-west-1.compute.amazonaws.com \
#   $OAE_ACCOUNT@ec2-204-236-168-81.us-west-1.compute.amazonaws.com \
#   $OAE_ACCOUNT@OAE-Preview-2008250595.us-west-1.elb.amazonaws.com:2022 \
#   $OAE_ACCOUNT@OAE-SOLR-426995740.us-west-1.elb.amazonaws.com:2022 \
#   $OAE_ACCOUNT@OAE-Postgres-566174176.us-west-1.elb.amazonaws.com:2022
#
#
###########################################################################
# Apache Load Balancer
node 'oae-apache1.localdomain' inherits oaenode {

    $sslcert_country      = "US"
    $sslcert_state        = "MI"
    $sslcert_locality     = "Ann Arbor"
    $sslcert_organisation = "The Sakai Foundation"

    class { 'apache::ssl': }

    # Headers is not in the default set of enabled modules
    apache::module { 'headers': }
    apache::module { 'deflate': }

    apache::vhost { "${localconfig::http_name}:80":
        template => 'localconfig/vhost-80.conf.erb',
    }

    # Serve trusted content on 443
    apache::vhost-ssl { "${localconfig::http_name}:443":
        sslonly  => true,
    }

    # Serve untrusted content on 443
    apache::vhost-ssl { "${localconfig::http_name_untrusted}:443":
        sslonly  => true,
    }

    # Server pool for trusted content
    apache::balancer { "apache-balancer-oae-app":
        vhost      => "${localconfig::http_name}:443",
        location   => "/",
        locations_noproxy => ['/server-status', '/balancer-manager'],
        proto      => "http",
        members    => $localconfig::apache_lb_members,
        params     => ["retry=20", "min=3", "flushpackets=auto"],
        standbyurl => $localconfig::apache_lb_standbyurl,
        template   => 'localconfig/balancer.erb',
    }

    # Server pool for untrusted content
    apache::balancer { "apache-balancer-oae-app-untrusted":
        vhost      => "${localconfig::http_name_untrusted}:443",
        location   => "/",
        proto      => "http",
        members    => $localconfig::apache_lb_members_untrusted,
        params     => ["retry=20", "min=3", "flushpackets=auto"],
        standbyurl => $localconfig::apache_lb_standbyurl,
    }
    
    class { 'munin::client':
      allowed_ip_regex => '.*'
    }
}

###########################################################################
# OAE app nodes
node oaeappservernode inherits oaenode {

    # YJP variables are for the setenv.sh.erb template executed by oae::app::server to enable YourKit
    $yjp_parent = '/usr/local/yourkit'
    $yjp_filename = 'yjp-11.0.8'
    $yjp_remote_name = 'yjp-11.0.8-linux'
    $yjp_agent_module = "${yjp_parent}/${yjp_filename}/bin/linux-x86-64/libyjpagent.so"
    $yjp_snapshots_dir = "/home/${oae::params::user}/Snapshots"
    
    class { 'oae::app::server':
        downloadurl    => 'http://source.sakaiproject.org/maven2/org/sakaiproject/nakamura/org.sakaiproject.nakamura.app/1.4.0/org.sakaiproject.nakamura.app-1.4.0.jar',
        javamemorymax  => $localconfig::javamemorymax,
        javamemorymin  => $localconfig::javamemorymin,
        javapermsize   => $localconfig::javapermsize,
        javagclog      => 'gc.log',
        setenv_template => 'localconfig/setenv.sh.erb'        
    }
    
    oae::app::server::sling_config {
        "org.sakaiproject.nakamura.lite.storage.jdbc.JDBCStorageClientPool":
        config => {
            'jdbc-url'    => $localconfig::db_url,
            'jdbc-driver' => $localconfig::db_driver,
            'username'    => $localconfig::db_user,
            'password'    => $localconfig::db_password,
        }
    }

    ## Server protection service
    # Separates trusted vs untusted content.
    oae::app::server::sling_config {
        "org.sakaiproject.nakamura.http.usercontent.ServerProtectionServiceImpl":
        config => {
            'disable.protection.for.dev.mode' => false,
            'trusted.hosts'  => [
                "localhost:8080\\ \\=\\ http://localhost:8082",
                "${localconfig::http_name}\\ \\=\\ https://${localconfig::http_name_untrusted}",
                "${localconfig::apache_lb_members[0]}\\ \\=\\ http://${localconfig::apache_lb_members_untrusted[0]}"
            ],
            'trusted.secret' => $localconfig::serverprotectsec,
        }
    }

    ## Solr
    # Specify the client type
    oae::app::server::sling_config {
        "org.sakaiproject.nakamura.solr.SolrServerServiceImpl":
        config => { "solr-impl" => "remote", },
    }

    # Configure the client with the master/slave(s)] info
    oae::app::server::sling_config {
        "org.sakaiproject.nakamura.solr.RemoteSolrClient":
        config => {
            "remoteurl"  => $localconfig::solr_remoteurl,
            "socket.timeout" => 10000,
            "connection.timeout" => 3000,
            "max.total.connections" => 500,
            "max.connections.per.host" => 500,
        },
    }

    ## Clustering
    oae::app::server::sling_config {
        "org.sakaiproject.nakamura.cluster.ClusterTrackingServiceImpl":
        config => {
            'secure-host-url' => "http://${ipaddress}:8081",
        }
    }

    # Clustered Cache
    oae::app::server::sling_config {
        "org.sakaiproject.nakamura.memory.CacheManagerServiceImpl":
        config => {
            'bind-address' => $ipaddress,
        }
    }
    
    # Fix the max-calls limit on SlingMainServlet to avoid artificial boundaries
    oae::app::server::sling_config { 'org.apache.sling.engine.impl.SlingMainServlet':
      config => {
        'sling.max.calls' => 20000
      }
    }
    
    class { 'nfs::client': }
    nfs::mount { '/mnt/sakaioae-files':
        ensure      => present,
        share       => '/export/sakaioae/files',
        mountpoint  => "/mnt/sakaioae-files",
        server      => $localconfig::nfs_server_ip,
    }

    file { "${oae::params::basedir}/store":
        ensure => link,
        target => "/mnt/sakaioae-files/bodies",
        require => Nfs::Mount['/mnt/sakaioae-files'],
    }
    
    class { 'yourkit':
      user            => $oae::params::user,
      group           => $oae::params::user,
      remoteFileName  => $yjp_remote_name,
      localFileName   => $yjp_filename,
      rootDir         => $yjp_parent
    }
    
    file { $yjp_snapshots_dir:
      ensure    => directory,
      owner     => $oae::params::user,
      group     => $oae::params::user,
      mode      => '0755',
    }
}

node 'oae-app0.localdomain' inherits oaeappservernode {

    class { 'oae::app::ehcache':
        peers       => [ $localconfig::app_server1_ip, ],
        tcp_address => $ipaddress,
        remote_object_port => $localconfig::ehcache_remote_object_port,
    }
    
    class { 'munin::server':
      allowed_ip_regex => '.*',
      nodes => [
        { 'name' => 'app0.oae-performance.sakaiproject.org', 'address' => $localconfig::app_server0_external },
        { 'name' => 'app1.oae-performance.sakaiproject.org', 'address' => $localconfig::app_server1_external },
        { 'name' => 'solr.oae-performance.sakaiproject.org', 'address' => $localconfig::solr_master },
        { 'name' => 'postgres.oae-performance.sakaiproject.org', 'address' => $localconfig::db_server },
        { 'name' => 'preview.oae-performance.sakaiproject.org', 'address' => $localconfig::preview_processor_url },
        { 'name' => 'apache.oae-performance.sakaiproject.org', 'address' => $localconfig::http_name }
      ]
    }

}

node 'oae-app1.localdomain' inherits oaeappservernode {

    class { 'oae::app::ehcache':
        peers       => [ $localconfig::app_server0_ip, ],
        tcp_address => $ipaddress,
        remote_object_port => $localconfig::ehcache_remote_object_port,
    }
    
    class { 'munin::client':
      allowed_ip_regex => '.*'
    }
    
    file { "/home/${localconfig::user}/.oae":
      ensure  => directory,
      owner   => $localconfig::user,
      group   => $localconfig::group,
      mode    => 644
    }
    
    file { "/home/${localconfig::user}/.oae/data":
      ensure  => directory,
      owner   => $localconfig::user,
      group   => $localconfig::group,
      mode    => 644,
      require => File["/home/${localconfig::user}/.oae"],
    }
}

###########################################################################
# OAE Solr Nodes
node solrnode inherits oaenode {

    class { 'tomcat6':
        parentdir => "${localconfig::basedir}",
        tomcat_user  => $localconfig::user,
        tomcat_group => $localconfig::group,
        require      => File[$oae::params::basedir],
    }

}

node 'oae-solr0.localdomain' inherits solrnode {

    class { 'solr::tomcat':
        user         => $localconfig::user,
        group        => $localconfig::group,
        tomcat_user  => $localconfig::user,
        tomcat_group => $localconfig::group,
        tomcat_home  => "${localconfig::basedir}/tomcat",
        solr_tarball => 'https://nodeload.github.com/sakaiproject/nakamura/tarball/1.4.0-release-a',
        require      => Class['Tomcat6'],
    }
    
    class { 'munin::client':
      allowed_ip_regex => '.*'
    }
    
    file { "/home/${localconfig::user}/.oae":
      ensure  => directory,
      owner   => $localconfig::user,
      group   => $localconfig::group,
      mode    => 644
    }
    
    file { "/home/${localconfig::user}/.oae/data":
      ensure  => directory,
      owner   => $localconfig::user,
      group   => $localconfig::group,
      mode    => 644,
      require => File["/home/${localconfig::user}/.oae"],
    }

    class { 'cassandra::common': }
}

# node /oae-solr[1-3].localdomain/ inherits solrnode {
# 
#     class { 'solr::tomcat':
#         user         => $localconfig::user,
#         group        => $localconfig::group,
#         master_url   => "${localconfig::solr_remoteurl}/replication",
#         tomcat_user  => $localconfig::user,
#         tomcat_group => $localconfig::group,
#         tomcat_home  => "${localconfig::basedir}/tomcat",
#         solr_tarball => 'http://nodeload.github.com/sakaiproject/solr/tarball/org.sakaiproject.nakamura.solr-1.4.2',
#         require      => Class['Tomcat6'],
#     }
# }

###########################################################################
# OAE Content Preview Processor Node
node 'oae-preview.localdomain' inherits oaenode {
    class { 'oae::preview_processor::init':
        upload_url   => "https://${localconfig::http_name}/",
    }
    
    class { 'munin::client':
      allowed_ip_regex => '.*'
    }

    class { 'cassandra::common': }
}

###########################################################################
# NFS Server
node 'oae-nfs.localdomain' inherits oaenode {

    class { 'nfs::server': }

    nfs::export { 'export-sakai-files-app0-app1-rw':
        ensure  => present,
        share   => '/export/sakaioae/files',
        options => 'rw',
        guests   => [
            [ $localconfig::app_server0_ip, 'rw' ],
            [ $localconfig::app_server1_ip, 'rw' ],
        ],
    }

    file { '/export': ensure => directory }
    file { '/export/sakaioae/': ensure => directory, require => File['/export'] }
    file { '/export/sakaioae/files': ensure => directory, require => File['/export/sakaioae'] }
    file { '/export/sakaioae/files/bodies':
        ensure => directory,
        owner  => $oae::params::user,
        group  => $oae::params::group,
        require => File['/export/sakaioae'],
    }
}

###########################################################################
# Postgres Database Server
node 'oae-db0.localdomain' inherits oaenode {

    $db           = $localconfig::db
    $db_user      = $localconfig::db_user
    $db_password  = $localconfig::db_password

    class { 'postgres::repos': stage => init }
    class { 'postgres': }

    postgres::database { $db:
        ensure => present,
        require => Class['Postgres'],
    }

    postgres::role { $db_user:
        ensure   => present,
        password => $db_password,
        require  => Postgres::Database[$db],
    }

    postgres::role { 'nakrole':
        ensure   => present,
        password => $db_password,
        require  => Postgres::Database[$db],
    }

    postgres::clientauth { "all-md5":
       type => 'host',
       db   => $db,
       user => $db_user,
       address => "0.0.0.0/0",
       method  => 'md5',
    }

    postgres::clientauth { "all-ident":
       type => 'host',
       db   => $db,
       user => $db_user,
       address => "0.0.0.0/32",
       method  => 'ident',
    }
 
    postgres::backup::simple { $db: }
    
    class { 'munin::client':
      allowed_ip_regex => '.*'
    }
    
    # Add DB user automation scripts and environment
    file { "/home/${localconfig::user}/.pgpass":
      ensure  => present,
      owner   => $localconfig::user,
      group   => $localconfig::group,
      mode    => 600,
      content => template('localconfig/pgpass.erb')
    }
    
    file { "/home/${localconfig::user}/.oae":
      ensure  => directory,
      owner   => $localconfig::user,
      group   => $localconfig::group,
      mode    => 644
    }
    
    file { "/home/${localconfig::user}/.oae/scripts":
      ensure  => directory,
      owner   => $localconfig::user,
      group   => $localconfig::group,
      mode    => 644,
      require => File["/home/${localconfig::user}/.oae"],
    }
    
    file { "/home/${localconfig::user}/.oae/data":
      ensure  => directory,
      owner   => $localconfig::user,
      group   => $localconfig::group,
      mode    => 644,
      require => File["/home/${localconfig::user}/.oae"],
    }
    
    file { "/home/${localconfig::user}/.oae/scripts/drop_all_tables.sql":
      ensure  => present,
      owner   => $localconfig::user,
      group   => $localconfig::group,
      mode    => 644,
      content => template("localconfig/drop_all_tables.sql.erb"),
      require => File["/home/${localconfig::user}/.oae/scripts"],
    }

    class { 'cassandra::common': }
}
