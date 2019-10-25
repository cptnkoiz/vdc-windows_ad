#
# Help can be found in readme.md for a global help
#
# === Authors
#
# Jerome RIVIERE (www.jerome-riviere.re)
#
# === Copyright
#
# Copyright 2014 Jerome RIVIERE.
#
class windows_ad (
  #######################
  ### part install AD ###
  #######################
  # when present install process will be set. if already install nothing done
  # when absent uninstall will be launch
  Enum['present', 'absent']$install = 'present',
  Boolean $installmanagementtools   = true,
  Boolean $installsubfeatures       = false,
  Boolean $restart                  = false,
  Boolean $installflag              = true,           # Flag to bypass the install of AD if desired

  ##################################
  ### Part Configure AD - Global ###
  ##################################
  # when present configure process will be done. if already configure nothing done
  # absent don't do anything right now
  Enum['present', 'absent']$configure = 'present',
  String $domain                      = 'forest',
  Optional[String] $domainname        = undef,        # FQDN
  Optional[String] $netbiosdomainname = undef,        # FQDN
  Boolean $configureflag              = true,         # Flag to bypass the configuration of AD if desired

  #level AD
  Integer[4,6] $domainlevel  = 6,                     # Domain level {4 - Server 2008 R2 | 5 - Server 2012 | 6 - Server 2012 R2}
  Integer[4,6] $forestlevel  = 6,                     # Domain level {4 - Server 2008 R2 | 5 - Server 2012 | 6 - Server 2012 R2}

  Variant[Enum['true','false'],Boolean] $installdns    = true,                   # Add DNS Server Role
  String $globalcatalog                                = 'yes',                  # Add Global Catalog functionality
  String $kernel_ver                                   = $::kernelversion,

  # Installation Directories
  # TODO Probar Absolutepath, es del módulo stdlib
  String $databasepath       = 'c:\\windows\\ntds',   # Active Directory database path
  String $logpath            = 'c:\\windows\\ntds',   # Active Directory log path
  String $sysvolpath         = 'c:\\windows\\sysvol', # Active Directory sysvol path

  Optional[String] $dsrmpassword   = undef,

  ##################################
  ### Part Configure AD - Forest ###
  ##################################
  #uninstall forest
  Optional[String] $localadminpassword = undef,
  Boolean $force                       = true,
  Boolean $forceremoval                = true,
  String $uninstalldnsrole             = 'yes',
  Boolean $demoteoperationmasterrole   = true,

  #################################
  ### Part Configure AD - Other ###
  #################################
  Optional[String] $secure_string_pwd  = undef,
  Optional[String] $installtype        = undef,          # New domain or replica of existing domain {replica | domain}
  Optional[String] $domaintype         = undef,          # lint:ignore:140chars # Type of domain {Tree | Child | Forest} (New domain tree in an existing forest, child domain, or new forest) 
  Optional[String] $sitename           = undef,          # Site Name

  ### Define Hiera hashes ###
  Optional[Hash] $groups             = undef,
  Boolean $groups_hiera_merge        = true,
  Optional[Hash] $users              = undef,
  Boolean $users_hiera_merge         = true,
  Optional[Hash] $usersingroup       = undef,
  Boolean $usersingroup_hiera_merge  = true,
) {

  $install_dns = $installdns ? {
    'true'  => true,
    true    => true,
    'false' => false,
    false   => false,
    default => fail("Los valores introducidos en hiera son incorrectos. Valor introducido: ${installdns}"),
  }

  class{'windows_ad::install':
    ensure                 => $install,
    installmanagementtools => $installmanagementtools,
    installsubfeatures     => $installsubfeatures,
    restart                => $restart,
    installflag            => $installflag,
  }

  class{'windows_ad::conf_forest':
    ensure                    => $configure,
    domainname                => $domainname,
    netbiosdomainname         => $netbiosdomainname,
    domainlevel               => $domainlevel,
    forestlevel               => $forestlevel,
    globalcatalog             => $globalcatalog,
    databasepath              => $databasepath,
    logpath                   => $logpath,
    sysvolpath                => $sysvolpath,
    dsrmpassword              => $dsrmpassword,
    installdns                => $install_dns,
    kernel_ver                => $kernel_ver,
    localadminpassword        => $localadminpassword,
    force                     => $force,
    forceremoval              => $forceremoval,
    uninstalldnsrole          => $uninstalldnsrole,
    demoteoperationmasterrole => $demoteoperationmasterrole,
    configureflag             => $configureflag,
  }
  if($installflag or $configureflag){
    if($install == present){
      anchor{'windows_ad::begin':}
      -> Class['windows_ad::install']
      -> Class['windows_ad::conf_forest']
      -> anchor{'windows_ad::end':}
      -> Windows_ad::Organisationalunit <| |>
      -> Windows_ad::Group <| |>
      -> Windows_ad::User <| |>
      -> Windows_ad::Groupmembers <| |>
    }else{
      if($configure == present){
        fail('You can\'t desactivate the Role ADDS without uninstall ADDSControllerDomain first')
      }else{
        anchor{'windows_ad::begin':}
        -> Class['windows_ad::conf_forest']
        -> Class['windows_ad::install']
        -> anchor{'windows_ad::end':}
      }
    }
  }else{
    anchor{'windows_ad::begin':}
    -> Windows_ad::Organisationalunit <| |>
    -> Windows_ad::Group <| |>
    -> Windows_ad::User <| |>
    -> Windows_ad::Groupmembers <| |>
    -> anchor{'windows_ad::end':}
  }

  if $groups != undef {
    if $groups_hiera_merge == true {
      $groups_real = hiera_hash('windows_ad::groups')
    } else {
      $groups_real = $groups
    }
    create_resources('windows_ad::group',$groups_real)
  }

  if $users != undef {
    if $users_hiera_merge == true {
      $users_real = hiera_hash('windows_ad::users')
    } else {
      $users_real = $users
    }
    create_resources('windows_ad::user',$users_real)
  }


  if $usersingroup != undef {
    if $usersingroup_hiera_merge == true {
      $usersingroup_real = hiera_hash('windows_ad::usersingroup')
    } else {
      $usersingroup_real = $usersingroup
    }
    create_resources('windows_ad::groupmembers',$usersingroup_real)
  }

}
