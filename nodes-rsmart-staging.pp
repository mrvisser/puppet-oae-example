###########################################################################
#
# Nodes
#
# make sure that modules/localconfig -> modules/rsmart-config-m1
# see modules/rsmart-config-m1/manifests.init.pp for the config.


###########################################################################
#
# Apache load balancer
#

node 'staging-apache[1-2].rsmart.local' inherits oaenode {
}

###########################################################################
#
# OAE app nodes
#
node /staging-app[1-2].rsmart.local/ inherits oaenode {

    $http_name = $localconfig::apache_lb_http_name

    class { 'oae::app::server':
        version_oae    => $localconfig::version_oae,
        downloaddir    => $localconfig::downloaddir,
        jarfile        => $localconfig::jarfile,
        javamemorymax  => $localconfig::javamemorymax,
        javapermsize   => $localconfig::javapermsize,
    }

    class { 'oae::core':
         url    => $localconfig::db_url,
         driver => $localconfig::db_driver,
         user   => $localconfig::db_user,
         pass   => $localconfig::db_password,
    }

    class { 'oae::app::ehcache':
        mcast_address => $localconfig::mcast_address,
        mcast_port    => $localconfig::mcast_port,
    }
    
    oae::app::server::sling_config { "org/sakaiproject/nakamura/lite/storage/jdbc/JDBCStorageClientPool.config":
            dirname => "org/sakaiproject/nakamura/lite/storage/jdbc",
            config => {
                'jdbc-driver' => $localconfig::db_driver,
                'jdbc-url'    => $localconfig::db_url,
                'username'    => $localconfig::db_user,
                'password'    => $localconfig::db_password,
                'long-string-size' => 16384
                'store-base-dir'   => "save/files"
            }
        }

        # Separates trusted vs untusted content.
        oae::app::server::sling_config { "org/sakaiproject/nakamura/http/usercontent/ServerProtectionServiceImpl.config":
            dirname => "org/sakaiproject/nakamura/http/usercontent",
            config => {
                'disable.protection.for.dev.mode' => false,
                'trusted.hosts'  => [
                    "localhost\\ \\=\\ https://localhost:8443", 
                    "${http_name}\\ \\=\\ https://${http_name}:8443",
                ],
                'trusted.secret' => $localconfig::serverprotectsec,
            }
        }

        # Solr Client
        oae::app::server::sling_config { "org/sakaiproject/nakamura/solr/MultiMasterRemoteSolrClient.config":
            dirname => "org/sakaiproject/nakamura/solr",
            config => {
                "remoteurl"  => $localconfig::solr_remoteurl,
                "query-urls" => $localconfig::solr_queryurls,
            }
        }

        # Specify the client type
        oae::app::server::sling_config { "org/sakaiproject/nakamura/solr/SolrServerServiceImpl.config":
            dirname => "org/sakaiproject/nakamura/solr",
            config => {
                "solr-impl" => "multiremote",
            }
        }

        # Clustering
        oae::app::server::sling_config { "org/sakaiproject/nakamura/cluster/ClusterTrackingServiceImpl.config":
            dirname => 'org/sakaiproject/nakamura/cluster',
            config => {
                'secure-host-url' => "http://${ipaddress}:8081",
            }
        }

        # Clustered Cache
        oae::app::server::sling_config { "org/sakaiproject/nakamura/memory/CacheManagerServiceImpl.config":
            dirname => 'org/sakaiproject/nakamura/memory',
            config => {
                'bind-address' => $ipaddress,
            }
        }

    oae::app::server::sling_config { "org/sakaiproject/nakamura/basiclti/CLEVirtualToolDataProvider.config":
        dirname => "org/sakaiproject/nakamura/basiclti",
        config => {
            'sakai.cle.basiclti.secret' => "secret"
            'sakai.cle.server.url'      => "https://${http_name}"
            'sakai.cle.basiclti.key'    => "12345"
        }
    }
}

###########################################################################
#
# OAE Solr Nodes
#

node 'staging-solr1.rsmart.local' inherits oaenode {
    class { 'oae::solr': 
        master_url => "${localconfig::solr_remoteurl}/replication",
        solrconfig => 'localconfig/master-solrconfig.xml.erb',
    }
}

###########################################################################
#
# OAE Content Preview Processor Node
#
node 'staging-preview.rsmart.local' inherits oaenode {
    class { 'oae::preview_processor::init': 
        nakamura_git => $localconfig::nakamura_git,
        nakamura_tag => $localconfig::nakamura_tag,
    }
}
