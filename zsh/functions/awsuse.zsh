awsuse() {
  local profile
  profile=$(aws configure list-profiles | fzf --prompt="Choose AWS profile: ")
  if [ -z "$profile" ]; then
    echo "❌ No profile selected"
    return 1
  fi

  ssocred "$profile"
  if [ $? -eq 0 ]; then
    export AWS_PROFILE="$profile"
    echo "✅ Switched to AWS_PROFILE=$AWS_PROFILE"
    aws sts get-caller-identity --output table
  else
    echo "❌ Failed to switch to profile '$profile'"
  fi
}
