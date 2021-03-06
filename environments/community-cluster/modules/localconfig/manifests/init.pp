#
# Use this class to configure a specific OAE cluster.
# In your nodes file refer to these variables as $localconfig::variable_name.
#
class localconfig {

    ###########################################################################
    # OS
    $user    = 'sakaioae'
    $group   = 'sakaioae'
    $uid     = 8080
    $gid     = 8080
    $basedir = '/usr/local/sakaioae'

    ###########################################################################
    # Database setup
    $db          = 'nakamura'
    $db_server   = 'OAE-Postgres-566174176.us-west-1.elb.amazonaws.com'
    $db_url      = "jdbc:postgresql://${db_server}/${db}?charSet\\=UTF-8&tcpKeepAlive\\=true"
    $db_driver   = 'org.postgresql.Driver'
    $db_user     = 'nakamura'
    $db_password = 'ironchef'

    ###########################################################################
    # App servers
    #$app_server0 = 'ec2-50-18-147-148.us-west-1.compute.amazonaws.com'
    #$app_server1 = 'ec2-204-236-168-81.us-west-1.compute.amazonaws.com'
    $app_server0 = 'ip-10-168-9-8.us-west-1.compute.internal'
    $app_server1 = 'ip-10-168-249-50.us-west-1.compute.internal'

    $app_server0_external = 'ec2-50-18-147-148.us-west-1.compute.amazonaws.com'
    $app_server1_external = 'ec2-204-236-168-81.us-west-1.compute.amazonaws.com'

    # These will eventually change.
    $app_server0_ip = dnsLookup($app_server0)
    $app_server1_ip = dnsLookup($app_server1)

    # ELBs for trusted and untrusted content
    $http_name              = 'oae-performance.sakaiproject.org'
    $http_name_untrusted    = 'content-oae-performance.sakaiproject.org'

    $apache_lb_members = ['oae-appservers-365563856.us-west-1.elb.amazonaws.com:8080']
    $apache_lb_members_untrusted = ['oae-appservers-untrusted-414965918.us-west-1.elb.amazonaws.com:8082']
    $apache_lb_standbyurl = ""

    $javamemorymax = '4096'
    $javamemorymin = '4096'
    $javapermsize  = '512'

    # oae server protection service
    $serverprotectsec = 'pi34ht5p395hc24nw4tbc42twh'

    # Solr
    $solr_master = 'OAE-SOLR-426995740.us-west-1.elb.amazonaws.com'
    $solr_remoteurl = "http://${solr_master}:8080/solr"

    # EHcache
    $ehcache_remote_object_port = '40002'

    # NFS
    $nfs_server_ip = '10.171.118.239'
    
    # Preview Processor
    $preview_processor_url = 'OAE-Preview-2008250595.us-west-1.elb.amazonaws.com'
    # Cassandra
    $cassandra_seed1 = dnsLookup($preview_processor_url)
    $cassandra_seed2 = dnsLookup($solr_master)
    $cassandra_seed3 = dnsLookup($db_server)
    $cassandra_seeds = "${cassandra_seed1},${cassandra_seed2},${cassandra_seed3}"
    $cassandra_cluster_name = "OAE Test Cluster"
}
