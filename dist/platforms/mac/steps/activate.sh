#!/usr/bin/env bash

# Ensure project directory structure exists
if [ ! -d "$ACTIVATE_LICENSE_PATH" ]; then
  mkdir -p "$ACTIVATE_LICENSE_PATH"
fi
if [ ! -d "$ACTIVATE_LICENSE_PATH/Assets" ]; then
  mkdir -p "$ACTIVATE_LICENSE_PATH/Assets"
fi

# Run in ACTIVATE_LICENSE_PATH directory
echo "Changing to \"$ACTIVATE_LICENSE_PATH\" directory."
pushd "$ACTIVATE_LICENSE_PATH"

activate_with_credentials() {
  local email=$1
  local pass=$2
  local serial=$3

  echo "Trying to activate license for $email"

  /Applications/Unity/Hub/Editor/$UNITY_VERSION/Unity.app/Contents/MacOS/Unity \
    -logFile - \
    -batchmode \
    -nographics \
    -quit \
    -serial "$serial" \
    -username "$email" \
    -password "$pass" \
    -projectPath "$ACTIVATE_LICENSE_PATH"
  
  return $?
}

success=false

if [ -n "$UNITY_CREDENTIALS" ]; then
  echo "Requesting activation with array of credentials..."

  # Split the data into blocks (entries separated by blank lines)
  IFS=$'\n\n' read -d '' -ra blocks <<< "$UNITY_CREDENTIALS"

  # Initialize variables
  email=""
  pass=""
  serial=""

  # Loop over each block
  for block in "${blocks[@]}"; do
      # Trim leading/trailing whitespace
      block=$(echo "$block" | sed '/^\s*$/d')


      # Process each line in the block
      while IFS= read -r line; do
          key="${line%%:*}"
          value="${line#*:}"

          case "$key" in
              EMAIL) email="$value" ;;
              PASS) pass="$value" ;;
              SERIAL) serial="$value" ;;
          esac
      done <<< "$block"

      if [[ -n "$email" && -n "$pass" && -n "$serial" ]]; then
        # Place your code here
        activate_with_credentials "$email" "$pass" "$serial"
        UNITY_EXIT_CODE=$?

        if [ $UNITY_EXIT_CODE -eq 0 ]; then
          # Write to ENV variables back, so return license can work.
          export UNITY_EMAIL=$email
          export UNITY_PASSWORD=$pass
          export UNITY_SERIAL=$serial

          cleaned_email="${email//@/AT}"
          echo "Activation complete with credentials: $cleaned_email"
          success=true

          # Clear the variables
          email=""
          pass=""
          serial=""
          
          # Exit the loop since activation was successful
          break
        fi
      fi
      
  done
else
  # Fallback to single set of credentials
  echo "Requesting activation with default credentials"
  echo "Bulk credentials are empty: $UNITY_CREDENTIALS"
  activate_with_credentials "$UNITY_EMAIL" "$UNITY_PASSWORD" "$UNITY_SERIAL"
  UNITY_EXIT_CODE=$?
  [ $UNITY_EXIT_CODE -eq 0 ] && success=true
fi

if $success; then
  echo "License activation successful."
else
  echo "Unclassified error occurred while trying to activate license."
  echo "Exit code was: $UNITY_EXIT_CODE"
  echo "::error ::There was an error while trying to activate the Unity license."
  exit $UNITY_EXIT_CODE
fi

# Return to previous working directory
popd
