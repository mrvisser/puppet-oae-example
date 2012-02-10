###########################################################################
#
# Node Type Definitions
#
node basenode {

    if $operatingsystem =~ /Redhat|CentOS/ {
        if $virtual == "virtualbox" {
            class { 'centos_minimal': stage => init }
        }
    }

    if $operatingsystem =~ /Amazon|Linux/ {
        class { 'centos': stage => init }
    }

    class { 'git': }
    class { 'java': }
    class { 'ntp':
        time_zone =>  '/usr/share/zoneinfo/America/Phoenix',
    }

    realize(Group['hyperic'])
    realize(User['hyperic'])

    realize(Group['efroese'])
    realize(User['efroese'])

    realize(Group['lspeelmon'])
    realize(User['lspeelmon'])

    realize(Group['dgillman'])
    realize(User['dgillman'])

    realize(Group['cramaker'])
    realize(User['cramaker'])
    
    realize(Group['dthomson'])
    realize(User['dthomson'])
}

node oaenode inherits basenode {

    # OAE cluster-specific configuration
    class { 'localconfig': }
    class { 'localconfig::hosts': }
    class { 'localconfig::users': }

    # OAE module configuration
    class { 'oae::params':
        user    => $localconfig::user,
        group   => $localconfig::group,
        basedir => $localconfig::basedir,
    }
}
