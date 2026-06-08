#!/usr/bin/env python3
"""Fetch overdue + this-week tasks from Todoist via v1 Sync API.

Reads TODOIST_API_KEY from ~/.hermes/config.yaml (mcp_servers.todoist.env).
Usage: python3 todoist_overdue.py [--json]
"""
import json, urllib.request, urllib.parse, ssl, os, sys
from datetime import datetime, date, timedelta

def load_token():
    try:
        import yaml
        with open(os.path.expanduser('~/.hermes/config.yaml')) as f:
            cfg = yaml.safe_load(f)
        return cfg['mcp_servers']['todoist']['env']['TODOIST_API_KEY']
    except Exception:
        return os.environ.get('TODOIST_API_KEY', '')

def parse_date(s):
    for fmt in ('%Y-%m-%dT%H:%M:%SZ', '%Y-%m-%dT%H:%M:%S', '%Y-%m-%d'):
        try:
            return datetime.strptime(s, fmt).date()
        except ValueError:
            continue
    return None

def fetch_tasks(token):
    ctx = ssl.create_default_context()
    data = urllib.parse.urlencode({
        'sync_token': '*',
        'resource_types': '["items", "projects"]'
    }).encode()
    req = urllib.request.Request(
        'https://api.todoist.com/api/v1/sync',
        data=data,
        headers={
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/x-www-form-urlencoded'
        }
    )
    resp = urllib.request.urlopen(req, context=ctx)
    return json.loads(resp.read())

def main():
    token = load_token()
    if not token:
        print("ERROR: No Todoist token found", file=sys.stderr)
        sys.exit(1)

    result = fetch_tasks(token)
    items = result.get('items', result.get('tasks', []))
    projects = {p['id']: p.get('name', '?') for p in result.get('projects', [])}

    today = date.today()
    end_of_week = today + timedelta(days=(6 - today.weekday()))

    overdue = []
    this_week = []
    active_count = 0

    for t in items:
        if t.get('checked', False) or t.get('is_deleted', False):
            continue
        active_count += 1
        due = t.get('due')
        if not due or not due.get('date'):
            continue
        d = parse_date(due['date'])
        if not d:
            continue
        if d < today:
            overdue.append(t)
        elif d <= end_of_week:
            this_week.append((d, t))

    as_json = '--json' in sys.argv

    if as_json:
        out = {
            'overdue': [{'content': t['content'], 'due': t['due']['date'],
                         'project': projects.get(t.get('project_id'), '?'),
                         'priority': t['priority'],
                         'recurring': t.get('due', {}).get('is_recurring', False)}
                        for t in sorted(overdue, key=lambda x: x['due']['date'])],
            'this_week': [{'content': t['content'], 'due': t['due']['date'],
                           'project': projects.get(t.get('project_id'), '?'),
                           'priority': t['priority']}
                          for _, t in sorted(this_week)],
            'stats': {'active': active_count, 'overdue': len(overdue),
                      'this_week': len(this_week)}
        }
        print(json.dumps(out, ensure_ascii=False, indent=2))
    else:
        if overdue:
            overdue.sort(key=lambda t: parse_date(t['due']['date']))
            print(f'🔴 {len(overdue)} overdue:\n')
            for t in overdue:
                due = t.get('due', {})
                r = ' 🔄' if due.get('is_recurring', False) else ''
                p = f' ⚡P{t["priority"]}' if t['priority'] > 1 else ''
                proj = projects.get(t.get('project_id'), '?')
                print(f'  • {t["content"]}{r}{p}')
                print(f'    📅 {due.get("date")}  |  📁 {proj}')
                print()
        else:
            print('✅ No overdue tasks\n')

        if this_week:
            this_week.sort()
            print(f'📅 {len(this_week)} due this week:\n')
            for d, t in this_week:
                day = d.strftime('%a %d/%m')
                r = ' 🔄' if t.get('due', {}).get('is_recurring', False) else ''
                p = f' ⚡P{t["priority"]}' if t['priority'] > 1 else ''
                proj = projects.get(t.get('project_id'), '?')
                marker = ' 👈 TODAY' if d == today else ''
                print(f'  • [{day}] {t["content"]}{r}{p}{marker}')
                print(f'    📁 {proj}')
                print()
        else:
            print('📅 Nothing due this week\n')

        print(f'📊 Active: {active_count} | Overdue: {len(overdue)} | This week: {len(this_week)}')

if __name__ == '__main__':
    main()
