* generate.py generates requests.json
* multi-request-json.lua (http://czerasz.com/2015/07/19/wrk-http-benchmarking-tool-example/)
* wrk -c1 -t1 -d5s -s /scripts/multi-request-json.lua http://$APPLICATION_IP:$APPLICATION_PORT
