# Class: windows_ad for Windows 2008 R2, 2012, 2012 R2, 2016
#
# Full description of windows_ad::install here.
#
# This class allow you to install/uninstall a windows domain services roles ADDS
#
# When you use this class please use it with windows_ad directly. see the readme file.
#
# === Parameters
#
#
# === Examples
# 
#  class{'windows_ad::install':
#    ensure                 => present,
#    installmanagementtools => true,
#    installsubfeatures     => true,
#    restart                => true,
#    installflag            => false,
#  }
#
# === Authors
#
# Jerome RIVIERE (www.jerome-riviere.re)
#
# === Copyright
#
# Copyright 2014 Jerome RIVIERE.
#
class windows_ad::install (
    Enum['present', 'absent'] $ensure = $ensure,
    Boolean $installmanagementtools   = $installmanagementtools,
    Boolean $installsubfeatures       = $installsubfeatures,
    Boolean $restart                  = $restart,
    Boolean $installflag              = $installflag,
) {

  if ($installflag == true){
    if $::operatingsystem != 'windows' { fail ("${module_name} not supported on ${::operatingsystem}") }

    $restartbool = $restart ? {
      true  => true,
      false => false,
      default => false,
    }
    # if $restart { $restartbool = true } else { $restartbool = false }
    $subfeatures = $installsubfeatures ? {
      false => undef,
      true  => '-IncludeAllSubFeature',
    }
    # if $installsubfeatures { $subfeatures = '-IncludeAllSubFeature' }

    # if $::kernelversion =~ /^(6.1)/ and $installmanagementtools {
    #   fail ('Windows 2012 or newer is required to use the installmanagementtools parameter')
    # } elsif $installmanagementtools {
    #   $managementtools = '-IncludeManagementTools'
    # }

    # Kernel versions allowed for installation: Windows server 2008 R2, 2012, 2012 R2, 2016
    if $::kernelversion !~ /^(6\.1|6\.2|6\.3|10)/ { fail ("${module_name} requires Windows 2008 R2 or newer") }

    # from Windows 2008 R2 install with 'Add-WindowsFeature' http://technet.microsoft.com/en-us/library/ee662309.aspx
    # from Windows 2012 and 2016 'Add-WindowsFeature' has been replaced with 'Install-WindowsFeature' http://technet.microsoft.com/en-us/library/ee662309.aspx
    if ($ensure == 'present') {
      if $::kernelversion =~ /^(6.1)/ {
        $command = 'Add-WindowsFeature'
        if $installmanagementtools {fail ('Windows 2012 or newer is required to use the installmanagementtools parameter')}
      } else {
        $command = 'Install-WindowsFeature'
        if $installmanagementtools {$managementtools = '-IncludeManagementTools'}
        }

      exec { "add-feature-${title}":
        command  => "Import-Module ServerManager; ${command} AD-Domain-Services ${managementtools} ${subfeatures} -Restart:$${restartbool}",
        onlyif   => "Import-Module ServerManager; if (@(Get-WindowsFeature AD-Domain-Services | ?{\$_.Installed -match \'false\'}).count -eq 0) { exit 1 }", # lint:ignore:140chars
        provider => powershell,
      }
    } elsif ($ensure == 'absent') {
      exec { "remove-feature-${title}":
        command  => "Import-Module ServerManager; Remove-WindowsFeature AD-Domain-Services -Restart:$${restartbool}",
        onlyif   => "Import-Module ServerManager; if (@(Get-WindowsFeature AD-Domain-Services |?{\$_.Installed -match \'true\'}).count -eq 0) { exit 1 }", # lint:ignore:140chars
        provider => powershell,
      }
    }
  }
}
