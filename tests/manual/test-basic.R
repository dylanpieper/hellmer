chat <- chat_sequential(system_prompt = "Reply concisely")

prompts <- c(
  "What is 2+2?",
  "Name one planet.",
  "Is water wet?",
  "What color is the sky?",
  "Count to 3.",
  "Say hello.",
  "Name a primary color.",
  "What is 5x5?",
  "True or false: Birds can fly.",
  "What day comes after Monday?"
)

#prompts <- as.list(prompts) # works with list or vector

result <- chat$batch(prompts) # resumes if interrupted

result$progress()
result$texts()
result$chats()