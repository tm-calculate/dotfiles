#!/usr/bin/python
# chmod 600
import os
import sys
import time
import imaplib
import re

# mail boxes
boxes = {
    'MO': {
        'login': '',
        'password': '',
        'server': '',
        'port': 143,
        'ssl': False
    },
    'MG': {
        'login': '',
        'password': '',
        'server': '',
        'port': 993,
        'ssl': True
    }
}

# check mail for interval in seconds
interval = 600

# disable stdout buffering
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

# main loop
while True:
    for name, account in boxes.iteritems():
        if account['ssl']:
            conn = imaplib.IMAP4_SSL(account['server'])
        else:
            conn = imaplib.IMAP4(account['server'])

        try:
            (retcode, caps) = conn.login(account['login'], account['password'])
        except:
            print sys.exc_info()[1]
            sys.exit(1)

        conn.select(readonly=True)
        count = re.search("UNSEEN (\d+)", conn.status("INBOX", "(UNSEEN)")[1][0]).group(1)
        print name + count

    time.sleep(interval)
