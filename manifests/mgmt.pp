# Put slurmctld state and prometheus data on dedicated mgmt volumes
class elastic_hpc::mgmt (
  Stdlib::Absolutepath $slurm_volume = '/mnt/mgmt/slurm',
  Stdlib::Absolutepath $prometheus_volume = '/mnt/mgmt/prometheus',
) {
  elastic_hpc::bind_mount { '/var/spool/slurm':
    source => $slurm_volume,
  }
  Mount['/var/spool/slurm'] -> Service <| title == 'slurmctld' |>

  elastic_hpc::bind_mount { '/var/lib/prometheus':
    source => $prometheus_volume,
  }
  Mount['/var/lib/prometheus'] -> Service <| title == 'prometheus' |>
}
