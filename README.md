openvpn_as
==========

+This is deprecated and unmaintained in favor of the official module: https://forge.puppet.com/modules/openvpn/openvpnas/
+
+
+<br><br><br><br><br><br>
#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with openvpn_as](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with openvpn_as](#beginning-with-openvpn_as)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

# Description

This module installs and manages OpenVPN Access Server.

"OpenVPN Access Server is a full featured secure network tunneling VPN software solution that integrates OpenVPN server
capabilities, enterprise management capabilities, simplified OpenVPN Connect UI, and OpenVPN Client software packages
that accommodate Windows, MAC, Linux, Android, and iOS environments. OpenVPN Access Server supports a wide range of
configurations, including secure and granular remote access to internal network and/ or private cloud network resources
and applications with fine-grained access control." -[openvpn.net]

## What is the difference between OpenVPN Access Server and OpenVPN Community Edition?

Community Edition is the normal free/libre edition that most folks are used to. Access Server is a licensed version of OpenVPN with a web GUI that simplifies a lot of the configuration management.

# Setup

## Setup Requirements

* jq. You can let the module install it via the `jq_install` parameter, but it is required for the module to operate.
* The openvpn-as package: [https://openvpn.net/index.php/access-server/download-openvpn-as-sw/113.html](https://openvpn.net/index.php/access-server/download-openvpn-as-sw/113.html)


## Beginning with openvpn_as  

If you don't have a working openvpn_as cluster, you can use this module to install and initalize one.

Then it is recommended to configure them via the GUI and use the values it created in the config DB to manage the config profiles via this module.

Here are one-liners to turn your current config and user databases into yaml (to easily place it into hieradata)

```sh
/<openvpn_as directory>/scripts/confdba --show |  ruby -e "require 'json'; require 'yaml'; print YAML.dump(JSON.load(ARGF.read()))"
/<openvpn_as directory>/scripts/confdba --show --userdb|  ruby -e "require 'json'; require 'yaml'; print YAML.dump(JSON.load(ARGF.read()))"
```

The particulars of the configuration of the Access Server itself are beyond the scope of this document. For that, check the [docs]

# Usage

This will by default install and initialize openvpn_as, assuming you have made the package `openvpn-as` available in the system repos

```puppet
include openvpn_as
```

Alternatively, you could specify the package url directly in the code

```puppet
class { 'openvpn_as':
  package_spource  => 'https://swupdate.openvpn.org/as/openvpn-as-version.ext',
  package_provider => 'rpm', # or dpkg, maybe
}
```

The bulk of your settings will be in the `profiles` and `userprops` databases. There is a suggestion for how to parameterize these configs [above](#beginning-with-openvpn_as). Here is a pattern that may come in handy if you are combining your configuration from hieradata with sensitive values (say from hiera-eyaml) and maybe some files or templates into your configuration.

```puppet
include stdlib

$profiles_hiera = hiera_hash('openvpn_as::profiles')
$profiles_files = {
  'Default' => {
    'auth.module.post_auth_script' => file('profile/openvpn/auth.module.post_auth_script'),
    'cs.priv_key'                  => hiera('some:key'),
    'cs.cert'                      => hiera('some::cert'),
    'cs.ca_bundle'                 => hiera('some::bundle'),
  }
}
$profiles = deep_merge($profiles_hiera, $profiles_files)

class { 'openvpn_as':
  # ...
  profiles => $profiles,
}
```

# Reference

## Class: `openvpn_as`

### `active_profile`

String. Default: `Default`

### `as_conf`

Hash. Default: {}

### `config_force`

Boolean. Default: false

### `exec_path`

String. Default: `/usr/local/openvpn_as/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/usr/local/openvpn_as/bin`

### `ovpn_dir`

String. Default: `/usr/local/openvpn_as`

### `ovpn_init`

Boolean. Default: true

### `ovpn_init_force`

Boolean. Default: false

### `profiles`

Variant[Hash, Undef]. Default: {}

### `userprops`

Variant[Hash, Undef. Default: {}

### `jq_install`

Boolean. Default: false

### `rsync_install`

Boolean. Default: false

### `package_ensure`

Variant[Boolean, String]. Default: `installed`

### `package_name`

String. Default: `openvpn-as`

### `package_provider`

Variant[String, Undef]. Default:  undef

### `package_source`

Variant[String, Undef. Default: undef

### `service_ensure`

Variant[Boolean, Enum[`stopped`, `running`]]. Default: `running`

### `service_manage`

Boolean. Default: true

### `service_name`

String. Default: `openvpnas`

# Limitations

This has only been tested on EL7, but it was designed with generality in mind and will probably work just fine on Debian-based distros as well. If you try it, please let us know!

## Development

Taking pull requests at https://github.com/theias/openvpn_as.git


[openvpn.net]: https://openvpn.net/index.php/access-server/overview.html
[docs]: https://openvpn.net/index.php/access-server/docs.html
