# http://czerasz.com/2015/07/19/wrk-http-benchmarking-tool-example/

import json
import uuid
import random
import sys


def main():
    num_requests = 10
    uuid_set = [uuid.uuid4() for _ in xrange(1000)]
    columns = ['column_%d' % n for n in xrange(5)]
    ref_keys = [n for n in xrange(5)]
    with open('requests.json', 'w') as f:
        print >>f, '['
        for num in xrange(num_requests):
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
            else:
                # PUT
                request = {
                    'path': '/access/trips/cells',
                    'method': 'PUT',
                    'headers': {
                        'content-type': 'application/json',
                    },
                    'body': json.dumps({
                            "rows":[
                                {
                                    "uuid": str(random.choice(uuid_set)),
                                    "columns": [
                                        {
                                            "column_key": "BASE",
                                            "ref_key": "1",
                                            "data": {"the": "data"}
                                        },
                                        {
                                            "column_key": "ROUTE",
                                            "ref_key": "1",
                                            "data": {"start": "here"}
                                        },
                                        {
                                            "column_key": "ROUTE",
                                            "ref_key": "10",
                                            "data": {"end": "there"}
                                        }
                                    ]
                                }
                            ]
                    })
                }
            print >>f, json.dumps(request),
            if num == num_requests - 1:
                print >>f, ''
            else:
                print >>f, ','
        print >>f, ']'


if __name__ == '__main__':
    sys.exit(main())
