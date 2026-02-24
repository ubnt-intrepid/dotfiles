---
name: clean-sessions
description: Clean up Claude Code session history for the current project interactively
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion
---

# Session History Cleanup

Clean up Claude Code conversation history files for the current project.

## Step 1: Locate session directory

Determine the session directory for the current project:

```
~/.claude/projects/<encoded-project-path>/
```

Where `<encoded-project-path>` is the current working directory with `/` replaced by `-` and prefixed with `-`.
For example: `/Users/foo/my-project` -> `-Users-foo-my-project`

## Step 2: Inventory all sessions

Run the following script to collect session metadata. Replace `SESSION_DIR` and `CURRENT_SESSION` with actual values.

```python
import json, os
from datetime import datetime

SESSION_DIR = '<session-directory>'
CURRENT_SESSION = '<current-session-id>'

index_data = {}
try:
    with open(os.path.join(SESSION_DIR, 'sessions-index.json')) as f:
        for e in json.load(f).get('entries', []):
            index_data[e['sessionId']] = e
except:
    pass

results = []
for fname in sorted(os.listdir(SESSION_DIR)):
    if not fname.endswith('.jsonl'):
        continue
    sid = fname.replace('.jsonl', '')
    if sid == CURRENT_SESSION:
        continue

    fpath = os.path.join(SESSION_DIR, fname)
    stat = os.stat(fpath)
    size = stat.st_size
    mtime = datetime.fromtimestamp(stat.st_mtime).strftime('%Y-%m-%d')

    user_msgs = []
    try:
        with open(fpath) as fh:
            for line in fh:
                try:
                    obj = json.loads(line)
                    msg = obj.get('message', {})
                    if msg.get('role') != 'user':
                        continue
                    content = msg.get('content', '')
                    if isinstance(content, list):
                        for c in content:
                            if isinstance(c, dict) and c.get('type') == 'text':
                                text = c['text'].strip()
                                if text and not text.startswith('<'):
                                    user_msgs.append(text[:100])
                    elif isinstance(content, str):
                        text = content.strip()
                        if text and not text.startswith('<'):
                            user_msgs.append(text[:100])
                except:
                    pass
    except:
        pass

    idx = index_data.get(sid, {})
    size_str = f'{size/1024:.0f}KB' if size < 1048576 else f'{size/1048576:.1f}MB'
    results.append({
        'sid': sid, 'sid_short': sid[:8], 'fname': fname,
        'size': size, 'size_str': size_str, 'mtime': mtime,
        'user_msgs': user_msgs, 'user_msg_count': len(user_msgs),
        'summary': idx.get('summary', ''),
        'branch': idx.get('gitBranch', ''),
        'has_subdir': os.path.isdir(os.path.join(SESSION_DIR, sid)),
    })

print(json.dumps(results, ensure_ascii=False, indent=2))
```

Save the output to a temporary file (e.g., `/tmp/session_inventory.json`) for use in subsequent steps.

## Step 3: Categorize sessions

Classify each session into one of the following categories based on its content:

### Category 1: Empty sessions
Sessions with no meaningful user interaction. This includes:
- Files under 2KB with no user messages
- Sessions where the only user input is `/exit`, `clear`, `c`, or a single interrupted request
- Sessions containing only auto-generated content (e.g., `local-command-caveat` system messages) with no substantive user response

### Category 2: Lightweight sessions
Sessions driven by a single prompt or a brief exchange. Typically small in size (under ~50KB) and containing only a few user messages. Examples include one-off questions, short reviews, or quick lookups that are unlikely to be revisited.

### Category 3: Heavy sessions
All remaining sessions that do not fit the above two categories. These are multi-turn work sessions involving substantial code changes, in-depth investigations, or ongoing tasks.

## Step 4: Interactive selection

Present sessions grouped by category as a bulleted list, starting from the most obviously deletable. **Do not delete anything in this step.** Only collect the user's decisions.

For each category, display sessions as:

```
### Category N: <name> (<count> sessions, ~<total size>)
- <sid_short> | <mtime> | <size_str> | <summary or first user message>
- ...
```

Then use AskUserQuestion to ask: "delete all", "keep all", or "review individually".
If "review individually", present each session with delete/keep options.

Accumulate a list of session IDs marked for deletion across all categories.

## Step 5: Final confirmation and batch deletion

After all categories have been reviewed, present a summary of what will be deleted:

```
### Deletion plan
- <sid_short> | <mtime> | <size_str> | <summary>
- ...
Total: <count> sessions, ~<total size>
```

Use AskUserQuestion to get **final confirmation** before proceeding.

If confirmed, run the following script. Replace `SESSION_DIR` and `DELETE_SIDS` with actual values.

```python
import json, os, shutil

SESSION_DIR = '<session-directory>'
DELETE_SIDS = [
    # '<session-id-1>',
    # '<session-id-2>',
]

deleted_files = 0
deleted_dirs = 0
freed_bytes = 0

for sid in DELETE_SIDS:
    # Delete .jsonl file
    fpath = os.path.join(SESSION_DIR, sid + '.jsonl')
    if os.path.exists(fpath):
        freed_bytes += os.path.getsize(fpath)
        os.remove(fpath)
        deleted_files += 1

    # Delete subdirectory if it exists
    dpath = os.path.join(SESSION_DIR, sid)
    if os.path.isdir(dpath):
        for root, dirs, files in os.walk(dpath):
            for f in files:
                freed_bytes += os.path.getsize(os.path.join(root, f))
        shutil.rmtree(dpath)
        deleted_dirs += 1

print(f'Deleted {deleted_files} session files, {deleted_dirs} subdirectories')
print(f'Freed {freed_bytes / 1048576:.1f} MB')
```

## Step 6: Post-cleanup

Run the following script to clean up orphaned directories and update the index. Replace `SESSION_DIR` with the actual value.

```python
import json, os, shutil

SESSION_DIR = '<session-directory>'

# 1. Remove orphaned subdirectories
orphaned = 0
for d in os.listdir(SESSION_DIR):
    dpath = os.path.join(SESSION_DIR, d)
    if not os.path.isdir(dpath) or d in ('memory',) or d.startswith('.'):
        continue
    if not os.path.exists(os.path.join(SESSION_DIR, d + '.jsonl')):
        shutil.rmtree(dpath)
        orphaned += 1

# 2. Update sessions-index.json
idx_path = os.path.join(SESSION_DIR, 'sessions-index.json')
if os.path.exists(idx_path):
    with open(idx_path) as f:
        data = json.load(f)
    before = len(data['entries'])
    data['entries'] = [e for e in data['entries'] if os.path.exists(e['fullPath'])]
    after = len(data['entries'])
    with open(idx_path, 'w') as f:
        json.dump(data, f, indent=2)
    print(f'sessions-index.json: {before} -> {after} entries')

# 3. Final summary
remaining = [f for f in os.listdir(SESSION_DIR) if f.endswith('.jsonl') and f != 'sessions-index.json']
total = sum(os.path.getsize(os.path.join(SESSION_DIR, f)) for f in remaining)
print(f'Remaining sessions: {len(remaining)}')
print(f'Total size: {total / 1048576:.1f} MB')
if orphaned:
    print(f'Orphaned directories removed: {orphaned}')
```

Display the final summary to the user.
