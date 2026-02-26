#!/bin/bash
input=$(cat)

IFS=$'\t' read -r MODEL CONTEXT_SIZE CURRENT_TOKENS <<< "$(echo "$input" | jq -r '
  .context_window.current_usage as $usage |
  [
    .model.display_name,
    .context_window.context_window_size,
    (if $usage != null then
      ($usage.input_tokens + $usage.cache_creation_input_tokens + $usage.cache_read_input_tokens)
    else
      0
    end)
  ] | @tsv
')"

PERCENT_USED=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
echo "[$MODEL] Context: ${PERCENT_USED}%"
