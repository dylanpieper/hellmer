% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/chatalot.R
\name{seq_chat}
\alias{seq_chat}
\title{Process a lot of prompts in sequence}
\usage{
seq_chat(chat_model = NULL, ...)
}
\arguments{
\item{chat_model}{Character string specifying the chat model to use (e.g., "openai/gpt-4.1" or "anthropic/claude-3-5-sonnet-latest").
This creates an ellmer chat object using \code{\link[ellmer:chat-any]{ellmer::chat()}}.}

\item{...}{Additional arguments passed to the underlying chat model (e.g., \code{system_prompt})}
}
\value{
A process object (S7 class) containing
\itemize{
\item \strong{prompts}: Original input prompts
\item \strong{responses}: Raw response data for completed prompts
\item \strong{completed}: Number of successfully processed prompts
\item \strong{file}: Path where batch state is saved
\item \strong{type}: Type specification used for structured data
\item \strong{texts}: Function to extract text responses or structured data
\item \strong{chats}: Function to extract chat objects
\item \strong{progress}: Function to get processing status
\item \strong{process}: Function to process a lot of prompts
}
}
\description{
Process a lot of chat prompts in sequence, or one at a time.
Save responses to disk for each chat
and resume processing from the last saved chat.
For parallel processing, use \code{future_chat()}.
}
\section{Process Method}{

This function provides access to the \code{process()} method for sequential processing of prompts.
See \code{?process.sequential_chat} for full details of the method and its parameters.
}

\examples{
\dontshow{if (ellmer::has_credentials("openai")) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
# Create chat processor
chat <- seq_chat("openai/gpt-4.1")

# Process prompts
response <- chat$process(
  list(
    "What is R?",
    "Explain base R versus tidyverse",
    "Explain vectors, lists, and data frames"
  )
)


# Return responses
response$texts()

# Return chat objects
response$chats()

# Check progress if interrupted
response$progress()
\dontshow{\}) # examplesIf}
}
