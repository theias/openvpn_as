# Set config values with confdba for the config and userprop tables
# Given a hash like this:
#
#  {
#    'Profilename' => {
#      'key1' => 'value or path 1',
#      'key2' => 'value or path 2',
#      [...]
#    }
#  }
#
# Ensure that the profiles exist and then attempt to configure the keys/values under them.
# For each key, query the DB to see if the passed value is already set.
# If it is not, set the passed value.
#
#
# @api private
#
define openvpn_as::confdba (
  Variant[Hash, Undef]        $profiles,
  String                      $exec_path = $openvpn_as::params::exec_path,
  String                      $ovpn_dir = $openvpn_as::params::ovpn_dir,
  String                      $tmp_dir = "${openvpn_as::params::ovpn_dir}/tmp",
  Boolean                     $userdb = false,
){
  # Use the --userdb flag if specified - by default confdba just changes the 'config' db
  $userdb_sw = $userdb ? {
    false   => '',
    true => '--userdb',
  }

  # Loop on each profile and compare and set values therein as appropriate
  $profiles.each | $profile, $settings | {
    # Ensure that all given profiles exist before asigning values under them
    exec { "${::fqdn}_ensure_profile_${userdb_sw}__${profile}":
      path    => $exec_path,
      command => "confdba ${userdb_sw} --mod --create --prof ${profile}",
      unless  => "confdba ${userdb_sw} --show --prof='${profile}' | jq -e '.[\"${profile}\"]'",
    }
    # Key/value checking/setting
    $settings.each | $key, $val | {
      $tmp_file = "${tmp_dir}/${key}"
      file { $tmp_file:
        ensure  => 'file',
        content => $val,
        mode    => '0600',
      }
      file { "${tmp_file}.json":
        ensure  => 'file',
        content => to_json($val),
        mode    => '0600',
      }
      # Set the value via confdba
      exec { "${::fqdn}_config_${key}_for_profile_${profile}_${userdb_sw}":
        command => "confdba ${userdb_sw} --mod --prof='${profile}' --key '${key}' --value_file '${tmp_file}'",
        path    => $exec_path,
        # This jq query will let this assignment run iff the value of $key doesn't already match $val 
        unless  => "confdba ${userdb_sw} --prof='${profile}' --show | jq --argfile compstr ${tmp_file}.json -e '.[\"${profile}\"][\"${key}\"] == \$compstr'", # lint:ignore:140chars
      }
    }
  }
}
