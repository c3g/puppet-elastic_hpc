# Bind mount a Magic Castle volume (mounted under /mnt/<tag>/<name> by
# profile::volumes with bind_mount = false) on a directory that is already
# managed by another module. No File resource is declared on $target to
# avoid duplicate declarations; it is created with mkdir if missing.
#
# $services are started only once the bind mount is in place. When
# $migrate_data is true, they are stopped and the existing content of $target
# is copied on the volume before mounting, if the volume is still empty.
define elastic_hpc::bind_mount (
  Stdlib::Absolutepath $source,
  Stdlib::Absolutepath $target = $title,
  Array[String[1]] $services = [],
  Boolean $migrate_data = false,
) {
  exec { "mkdir -p ${target}":
    creates => $target,
    path    => ['/bin', '/usr/bin'],
  }

  if $migrate_data {
    stdlib::ensure_packages(['rsync'], { ensure => 'installed' })

    $stop_cmd = $services.map |$service| { "systemctl stop ${service}; " }.join('')
    exec { "migrate ${target} to ${source}":
      command  => "${stop_cmd}rsync -aHAX ${target}/ ${source}/",
      onlyif   => "test -z \"$(ls -A ${source})\"",
      unless   => "mountpoint -q ${target}",
      provider => 'shell',
      path     => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
      require  => [Exec["mkdir -p ${target}"], Mount[$source], Package['rsync']],
      before   => Mount[$target],
    }
  }

  mount { $target:
    ensure  => mounted,
    device  => $source,
    fstype  => 'none',
    options => "rw,bind,x-systemd.requires-mounts-for=${source}",
    require => [Exec["mkdir -p ${target}"], Mount[$source]],
  }

  # Ownership and mode set by the module managing $target apply to the volume
  Mount[$target] -> File <| title == $target |>

  # Services are (re)started by their own Service resource after the mount
  $services.each |$service| {
    Mount[$target] -> Service <| title == $service |>
  }
}
