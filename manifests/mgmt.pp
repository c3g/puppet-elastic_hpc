# Put slurmctld state and prometheus data on dedicated mgmt volumes
#
# Set $migrate_data to true to copy the existing data on the volumes
# (services writing in the directories are stopped during the copy).
class elastic_hpc::mgmt (
  Stdlib::Absolutepath $slurm_volume = '/mnt/mgmt/slurm',
  Stdlib::Absolutepath $prometheus_volume = '/mnt/mgmt/prometheus',
  Boolean $migrate_data = false,
) {
  elastic_hpc::bind_mount { '/var/spool/slurm':
    source       => $slurm_volume,
    services     => ['slurmctld'],
    migrate_data => $migrate_data,
  }

  elastic_hpc::bind_mount { '/var/lib/prometheus':
    source       => $prometheus_volume,
    services     => ['prometheus'],
    migrate_data => $migrate_data,
  }
}
