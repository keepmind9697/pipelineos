#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Read-only task pool auditor for PipelineOS")
    parser.add_argument("--base", default=".", help="Workspace base directory")
    parser.add_argument("--meeting-id", default="", help="Active meeting id override")
    parser.add_argument("--timeout-hours", type=int, default=24, help="Queued task stale timeout")
    return parser.parse_args()


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def iso_now() -> str:
    return datetime.now(timezone(timedelta(hours=8))).replace(microsecond=0).isoformat()


def parse_dt(value: str | None) -> datetime | None:
    if not value:
      return None
    try:
        value = value.replace("Z", "+00:00")
        return datetime.fromisoformat(value)
    except Exception:
        return None


@dataclass
class Decision:
    subject_type: str
    subject_id: str
    classification: str
    visible_to_runtime: bool
    eligible_for_current_selector: bool
    reason_codes: list[str]
    recommended_action_type: str
    requires_human_review: bool


def read_active_meeting(base: Path, override: str) -> str:
    if override:
        return override
    state_path = base / "workspace/shared/pipeline-state.json"
    if state_path.exists():
        try:
            data = load_json(state_path)
            return data.get("current_meeting_id", "")
        except Exception:
            return ""
    return ""


def classify_task(
    task_id: str,
    task: dict[str, Any],
    active_meeting_id: str,
    duplicate_ids: set[str],
    timeout_hours: int,
) -> tuple[Decision, dict[str, Any] | None]:
    status = str(task.get("status", ""))
    source_action_id = str(task.get("source_action_id", "") or "")
    source_meeting_id = str(task.get("source_meeting_id", "") or "")
    last_updated = str(task.get("last_updated", "") or "")
    working_scope = str(task.get("working_scope", "") or "")

    reasons: list[str] = []
    classification = "unsafe"
    action_type = "repair_metadata"
    visible = False
    selectable = False
    requires_human_review = False

    required = ["task_id", "role", "summary", "status", "assigned_to", "created_at", "last_updated", "inputs", "outputs", "handoff_to"]
    missing_required = [k for k in required if k not in task]
    if missing_required:
        reasons.append("schema_invalid")
        decision = Decision("task", task_id, "unsafe", False, False, reasons, "repair_metadata", False)
        return decision, None

    if active_meeting_id and source_meeting_id and source_meeting_id != active_meeting_id:
        classification = "out_of_meeting_scope"
        reasons.append("not_active_meeting")
        action_type = "exclude_from_current_selector"
    elif not source_action_id:
        classification = "orphan"
        reasons.append("missing_source_action_id")
        action_type = "repair_metadata"
    elif not source_meeting_id:
        classification = "orphan"
        reasons.append("missing_source_meeting_id")
        action_type = "repair_metadata"
    elif task_id in duplicate_ids:
        classification = "duplicate"
        reasons.append("duplicate_source_action")
        reasons.append("canonical_task_exists")
        action_type = "mark_cleanup_candidate"
        requires_human_review = True
    else:
        last_dt = parse_dt(last_updated)
        if status == "queued" and last_dt is not None:
            if datetime.now(last_dt.tzinfo or timezone.utc) - last_dt > timedelta(hours=timeout_hours):
                classification = "stale"
                reasons.append("queued_timeout_exceeded")
                action_type = "suppress_from_live_pool"
            else:
                classification = "live"
                visible = True
                selectable = True
        elif status in {"in_progress", "blocked", "ready_for_qa"}:
            classification = "live_blocked" if status in {"blocked", "ready_for_qa"} else "live"
            visible = True
            selectable = status == "in_progress"
            if status == "blocked":
                reasons.append("missing_dependency")
                action_type = "relink_to_action"
            elif status == "ready_for_qa":
                reasons.append("waiting_validation")
                action_type = "exclude_from_current_selector"
            else:
                action_type = "exclude_from_current_selector"
        else:
            classification = "stale"
            action_type = "suppress_from_live_pool"

    if classification == "live":
        live_item = {
            "task_id": task_id,
            "source_meeting_id": source_meeting_id,
            "source_action_id": source_action_id,
            "status": status,
            "priority": "unknown",
            "working_scope": working_scope or "--",
            "why_live": "Current meeting linked, action linked, and not suppressed by duplicate/stale safety rules.",
            "selection_eligible": selectable,
            "selection_blockers": reasons,
        }
    elif classification == "live_blocked":
        live_item = {
            "task_id": task_id,
            "source_meeting_id": source_meeting_id,
            "source_action_id": source_action_id,
            "status": status,
            "priority": "unknown",
            "working_scope": working_scope or "--",
            "why_live": "Visible to runtime for awareness, but blocked from current-task selection.",
            "selection_eligible": False,
            "selection_blockers": reasons or [status],
        }
    else:
        live_item = None

    decision = Decision("task", task_id, classification, visible, selectable, reasons, action_type, requires_human_review)
    return decision, live_item


def main() -> int:
    args = parse_args()
    base = Path(args.base).resolve()
    tasks_dir = base / "workspace/shared/tasks"
    outputs_dir = base / "workspace/executor/outputs"
    outputs_dir.mkdir(parents=True, exist_ok=True)

    active_meeting_id = read_active_meeting(base, args.meeting_id)
    total_files_seen = 0
    parseable_tasks = 0
    unparseable_files = 0
    queued_count = 0
    in_progress_count = 0
    ready_for_qa_count = 0

    parsed_tasks: dict[str, dict[str, Any]] = {}
    unsafe_tasks: list[dict[str, Any]] = []

    for path in sorted(tasks_dir.glob("*.json")):
        total_files_seen += 1
        try:
            task = load_json(path)
        except Exception:
            unparseable_files += 1
            unsafe_tasks.append(
                {
                    "task_path": str(path.relative_to(base)),
                    "task_id": "",
                    "unsafe_reason": "Task file is unreadable JSON.",
                    "severity": "high",
                    "repair_suggestion": "Repair or quarantine this file before runtime consumes it.",
                }
            )
            continue

        parseable_tasks += 1
        task_id = str(task.get("task_id", path.stem))
        parsed_tasks[task_id] = task
        status = str(task.get("status", ""))
        if status == "queued":
            queued_count += 1
        elif status == "in_progress":
            in_progress_count += 1
        elif status == "ready_for_qa":
            ready_for_qa_count += 1

    groups: dict[tuple[str, str], list[str]] = defaultdict(list)
    for task_id, task in parsed_tasks.items():
        source_action_id = str(task.get("source_action_id", "") or "")
        source_meeting_id = str(task.get("source_meeting_id", "") or "")
        if source_action_id and source_meeting_id:
            groups[(source_meeting_id, source_action_id)].append(task_id)

    duplicate_groups = []
    duplicate_ids: set[str] = set()
    for index, ((source_meeting_id, source_action_id), task_ids) in enumerate(sorted(groups.items()), start=1):
        if len(task_ids) < 2:
            continue
        canonical = sorted(task_ids)[0]
        dupes = sorted(task_ids)[1:]
        duplicate_ids.update(dupes)
        duplicate_groups.append(
            {
                "group_id": f"dup-{index:03d}",
                "canonical_task_id": canonical,
                "duplicate_task_ids": dupes,
                "match_basis": ["source_meeting_id", "source_action_id"],
                "source_meeting_id": source_meeting_id,
                "source_action_id": source_action_id,
                "recommended_cleanup_state": "cleanup_candidate",
            }
        )

    live_candidates = []
    stale_tasks = []
    orphan_tasks = []
    decisions: list[Decision] = []

    for task_id, task in sorted(parsed_tasks.items()):
        decision, live_item = classify_task(task_id, task, active_meeting_id, duplicate_ids, args.timeout_hours)
        decisions.append(decision)
        if live_item:
            live_candidates.append(live_item)

        if decision.classification == "stale":
            stale_tasks.append(
                {
                    "task_id": task_id,
                    "status": task.get("status", ""),
                    "last_update": task.get("last_updated", ""),
                    "timeout": f"{args.timeout_hours}h",
                    "stale_state": "stale",
                    "source_meeting_id": task.get("source_meeting_id", ""),
                    "source_action_id": task.get("source_action_id", ""),
                    "stale_reason": ", ".join(decision.reason_codes) or "suppressed_by_policy",
                    "reactivation_requirement": "Explicit relink to active meeting/action context.",
                }
            )
        elif decision.classification in {"orphan", "out_of_meeting_scope"}:
            missing_fields = []
            if not task.get("source_meeting_id"):
                missing_fields.append("source_meeting_id")
            if not task.get("source_action_id"):
                missing_fields.append("source_action_id")
            orphan_tasks.append(
                {
                    "task_id": task_id,
                    "status": task.get("status", ""),
                    "missing_fields": missing_fields,
                    "last_update": task.get("last_updated", ""),
                    "reason_orphaned": ", ".join(decision.reason_codes) or decision.classification,
                    "archive_candidate": decision.classification == "out_of_meeting_scope",
                    "repairable": decision.classification == "orphan",
                }
            )
        elif decision.classification == "unsafe" and all(item.get("task_id") != task_id for item in unsafe_tasks):
            unsafe_tasks.append(
                {
                    "task_path": str((tasks_dir / f"{task_id}.json").relative_to(base)),
                    "task_id": task_id,
                    "unsafe_reason": ", ".join(decision.reason_codes) or "schema_invalid",
                    "severity": "high",
                    "repair_suggestion": "Normalize task schema before runtime consumption.",
                }
            )

    recommended_actions = [
        {
            "action_id": "audit-001",
            "action_type": "exclude_from_current_selector",
            "target_scope": "workspace/shared/tasks/",
            "reason": "Runtime must not select current work directly from the raw task directory.",
            "priority": "high",
            "owner_role": "runtime",
            "destructive": False,
            "requires_human_review": False,
        },
        {
            "action_id": "audit-002",
            "action_type": "repair_metadata",
            "target_scope": "tasks missing source_action_id or source_meeting_id",
            "reason": "Metadata gaps prevent safe live-task mapping and duplicate detection.",
            "priority": "high",
            "owner_role": "executor",
            "destructive": False,
            "requires_human_review": False,
        },
    ]

    if duplicate_groups:
        recommended_actions.append(
            {
                "action_id": "audit-003",
                "action_type": "mark_cleanup_candidate",
                "target_scope": "duplicate task groups",
                "reason": "Duplicate task groups should be suppressed from live scheduling without destructive cleanup.",
                "priority": "medium",
                "owner_role": "runtime",
                "destructive": False,
                "requires_human_review": True,
            }
        )

    report = {
        "summary": {
            "generated_at": iso_now(),
            "active_meeting_id": active_meeting_id,
            "total_files_seen": total_files_seen,
            "parseable_tasks": parseable_tasks,
            "unparseable_files": unparseable_files,
            "queued_count": queued_count,
            "in_progress_count": in_progress_count,
            "ready_for_qa_count": ready_for_qa_count,
            "stale_count": len(stale_tasks),
            "duplicate_count": sum(len(g["duplicate_task_ids"]) for g in duplicate_groups),
            "orphan_count": len(orphan_tasks),
            "unsafe_count": len(unsafe_tasks),
            "live_candidate_count": len(live_candidates),
        },
        "live_candidates": live_candidates,
        "stale_tasks": stale_tasks,
        "duplicate_groups": duplicate_groups,
        "orphan_tasks": orphan_tasks,
        "unsafe_tasks": unsafe_tasks,
        "recommended_actions": recommended_actions,
    }

    json_path = outputs_dir / "task-pool-audit-report.json"
    md_path = outputs_dir / "task-pool-audit-report.md"
    decisions_path = outputs_dir / "task-pool-audit-decisions.json"

    json_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    decisions_path.write_text(
        json.dumps([decision.__dict__ for decision in decisions], ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    md_lines = [
        "# Task Pool Audit Report",
        "",
        "## Summary",
        "",
        f"- Active meeting: `{active_meeting_id or 'none'}`",
        f"- Total files seen: `{total_files_seen}`",
        f"- Parseable tasks: `{parseable_tasks}`",
        f"- Unparseable files: `{unparseable_files}`",
        f"- Queued tasks: `{queued_count}`",
        f"- In-progress tasks: `{in_progress_count}`",
        f"- Ready-for-QA tasks: `{ready_for_qa_count}`",
        f"- Live candidates: `{len(live_candidates)}`",
        f"- Stale tasks: `{len(stale_tasks)}`",
        f"- Duplicate tasks: `{sum(len(g['duplicate_task_ids']) for g in duplicate_groups)}`",
        f"- Orphan tasks: `{len(orphan_tasks)}`",
        f"- Unsafe tasks: `{len(unsafe_tasks)}`",
        "",
        "## Live Candidates",
        "",
    ]
    if live_candidates:
        for item in live_candidates[:20]:
            md_lines.append(f"- `{item['task_id']}` status=`{item['status']}` source_action=`{item['source_action_id']}` eligible=`{item['selection_eligible']}`")
    else:
        md_lines.append("- None")
    md_lines.extend(["", "## Recommended Actions", ""])
    for item in recommended_actions:
        md_lines.append(f"- `{item['action_id']}` `{item['action_type']}`: {item['reason']}")
    md_path.write_text("\n".join(md_lines) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
