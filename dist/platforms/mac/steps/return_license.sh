#!/usr/bin/env bash

# Run in ACTIVATE_LICENSE_PATH directory
echo "Changing to \"$ACTIVATE_LICENSE_PATH\" directory."
pushd "$ACTIVATE_LICENSE_PATH"

cleaned_email="${UNITY_EMAIL//@/AT}"
echo "Returning license for email: \"$cleaned_email\""

/Applications/Unity/Hub/Editor/$UNITY_VERSION/Unity.app/Contents/MacOS/Unity \
  -logFile - \
  -batchmode \
  -nographics \
  -quit \
  -username "$UNITY_EMAIL" \
  -password "$UNITY_PASSWORD" \
  -returnlicense \
  -projectPath "$ACTIVATE_LICENSE_PATH"

# Return to previous working directory
popd
