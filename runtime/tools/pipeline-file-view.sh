#!/usr/bin/env zsh

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
BASE=$(cd -- "$SCRIPT_DIR/.." && pwd)
REFRESH_SECONDS="${PIPELINE_REFRESH_SECONDS:-10}"
MODE="${1:-task}"
PIPELINE_STATE_FILE="$BASE/workspace/shared/pipeline-state.json"

state_value() {
  local key="$1"
  [[ -f "$PIPELINE_STATE_FILE" ]] || return 1
  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$PIPELINE_STATE_FILE" | head -n 1
}

latest_matching_find() {
  local root="$1"
  local expr="$2"
  local -a files
  files=("${(@f)$(find "$root" -type f $=expr -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null)}")
  (( ${#files[@]} > 0 )) || return 1
  print -r -- "${files[1]}"
}

current_mode() {
  local mode=""
  mode="$(state_value current_mode 2>/dev/null || true)"
  [[ -n "$mode" ]] || return 1
  print -r -- "$mode"
}

current_task_id() {
  local task_id=""
  task_id="$(state_value current_task_id 2>/dev/null || true)"
  [[ -n "$task_id" ]] || return 1
  print -r -- "$task_id"
}

current_meeting_id() {
  local meeting_id=""
  meeting_id="$(state_value current_meeting_id 2>/dev/null || true)"
  [[ -n "$meeting_id" ]] || return 1
  print -r -- "$meeting_id"
}

resolve_task_file() {
  local task_id="$1"
  local task_file="$BASE/workspace/shared/tasks/${task_id}.json"
  [[ -f "$task_file" ]] && print -r -- "$task_file"
}

resolve_handoff_file() {
  local task_id="$1"
  local file

  for file in \
    "$BASE/workspace/executor/handoff/$task_id/$task_id.md" \
    "$BASE/workspace/executor/handoff/$task_id/$task_id-done.md" \
    "$BASE/workspace/qa/handoff/$task_id/$task_id-done.md" \
    "$BASE/workspace/architect/handoff/$task_id/$task_id-done.md" \
    "$BASE/workspace/executor/handoff/${task_id}-done.md" \
    "$BASE/workspace/qa/handoff/${task_id}-done.md" \
    "$BASE/workspace/architect/handoff/${task_id}-done.md"; do
    [[ -f "$file" ]] && print -r -- "$file" && return 0
  done

  latest_matching_find "$BASE/workspace" "! -name '*.meta.json' -a \\( -path '$BASE/workspace/architect/handoff/*${task_id}*' -o -path '$BASE/workspace/qa/handoff/*${task_id}*' -o -path '$BASE/workspace/executor/handoff/*${task_id}*' -o -path '$BASE/workspace/shared/handoffs/*${task_id}*' \\)"
}

resolve_qa_report_file() {
  local task_id="$1"
  local file

  for file in \
    "$BASE/workspace/executor/handoff/$task_id/qa-report.json" \
    "$BASE/workspace/qa/handoff/$task_id/qa-report.json" \
    "$BASE/workspace/executor/handoff/$task_id/${task_id}-qa-report.json" \
    "$BASE/workspace/qa/handoff/$task_id/${task_id}-qa-report.json"; do
    [[ -f "$file" ]] && print -r -- "$file" && return 0
  done

  latest_matching_find "$BASE/workspace" "\\( -name '*${task_id}*qa-report*.json' -o -name '*${task_id}*qa-*.json' -o -path '*/${task_id}/qa-report.json' \\)"
}

resolve_decision_file() {
  local task_id="$1"
  latest_matching_find "$BASE/workspace" "\\( -name '*${task_id}*decision*.json' -o -name '*${task_id}*dec-*.json' -o -path '*/${task_id}/decision.json' \\)"
}

resolve_meeting_state_file() {
  local meeting_id="$1"
  local file="$BASE/workspace/shared/meetings/${meeting_id}/04-state.json"
  [[ -f "$file" ]] && print -r -- "$file"
}

resolve_file() {
  local task_id=""
  local effective_mode="$MODE"
  local meeting_id=""

  [[ "$effective_mode" == "auto" ]] && effective_mode="task"

  if ! task_id="$(current_task_id 2>/dev/null)"; then
    task_id=""
  fi

  case "$effective_mode" in
    task)
      [[ -n "$task_id" ]] || return 1
      resolve_task_file "$task_id"
      ;;
    handoff)
      [[ -n "$task_id" ]] || return 1
      resolve_handoff_file "$task_id"
      ;;
    qa-report)
      [[ -n "$task_id" ]] || return 1
      resolve_qa_report_file "$task_id"
      ;;
    decision)
      [[ -n "$task_id" ]] || return 1
      resolve_decision_file "$task_id"
      ;;
    meeting)
      meeting_id="$(current_meeting_id 2>/dev/null || true)"
      [[ -n "$meeting_id" ]] || return 1
      resolve_meeting_state_file "$meeting_id"
      ;;
    system)
      print -r -- "$BASE/workspace/shared/SYSTEM.md"
      ;;
    *)
      return 1
      ;;
  esac
}

json_value() {
  local key="$1"
  local file="$2"
  [[ -f "$file" ]] || return 1
  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$file" | head -n 1
}

task_array_values() {
  local key="$1"
  local file="$2"
  [[ -f "$file" ]] || return 1

  awk -v key="\"$key\"" '
    $0 ~ key "[[:space:]]*:[[:space:]]*\\[" { in_array=1; next }
    in_array && /\]/ { exit }
    in_array {
      gsub(/^[[:space:]]*"/, "", $0)
      gsub(/",[[:space:]]*$/, "", $0)
      gsub(/"$/, "", $0)
      if (length($0) > 0) print $0
    }
  ' "$file"
}

file_state() {
  local path="$1"
  if [[ -f "$BASE/$path" ]]; then
    print -r -- "OK"
  else
    print -r -- "--"
  fi
}

display_path() {
  local path="$1"
  if [[ -n "$path" ]]; then
    print -r -- "${path#$BASE/}"
  else
    print -r -- "--"
  fi
}

print_rule() {
  printf '+-%-18s-+-%-12s-+-%-61s-+\n' \
    '------------------' \
    '------------' \
    '-------------------------------------------------------------'
}

print_row() {
  local col1="$1"
  local col2="$2"
  local col3="$3"
  printf '| %-18.18s | %-12.12s | %-61.61s |\n' "$col1" "$col2" "$col3"
}

render_no_task() {
  local meeting_id=""
  local current_work_mode=""

  meeting_id="$(current_meeting_id 2>/dev/null || echo none)"
  current_work_mode="$(current_mode 2>/dev/null || echo meeting)"

  echo "\033[1;37m[5] CURRENT TASK\033[0m  自动刷新 ${REFRESH_SECONDS}s"
  echo "\033[90m窗口 5 只追踪 current task；没有 active execution task 时不回退到会议正文或旧任务\033[0m"
  echo
  print_rule
  print_row "Task" "none" "当前没有处于 queued/in_progress/blocked 的执行任务"
  print_row "Mode" "${current_work_mode:-meeting}" "current_task_id 未设置"
  print_row "Meeting" "$( [[ "$meeting_id" != "none" ]] && echo LINKED || echo -- )" "id=${meeting_id}"
  print_rule
  echo
  echo "当前 action 已转换完成；等待新的执行任务被激活。"
}

render_task_status() {
  local file="$1"
  local task_id="$2"
  local summary=""
  local task_status=""
  local assigned_to=""
  local handoff_to=""
  local current_work_mode=""
  local linked_meeting_id=""
  local input_file=""
  local output_file=""
  local output_status=""
  local handoff_file=""
  local qa_report_file=""
  local decision_file=""
  local source_action_id=""

  summary="$(json_value summary "$file" 2>/dev/null || true)"
  task_status="$(json_value status "$file" 2>/dev/null || true)"
  assigned_to="$(json_value assigned_to "$file" 2>/dev/null || true)"
  handoff_to="$(json_value handoff_to "$file" 2>/dev/null || true)"
  current_work_mode="$(current_mode 2>/dev/null || echo execution)"
  linked_meeting_id="$(json_value source_meeting_id "$file" 2>/dev/null || current_meeting_id 2>/dev/null || true)"
  source_action_id="$(json_value source_action_id "$file" 2>/dev/null || true)"
  input_file="$(task_array_values inputs "$file" 2>/dev/null | head -n 1 || true)"
  output_file="$(task_array_values outputs "$file" 2>/dev/null | head -n 1 || true)"

  if [[ -n "$output_file" ]]; then
    output_status="$(file_state "$output_file")"
  else
    output_status="--"
  fi

  handoff_file="$(resolve_handoff_file "$task_id" 2>/dev/null || true)"
  qa_report_file="$(resolve_qa_report_file "$task_id" 2>/dev/null || true)"
  decision_file="$(resolve_decision_file "$task_id" 2>/dev/null || true)"

  echo "\033[1;37m[5] CURRENT TASK\033[0m  自动刷新 ${REFRESH_SECONDS}s"
  echo "\033[90m窗口 5 只显示当前执行对象；会议产物留在窗口 4 的 action registry\033[0m"
  echo
  print_rule
  print_row "Task" "${task_id:-none}" "${summary:-No task summary}"
  print_row "Status" "${task_status:---}" "source_action=${source_action_id:---}"
  print_row "Owner" "${assigned_to:---}" "handoff_to=${handoff_to:---}"
  print_row "Mode" "${current_work_mode:-execution}" "current_task only"
  print_row "Meeting" "$( [[ -n "$linked_meeting_id" ]] && echo LINKED || echo -- )" "id=${linked_meeting_id:-none}"
  print_row "Task JSON" "$(file_state "workspace/shared/tasks/${task_id}.json")" "${file#$BASE/}"
  print_row "Primary Input" "$( [[ -n "$input_file" ]] && file_state "$input_file" || echo -- )" "${input_file:---}"
  print_row "Primary Output" "$output_status" "${output_file:---}"
  print_row "Handoff" "$( [[ -n "$handoff_file" ]] && echo OK || echo -- )" "$(display_path "$handoff_file")"
  print_row "QA Report" "$( [[ -n "$qa_report_file" ]] && echo OK || echo -- )" "$(display_path "$qa_report_file")"
  print_row "Decision" "$( [[ -n "$decision_file" ]] && echo OK || echo -- )" "$(display_path "$decision_file")"
  print_rule
}

render_file() {
  local file="$1"
  local task_id="$2"

  echo "\033[1;37m[5] FILE VIEW\033[0m  自动刷新 ${REFRESH_SECONDS}s"
  echo "\033[90m手动模式：task|handoff|qa-report|decision|meeting|system  当前=$MODE\033[0m"
  echo "\033[90mCURRENT_TASK=${task_id:-none}\033[0m"
  echo
  echo "\033[1;36mFILE\033[0m  $file"
  echo
  sed -n '1,120p' "$file"
}

while true; do
  clear
  zsh "$SCRIPT_DIR/meeting-sync.sh" >/dev/null 2>&1 || true
  if ! task_id="$(current_task_id 2>/dev/null)"; then
    task_id=""
  fi

  if [[ "$MODE" == "auto" || "$MODE" == "task" ]]; then
    if [[ -n "$task_id" ]] && file="$(resolve_task_file "$task_id" 2>/dev/null)" && [[ -f "$file" ]]; then
      render_task_status "$file" "$task_id"
    else
      render_no_task
    fi
  elif file="$(resolve_file 2>/dev/null)" && [[ -n "$file" && -f "$file" ]]; then
    render_file "$file" "$task_id"
  else
    echo "\033[1;37m[5] FILE VIEW\033[0m  自动刷新 ${REFRESH_SECONDS}s"
    echo
    echo "当前模式没有可显示文件。"
  fi
  sleep "$REFRESH_SECONDS"
done
