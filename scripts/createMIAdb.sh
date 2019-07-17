#!/bin/bash

MIAdb="../db/MIA.db"

[[ ! $(apt search sqlite3) =~ sqlite3 ]] && apt-get install -y sqlite3 libsqlite3-dev

[[ ! -d ../db ]] && mkdir ../db
[[ -f $MIAdb ]] && printf "\n\n** MIA.db already exists: $(readlink -f $MIAdb)\n\n" && exit
sqlite3 $MIAdb < <(echo -e ".exit")
sqlite3 $MIAdb < <(echo -e "PRAGMA journal_mode=WAL;")
sqlite3 $MIAdb < <(echo -e ".read createMIAdb_tables.sql")
sqlite3 $MIAdb < <(echo -e ".read blastRefs.sql")
sqlite3 $MIAdb < <(echo -e ".read hanaRefs.sql")
