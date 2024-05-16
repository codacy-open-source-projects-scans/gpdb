#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -d testdata ]; then
	mkdir testdata
fi
pushd ${DIR}/testdata
GPPORT=${PGPORT}
GPOPTIONS=${PGOPTIONS}
export PGPORT=${PG_PORT}
# set PGOPTIONS to be empty and restart the GP.
# Becuase PGOPTIONS='-c optimizer=off' is sometimes set on gp cluster
# and it will be sent to pg through postgres_fdw, but pg can not
# recognize the 'optimizer' config. PGOPTIONS is not useful for gp
# cluster, it is used by psql.
export PGOPTIONS=''
pgbin="pgsql"

# install postgres
if [ ! -d "${pgbin}" ] ; then
	mkdir ${pgbin}
	if [ ! -d postgresql-12.12 ]; then
		wget https://ftp.postgresql.org/pub/source/v12.12/postgresql-12.12.tar.gz
		tar -xf postgresql-12.12.tar.gz
	fi
	pushd postgresql-12.12
	./configure --prefix=${DIR}/testdata/${pgbin}
    make MAKELEVEL=0 install
	rm -rf postgresql-12.12.tar.gz
	popd
fi

# start postgres 1
# there may be already a postgres postgres running, anyway, stop it
if [ -d "pgdata" ] ; then
	${pgbin}/bin/pg_ctl -D pgdata  stop || true
	rm -r pgdata
fi
${pgbin}/bin/initdb -D pgdata
${pgbin}/bin/pg_ctl -D pgdata -l pglog start

# init postgres 1
${pgbin}/bin/dropdb --if-exists contrib_regression
${pgbin}/bin/createdb contrib_regression

# start postgres 2
# listening to port 5555
# there may be already a postgres postgres running, anyway, stop it
if [ -d "pgdata2" ] ; then
    ${pgbin}/bin/pg_ctl -D pgdata2  stop || true
    rm -r pgdata2
fi
${pgbin}/bin/initdb -D pgdata2
${pgbin}/bin/pg_ctl -D pgdata2 -l pglog2 -o "-p 5555" start

# init postgres 2
${pgbin}/bin/dropdb -p 5555 --if-exists contrib_regression
${pgbin}/bin/createdb -p 5555 contrib_regression

export PGPORT=${GPPORT}
# export PGOPTIONS=${GPOPTIONS}
popd
gpstop -ar
