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
  if (degree >= 2) value <- cbind(value, u^2, u*v, v^2)
  if (degree >= 3) value <- cbind(value, u^3, u^2*v, u*v^2, v^3)
  value
}

inverse_sqrt <- function(matrix, tolerance=1e-10) {
  result <- eigen((matrix + t(matrix))/2, symmetric=TRUE)
  keep <- result$values > max(result$values) * tolerance
  vectors <- result$vectors[,keep,drop=FALSE]
  values <- result$values[keep]
  vectors %*% diag(1/sqrt(values), length(values)) %*% t(vectors)
}

crossing_features <- function(crossing, degree, center, scale) {
  q <- d[d$crossing_id == crossing,]
  q <- q[order(q$seed_id),]
  features(q$y, q$z, degree, center, scale)
}

fit_branch <- function(steps, fold, degree) {
  train_seed <- sort(unique(d$seed_id[d$fold != fold]))
  test_seed <- sort(unique(d$seed_id[d$fold == fold]))
  train_rows <- d$fold != fold
  center <- c(mean(d$y[train_rows]), mean(d$z[train_rows]))
  scale <- c(sd(d$y[train_rows]), sd(d$z[train_rows]))
  crossings <- sort(unique(c(steps, steps + 2)))
  phi <- lapply(crossings, crossing_features, degree=degree,
                center=center, scale=scale)
  names(phi) <- as.character(crossings)
  seed_order <- sort(unique(d$seed_id))
  train <- seed_order %in% train_seed
  test <- seed_order %in% test_seed
  grams <- lapply(phi, function(value) crossprod(value[train,,drop=FALSE]) / sum(train))
  whiten <- lapply(grams, inverse_sqrt)
  train_operator <- diag(ncol(phi[[1]]))
  test_operator <- diag(ncol(phi[[1]]))
  step_errors <- numeric()
  for (k in steps) {
    left <- as.character(k)
    right <- as.character(k + 2)
    train_cross <- crossprod(phi[[left]][train,,drop=FALSE],
                             phi[[right]][train,,drop=FALSE]) / sum(train)
    test_cross <- crossprod(phi[[left]][test,,drop=FALSE],
                            phi[[right]][test,,drop=FALSE]) / sum(test)
    train_step <- whiten[[left]] %*% train_cross %*% whiten[[right]]
    test_step <- whiten[[left]] %*% test_cross %*% whiten[[right]]
    step_errors <- c(step_errors,
                     norm(test_step - train_step, 'F') / norm(train_step, 'F'))
    train_operator <- train_operator %*% train_step
    test_operator <- test_operator %*% test_step
  }
  values <- eigen(train_operator, only.values=TRUE)$values
  values <- values[order(Mod(values), decreasing=TRUE)]
  singular <- svd(train_operator, nu=0, nv=0)$d
  list(values=values, singular=singular,
       operator_error=norm(test_operator-train_operator,'F') /
                      norm(train_operator,'F'),
       step_error=mean(step_errors))
}

branches <- list(positive=c(1,3,5,7), negative=c(2,4,6))
for (degree in 1:3) {
  for (branch in names(branches)) {
    for (fold in 0:4) {
      result <- fit_branch(branches[[branch]], fold, degree)
      values <- head(result$values, 5)
      singular <- head(result$singular, 5)
      encoded <- paste(sprintf('%.6f%+.6fi|%.6f',
                               Re(values), Im(values), Mod(values)),
                       collapse=',')
      cat(sprintf(paste0(
        'degree=%d branch=%s fold=%d operator_error=%.6f ',
        'mean_step_error=%.6f eig=%s singular=%s\n'),
        degree, branch, fold, result$operator_error, result$step_error,
        encoded, paste(sprintf('%.6f',singular),collapse=',')))
    }
  }
}
