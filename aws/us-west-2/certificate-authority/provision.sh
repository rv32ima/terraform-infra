#!/usr/bin/env bash
set -eu

if [ -e "/.provisioned" ]; then
  exit 0
fi

get_http_token() {
  curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"
}

get_tag() {
  curl -H "X-aws-ec2-metadata-token: $(get_http_token)" "http://169.254.169.254/latest/meta-data/tags/instance/$1"
}

nix build \
  --extra-experimental-features "nix-command" \
  --substituters "$(get_tag Substituters)" \
  --profile "/nix/var/nix/profiles/system" \
  "$(get_tag NixStorePath)"

echo "1" > /.provisioned
/nix/var/nix/profiles/system/bin/switch-to-configuration boot
systemctl start kexec.target