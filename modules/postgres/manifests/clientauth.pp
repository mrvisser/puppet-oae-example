# = Class: postgres::clientauth
#
# Manage postgres client authentication
#
# == Parameters:
#
# $type::    Authenitcation type
#
# $db::      The database name
#
# $user::    The user name
#
# $address:: Where the user can authenticate from
#
# $method::  The authentication method
#
# $option::  Other options (optional)
#
# == Actions:
#   Add a clientauth ine to pg_hba.conf
#
define postgres::clientauth (
    $type,
    $db,
    $user,
    $address,
    $method,
    $option=""
    ) {

    if $option == "" {
        $config_line = "${type} ${db} ${user} ${address} ${method}"
    }
    else {
        $config_line = "${type} ${db} ${user} ${address} ${method} ${option}"
    }

    $hba_conf = '/var/lib/pgsql/9.1/data/pg_hba.conf'

    exec { "append-${config_line}-to-${hba_conf}":
        command => "echo ${config_line} >> ${hba_conf}",
        unless  => "grep '${config_line}' ${hba_conf}",
        notify  => Service['postgresql-9.1'],
    }
}