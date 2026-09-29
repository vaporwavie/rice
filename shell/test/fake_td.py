import json
from pathlib import Path
import stat

READ = ['upcoming', '30', '--json', '--all']

# Stands in for `td` through TD_BIN so tests never reach the real Todoist account.
SCRIPT = '''#!/usr/bin/env python3
import datetime
import json
from pathlib import Path
import sys

root = Path(__file__).resolve().parent
args = sys.argv[1:]
with (root / 'td-calls.log').open('a') as log:
    log.write(json.dumps(args) + '\\n')
fixture = root / 'td-fixture.json'
if args == %(read)s:
    failing = root / 'td-fail-read'
    if failing.exists():
        sys.stderr.write(failing.read_text())
        sys.exit(1)
    snapshot = fixture.read_text()
    if (root / 'td-slow-read').exists():
        import time
        time.sleep(1.5)
    sys.stdout.write(snapshot)
    sys.exit(0)
if len(args) == 3 and args[:2] == ['task', 'complete'] and args[2].startswith('id:'):
    ref = args[2][3:]
    failing = root / 'td-fail-complete'
    if failing.exists() and failing.read_text().strip() == ref:
        sys.exit('HTTP 400: Bad Request')
    data = json.loads(fixture.read_text())
    task = next((t for t in data['results'] if t['id'] == ref), None)
    if task is None:
        sys.exit('HTTP 404: Not Found')
    if task['due']['isRecurring']:
        date = task['due']['date']
        day = datetime.date.fromisoformat(date[:10]) + datetime.timedelta(days=7)
        task['due']['date'] = day.isoformat() + date[10:]
    else:
        data['results'].remove(task)
    pending = fixture.with_suffix('.next')
    pending.write_text(json.dumps(data))
    pending.replace(fixture)
    print('Completed: ' + task['content'])
    sys.exit(0)
sys.exit('fake td: unexpected arguments ' + json.dumps(args))
''' % {'read': repr(READ)}


def task(id, content, date, recurring=False, timezone=None, priority=1):
    return {'id': id, 'content': content, 'description': '', 'priority': priority,
            'due': {'date': date, 'string': date, 'isRecurring': recurring, 'timezone': timezone, 'lang': 'en'},
            'deadline': None, 'labels': [], 'projectId': 'inbox', 'url': f'https://app.todoist.com/app/task/{id}'}


class FakeTd:
    def __init__(self, root):
        self.root = Path(root)
        self.bin = self.root / 'td'
        self.fixture = self.root / 'td-fixture.json'
        self.log = self.root / 'td-calls.log'
        self.fail_file = self.root / 'td-fail-complete'
        self.bin.write_text(SCRIPT)
        self.bin.chmod(self.bin.stat().st_mode | stat.S_IXUSR)
        self.serve([])

    def serve(self, tasks):
        pending = self.fixture.with_suffix('.next')
        pending.write_text(json.dumps({'results': tasks, 'nextCursor': None}))
        pending.replace(self.fixture)

    def serve_raw(self, text):
        pending = self.fixture.with_suffix('.next')
        pending.write_text(text)
        pending.replace(self.fixture)

    def fail_complete(self, id):
        if id:
            self.fail_file.write_text(id)
        else:
            self.fail_file.unlink(missing_ok=True)

    def fail_reads(self, message):
        flag = self.root / 'td-fail-read'
        if message:
            flag.write_text(json.dumps({'error': {'code': 'NO_TOKEN', 'message': message, 'hints': ['td auth login']}}) + '\n')
        else:
            flag.unlink(missing_ok=True)

    def slow_reads(self, slow):
        flag = self.root / 'td-slow-read'
        if slow:
            flag.touch()
        else:
            flag.unlink(missing_ok=True)

    def calls(self):
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def completes(self):
        return [call for call in self.calls() if call[:2] == ['task', 'complete']]
