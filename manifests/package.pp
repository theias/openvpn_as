# Install openvpn_as package
class openvpn_as::package (
  Variant[Boolean, String]                     $package_ensure = $openvpn_as::params::package_ensure,
  String                                       $package_name = $openvpn_as::params::package_name,
  Variant[Undef, String]                       $package_provider = $openvpn_as::params::package_provider,
  Variant[Undef, String]                       $package_source = $openvpn_as::params::package_source,
) inherits openvpn_as::params {
  # Package
  package { $package_name:
    ensure   => $package_ensure,
    provider => $package_provider,
    source   => $package_source,
  }

}
