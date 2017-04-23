#!/bin/bash

# usage: build.sh LANE
#        LANE: alpha|beta

# App specific config here
SCRATCH_CONFIG="scratch.xcconfig"
MESSAGE="// This file is automatically generated. Do not edit by hand (please)."

# Put SCRATCH_CONFIG in place
echo "${MESSAGE}" > "$SCRATCH_CONFIG"

# git info we'll be using
LATEST_TAG=$(git describe --tags --abbrev=0) || (echo "No tags, try pushing tags first." && exit 12)

PREVIOUS_TAG=$(git describe --tags --abbrev=0 ${LATEST_TAG}~1)
NUM_COMMITS_SINCE_LATEST_TAG=$(git rev-list ${LATEST_TAG}.. --count)
TAGGED_VERSION=$(git describe --tags --abbrev=0 | sed -e 's/^v//') # just get rid of leading 'v'
BRANCH=$(git rev-parse --abbrev-ref HEAD)
BRANCH=${BUILDKITE_BRANCH-$BRANCH} # Prefer the branch that buildkite has told us we're on (when we're building on buildkite, we probably have a detached head...).
SHORT_BRANCH=$(echo $BRANCH | cut -d / -f 3 -s) # prefer 'xyz' to 'user/feature/xyz'

if [ -n "${BUILDKITE_BUILD_NUMBER}" ]; then
	echo APP_VERSION = ${BUILDKITE_BUILD_NUMBER} >> "$SCRATCH_CONFIG"
fi

if [ -n "${BUILDKITE_BRANCH}" ]; then
	echo BUILDKITE_BRANCH = ${BUILDKITE_BRANCH} >> "$SCRATCH_CONFIG"
fi

if [[ $(git describe) == $LATEST_TAG ]]; then
	echo APP_SHORT_VERSION = ${TAGGED_VERSION} >> "$SCRATCH_CONFIG"
else
	APP_SHORT_VERSION="$TAGGED_VERSION"-${NUM_COMMITS_SINCE_LATEST_TAG}-${SHORT_BRANCH-$BRANCH}
	echo APP_SHORT_VERSION = ${APP_SHORT_VERSION} >> "$SCRATCH_CONFIG"
fi

if [[ $1 == "alpha" ]]; then
	cat Config/alpha.xcconfig >> $SCRATCH_CONFIG
fi

cat $SCRATCH_CONFIG

fastlane $1
