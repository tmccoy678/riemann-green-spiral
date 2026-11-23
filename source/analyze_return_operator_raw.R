arguments <- commandArgs(trailingOnly=TRUE)
input <- if (length(arguments)) arguments[[1]] else 'data/return_ensemble_first9.tsv'
d <- read.delim(input)
grid_y <- round((d$seed_y - 18) / 0.125)
grid_z <- round((d$seed_z - 4) / 0.125)
d$fold <- (grid_y + 2 * grid_z) %% 5

features <- function(y, z, degree, center, scale) {
  u <- (y - center[1]) / scale[1]
  v <- (z - center[2]) / scale[2]
  value <- cbind(1, u, v)
  if (degree >= 2) {
    value <- cbind(value, u^2, u*v, v^2)
  }
  if (degree >= 3) {
    value <- cbind(value, u^3, u^2*v, u*v^2, v^3)
  }
  value
}

step_data <- function(k) {
  left <- d[d$crossing_id == k, c('seed_id','y','z','fold')]
  right <- d[d$crossing_id == k + 2, c('seed_id','y','z')]
  names(left)[2:3] <- c('y0','z0')
  names(right)[2:3] <- c('y1','z1')
  merge(left, right, by='seed_id')
}

cat('HELDOUT_STEP_VALIDATION\n')
global_minimum_skill <- Inf
for (k in 1:7) {
  q <- step_data(k)
  skills <- numeric()
  errors <- numeric()
  for (fold in 0:4) {
    train <- q$fold != fold
    x <- cbind(1, q$y0, q$z0)
    y <- cbind(q$y1, q$z1)
    coefficients <- qr.solve(x[train,,drop=FALSE], y[train,,drop=FALSE])
    prediction <- x[!train,,drop=FALSE] %*% coefficients
    error <- sqrt(mean(rowSums((y[!train,,drop=FALSE] - prediction)^2)))
    identity_error <- sqrt(mean(rowSums(
      (y[!train,,drop=FALSE] - x[!train,2:3,drop=FALSE])^2)))
    errors <- c(errors, error)
    skills <- c(skills, 1 - error / identity_error)
  }
  global_minimum_skill <- min(global_minimum_skill, skills)
  cat(sprintf(paste0('step=%d_to_%d rmse_mean=%.6f rmse_max=%.6f ',
                     'skill_min=%.3f skill_mean=%.3f\n'),
              k, k + 2, mean(errors), max(errors), min(skills), mean(skills)))
}
cat(sprintf('heldout_affine_skill_minimum=%.3f\n', global_minimum_skill))

fit_step <- function(k, fold, degree, center, scale) {
  q <- step_data(k)
  train <- q$fold != fold
  x <- features(q$y0, q$z0, degree, center, scale)
  y <- features(q$y1, q$z1, degree, center, scale)
  operator <- qr.solve(x[train,,drop=FALSE], y[train,,drop=FALSE])
  list(operator=operator, data=q)
}

compose_branch <- function(steps, fold, degree) {
  train_rows <- d$fold != fold
  center <- c(mean(d$y[train_rows]), mean(d$z[train_rows]))
  scale <- c(sd(d$y[train_rows]), sd(d$z[train_rows]))
  maps <- lapply(steps, fit_step, fold=fold, degree=degree,
                 center=center, scale=scale)
  operator <- diag(nrow(maps[[1]]$operator))
  for (map in maps) {
    operator <- operator %*% map$operator
  }

  first <- maps[[1]]$data
  test <- first$fold == fold
  final_id <- tail(steps, 1) + 2
  final <- d[d$crossing_id == final_id, c('seed_id','y','z')]
  final <- final[match(first$seed_id[test], final$seed_id),]
  prediction <- features(first$y0[test], first$z0[test], degree,
                         center, scale) %*% operator
  predicted_y <- prediction[,2] * scale[1] + center[1]
  predicted_z <- prediction[,3] * scale[2] + center[2]
  rmse <- sqrt(mean((final$y - predicted_y)^2 +
                    (final$z - predicted_z)^2))

  values <- eigen(operator, only.values=TRUE)$values
  constant_id <- which.min(abs(values - 1))
  nontrivial <- values[-constant_id]
  nontrivial <- nontrivial[order(Mod(nontrivial), decreasing=TRUE)]
  list(rmse=rmse, values=nontrivial, constant=values[constant_id])
}

branches <- list(positive=c(1,3,5,7), negative=c(2,4,6))
rows <- list()
spectra <- list()
row_id <- 0
for (degree in 1:3) {
  for (branch in names(branches)) {
    for (fold in 0:4) {
      result <- compose_branch(branches[[branch]], fold, degree)
      row_id <- row_id + 1
      lead <- result$values[1]
      rows[[row_id]] <- data.frame(
        degree=degree, branch=branch, fold=fold, rmse=result$rmse,
        constant_real=Re(result$constant), constant_imag=Im(result$constant),
        lead_real=Re(lead), lead_imag=Im(lead), lead_magnitude=Mod(lead))
      spectra[[row_id]] <- result$values
    }
  }
}
summary <- do.call(rbind, rows)

for (degree in 1:3) {
  for (branch in names(branches)) {
    q <- summary[summary$degree == degree & summary$branch == branch,]
    cat(sprintf(paste0(
      'degree=%d branch=%s rmse_mean=%.6f rmse_range=[%.6f,%.6f] ',
      'constant_error_max=%.3e lead_magnitude_range=[%.6f,%.6f] ',
      'lead_imag_abs_max=%.6f\n'),
      degree, branch, mean(q$rmse), min(q$rmse), max(q$rmse),
      max(Mod(q$constant_real + 1i*q$constant_imag - 1)),
      min(q$lead_magnitude), max(q$lead_magnitude), max(abs(q$lead_imag))))
  }
}

cat('SPECTRA\n')
for (index in seq_along(spectra)) {
  q <- summary[index,]
  values <- head(spectra[[index]], 5)
  encoded <- paste(sprintf('%.6f%+.6fi|%.6f', Re(values), Im(values), Mod(values)),
                   collapse=',')
  cat(sprintf('degree=%d branch=%s fold=%d %s\n',
              q$degree, q$branch, q$fold, encoded))
}
