#!/usr/bin/env zsh

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
BASE=$(cd -- "$SCRIPT_DIR/.." && pwd)
MEETINGS_DIR="$BASE/workspace/shared/meetings"
STATE_FILE="$BASE/workspace/shared/pipeline-state.json"
RUNTIME_BRIEFING_FILE="$BASE/workspace/shared/runtime-briefing.json"
ACTION_REGISTRY_FILE="$BASE/workspace/shared/action-registry.json"
REFRESH_SECONDS="${PIPELINE_REFRESH_SECONDS:-10}"

state_value() {
  local key="$1"
  [[ -f "$STATE_FILE" ]] || return 1
  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$STATE_FILE" | head -n 1
}

latest_meeting_dir() {
  local -a dirs
  dirs=("$MEETINGS_DIR"/*(/Nom))
  (( ${#dirs[@]} > 0 )) || return 1
  print -r -- "${dirs[1]}"
}

current_meeting_dir() {
  local meeting_id=""
  meeting_id="$(state_value current_meeting_id 2>/dev/null || true)"

  if [[ -n "$meeting_id" && -d "$MEETINGS_DIR/$meeting_id" ]]; then
    print -r -- "$MEETINGS_DIR/$meeting_id"
  else
    latest_meeting_dir
  fi
}

json_string_value() {
  local file="$1"
  local key="$2"
  [[ -f "$file" ]] || return 1
  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$file" | head -n 1
}

json_array_values() {
  local file="$1"
  local key="$2"
  [[ -f "$file" ]] || return 1

  awk -v key="\"$key\"" '
    $0 ~ key "[[:space:]]*:[[:space:]]*\\[" { in_array=1; next }
    in_array && /\]/ { exit }
    in_array {
      line=$0
      gsub(/^[[:space:]]*"/, "", line)
      gsub(/",[[:space:]]*$/, "", line)
      gsub(/"$/, "", line)
      if (length(line) > 0) print line
    }
  ' "$file"
}

runtime_briefing_file() {
  if [[ -f "$RUNTIME_BRIEFING_FILE" ]]; then
    print -r -- "$RUNTIME_BRIEFING_FILE"
    return 0
  fi

  local fallback="$BASE/workspace/executor/outputs/runtime-briefing-example-v0.1.json"
  [[ -f "$fallback" ]] || return 1
  print -r -- "$fallback"
}

nested_json_string_value() {
  local file="$1"
  local object_key="$2"
  local key="$3"
  [[ -f "$file" ]] || return 1

  awk -v obj="\""${object_key}"\"" -v key="\""${key}"\"" '
    $0 ~ obj "[[:space:]]*:[[:space:]]*\\{" { in_obj=1; next }
    in_obj && /^[[:space:]]*\}/ { exit }
    in_obj && $0 ~ key "[[:space:]]*:[[:space:]]*" {
      line=$0
      sub(/.*:[[:space:]]*"/, "", line)
      sub(/".*/, "", line)
      print line
      exit
    }
  ' "$file"
}

agenda_meta_value() {
  local file="$1"
  local label="$2"
  [[ -f "$file" ]] || return 1
  sed -n "s/^- \\*\\*${label}\\*\\*[：:]\\(.*\\)$/\\1/p" "$file" | sed 's/^[[:space:]]*//' | head -n 1
}

agenda_problem_values() {
  local file="$1"
  [[ -f "$file" ]] || return 1

  awk '
    /^## 议题/ { in_section=1; next }
    in_section && /^## / { exit }
    in_section {
      line=$0
      gsub(/^[[:space:]]*[-0-9.]*[[:space:]]*/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (length(line) > 0) print line
    }
  ' "$file"
}

discussion_events() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  rg '^## \[' "$file" | tail -n 3 | sed 's/^## \[//; s/\] — / | /; s/\] / | /; s/\]//'
}

derived_phase() {
  local dir="$1"
  local discussion="$dir/01-discussion.md"
  local decisions="$dir/02-decisions.md"
  local actions="$dir/03-actions.md"

  if [[ -f "$actions" ]] && rg -q '^### A[0-9]+' "$actions"; then
    print -r -- "action"
  elif [[ -f "$decisions" ]] && rg -q '^### D[0-9]+' "$decisions"; then
    print -r -- "decision"
  elif [[ -f "$discussion" ]] && rg -q '^## \[' "$discussion"; then
    print -r -- "discussion"
  else
    print -r -- "agenda"
  fi
}

find_linked_task() {
  local action_id="$1"
  local task_file=""

  task_file="$(rg -l "\"source_action_id\"[[:space:]]*:[[:space:]]*\"${action_id}\"" "$BASE/workspace/shared/tasks" 2>/dev/null | head -n 1 || true)"
  [[ -n "$task_file" ]] || return 1
  print -r -- "${task_file:t:r}"
}

task_status_value() {
  local task_id="$1"
  local file="$BASE/workspace/shared/tasks/${task_id}.json"
  [[ -f "$file" ]] || return 1
  json_string_value "$file" status
}

action_registry_rows() {
  local actions_file="$1"
  if [[ -f "$ACTION_REGISTRY_FILE" ]]; then
    python3 - "$ACTION_REGISTRY_FILE" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
for entry in data.get("entries", []):
    print("\t".join([
        entry.get("action_id", ""),
        entry.get("title", ""),
        entry.get("owner_role", "--"),
        entry.get("state", "OPEN"),
        entry.get("linked_task_id", "")
    ]))
PY
    return 0
  fi

  [[ -f "$actions_file" ]] || return 1

  awk '
    /^### A[0-9]+：/ {
      if (action_id != "") {
        printf "%s\t%s\t%s\t%s\t%s\n", action_id, title, owner, "OPEN", ""
      }
      line=$0
      sub(/^### /, "", line)
      split(line, parts, "：")
      action_id=parts[1]
      title=substr(line, length(action_id) + 4)
      owner="--"
      next
    }
    /^- 负责：/ {
      owner=$0
      sub(/^- 负责：[[:space:]]*/, "", owner)
      next
    }
    END {
      if (action_id != "") {
        printf "%s\t%s\t%s\t%s\t%s\n", action_id, title, owner, "OPEN", ""
      }
    }
  ' "$actions_file"
}

render_panel() {
  local dir="$1"
  local state_file="$dir/04-state.json"
  local agenda="$dir/00-agenda.md"
  local actions="$dir/03-actions.md"
  local discussion="$dir/01-discussion.md"
  local meeting_id=""
  local date=""
  local host=""
  local phase=""
  local current_mode=""
  local current_task=""
  local current_action=""
  local current_executor=""
  local current_step=""
  local started_at=""
  local runtime_source=""
  local briefing_file=""
  local line=""
  local count=0

  meeting_id="$(json_string_value "$state_file" meeting_id 2>/dev/null || agenda_meta_value "$agenda" '会议 ID' 2>/dev/null || echo "${dir:t}")"
  date="$(json_string_value "$state_file" date 2>/dev/null || agenda_meta_value "$agenda" '日期' 2>/dev/null || echo --)"
  host="$(json_string_value "$state_file" host 2>/dev/null || agenda_meta_value "$agenda" '主持人（Architect）' 2>/dev/null || echo --)"
  phase="$(json_string_value "$state_file" phase 2>/dev/null || derived_phase "$dir")"
  current_mode="$(state_value current_mode 2>/dev/null || echo meeting)"
  current_task="$(state_value current_task_id 2>/dev/null || true)"

  if briefing_file="$(runtime_briefing_file 2>/dev/null)"; then
    runtime_source="${briefing_file#$BASE/}"
    current_mode="$(nested_json_string_value "$briefing_file" current_control_state current_mode 2>/dev/null || echo "$current_mode")"
    current_action="$(nested_json_string_value "$briefing_file" current_control_state current_action_id 2>/dev/null || true)"
    current_task="$(nested_json_string_value "$briefing_file" current_control_state current_task_id 2>/dev/null || echo "$current_task")"
    current_executor="$(nested_json_string_value "$briefing_file" current_control_state current_executor 2>/dev/null || true)"
    current_step="$(nested_json_string_value "$briefing_file" current_control_state current_step 2>/dev/null || true)"
    started_at="$(nested_json_string_value "$briefing_file" current_control_state started_at 2>/dev/null || true)"
  fi

  echo "\033[1;37m[4] MEETING CONTROL\033[0m  自动刷新 ${REFRESH_SECONDS}s"
  echo "\033[90m窗口 4 只显示会议控制状态与 action registry，不显示会议正文\033[0m"
  echo
  printf "\033[1;36mMEETING\033[0m  %s\n" "$meeting_id"
  printf "\033[1;36mDATE\033[0m     %s\n" "$date"
  printf "\033[1;36mHOST\033[0m     %s\n" "$host"
  printf "\033[1;36mPHASE\033[0m    %s\n" "$phase"
  printf "\033[1;36mMODE\033[0m     %s\n" "$current_mode"
  printf "\033[1;36mTASK\033[0m     %s\n" "${current_task:---}"
  echo
  echo "\033[1;33mRuntime Status\033[0m"
  printf "  %-12s %s\n" "Mode" "${current_mode:---}"
  printf "  %-12s %s\n" "Current Action" "${current_action:---}"
  printf "  %-12s %s\n" "Current Task" "${current_task:---}"
  printf "  %-12s %s\n" "Executor" "${current_executor:---}"
  printf "  %-12s %s\n" "Step" "${current_step:---}"
  printf "  %-12s %s\n" "Started At" "${started_at:---}"
  printf "  %-12s %s\n" "Source" "${runtime_source:---}"
  echo
  echo "\033[1;33mProblems\033[0m"

  while IFS= read -r line; do
    (( count += 1 ))
    printf "  %d. %s\n" "$count" "$line"
  done < <(json_array_values "$state_file" problems 2>/dev/null || agenda_problem_values "$agenda" 2>/dev/null || true)

  if (( count == 0 )); then
    echo "  - 无结构化问题定义"
  fi

  echo
  echo "\033[1;33mRecent Events\033[0m"
  count=0
  while IFS= read -r line; do
    (( count += 1 ))
    printf "  - %s\n" "$line"
  done < <(json_array_values "$state_file" recent_events 2>/dev/null || discussion_events "$discussion" 2>/dev/null || true)

  if (( count == 0 )); then
    echo "  - 暂无最近事件"
  fi

  echo
  echo "\033[1;33mAction Registry\033[0m"
  printf "%-6s %-44s %-24s %-12s %-12s\n" "ID" "Title" "Owner" "State" "Task"
  printf "%-6s %-44s %-24s %-12s %-12s\n" "------" "--------------------------------------------" "------------------------" "------------" "------------"

  count=0
  while IFS=$'\t' read -r action_id title owner linked_state linked_task; do
    (( count += 1 ))
    if [[ -z "$linked_state" ]]; then
      linked_state="OPEN"
    fi
    if [[ -z "$linked_task" ]]; then
      linked_task="$(find_linked_task "$action_id" 2>/dev/null || true)"
    fi
    if [[ -n "$linked_task" && "$linked_state" == "OPEN" ]]; then
      linked_state="$(task_status_value "$linked_task" 2>/dev/null || echo LINKED)"
    fi
    printf "%-6.6s %-44.44s %-24.24s %-12.12s %-12.12s\n" \
      "$action_id" \
      "$title" \
      "$owner" \
      "$linked_state" \
      "${linked_task:---}"
  done < <(action_registry_rows "$actions" 2>/dev/null || true)

  if (( count == 0 )); then
    echo "  暂无 action registry。"
  fi

  echo
  if [[ -f "$ACTION_REGISTRY_FILE" ]]; then
    echo "\033[90m来源：${state_file#$BASE/}  ${ACTION_REGISTRY_FILE#$BASE/}\033[0m"
  else
    echo "\033[90m来源：${state_file#$BASE/}  ${actions#$BASE/}\033[0m"
  fi
}

show_system() {
  local system_file="$BASE/workspace/shared/SYSTEM.md"
  echo "\033[1;37m[4] MEETING CONTROL\033[0m  自动刷新 ${REFRESH_SECONDS}s"
  echo
  if [[ -f "$system_file" ]]; then
    echo "\033[1;36mSTATE\033[0m  无活跃会议，降级显示系统规范"
    echo "\033[1;36mFILE\033[0m   $system_file"
    echo
    sed -n '1,80p' "$system_file"
  else
    echo "\033[90m暂无 meeting，也未找到 workspace/shared/SYSTEM.md\033[0m"
  fi
}

while true; do
  clear
  zsh "$SCRIPT_DIR/meeting-sync.sh" >/dev/null 2>&1 || true

  if ! dir=$(current_meeting_dir 2>/dev/null); then
    show_system
    sleep "$REFRESH_SECONDS"
    continue
  fi

  render_panel "$dir"
  sleep "$REFRESH_SECONDS"
done
