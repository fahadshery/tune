# Genneral logging to the screen used in various places.
# ------------------------------------------------------------------------------

siren <- function(x, type = "info") {
  types <- c("warning", "go", "danger", "success", "info")
  if (!any(type == types)) {
    rlang::abort(
      paste("`type` should be one of: ",
            paste0("'", types, "'", collapse = ", ")
      )
    )
  }
  msg <- glue::glue(x)
  symb <- dplyr::case_when(
    type == "warning" ~ crayon::yellow("!"),
    type == "go" ~ crayon::black(cli::symbol$pointer ),
    type == "danger" ~ crayon::red("x"),
    type == "success" ~ crayon::green("\u2713"),
    TRUE ~ crayon::blue("i")
  )
  msg <- dplyr::case_when(
    type == "warning" ~ crayon::yellow(msg),
    type == "go" ~  crayon::black(msg),
    type == "danger" ~ crayon::red(msg),
    type == "success" ~  crayon::black(msg),
    TRUE ~  crayon::black(msg)
  )
  message(paste(symb, msg))
}


tune_log <- function(control, split = NULL, task, type = "success") {
  if (!control$verbose) {
    return(invisible(NULL))
  }
  if (!is.null(split)) {
    labs <- labels(split)
    labs <- rev(unlist(labs))
    labs <- paste0(labs, collapse = ", ")
    labs <- paste0(labs, ": ")
  } else {
    labs <- ""
  }

  # see https://github.com/r-lib/cli/issues/92
  task <- gsub("\\{", "", task)

  siren(paste0(labs, task), type = type)
  NULL
}

log_problems <- function(notes, control, split, loc, res, bad_only = FALSE) {
  # Always log warnings and errors
  control2 <- control
  control2$verbose = TRUE

  wrn <- res$signals
  if (length(wrn) > 0) {
    wrn_msg <- map_chr(wrn, ~ .x$message)
    wrn_msg <- unique(wrn_msg)
    wrn_msg <- paste(wrn_msg, collapse = ", ")
    wrn_msg <- glue::glue_collapse(wrn_msg, width = options()$width - 5)
    wrn_msg <- paste0(loc, ": ", wrn_msg)
    notes <- c(notes, wrn_msg)
    tune_log(control2, split, wrn_msg, type = "warning")
  }
  if (inherits(res$res, "try-error")) {
    err_msg <- as.character(attr(res$res,"condition"))
    err_msg <- gsub("\n$", "", err_msg)
    err_msg <- glue::glue_collapse(err_msg, width = options()$width - 5)
    err_msg <- paste0(loc, ": ", err_msg)
    notes <- c(notes, err_msg)
    tune_log(control2, split, err_msg, type = "danger")
  } else {
    if (!bad_only) {
      tune_log(control, split, loc, type = "success")
    }
  }
  notes
}

catch_and_log <- function(.expr, ..., bad_only = FALSE, notes) {
  tune_log(..., type = "info")
  tmp <- catcher(.expr)
  new_notes <- log_problems(notes, ..., tmp, bad_only = bad_only)
  assign(".notes", new_notes, envir = parent.frame())
  tmp$res
}

log_best <- function(control, iter, info, digits = 4) {
  if (!control$verbose) {
    return(invisible(NULL))
  }

  message("")
  message(cli::rule(left = crayon::bold(paste("Iteration", iter))))
  message("")

  msg <-
    paste0(
      "Current best:\t\t",
      info$perf,
      "=",
      signif(info$best_val, digits = digits),
      " (@iter ",
      info$best_iter,
      ")"
    )
  tune_log(control, split = NULL, task = msg, type = "info")
}

check_and_log_flow <- function(control, results) {
  if (all(is.na(results$.mean))) {
    if (nrow(results) < 2) {
      tune_log(control, split = NULL, task = "Halting search", type = "danger")
      eval.parent(parse(text = "break"))
    } else {
      tune_log(control, split = NULL, task = "Skipping to next iteration", type = "danger")
      eval.parent(parse(text = "next"))
    }
  }
  invisible(NULL)
}

log_progress <- function(control, x, maximize = TRUE, objective = NULL, digits = 4) {
  if (!control$verbose) {
    return(invisible(NULL))
  }

  x <- dplyr::filter(x, .metric == objective)
  if (maximize) {
    bst <- which.max(x$mean)
  } else {
    bst <- which.min(x$mean)
  }
  bst_iter <- x$.iter[bst]
  max_iter <- max(x$.iter)
  bst_val <- x$mean[x$.iter == max_iter]
  bst_se <- x$std_err[x$.iter == max_iter]
  msg <-
    paste0(" Newest results:\t",
           objective,
           "=",
           signif(bst_val, digits = digits))
  if (!is.na(bst_se) && bst_se > 0) {
    msg <- paste0(msg,  " (+/-", signif(bst_se, digits = digits - 1), ")")
  }

  if (bst_iter == max_iter) {
    msg <- paste0(crayon::red(cli::symbol$heart), msg)
  } else {
    msg <- paste0(crayon::silver(cli::symbol$circle_cross), msg)
  }
  message(msg)
}

param_msg <- function(control, candidate) {
  if (!control$verbose) {
    return(invisible(NULL))
  }
  candidate <- candidate[, !(names(candidate) %in% c(".mean", ".sd", "objective"))]
  p_chr <- paste0(names(candidate), "=", format(as.data.frame(candidate), digits = 3))
  msg <- glue::glue_collapse(p_chr, width = options()$width - 5, sep = ", ")
  tune_log(control, split = NULL, task = msg, type = "info")
}


acq_summarizer <- function(control, iter, objective = NULL, digits = 4) {
  if (!control$verbose) {
    return(invisible(NULL))
  }
  if (inherits(objective, "conf_bound") && is.function(objective$kappa)) {
    val <- paste0("Kappa value: ", signif(objective$kappa(iter), digits = digits))
  } else {
    if (inherits(objective, c("exp_improve", "prob_improve")) &&
        is.function(objective$trade_off)) {
      val <- paste0("Trade-off value: ", signif(objective$trade_off(iter), digits = digits))

    } else {
      val <- NULL
    }
  }
  if (!is.null(val)) {
    tune_log(control, split = NULL, task = val, type = "info")
  }
  invisible(NULL)
}
