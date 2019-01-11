#!/bin/bash -e

if ! bundle show sprockets; then
  echo "No sprockets found - not compiling any assets."
  exit 0
fi

if bundle show pg; then
  export DATABASE_URL="postgres://noop"
elif bundle show mysql2; then
  export DATABASE_URL="mysql2://noop"
elif bundle show sqlite3; then
  export DATABASE_URL="sqlite3://noop"
else
  echo "Cannot find database gem - asset compilation might fail."
fi

if [ -e .env ]; then
  source .env
fi

# this is lame, but there doesn't seem to be a good way anyone has found to
# ensure that a docker image is totally complete and self-contained with all
# the assets necessary to handle a deploy to any rails env without recompile
NO_RESQUE=true RAILS_ENV=devsandbox SECRET_KEY_BASE=`bin/rails secret` bundle exec rails assets:precompile
NO_RESQUE=true RAILS_ENV=staging SECRET_KEY_BASE=`bin/rails secret` bundle exec rails assets:precompile
NO_RESQUE=true RAILS_ENV=production SECRET_KEY_BASE=`bin/rails secret` bundle exec rails assets:precompile
