#!/bin/bash
input=$(cat)

# Extract all fields from JSON in a single jq call
IFS=$'\t' read -r MODEL CONTEXT_SIZE CURRENT_TOKENS TOTAL_IN TOTAL_OUT DURATION_MS CUR_DIR <<< "$(echo "$input" | jq -r '
  .context_window.current_usage as $usage |
  [
    .model.display_name,
    .context_window.context_window_size,
    (if $usage != null then
      ($usage.input_tokens + $usage.cache_creation_input_tokens + $usage.cache_read_input_tokens)
    else
      0
    end),
    (.context_window.total_input_tokens // 0),
    (.context_window.total_output_tokens // 0),
    (.cost.total_duration_ms // 0),
    (.workspace.current_dir // "")
  ] | @tsv
')"

BRANCH=$(git -C "$CUR_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
PERCENT_USED=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
CUR_DIR_NAME="$(basename "$CUR_DIR")"

format_tokens() {
  local n=$1
  if (( n >= 1000000 )); then
    printf "%d.%dM" $((n / 1000000)) $((n % 1000000 / 100000))
  elif (( n >= 1000 )); then
    printf "%dk" $((n / 1000))
  else
    printf "%d" "$n"
  fi
}

format_duration() {
  local total_sec=$(($1 / 1000))
  local m=$((total_sec / 60))
  local s=$((total_sec % 60))
  if (( m > 0 )); then
    printf "%dm%02ds" "$m" "$s"
  else
    printf "%ds" "$s"
  fi
}

# Build statusline parts
parts=("[$MODEL]")
parts+=("$CUR_DIR_NAME")
[[ -n $BRANCH ]] && parts+=("$BRANCH")
parts+=("Context: ${PERCENT_USED}% (In:$(format_tokens "$TOTAL_IN") Out:$(format_tokens "$TOTAL_OUT"))")
parts+=("$(format_duration "$DURATION_MS")")

# Join with " | "
printf '%s' "${parts[0]}"
for part in "${parts[@]:1}"; do
  printf ' | %s' "$part"
done
echo
