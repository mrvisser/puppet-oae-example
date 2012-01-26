#
# Use this class to configure a specific OAE cluster.
# In your nodes file refer to these variables as $localconfig::variable_name.
#
class localconfig {
    
    Class['localconfig::hosts'] -> Class['localconfig']

    ###########################################################################
    # OS
    $user    = 'rsmart'
    $group   = 'rsmart'
    $uid     = 500
    $gid     = 500
    $basedir = '/home/rsmart/sakaioae'

    ###########################################################################
    # Nodes
    
    # prod-app1
    $app_server1 = '10.52.11.100'
    # prod-app2
    $app_server2 = '10.52.11.101'
    # prod-nfs
    $nfs_server  = '10.52.11.90'
    # prod-dbserv1
    $db_server   = '10.52.11.70'
    # solr master server
    $solr_master = '10.52.11.30'

	# prod-cle
    $cle_server  = '10.53.10.17'

    ###########################################################################
    # Database setup
    $db          = 'nak'
    $db_url      = "jdbc:postgresql://${db_server}/${db}?charSet\\=UTF-8"
    $db_driver   = 'org.postgresql.Driver'
    $db_user     = 'nakamura'
    $db_password = 'ironchef'

    ###########################################################################
    $storedir    = "/files-academic"
    $nfs_share   = '/files-academic'
    $nfs_options = '_netdev,rw,rsize=8192,wsize=8192'

    ###########################################################################
    # Git (Preview processor)
    $nakamura_git = "http://github.com/rsmart/nakamura.git"
    $nakamura_tag = "1.1"

    ###########################################################################
    # Apache load balancer
    $http_name                   = 'prod2.academic.rsmart.com'
    $apache_lb_members           = [ "${app_server1}:8080", "${app_server2}:8080" ]
    $apache_lb_members_untrusted = [ "${app_server1}:8082", "${app_server2}:8082" ]
    
    $apache_cle_lb_members = [ "${cle_server}:8009 route=cle1", "${cle_server}:8010 route=cle2" ]
    $apache_cle_location_match = "^/(xsl-portal.*|access.*|courier.*|dav.*|direct.*|imsblti.*|library.*|messageforums-tool.*|osp-common-tool.*|polls-tool.*|portal.*|profile-tool.*|profile2-tool.*|sakai.*|samigo-app.*|scheduler-tool.*|rsmart-customizer-tool.*|oauth-tool.*|emailtemplateservice-tool.*|sitestats-tool.*|rsmart-support-tool.*|mailsender-tool.*|tool.css|portool_base.css)"
    $cle_dav_server0 = '10.53.10.19'

    ###########################################################################
    # App servers
    $jarsource     = '/home/rsmart/com.rsmart.academic.app-1.1.0-M1-QA1.jar'
    $jarfile       = 'com.rsmart.academic.app-1.1.0-M1-QA1.jar'
    $java          = '/usr/java/jdk1.6.0_30/bin/java'
    $javamemorymax = '4096'
    $javamemorymin = '4096'
    $javapermsize  = '256'

    # These hosts can access /system/console
    $oae_admin_hosts = ['72.44.192.164', ]

    # oae server protection service
    $serverprotectsec = 'ljgfh259w4tyfknjslkdg0134tjna'

    # ehcache
    $ehcache_tcp_port = '40001'
    $ehcache_remote_object_port = '40002'

    # solr
    $solr_remoteurl = "http://${solr_master}:8080/solr"
    $solr_queryurls = "http://${solr_master}:8080/solr|http://${solr_slave0}:8080/solr|http://${solr_slave1}:8080/solr"

    $tomcat_user    = 'admin'
    $tomcat_password = 'pulp134@rain'
}