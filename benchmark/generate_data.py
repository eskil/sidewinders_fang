# http://czerasz.com/2015/07/19/wrk-http-benchmarking-tool-example/

import json
import uuid
import random
import sys


def main():
    num_requests = 10000
    num_uuids = 1000
    num_columns = 10
    num_ref_keys = 10
    uuid_set = [uuid.uuid4() for _ in xrange(num_uuids)]
    columns = ['column_%d' % n for n in xrange(num_columns)]
    ref_keys = ['%d' % n for n in xrange(num_ref_keys)]


    with open('requests.json', 'w') as f:
        print >>f, '['

        for uid in uuid_set:
            body = {
                'rows': [{
                    'uuid': str(random.choice(uuid_set)),
                    'columns': []
                }]
            }
            for column in columns:
                for ref_key in ref_keys:
                    body['rows'][0]['columns'].append({
                        'column_key': column,
                        'ref_key': ref_key,
                        'data': {'the': 'data'},
                    })
            request = {
                'path': '/access/trips/cells',
                'method': 'PUT',
                'headers': {
                    'content-type': 'application/json',
                },
                'body': json.dumps(body)
            }
            print >>f, json.dumps(request), ','

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
                if random.random() < 0.5:
                    body = {'rows': [
                        {
                            'uuid': str(random.choice(uuid_set)),
                            'columns': [{
                                'column_key': random.choice(columns),
                                'ref_key': random.choice(ref_keys),
                                'data': {'some': 'new data'}
                            }]
                        }
                    ]}
                else:
                    body = {'rows': [
                        {
                            'uuid': str(uuid.uuid4()),
                            'columns': [{
                                'column_key': random.choice(columns),
                                'ref_key': random.choice(ref_key),
                                'data': {'some': 'new data'}
                            }]
                        }
                    ]}

                request = {
                    'path': '/access/trips/cells',
                    'method': 'PUT',
                    'headers': {
                        'content-type': 'application/json',
                    },
                    'body': json.dumps(body)
                }
            print >>f, json.dumps(request),
            if num == num_requests - 1:
                print >>f, ''
            else:
                print >>f, ','
        print >>f, ']'


if __name__ == '__main__':
    sys.exit(main())
