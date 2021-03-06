class people {

        Class['Localconfig'] -> Class['People']

        class { 'people::groups': }
        class { 'people::users': }

        realize(User[$localconfig::user])

        realize(User['branden'])
        realize(Ssh_authorized_key['branden-public'])

        realize(User['aberg'])
        realize(Ssh_authorized_key['aberg-public'])

        realize(User['denbuzze'])
        realize(Ssh_authorized_key['denbuzze-public'])
        
        realize(User['zach'])
        realize(Ssh_authorized_key['zach-public'])
        
        realize(User['ctweney'])
        realize(Ssh_authorized_key['ctweney-public'])
        
        realize(User['chall'])
        realize(Ssh_authorized_key['chall-public'])
        
        realize(User['raydavis'])
        realize(Ssh_authorized_key['raydavis-public'])
        
        realize(User['arwhyte'])
        realize(Ssh_authorized_key['arwhyte-public'])

        realize(User['stuart'])
        realize(Ssh_authorized_key['stuart-public'])

        realize(User['simong'])
        realize(Ssh_authorized_key['simong-public'])
        
        realize(User['nicolaasmatthijs'])
        realize(Ssh_authorized_key['nicolaasmatthijs-public'])

        realize(Ssh_authorized_key['ec2-user-public'])
}
