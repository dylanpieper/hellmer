#' Process a batch of prompts in sequence
#' @description
#' Processes a batch of chat prompts one at a time in sequential order.
#' Maintains state between runs and can resume interrupted processing.
#' For parallel processing, use `chat_future()`.
#'
#' @param chat_model ellmer chat model function or object (e.g., \code{ellmer::chat_claude})
#' @param echo Level of output to display: "none" for silent operation,
#'        "text" for response text only, or "all" for full interaction (default: "none")
#' @param beep Logical to play a sound on batch completion, interruption, and error (default: TRUE)
#' @param max_retries Maximum number of retry attempts per prompt (default: 3L)
#' @param initial_delay Initial delay in seconds before first retry (default: 20)
#' @param max_delay Maximum delay in seconds between retries (default: 60)
#' @param backoff_factor Factor to multiply delay by after each retry (default: 2)
#' @param timeout Maximum time in seconds to wait for each prompt response (default: 60)
#' @param ... Additional arguments passed to the underlying chat model
#' @return A batch results object containing:
#'   \itemize{
#'     \item prompts: Original input prompts
#'     \item responses: Raw response data for completed prompts
#'     \item completed: Number of successfully processed prompts
#'     \item state_path: Path where batch state is saved
#'     \item type_spec: Type specification used for structured data
#'     \item texts: Function to extract text responses
#'     \item chats: Function to extract chat objects
#'     \item progress: Function to get processing status
#'     \item structured_data: Function to extract structured data (if `type_spec` was provided)
#'   }
#' @export
chat_sequential <- function(
    chat_model = NULL,
    echo = "none",
    beep = TRUE,
    max_retries = 3L,
    initial_delay = 20,
    max_delay = 60,
    backoff_factor = 2,
    timeout = 60,
    ...) {
  if (is.null(chat_model)) {
    stop("Define a ellmer chat model (e.g., chat_openai or chat_claude)")
  }

  chat_env <- new.env(parent = emptyenv())
  chat_env$chat_model <- if (is.function(chat_model)) {
    chat_model(echo = "none", ...)
  } else {
    chat_model
  }

  for (n in names(chat_env$chat_model)) {
    chat_env[[n]] <- chat_env$chat_model[[n]]
  }

  chat_env$echo <- echo
  chat_env$beep <- beep
  chat_env$timeout <- timeout
  chat_env$max_retries <- max_retries
  chat_env$initial_delay <- initial_delay
  chat_env$max_delay <- max_delay
  chat_env$backoff_factor <- backoff_factor
  chat_env$last_state_path <- NULL

  chat_env$batch <- function(prompts,
                             type_spec = NULL,
                             state_path = tempfile("chat_", fileext = ".rds")) {
    if (is.null(chat_env$last_state_path)) {
      chat_env$last_state_path <- state_path
    } else {
      state_path <- chat_env$last_state_path
    }

    process(
      chat_obj = chat_env$chat_model,
      prompts = prompts,
      type_spec = type_spec,
      state_path = state_path,
      echo = chat_env$echo,
      beep = chat_env$beep,
      max_retries = chat_env$max_retries,
      initial_delay = chat_env$initial_delay,
      max_delay = chat_env$max_delay,
      backoff_factor = chat_env$backoff_factor,
      timeout = chat_env$timeout
    )
  }

  class(chat_env) <- c("Chat", "R6")
  chat_env
}

#' Process a batch of prompts in parallel
#' @description
#' Processes a batch of chat prompts using parallel workers.
#' Splits prompts into chunks for processing while maintaining state.
#' For sequential processing, use `chat_sequential()`.
#'
#' @param chat_model ellmer chat model function or object (e.g., \code{ellmer::chat_claude})
#' @param workers Number of parallel workers to use (default: 4L)
#' @param plan Processing strategy to use: "multisession" for separate R sessions
#'        or "multicore" for forked processes (default: "multisession")
#' @param beep Logical to play a sound on batch completion, interruption, and error (default: TRUE)
#' @param chunk_size Number of prompts to process in parallel at a time (default: 4L)
#' @param max_chunk_attempts Maximum number of retry attempts for failed chunks (default: 3L)
#' @param max_retries Maximum number of retry attempts per prompt (default: 3L)
#' @param initial_delay Initial delay in seconds before first retry (default: 20)
#' @param max_delay Maximum delay in seconds between retries (default: 60)
#' @param backoff_factor Factor to multiply delay by after each retry (default: 2)
#' @param timeout Maximum time in seconds to wait for each prompt response (default: 2)
#' @param ... Additional arguments passed to the chat model
#' @return A batch results object containing:
#'   \itemize{
#'     \item prompts: Original input prompts
#'     \item responses: Raw response data for completed prompts
#'     \item completed: Number of successfully processed prompts
#'     \item state_path: Path where batch state is saved
#'     \item type_spec: Type specification used for structured data
#'     \item texts: Function to extract text responses
#'     \item chats: Function to extract chat objects
#'     \item progress: Function to get processing status
#'     \item structured_data: Function to extract structured data (if `type_spec` was provided)
#'   }
#' @export
chat_future <- function(
    chat_model = NULL,
    workers = 4L,
    plan = "multisession",
    beep = TRUE,
    chunk_size = 4L,
    max_chunk_attempts = 3L,
    max_retries = 3L,
    initial_delay = 20,
    max_delay = 60,
    backoff_factor = 2,
    timeout = 60,
    ...) {
  if (is.null(chat_model)) {
    stop("Define a ellmer chat_model (e.g., chat_openai or chat_claude)")
  }

  plan <- match.arg(plan, choices = c("multisession", "multicore"))
  chat_env <- new.env(parent = emptyenv())
  chat_env$chat_model <- if (is.function(chat_model)) {
    chat_model(echo = "none", ...)
  } else {
    chat_model
  }

  for (n in names(chat_env$chat_model)) {
    chat_env[[n]] <- chat_env$chat_model[[n]]
  }

  chat_env$workers <- workers
  chat_env$plan <- plan
  chat_env$beep <- beep
  chat_env$timeout <- timeout
  chat_env$max_chunk_attempts <- max_chunk_attempts
  chat_env$max_retries <- max_retries
  chat_env$initial_delay <- initial_delay
  chat_env$max_delay <- max_delay
  chat_env$backoff_factor <- backoff_factor
  chat_env$chunk_size <- chunk_size
  chat_env$last_state_path <- NULL

  chat_env$batch <- function(prompts,
                             type_spec = NULL,
                             state_path = tempfile("chat_", fileext = ".rds"),
                             chunk_size = chat_env$chunk_size) {
    if (is.null(chat_env$last_state_path)) {
      chat_env$last_state_path <- state_path
    } else {
      state_path <- chat_env$last_state_path
    }

    process_future(
      chat_obj = chat_env$chat_model,
      prompts = prompts,
      type_spec = type_spec,
      state_path = state_path,
      workers = chat_env$workers,
      chunk_size = chunk_size,
      plan = chat_env$plan,
      beep = chat_env$beep,
      timeout = chat_env$timeout,
      max_chunk_attempts = chat_env$max_chunk_attempts,
      max_retries = chat_env$max_retries,
      initial_delay = chat_env$initial_delay,
      max_delay = chat_env$max_delay,
      backoff_factor = chat_env$backoff_factor
    )
  }

  class(chat_env) <- c("Chat", "R6")
  chat_env
}
