#!/bin/bash

set -x

kill_clickhouse () {
    while kill -0 `pgrep -u clickhouse`;
    do
        kill `pgrep -u clickhouse` 2>/dev/null
        echo "Process" `pgrep -u clickhouse` "still alive"
        sleep 10
    done
}

start_clickhouse () {
    LLVM_PROFILE_FILE='server_%h_%p_%m.profraw' sudo -Eu clickhouse /usr/bin/clickhouse-server --config /etc/clickhouse-server/config.xml &
}

chmod 777 /
dpkg -i package_folder/clickhouse-common-static_*.deb; \
    dpkg -i package_folder/clickhouse-common-static-dbg_*.deb; \
    dpkg -i package_folder/clickhouse-server_*.deb;  \
    dpkg -i package_folder/clickhouse-client_*.deb; \
    dpkg -i package_folder/clickhouse-test_*.deb

ln -s /usr/share/clickhouse-test/config/zookeeper.xml /etc/clickhouse-server/config.d/; \
    ln -s /usr/share/clickhouse-test/config/listen.xml /etc/clickhouse-server/config.d/; \
    ln -s /usr/share/clickhouse-test/config/part_log.xml /etc/clickhouse-server/config.d/; \
    ln -s /usr/share/clickhouse-test/config/log_queries.xml /etc/clickhouse-server/users.d/; \
    ln -s /usr/share/clickhouse-test/config/readonly.xml /etc/clickhouse-server/users.d/; \
    ln -s /usr/share/clickhouse-test/config/ints_dictionary.xml /etc/clickhouse-server/; \
    ln -s /usr/share/clickhouse-test/config/strings_dictionary.xml /etc/clickhouse-server/; \
    ln -s /usr/share/clickhouse-test/config/decimals_dictionary.xml /etc/clickhouse-server/; \
    ln -s /usr/lib/llvm-8/bin/llvm-symbolizer /usr/bin/llvm-symbolizer

service zookeeper start
sleep 5

start_clickhouse

sleep 10

LLVM_PROFILE_FILE='client.profraw' clickhouse-test --shard --zookeeper $ADDITIONAL_OPTIONS $SKIP_TESTS_OPTION 2>&1 | ts '%Y-%m-%d %H:%M:%S' | tee test_output/test_result.txt

kill_clickhouse

cp /*.profraw /profraw ||: