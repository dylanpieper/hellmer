#' Extract texts or structured data from a batch result
#' @name texts
#' @param x A batch object
#' @param ... Additional arguments passed to methods
#' @return A character vector or list of text responses. If a type specification was provided to the batch, structured data objects will be returned instead.
#' @examplesIf ellmer::has_credentials("openai")
#' # Create a chat processor
#' chat <- chat_sequential(chat_openai())
#'
#' # Process a batch of prompts
#' batch <- chat$batch(list(
#'   "What is R?",
#'   "Explain base R versus tidyverse",
#'   "Explain vectors, lists, and data frames"
#' ))
#'
#' # Extract text responses
#' batch$texts()
#' @export
texts <- S7::new_generic("texts", "x")

#' Extract chat objects from a batch result
#' @name chats
#' @param x A batch object
#' @param ... Additional arguments
#' @return A list of chat objects
#' @examplesIf ellmer::has_credentials("openai")
#' # Create a chat processor
#' chat <- chat_sequential(chat_openai())
#'
#' # Process a batch of prompts
#' batch <- chat$batch(list(
#'   "What is R?",
#'   "Explain base R versus tidyverse",
#'   "Explain vectors, lists, and data frames"
#' ))
#'
#' # Return the chat objects
#' batch$chats()
#' @export
chats <- S7::new_generic("chats", "x")

#' Get progress information from a batch result
#' @name progress
#' @param x A batch object
#' @param ... Additional arguments passed to methods
#' @return A list containing progress details
#' @examplesIf ellmer::has_credentials("openai")
#' # Create a chat processor
#' chat <- chat_sequential(chat_openai())
#'
#' # Process a batch of prompts
#' batch <- chat$batch(list(
#'   "What is R?",
#'   "Explain base R versus tidyverse",
#'   "Explain vectors, lists, and data frames"
#' ))
#'
#' # Check the progress
#' batch$progress()
#' @export
progress <- S7::new_generic("progress", "x")


#' Batch class for managing chat processing
#' @name batch
#' @param prompts List of prompts to process
#' @param responses List to store responses
#' @param completed Integer indicating number of completed prompts
#' @param state_path Path to save state file
#' @param type_spec Type specification for structured data extraction
#' @param judgements Number of judgements in a `batch_judge()` workflow (1 = initial extract + 1 judgement, 2 = initial extract + 2 judgements, etc.)
#' @param echo Level of output to display ("none", "text", "all")
#' @param input_type Type of input ("vector" or "list")
#' @param max_retries Maximum number of retry attempts
#' @param initial_delay Initial delay before first retry
#' @param max_delay Maximum delay between retries
#' @param backoff_factor Factor to multiply delay by after each retry
#' @param chunk_size Size of chunks for parallel processing
#' @param workers Number of parallel workers
#' @param plan Parallel backend plan
#' @param state Internal state tracking
#' @return Returns an S7 class object of class "batch" that represents a collection of prompts and their responses from chat models. The object contains all input parameters as properties and provides methods for:
#' \itemize{
#'   \item Extracting text responses via \code{texts()} (includes structured data when a type specification is provided)
#'   \item Accessing full chat objects via \code{chats()}
#'   \item Tracking processing progress via \code{progress()}
#' }
#' The batch object manages prompt processing, tracks completion status, and handles retries for failed requests.
#' @examplesIf ellmer::has_credentials("openai")
#' # Create a chat processor
#' chat <- chat_sequential(chat_openai())
#'
#' # Process a batch of prompts
#' batch <- chat$batch(list(
#'   "What is R?",
#'   "Explain base R versus tidyverse",
#'   "Explain vectors, lists, and data frames"
#' ))
#'
#' # Check the progress if interrupted
#' batch$progress()
#'
#' # Return the responses as a vector or list
#' batch$texts()
#'
#' # Return the chat objects
#' batch$chats()
#' @export
batch <- S7::new_class(
  "batch",
  properties = list(
    prompts = S7::new_property(
      class = S7::class_list,
      validator = function(value) {
        if (length(value) == 0) {
          "@prompts must not be empty"
        }
        if (!all(purrr::map_lgl(value, is.character))) {
          "@prompts must be a list of character strings"
        }
        NULL
      }
    ),
    responses = S7::new_property(
      class = S7::class_list,
      validator = function(value) NULL
    ),
    completed = S7::new_property(
      class = S7::class_integer,
      validator = function(value) {
        if (length(value) != 1) {
          "@completed must be a single integer"
        }
        if (value < 0) {
          "@completed must be non-negative"
        }
        NULL
      }
    ),
    state_path = S7::class_character | NULL,
    type_spec = S7::new_property(
      class = S7::class_any | NULL,
      validator = function(value) {
        if (!is.null(value)) {
          if (!inherits(value, c("ellmer::TypeObject", "ellmer::Type", "ellmer::TypeArray"))) {
            return("@type_spec must be an ellmer type specification (created with type_object(), type_array(), etc.) or NULL")
          }
        }
        NULL
      }
    ),
    judgements = S7::new_property(
      class = S7::class_integer,
      validator = function(value) {
        if (length(value) != 1) {
          "@judgements must be a single integer"
        }
        if (value < 0) {
          "@judgements must be non-negative"
        }
        NULL
      }
    ),
    echo = S7::new_property(
      class = S7::class_character,
      validator = function(value) {
        if (!value %in% c("none", "text", "all")) {
          "@echo must be one of 'none', 'text', or 'all'"
        }
        NULL
      }
    ),
    input_type = S7::new_property(
      class = S7::class_character,
      validator = function(value) {
        if (!value %in% c("vector", "list")) {
          "input_type must be either 'vector' or 'list'"
        } else {
          NULL
        }
      }
    ),
    max_retries = S7::new_property(
      class = S7::class_integer,
      validator = function(value) {
        if (length(value) != 1) {
          "@max_retries must be a single integer"
        }
        if (value < 0) {
          "@max_retries must be non-negative"
        }
        NULL
      }
    ),
    initial_delay = S7::new_property(
      class = S7::class_numeric,
      validator = function(value) {
        if (length(value) != 1) {
          "@initial_delay must be a single numeric"
        }
        if (value < 0) {
          "@initial_delay must be non-negative"
        }
        NULL
      }
    ),
    max_delay = S7::new_property(
      class = S7::class_numeric,
      validator = function(value) {
        if (length(value) != 1) {
          "@max_delay must be a single numeric"
        }
        if (value < 0) {
          "@max_delay must be non-negative"
        }
        NULL
      }
    ),
    backoff_factor = S7::new_property(
      class = S7::class_numeric,
      validator = function(value) {
        if (length(value) != 1) {
          "@backoff_factor must be a single numeric"
        }
        if (value <= 1) {
          "@backoff_factor must be greater than 1"
        }
        NULL
      }
    ),
    chunk_size = S7::new_property(
      class = S7::class_integer | NULL,
      validator = function(value) {
        if (!is.null(value)) {
          if (length(value) != 1) {
            "@chunk_size must be a single integer"
          }
          if (value <= 0) {
            "@chunk_size must be positive"
          }
        }
        NULL
      }
    ),
    workers = S7::new_property(
      class = S7::class_integer | NULL,
      validator = function(value) {
        if (!is.null(value)) {
          if (length(value) != 1) {
            "@workers must be a single integer"
          }
          if (value <= 0) {
            "@workers must be positive"
          }
        }
        NULL
      }
    ),
    plan = S7::new_property(
      class = S7::class_character | NULL,
      validator = function(value) {
        if (!is.null(value)) {
          if (!value %in% c("multisession", "multicore")) {
            "@plan must be either 'multisession' or 'multicore'"
          }
        }
        NULL
      }
    ),
    state = S7::new_property(
      class = S7::class_list | NULL,
      validator = function(value) {
        if (!is.null(value)) {
          required_fields <- c("active_workers", "failed_chunks", "retry_count")
          if (!all(required_fields %in% names(value))) {
            return("@state must contain active_workers, failed_chunks, and retry_count")
          }
        }
        NULL
      }
    )
  ),
  validator = function(self) {
    if (self@completed > length(self@prompts)) {
      "@completed cannot be larger than number of prompts"
    }
    if (!is.null(self@state)) {
      if (self@state$active_workers > self@workers) {
        return("Active workers cannot exceed total workers")
      }
    }
    NULL
  }
)


#' @keywords internal
S7::method(texts, batch) <- function(x, flatten = TRUE) {
  responses <- x@responses[seq_len(x@completed)]

  extract_text <- function(response) {
    if (is.null(response)) {
      return(NA_character_)
    }

    if (!is.null(response$structured_data)) {
      return(response$structured_data)
    }

    if (!is.null(response$text)) {
      return(response$text)
    }

    NA_character_
  }

  values <- purrr::map(responses, extract_text)

  if (x@input_type == "vector" && flatten && all(purrr::map_lgl(values, is.character))) {
    return(unlist(values))
  } else {
    return(values)
  }
}

#' @keywords internal
S7::method(chats, batch) <- function(x) {
  responses <- x@responses[seq_len(x@completed)]
  map(responses, "chat")
}

#' @keywords internal
S7::method(progress, batch) <- function(x) {
  list(
    total_prompts = length(x@prompts),
    completed_prompts = x@completed,
    completion_percentage = (x@completed / length(x@prompts)) * 100,
    remaining_prompts = length(x@prompts) - x@completed,
    state_path = x@state_path
  )
}
