# SidewindersFang

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add sidewinders_fang to your list of dependencies in `mix.exs`:

        def deps do
          [{:sidewinders_fang, "~> 0.0.1"}]
        end

  2. Ensure sidewinders_fang is started before your application:

        def application do
          [applications: [:sidewinders_fang]]
        end



## Log

### Blank project setup

    mix new sidewinders_fang --sup
    cd sidewinders_fang
    git init
    git add *
    git add .gitignore

### Build release

    mix deps.get
    mix compile
    MIX_ENV=dev mix release

### Config mysql

    mysqld

    mysqladmin shutdown

### Launch Console

    rel/sidewinders_fang/bin/sidewinders_fang console

### Launch and observe

    iex -S mix
    iex(1)> :observer.start()

### Basics

    curl localhost:8080/access/trips/cell/2fca6088-cde4-4526-b5d2-f1af9c5147b2/BASE/1
    curl localhost:8080/access/trips/cell/2fca6088-cde4-4526-b5d2-f1af9c5147b2/BASE
    curl localhost:8080/access/trips/cell/2fca6088-cde4-4526-b5d2-f1af9c5147b2
    curl -X PUT -H 'Content-Type: application/json' --data '{"rows": [{"uuid": "2fca6088-cde4-4526-b5d2-f1af9c5147ba", "columns": [{"column_key": "BASE", "ref_key": "1", "data": {"the": "data"}}, {"column_key": "ROUTE", "ref_key": "1", "data": {"start": "here"}}, {"column_key": "ROUTE", "ref_key": "10", "data": {"end": "there"}}]}]}' localhost:8080/access/trips/cells/


    curl -X PUT -H 'Content-Type: application/json' --data '{"rows": [{"uuid": "2fca6088-cde4-4526-b5d2-f1af9c5147ba", "columns": [{"column_key": "BASE", "ref_key": "1", "data": {"the": "data"}}, {"column_key": "ROUTE", "ref_key": "1", "data": {"start": "here"}}, {"column_key": "ROUTE", "ref_key": "10", "data": {"end": "there"}}]}]}' localhost:8080/access/trips/cells/  | jq . && curl -X PUT -H 'Content-Type: application/json' --data '{"rows": [{"uuid": "2fca6088-cde4-4526-b5d2-f1af9c5147ba", "columns": [{"column_key": "BASE", "ref_key": "1", "data": {"the": "data"}}, {"column_key": "ROUTE", "ref_key": "1", "data": {"start": "here"}}, {"column_key": "ROUTE", "ref_key": "10", "data": {"end": "there"}}]}]}' localhost:8080/access/trips/cells/  | jq . && curl localhost:8080/access/trips/cell/2fca6088-cde4-4526-b5d2-f1af9c5147ba | jq .

### Benchmark

    cd benchmark
    python ./generate_data.py
    brew install lua51
    luarocks-5.1 install lua-cjson
    wrk --connections 10 --duration 10 --threads 10 -s multi-request-json.lua http://localhost:8080


### Important tags

    bottleneck, basic functionality including 409s on put_cell. Heavy bottleneck in Schemaless.Store genserver.
    pre_poolboy, Schemaless.Store genserver removed, perf doubles.
    poolboy, uses pools for Schemaless.Cluster, perf suprisingly halves again :-(
    mysql_otp, moved from MariaEx to MySQL/OTP driver.
    configurable_mysql_mariaex, option to pick mysql driver
    configurable_poolboy_and_mysql, options to pick poolboy/no-poolboy and mysql driver
