#!/bin/bash
set -eo pipefail

npm version patch --tag-version-prefix="" -m "Bumped version %s [ci skip]"
git push && git push --tags