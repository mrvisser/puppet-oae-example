class localconfig::hosts {
    # rSmart OAE 1.1 staging cluster 

    host { 'staging-apache1':
        # 50.18.195.239  -> 10.53.9.10      load balancer (apache)
        ensure => present,
        ip => '10.53.9.10',
        host_aliases => 'staging-apache1.academic.rsmart.local',
        comment => 'Apache load balancer'
    }

    host { 'staging-app1':
        ensure => present,
        ip => '10.53.10.16',
        host_aliases => 'staging-app1.academic.rsmart.local',
        comment => 'OAE app server'
    }

    host { 'staging-app2':
        ensure => present,
        ip => '10.53.10.20',
        host_aliases => 'staging-app2.academic.rsmart.local',
        comment => 'OAE app server'
    }

    host { 'staging-cle':
        ensure => present,
        ip => '10.53.10.17',
        host_aliases => 'staging-cle.academic.rsmart.local',
        comment => 'CLE server'
    }

    host { 'staging-dbserv1':
        ensure => present,
        ip => '10.53.10.10',
        host_aliases => 'staging-dbserv1.academic.rsmart.local',
        comment => 'Database master',
    }

    host { 'staging-dbserv2':
        ensure => present,
        ip => '10.53.10.11',
        host_aliases => 'staging-dbserv2.academic.rsmart.local',
        comment => 'Database slave',
    }

    host { 'staging-solr1':
        ensure => present,
        ip => '10.53.10.21',
        host_aliases => 'staging-solr1.academic.rsmart.local',
        comment => 'Solr master',
    }

    host { 'staging-nfs':
        ensure => present,
        ip => '10.53.10.13',
        host_aliases => 'staging-nfs.academic.rsmart.local',
        comment => 'NFS server',
    }

    host { 'staging-preview':
    ensure => present,
        ip => '10.53.10.14',
        host_aliases => 'staging-preview.academic.rsmart.local',
        comment => 'Preview processor',
    }

    host { 'staging-appdyn':
        ensure => present,
        ip => '10.53.10.18',
        host_aliases => 'staging-appdyn.academic.rsmart.local',
        comment => 'AppDynamics Controller/Hyperic',
    }
}
