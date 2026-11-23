root <- normalizePath(file.path(dirname(sub('^--file=','',
  grep('^--file=',commandArgs(FALSE),value=TRUE))), '..'))

read_receipt <- function(path) {
  line <- readLines(path)
  line <- line[grepl('=',line,fixed=TRUE)]
  key <- sub('=.*$','',line)
  value <- sub('^[^=]*=','',line)
  setNames(value,key)
}

growth <- read_receipt(file.path(root,'data','gaussian_width_growth_receipt.txt'))
photon <- read_receipt(file.path(root,'data','photon_neighbor_bundle_receipt.txt'))
slope <- as.numeric(growth[['slope_per_arc']])
diffusivity <- slope/2
critical_chi_mass <- 8*pi*diffusivity
focus <- as.numeric(photon[['maximum_flux_density_multiplier']])

stopifnot(slope>0)
stopifnot(as.numeric(growth[['r_squared']])>=0.95)

receipt <- c(
  'KELLER_SEGEL_BALANCE_EXPLORATION',
  sprintf('width_squared_slope_per_arc=%.17g',slope),
  sprintf('dimensionless_diffusivity=%.17g',diffusivity),
  sprintf('critical_chi_times_mass_2d=%.17g',critical_chi_mass),
  sprintf('upstream_flux_density_focus=%.17g',focus),
  'cycles_7_8_9_state=diffusive_reopening',
  'chemotactic_sensitivity_measured=0',
  'population_mass_measured=0',
  'critical_mass_classification_possible=0',
  'node_or_particle_identification=0',
  'riemann_hypothesis_claim=0'
)
writeLines(receipt,file.path(root,'data','keller_segel_balance_receipt.txt'))
cat(paste(receipt,collapse='\n'),'\n')
