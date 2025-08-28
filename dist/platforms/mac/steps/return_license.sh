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

# Capture the exit code from the license return command
RETURN_LICENSE_EXIT_CODE=$?

# Display results
if [ $RETURN_LICENSE_EXIT_CODE -eq 0 ]; then
  echo "License return succeeded"
else
  echo "License return failed, with exit code $RETURN_LICENSE_EXIT_CODE"
  echo "::warning ::License return failed! If this is a Pro License you might need to manually free the seat in your Unity admin panel or you might run out of seats to activate with."
fi

# Return to previous working directory
popd
