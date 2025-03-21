# hellmer 0.1.2
## Patch release
* Clarified package features and methods in DESCRIPTION file.
## R CMD check results
0 errors | 0 warnings | 0 notes

# hellmer 0.1.1
## Patch release
* Removed `structured_data()` method as `texts()` now handles structured data responses.
* Updated package documentation for better organization and clarity.
* Added experimental support for LLM-as-a-judge to refine extracted data via the `judgements` parameter.
## R CMD check results
0 errors | 0 warnings | 0 notes

# hellmer 0.1.0
## Resubmission
This is a resubmission. I addressed the reviewer's feedback by taking the following actions:
* Expanded the DESCRIPTION with more detailed information about package functionality and implemented methods.
* Added \value tags to all exported function documentation, including batch.Rd.
* Added executable examples to all Rd files with proper structure using @examplesIf to verify a required API key.
* Replaced direct console output using cat() with cli-based messages in R/hellmer-core.R that provide consistent formatting and user feedback. Given the potentially lengthy runtime of batch processing operations in this package, informative progress updates are essential for users to monitor batch status and estimate completion times.
## R CMD check results
0 errors | 0 warnings | 0 notes
* This is a new release.