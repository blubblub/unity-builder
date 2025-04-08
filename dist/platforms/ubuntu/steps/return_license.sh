#!/usr/bin/env bash

if [[ -n "$UNITY_LICENSING_SERVER" ]]; then
  #
  # Return any floating license used.
  #
  echo "Returning floating license: \"$FLOATING_LICENSE\""
  /opt/unity/Editor/Data/Resources/Licensing/Client/Unity.Licensing.Client --return-floating "$FLOATING_LICENSE"
elif [[ -n "$UNITY_SERIAL" ]]; then
  cleaned_email="${UNITY_EMAIL//@/AT}"

  echo "Returning license: \"$UNITY_SERIAL\" email: \"$cleaned_email\""
  #
  # SERIAL LICENSE MODE
  #
  # This will return the license that is currently in use.
  #
  unity-editor \
    -logFile /dev/stdout \
    -quit \
    -returnlicense \
    -username "$UNITY_EMAIL" \
    -password "$UNITY_PASSWORD" \
    -projectPath "/BlankProject"
fi
