# Bind mount a Magic Castle volume (mounted under /mnt/<tag>/<name> by
# profile::volumes with bind_mount = false) on a directory that is already
# managed by another module. No File resource is declared on $target to
# avoid duplicate declarations; it is created with mkdir if missing.
define elastic_hpc::bind_mount (
  Stdlib::Absolutepath $source,
  Stdlib::Absolutepath $target = $title,
) {
  exec { "mkdir -p ${target}":
    creates => $target,
    path    => ['/bin', '/usr/bin'],
  }

  mount { $target:
    ensure  => mounted,
    device  => $source,
    fstype  => 'none',
    options => "rw,bind,x-systemd.requires-mounts-for=${source}",
    require => [Exec["copy ${target} to ${source}"], Mount[$source]],
  }

  # Ownership and mode set by the module managing $target apply to the volume
  Mount[$target] -> File <| title == $target |>
}
