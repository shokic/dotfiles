# Work profile: what only a work Mac needs. Sourced by setup.sh after the shared setup,
# so it can use link, icloud_download, ICLOUD, HAS_TTY...

# AWS config (SSO profiles for the AWS CLI and granted): kept in iCloud Drive, not in this public
# repo. Linked rather than copied, so a change made on any Mac reaches the others.
AWS_CONFIG="$ICLOUD/aws/config"
if [ ! -f "$AWS_CONFIG" ]; then
  echo
  echo "⚠️  no AWS config in iCloud Drive/aws/config: add it there and re-run"
elif ! icloud_download "$AWS_CONFIG"; then
  echo "⚠️  couldn't download $AWS_CONFIG from iCloud Drive: download it in Finder and re-run"
else
  link "$AWS_CONFIG" ~/.aws/config
fi

# granted's `assume`: also save the SSO login to ~/.aws/sso/cache, not only the Keychain.
# AWS SDKs ignore the credentials assume exports when AWS_PROFILE is set, and read that cache instead,
# so without this they fail with "Token is expired" until `aws sso login` is run.
if command -v granted > /dev/null && ! grep -qx 'ExportSSOToken = true' ~/.granted/config 2>/dev/null; then
  granted settings set -s ExportSSOToken -v true
  echo "granted: SSO logins are now also saved for the AWS CLI and SDKs"
fi
