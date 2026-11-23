root <- normalizePath(file.path(dirname(sub('^--file=','',
  grep('^--file=',commandArgs(FALSE),value=TRUE))), '..'))
ensemble <- read.delim(file.path(root,'data','return_ensemble_first9.tsv'))
poincare <- read.delim(file.path(root,'data','path22_poincare.tsv'))
adaptive <- read.delim(file.path(root,'data','return_boundary_refinement_summary.tsv'))

transition <- merge(
  ensemble[ensemble$crossing_id<9,c('seed_id','crossing_id','orientation')],
  transform(ensemble[ensemble$crossing_id>1,c('seed_id','crossing_id','orientation')],
            crossing_id=crossing_id-1),
  by=c('seed_id','crossing_id'),suffixes=c('_from','_to'))
observed <- unique(transition[c('orientation_from','orientation_to')])
observed <- observed[order(observed$orientation_from),]
stopifnot(nrow(observed)==2)
stopifnot(all(observed$orientation_to==-observed$orientation_from))

heldout <- poincare$orientation[10:16]
prediction <- integer(length(heldout))
state <- poincare$orientation[9]
for(index in seq_along(heldout)) {
  state <- -state
  prediction[index] <- state
}
stopifnot(all(prediction==heldout))

adaptive_returns <- adaptive[adaptive$returned==1,]
stopifnot(nrow(adaptive_returns)==145)
stopifnot(all(adaptive_returns$first_nine_alternating==1))

receipt <- c(
  'LSYSTEM_ORIENTATION_EXPLORATION',
  'alphabet=positive,negative',
  'production_positive=negative',
  'production_negative=positive',
  sprintf('training_paths=%d',length(unique(ensemble$seed_id))),
  sprintf('training_transitions=%d',nrow(transition)),
  'path22_heldout_crossings=10..16',
  sprintf('path22_heldout_correct=%d/%d',sum(prediction==heldout),length(heldout)),
  sprintf('adaptive_heldout_paths=%d',nrow(adaptive_returns)),
  sprintf('adaptive_heldout_correct=%d/%d',
          sum(adaptive_returns$first_nine_alternating==1),nrow(adaptive_returns)),
  'quantitative_geometry_predicted=0',
  'riemann_hypothesis_claim=0'
)
writeLines(receipt,file.path(root,'data','l_system_orientation_receipt.txt'))
cat(paste(receipt,collapse='\n'),'\n')
