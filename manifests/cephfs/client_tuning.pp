# CephFS client tuning for compute nodes
#
# Shortens the time a CephFS client needs to release its capabilities when
# - tuned profile inheriting $base_profile with a shorter dirty data expiry
# - udev rule capping the dirty data of every CephFS mount (bdi ceph-*) to
#   $bdi_max_bytes, enforced at all time with strict_limit
#
class elastic_hpc::cephfs::client_tuning (
  String[1] $base_profile = 'hpc-compute',
  String[1] $profile_name = 'hpc-compute-cephfs',
  Integer[0] $bdi_max_bytes = 1073741824,
  Integer[0] $dirty_expire_centisecs = 1000,
) {
  stdlib::ensure_packages(['tuned'], { ensure => 'installed' })

  service { 'tuned':
    ensure  => running,
    enable  => true,
    require => Package['tuned'],
  }

  # tuned profile
  file { "/etc/tuned/${profile_name}":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['tuned'],
  }

  file { "/etc/tuned/${profile_name}/tuned.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('elastic_hpc/cephfs/tuned.conf.epp', {
        'base_profile'           => $base_profile,
        'dirty_expire_centisecs' => $dirty_expire_centisecs,
    }),
  }

  # Activate the profile when another one is active
  exec { "tuned-adm profile ${profile_name}":
    unless   => "tuned-adm active | grep -qxF 'Current active profile: ${profile_name}'",
    provider => 'shell',
    path     => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    require  => [File["/etc/tuned/${profile_name}/tuned.conf"], Service['tuned']],
  }

  # Apply the profile again when its content changes
  exec { "tuned-adm profile ${profile_name} (reload)":
    command     => "tuned-adm profile ${profile_name}",
    refreshonly => true,
    path        => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    subscribe   => File["/etc/tuned/${profile_name}/tuned.conf"],
    require     => Exec["tuned-adm profile ${profile_name}"],
  }

  # Values in sysctl.d are applied after tuned (reapply_sysctl = 1) and
  # would override the profile.
  file { '/etc/sysctl.d/90-cephfs-dirty.conf':
    ensure => absent,
  }

  # Per CephFS mount dirty data cap
  file { '/etc/udev/rules.d/90-cephfs-bdi.rules':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('elastic_hpc/cephfs/90-cephfs-bdi.rules.epp', {
        'bdi_max_bytes' => $bdi_max_bytes,
    }),
  }

  # Apply the rule to the CephFS already mounted, without remounting
  exec { 'udevadm trigger cephfs bdi':
    command     => 'udevadm control --reload && udevadm trigger --subsystem-match=bdi --action=add',
    refreshonly => true,
    provider    => 'shell',
    path        => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    subscribe   => File['/etc/udev/rules.d/90-cephfs-bdi.rules'],
  }

  File['/etc/udev/rules.d/90-cephfs-bdi.rules'] -> Mount <| fstype == 'ceph' |>
}
