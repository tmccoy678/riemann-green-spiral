root <- normalizePath(file.path(dirname(sub('^--file=','',
  grep('^--file=',commandArgs(FALSE),value=TRUE))), '..'))
d <- read.delim(file.path(root,'data','return_ensemble_first9.tsv'))
gridY <- round((d$seed_y-18)/0.125)
gridZ <- round((d$seed_z-4)/0.125)
d$fold <- (gridY+2*gridZ)%%5

getMap <- function(step,keep) {
  left <- d[d$crossing_id==step & keep,c('seed_id','y','z')]
  right <- d[d$crossing_id==step+2 & keep,c('seed_id','y','z')]
  names(left)[2:3] <- c('y0','z0')
  names(right)[2:3] <- c('y1','z1')
  q <- merge(left,right,by='seed_id')
  coefficients <- qr.solve(cbind(1,q$y0,q$z0),cbind(q$y1,q$z1))
  t(coefficients[2:3,,drop=FALSE])
}

compose <- function(steps,keep) {
  matrix <- diag(2)
  for(step in steps) matrix <- getMap(step,keep)%*%matrix
  matrix/sqrt(abs(det(matrix)))
}

basis <- list(
  matrix(c(1,0,0,0),2),
  matrix(c(0,1,1,0),2),
  matrix(c(0,0,0,1),2))

fitMetric <- function(positive,negative) {
  linear <- sapply(basis,function(metric) {
    as.vector(t(negative)%*%metric%*%positive-metric)
  })
  hessian <- 2*crossprod(linear)
  constraint <- c(1,0,1)
  system <- rbind(cbind(hessian,constraint),c(constraint,0))
  coefficient <- solve(system,c(0,0,0,2))[1:3]
  coefficient[1]*basis[[1]]+coefficient[2]*basis[[2]]+
    coefficient[3]*basis[[3]]
}

rows <- list()
for(fold in 0:4) {
  train <- d$fold!=fold
  test <- d$fold==fold
  positive <- compose(c(1,3,5,7),train)
  negative <- compose(c(2,4,6),train)
  metric <- fitMetric(positive,negative)
  positiveTest <- compose(c(1,3,5,7),test)
  negativeTest <- compose(c(2,4,6),test)
  eigenvalue <- eigen(metric,symmetric=TRUE)$values
  rows[[fold+1]] <- data.frame(
    fold=fold,
    train_residual=norm(t(negative)%*%metric%*%positive-metric,'F')/
      norm(metric,'F'),
    heldout_residual=norm(t(negativeTest)%*%metric%*%positiveTest-metric,'F')/
      norm(metric,'F'),
    positive_eigenvalue=eigenvalue[1],
    negative_eigenvalue=eigenvalue[2])
}
result <- do.call(rbind,rows)
writetable <- function(table,path) {
  write.table(table,path,sep='\t',row.names=FALSE,quote=FALSE)
}
writetable(result,file.path(root,'data','path22_scattering_pairing.tsv'))

stopifnot(all(result$positive_eigenvalue>0))
stopifnot(all(result$negative_eigenvalue<0))
stopifnot(max(result$heldout_residual)>0.9)

receipt <- c(
  'PATH22_SCATTERING_PAIRING_REJECTION',
  'metric_signature=1,1',
  sprintf('training_residuals=%s',paste(sprintf('%.9f',result$train_residual),collapse=',')),
  sprintf('heldout_residuals=%s',paste(sprintf('%.9f',result$heldout_residual),collapse=',')),
  sprintf('heldout_residual_min=%.17g',min(result$heldout_residual)),
  sprintf('heldout_residual_max=%.17g',max(result$heldout_residual)),
  'positive_definite_unitarity=0',
  'indefinite_signature_stable=1',
  'canonical_scattering_pairing_pass=0',
  'riemann_hypothesis_claim=0')
writeLines(receipt,file.path(root,'data','path22_scattering_pairing_receipt.txt'))
cat(paste(receipt,collapse='\n'),'\n')
