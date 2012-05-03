#
# User resources for sakai
#
class people::groups {

    Class['Localconfig'] -> Class['People::Groups']

    # rsmart
	@group { "${localconfig::group}":
		gid => $localconfig::gid,
	}

    # Real live human beings!
    @group { 'lspeelmon': gid => '501' }
    @group { 'dthomson':  gid => '502' }
    @group { 'cramaker':  gid => '503' }
    @group { 'efroese':   gid => '504' }
    @group { 'kcampos':   gid => '505' }
    @group { 'dgillman':  gid => '506' }
    @group { 'mdesimone': gid => '507' }
    @group { 'mflitsch':  gid => '508' }
    @group { 'karagon':   gid => '509' }
    @group { 'ppilli':    gid => '510' }
    @group { 'jbush':     gid => '511' }
    @group { 'skamali':   gid => '512' }
    @group { 'lbassett':  gid => '513' }

    # Services/Applications/Robots/Aliens
    @group { 'hyperic':   gid => '701' }
    @group { 'rsmartian':   gid => '800' }
    @group { 'devops':   gid => '900' }
}
