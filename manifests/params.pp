# params for openvpn_as!
class openvpn_as::params {
  $active_profile = 'Default'
  $as_conf = {}
  $config_force = false
  $exec_path = '/usr/local/openvpn_as/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/usr/local/openvpn_as/bin'
  $ovpn_dir = '/usr/local/openvpn_as'
  $ovpn_init = true
  $ovpn_init_force = false
  $profiles = {}
  $userprops = {}
  # Dependency
  $jq_install = false
  $rsync_install = false
  # Package
  $package_ensure = 'installed'
  $package_name = 'openvpn-as'
  $package_provider =  undef
  $package_source = undef
  # Service
  $service_ensure = 'running'
  $service_manage = true
  $service_name = 'openvpnas'
}
