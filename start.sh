#!/bin/bash
set -eo pipefail

pwlen="${SYNAPSE_SECRETS_LEN:-96}"
confdir="/etc/matrix-synapse/"
python="/opt/venvs/matrix-synapse/bin/python"

mkdir -p "$confdir/conf.d"

write_appservices()
{
	if [ -z "$SYNAPSE_APPSERVICES" ]
	then
		echo "app_service_config_files: []"
	else
		echo "app_service_config_files:"
		for as in $SYNAPSE_APPSERVICES
		do
			echo "  - '$as'"
		done
	fi
	echo "track_appservice_user_ips: false"
}

write_database()
{
	echo "database:"
	echo "  name: 'psycopg2'"
	echo "  args:"
	echo "    user: '${SYNAPSE_DB_USER:-postgres}'"
	echo "    password: '${SYNAPSE_DB_PASSWORD:-postgres}'"
	echo "    database: '${SYNAPSE_DB_NAME:-synapse}'"
	echo "    host: '${SYNAPSE_DB_HOST:-localhost}'"
	echo "    cp_min: ${SYNAPSE_CP_MIN:-2}"
	echo "    cp_max: ${SYNAPSE_CP_MAX:-25}"
}

write_email()
{
	if [ -n "$SYNAPSE_SMTP_HOST" -a -n "$SYNAPSE_SMTP_PORT" -a -n "$SYNAPSE_SMTP_FROM" ]
	then
		echo "email:"
		echo "  enable_notifs: ${SYNAPSE_ENABLE_NOTIFS:-false}"
		echo "  smtp_host: '$SYNAPSE_SMTP_HOST'"
		echo "  smtp_port: $SYNAPSE_SMTP_PORT"
		test -z "$SYNAPSE_SMTP_USER" || echo "  smtp_user: '$SYNAPSE_SMTP_USER'"
		test -z "$SYNAPSE_SMTP_PASS" || echo "  smtp_pass: '$SYNAPSE_SMTP_PASS'"
		echo "  require_transport_security: true"
		echo "  notif_from: '$SYNAPSE_SMTP_FROM'"
	fi
}

write_ratelimit()
{
	echo "rc_messages_per_second: ${SYNAPSE_MSG_PER_SEC:-5.0}"
	echo "rc_message_burst_count: ${SYNAPSE_MSG_BURST:-15.0}"
	echo "federation_rc_window_size: ${SYNAPSE_FEDER_WINDOW:-1000}"
	echo "federation_rc_sleep_limit: ${SYNAPSE_FEDER_LIMIT:-10}"
	echo "federation_rc_sleep_delay: ${SYNAPSE_FEDER_DELAY:-500}"
	echo "federation_rc_reject_limit: ${SYNAPSE_FEDER_REJECT:-30}"
	echo "federation_rc_concurrent: ${SYNAPSE_FEDER_CONCURRENT:-3}"
}

write_server()
{
	echo "server_name: '${SYNAPSE_SERVER_NAME:-localhost}'"
	echo "public_baseurl: '${SYNAPSE_BASE_URL:-http://127.0.0.1/}'"
	echo "max_upload_size: '${SYNAPSE_MAX_UPLOAD:-20M}'"
	echo "enable_registration: ${SYNAPSE_ENABLE_REGISTRATION:-false}"
	echo "registration_shared_secret: '${SYNAPSE_REGISTRATION_SECRET:-$(pwgen -ncs "$pwlen")}'"
	echo "allow_guest_access: ${SYNAPSE_GUEST_ACCESS:-false}"
	echo "url_preview_enabled: ${SYNAPSE_URL_PREVIEW:-false}"
	echo "enable_search: ${SYNAPSE_ENABLE_SEARCH:-true}"
	echo "enable_metrics: ${SYNAPSE_ENABLE_METRICS:-false}"
	echo "use_presence: ${SYNAPSE_ENABLE_PRESENCE:-true}"
}

write_turn()
{
	if [ -n "$SYNAPSE_TURN_URI" ]
	then
		echo "turn_uris:"
		echo "  - 'turn:${SYNAPSE_TURN_URI}:5349?transport=tcp'"
		echo "  - 'turn:${SYNAPSE_TURN_URI}:5349?transport=udp'"
		echo "turn_shared_secret: '${SYNAPSE_TURN_SECRET:-$(pwgen -ncs "$pwlen")}'"
		echo "turn_allow_guests: ${SYNAPSE_TURN_GUESTS:-false}"
	fi
}

write_secrets()
{
	echo "macaroon_secret_key: '$(pwgen -nycs -r "'"'"\' "$pwlen")'"
	echo "password_config:"
	echo "  enable: true"
	echo "  pepper: '$(pwgen -nycs -r "'"'"\' "$pwlen")'"
}

write_to_file()
{
	test ! -r "$2" || rm "$2"
	output=$($1)
	if [ -n "$output" ]
	then
		echo "$output" > "$2"
	fi
}


# rewrite all non-secret config files
write_to_file write_appservices "$confdir/conf.d/appservices.yaml"
write_to_file write_database "$confdir/conf.d/database.yaml"
write_to_file write_email "$confdir/conf.d/email.yaml"
write_to_file write_ratelimit "$confdir/conf.d/ratelimit.yaml"
write_to_file write_server "$confdir/conf.d/server.yaml"
write_to_file write_turn "$confdir/conf.d/turn.yaml"

# write secrets only if they are missing
test -r "$confdir/conf.d/secrets.yaml" || write_secrets >"$confdir/conf.d/secrets.yaml"

# generate all missing keys
test ! -r "$confdir/signing.key" || mv "$confdir/signing.key" "$confdir/conf.d/signing.key"
$python -m synapse.app.homeserver --generate-keys -c "$confdir/homeserver.yml" -c "$confdir/conf.d"

# start the synapse server
$python -m synapse.app.homeserver -c "$confdir/homeserver.yml" -c "$confdir/conf.d"
