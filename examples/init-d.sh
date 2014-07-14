#!/bin/sh

# This is an example of an init.d script to wrap around your worker.

set -e # exit the script if any statement returns a non-true return value
set -u # check whether all variables are initialised

# The variables for this script
PATH=$PATH:/usr/local/bin
TIMEOUT=15
APP_ROOT=/some/path
SCRIPT=./bin/my_worker
PID=worker.pid
USER=worker
LOG=worker.log

# make sure the path exists
cd $APP_ROOT || exit 1

case $1 in
start)
  su --login $USER --shell /bin/sh --command "cd $APP_ROOT; $SCRIPT start --pid $PID --log $LOG --daemonize"
  ;;
restart)
  su --login $USER --shell /bin/sh --command "cd $APP_ROOT; $SCRIPT restart --pid $PID --log $LOG --stop-timeout $TIMEOUT"
  ;;
stop)
  su --login $USER --shell /bin/sh --command "cd $APP_ROOT; $SCRIPT stop --pid $PID --stop-timeout $TIMEOUT"
  ;;
status)
  su --login $USER --shell /bin/sh --command "cd $APP_ROOT; $SCRIPT status --pid $PID"
  ;;
*)
  echo >&2 "Usage: $0 <start|stop|restart|status>"
  exit 1
  ;;
esac
