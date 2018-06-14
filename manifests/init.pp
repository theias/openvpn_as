# openvpn_as
#
# A description of what this class does
#
#
# If you don't have a working openvpn_as cluster, use this module to install
# and initalize one. Then configure them via the GUI and use the values it created in the 
# config DB to manage the config profiles via this module.
# Here is a one-liner to turn your current config db into yaml (to easily place it into hieradata)
# /<openvpn_as directory>/scripts/confdba --show |  ruby -e "require 'json'; require 'yaml'; print YAML.dump(JSON.load(ARGF.read()))"
#
#
# @summary A short summary of the purpose of this class
#
# @example
#   include openvpn_as
class openvpn_as (
  String                                       $active_profile = $openvpn_as::params::active_profile,
  Hash                                         $as_conf = $openvpn_as::params::as_conf,
  Boolean                                      $config_force = $openvpn_as::params::config_force,
  String                                       $exec_path = $openvpn_as::params::exec_path,
  String                                       $ovpn_dir = $openvpn_as::params::ovpn_dir,
  Boolean                                      $ovpn_init = $openvpn_as::params::ovpn_init,
  Boolean                                      $ovpn_init_force = $openvpn_as::params::ovpn_init_force,
  Variant[Hash, Undef]                         $profiles = $openvpn_as::params::profiles,
  Variant[Hash, Undef]                         $userprops = $openvpn_as::params::userprops,
  # Dependency
  Boolean                                      $jq_install = $openvpn_as::params::jq_install,
  Boolean                                      $rsync_install = $openvpn_as::params::rsync_install,
  # Package
  Variant[Boolean, String]                     $package_ensure = $openvpn_as::params::package_ensure,
  String                                       $package_name = $openvpn_as::params::package_name,
  Variant[String, Undef]                       $package_provider = $openvpn_as::params::package_provider,
  Variant[String, Undef]                       $package_source = $openvpn_as::params::package_source,
  # Service
  Variant[Boolean, Enum['stopped', 'running']] $service_ensure = $openvpn_as::params::service_ensure,
  Boolean                                      $service_manage = $openvpn_as::params::service_manage,
  String                                       $service_name = $openvpn_as::params::service_name,
) inherits openvpn_as::params {
  include stdlib
  # Preconfig
  if jq_install {
    ensure_packages(['jq'], {'ensure' => 'present'})
  }
  if rsync_install {
    ensure_packages(['rsync'], {'ensure' => 'present'})
  }

  # Install the package first
  class { 'openvpn_as::package':
    package_ensure   => $package_ensure,
    package_name     => $package_name,
    package_provider => $package_provider,
    package_source   => $package_source,
  }
  Class['openvpn_as::package']
  -> Class['openvpn_as']

  # Init
  # if requested, ensure openvpn-as gets initialized once
  if $ovpn_init {
    $force_str = $ovpn_init_force ? {
      true => '--force',
      false => '',
    }
    # Drop this file on the system to indicate that we have initialized openvpn-as
    file { "${ovpn_dir}/.init":
      ensure => 'present',
    }
    ~> exec { "${::fqdn}_init_opevpnas":
      path        => $exec_path,
      command     => "ovpn-init ${force_str} --batch",
      refreshonly => true,
    }
  }

  # Configure things
  # Only notify the openvnpas service if we're managing the service
  $notify = $service_manage ? {
    true => Service[$service_name],
    false => undef,
  }
  # as.conf
  file { "${ovpn_dir}/etc/as.conf":
    content => epp('openvpn_as/usr/local/openvpn_as/etc/as.conf.epp', $as_conf)
  }
  # Tmp dir to put configs to feed into confdba
  $tmp_dir = "${ovpn_dir}/tmp"
  file { $tmp_dir:
    ensure  => 'directory',
    mode    => '0600',
    require => Package[$package_name],
  }

  if $config_force {
    # Here do not check any values of any config or userprop keys; just set what was given.
    # Setting of configuration in this manner is EXCLUSIVE and any keys not specified
    # per profile will disappear from the server's configuration
    # and will probably always restart the openvpn service with each run

    # General config
    $cfg_filepath = "${tmp_dir}/.forceconfig.json"
    file { $cfg_filepath:
      ensure  => 'file',
      mode    => '0600',
      content => to_json($profiles),
    }
    ~> exec { "${::fqdn}_config_force":
      path        => $exec_path,
      command     => "confdba --load --file='${cfg_filepath}' ",
      refreshonly => true,
      notify      => $notify,
    }

    # User/group config
    $ucfg_filepath = "${tmp_dir}/.forceuserdb.json"
    file { $ucfg_filepath:
      ensure  => 'file',
      mode    => '0600',
      content => to_json($userprops),
    }
    ~> exec { "${::fqdn}_userdb_force":
      path        => $exec_path,
      command     => "confdba --load --userdb --file='${ucfg_filepath}'",
      refreshonly => true,
      notify      => $notify,
    }

    # Set active profile
    exec { "${::fqdn}_active_profile__force_${active_profile}":
      path    => $exec_path,
      command => "confdba --prof ${active_profile} --setact",
      notify  => $notify,
    }
  } else {
    # Here carefully compare given key values against current settings and only make
    # any changes to the individual keys if the setting doesn't match
    # Also then notify the service to restart if any changes made
    Openvpn_as::Confdba {
      exec_path => $exec_path,
      notify => $notify,
      ovpn_dir => $ovpn_dir,
    }
    # Config profiles
    openvpn_as::confdba { 'configure_profiles':
      profiles  => $profiles,
    }
    # Userprops
    openvpn_as::confdba { 'configure_userprops':
      profiles => $userprops,
      userdb   => true,
    }

    # Set active profile unless matches
    exec { "${::fqdn}_set_active_profile_${active_profile}":
      command => "confdba --prof ${active_profile} --setact",
      notify  => $notify,
      path    => $exec_path,
      unless  => "confdba --showact | jq -e '.[\"${active_profile}\"] != null'",
    }
  }

  # Service
  if $service_manage {
    service { $service_name:
      ensure => $service_ensure,
    }
  }
}
