import json
import uuid
import random

def main():
    uuid_set = [uuid.uuid4() for _ in xrange(1000)]
    columns = ['column_%d' % n for n in xrange(5)]
    ref_keys = [n for n in xrange(5)]
    for _ in xrange(1000):
        method = random.random()
        if method < 0.6:
            # GET
            level = random.random()
            if level < 0.3:
                request = {
                    'path': '/access/trips/cell/%s/%s/%s' % (random.choice(uuid_set), random.choice(columns), random.choice(ref_keys)),
                    'method': 'GET',
                }
            elif level < 0.6:
                request = {
                    'path': '/access/trips/cell/%s/%s' % (random.choice(uuid_set), random.choice(columns)),
                    'method': 'GET',
                }
            else:
                request = {
                    'path': '/access/trips/cell/%s' % (random.choice(uuid_set)),
                    'method': 'GET',
                }
        id = random.choice(uuid_set)
        request = {

if __name__ == '__main__':
    sys.exit(main())
