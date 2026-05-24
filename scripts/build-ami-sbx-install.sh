#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

DEFAULT_ARTICLES_ZIP_URL="https://github.com/swualabs/sandboxd-o/releases/download/v0.2.0/articles.zip"

ARTICLES_ZIP_URL="${ARTICLES_ZIP_URL:-$DEFAULT_ARTICLES_ZIP_URL}"
APP_ROOT="${APP_ROOT:-/opt/sandboxd-o}"
APP_DIR="${APP_ROOT}/articles"
SYSTEMD_DIR="/etc/systemd/system"

COMPONENT="${1:-${SANDBOXD_COMPONENT:-}}"
START_SERVICE="${START_SERVICE:-true}"
ALLOW_MISSING_ENV="${ALLOW_MISSING_ENV:-false}"

TMP_DIR=""

log() {
    printf '[sandboxd-o-ami] %s\n' "$*" >&2
}

die() {
    printf '[sandboxd-o-ami] ERROR: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    if [[ -n "${TMP_DIR:-}" && -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}

on_error() {
    local exit_code=$?
    local line_no="${1:-unknown}"

    printf '[sandboxd-o-ami] ERROR: failed at line %s, exit code %s\n' "$line_no" "$exit_code" >&2

    if [[ -n "${COMPONENT:-}" ]] && command -v systemctl >/dev/null 2>&1; then
        if systemctl list-unit-files "${COMPONENT}.service" >/dev/null 2>&1; then
            printf '\n[sandboxd-o-ami] Recent journal logs:\n' >&2
            journalctl -u "${COMPONENT}.service" -n 120 --no-pager >&2 || true
        fi
    fi

    exit "$exit_code"
}

trap 'on_error $LINENO' ERR
trap cleanup EXIT

usage() {
    cat >&2 <<'EOF'
Usage:
  sudo bash prepare-sandboxd-o-ami.sh sbxlet
  sudo bash prepare-sandboxd-o-ami.sh sbxorch

Environment variables:
  ARTICLES_ZIP_URL    Release zip URL.
  APP_ROOT            Install root directory. Default: /opt/sandboxd-o
  START_SERVICE       Start service immediately after install. Default: true
  ALLOW_MISSING_ENV   Allow missing .env file. Default: false

Examples:
  sudo bash prepare-sandboxd-o-ami.sh sbxlet
  sudo bash prepare-sandboxd-o-ami.sh sbxorch
  sudo START_SERVICE=false bash prepare-sandboxd-o-ami.sh sbxlet
  sudo ARTICLES_ZIP_URL=https://github.com/swualabs/sandboxd-o/releases/download/v0.2.0/articles.zip bash prepare-sandboxd-o-ami.sh sbxlet
EOF
}

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        die "this script must be run as root. Use sudo."
    fi
}

normalize_component() {
    case "$COMPONENT" in
        sbxlet | sbxorch)
            ;;
        "" | -h | --help | help)
            usage
            exit 0
            ;;
        *)
            usage
            die "invalid component: ${COMPONENT}. Expected 'sbxlet' or 'sbxorch'."
            ;;
    esac
}

require_ubuntu() {
    if [[ ! -r /etc/os-release ]]; then
        die "/etc/os-release not found. This script expects Ubuntu."
    fi

    # shellcheck disable=SC1091
    . /etc/os-release

    if [[ "${ID:-}" != "ubuntu" ]]; then
        die "unsupported OS: ${ID:-unknown}. This script expects Ubuntu."
    fi
}

require_systemd() {
    if ! command -v systemctl >/dev/null 2>&1; then
        die "systemctl not found. This script requires systemd."
    fi

    if [[ ! -d /run/systemd/system ]]; then
        die "systemd does not appear to be running."
    fi
}

install_packages() {
    export DEBIAN_FRONTEND=noninteractive

    log "Installing required packages"

    apt-get update
    apt-get install -y \
        ca-certificates \
        curl \
        unzip
}

download_and_extract() {
    local tmp_dir="$1"
    local zip_path="${tmp_dir}/articles.zip"
    local extract_dir="${tmp_dir}/extract"

    mkdir -p "$extract_dir"

    log "Downloading articles.zip from ${ARTICLES_ZIP_URL}"

    curl \
        --fail \
        --location \
        --show-error \
        --silent \
        --retry 5 \
        --retry-delay 2 \
        --connect-timeout 10 \
        --max-time 300 \
        "$ARTICLES_ZIP_URL" \
        -o "$zip_path"

    if [[ ! -s "$zip_path" ]]; then
        die "downloaded zip file is empty: ${zip_path}"
    fi

    log "Validating zip archive"
    unzip -tq "$zip_path" >/dev/null

    log "Extracting zip archive"
    unzip -q "$zip_path" -d "$extract_dir"

    printf '%s\n' "$extract_dir"
}

find_articles_dir() {
    local extract_dir="$1"
    local component_path=""

    if [[ ! -d "$extract_dir" ]]; then
        die "extract directory does not exist: ${extract_dir}"
    fi

    component_path="$(find "$extract_dir" -type f -name "$COMPONENT" | head -n 1 || true)"

    if [[ -z "$component_path" ]]; then
        log "Extracted files:"
        find "$extract_dir" -maxdepth 5 -type f -printf '  %p\n' >&2 || true
        die "component binary '${COMPONENT}' not found in articles.zip"
    fi

    dirname "$component_path"
}

validate_extracted_files() {
    local src_dir="$1"

    [[ -d "$src_dir" ]] || die "source directory does not exist: ${src_dir}"
    [[ -f "${src_dir}/${COMPONENT}" ]] || die "${COMPONENT} not found in ${src_dir}"

    if [[ "$COMPONENT" == "sbxlet" ]]; then
        [[ -f "${src_dir}/install.sh" ]] || die "install.sh is required for sbxlet but was not found in ${src_dir}"
    fi

    if [[ ! -f "${src_dir}/.env" ]]; then
        if [[ "$ALLOW_MISSING_ENV" == "true" ]]; then
            log "WARNING: .env not found in ${src_dir}, continuing because ALLOW_MISSING_ENV=true"
        else
            die ".env not found in ${src_dir}. Set ALLOW_MISSING_ENV=true to allow this."
        fi
    fi
}

stop_existing_services() {
    log "Stopping old sandboxd-o services if present"

    local services=(
        sbxlet.service
        sbxorch.service
        sandboxd-o.service
        sandboxd-o-sbxlet.service
        sandboxd-o-sbxorch.service
    )

    for svc in "${services[@]}"; do
        systemctl stop "$svc" >/dev/null 2>&1 || true
        systemctl disable "$svc" >/dev/null 2>&1 || true

        if [[ -f "${SYSTEMD_DIR}/${svc}" ]]; then
            rm -f "${SYSTEMD_DIR}/${svc}"
        fi
    done

    systemctl daemon-reload
}

install_articles() {
    local src_dir="$1"

    log "Installing articles into ${APP_DIR}"

    mkdir -p "$APP_ROOT"
    rm -rf "$APP_DIR"
    mkdir -p "$APP_DIR"

    cp -a "${src_dir}/." "$APP_DIR/"

    chown -R root:root "$APP_DIR"

    chmod 0755 "$APP_ROOT"
    chmod 0755 "$APP_DIR"
    chmod 0755 "${APP_DIR}/${COMPONENT}"

    if [[ -f "${APP_DIR}/install.sh" ]]; then
        chmod 0755 "${APP_DIR}/install.sh"
    fi

    if [[ -f "${APP_DIR}/.env" ]]; then
        chmod 0600 "${APP_DIR}/.env"
    fi
}

run_install_sh_if_needed() {
    if [[ "$COMPONENT" != "sbxlet" ]]; then
        log "Skipping install.sh because selected component is ${COMPONENT}"
        return
    fi

    log "Running install.sh for sbxlet"

    cd "$APP_DIR"
    ./install.sh
}

write_systemd_service() {
    local service_path="${SYSTEMD_DIR}/${COMPONENT}.service"
    local binary_path="${APP_DIR}/${COMPONENT}"
    local env_path="${APP_DIR}/.env"
    local env_file_line=""

    if [[ "$ALLOW_MISSING_ENV" == "true" ]]; then
        env_file_line="EnvironmentFile=-${env_path}"
    else
        env_file_line="EnvironmentFile=${env_path}"
    fi

    log "Writing systemd service: ${service_path}"

    cat >"$service_path" <<EOF
[Unit]
Description=Sandboxd-O ${COMPONENT}
Documentation=https://github.com/swualabs/sandboxd-o
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=${APP_DIR}
${env_file_line}
ExecStart=${binary_path}
Restart=always
RestartSec=3
KillSignal=SIGTERM
TimeoutStopSec=30
LimitNOFILE=1048576
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    chmod 0644 "$service_path"

    systemctl daemon-reload
    systemctl enable "${COMPONENT}.service"
}

verify_binary() {
    local binary_path="${APP_DIR}/${COMPONENT}"

    [[ -f "$binary_path" ]] || die "binary not found after install: ${binary_path}"
    [[ -x "$binary_path" ]] || die "binary is not executable: ${binary_path}"

    log "Binary installed: ${binary_path}"
}

verify_env() {
    local env_path="${APP_DIR}/.env"

    if [[ -f "$env_path" ]]; then
        log ".env installed: ${env_path}"

        if grep -nEv '^[[:space:]]*($|#|[A-Za-z_][A-Za-z0-9_]*=)' "$env_path" >/tmp/sandboxd-o-env-invalid-lines 2>/dev/null; then
            log "WARNING: .env has lines that may not be compatible with systemd EnvironmentFile:"
            cat /tmp/sandboxd-o-env-invalid-lines >&2
            log "WARNING: WorkingDirectory is still set, so ${COMPONENT} can still load .env itself if it supports dotenv loading."
        fi

        rm -f /tmp/sandboxd-o-env-invalid-lines
    else
        log "WARNING: .env is missing"
    fi
}

start_and_verify_service() {
    if [[ "$START_SERVICE" != "true" ]]; then
        log "Skipping immediate service start because START_SERVICE=${START_SERVICE}"
        return
    fi

    log "Starting ${COMPONENT}.service"

    systemctl restart "${COMPONENT}.service"

    sleep 2

    if ! systemctl is-active --quiet "${COMPONENT}.service"; then
        journalctl -u "${COMPONENT}.service" -n 120 --no-pager >&2 || true
        die "${COMPONENT}.service failed to start"
    fi

    log "${COMPONENT}.service is active"
}

print_summary() {
    cat <<EOF

[sandboxd-o-ami] Done.

Component:
  ${COMPONENT}

Installed directory:
  ${APP_DIR}

Systemd service:
  ${COMPONENT}.service

Useful commands:
  systemctl status ${COMPONENT}.service --no-pager
  journalctl -u ${COMPONENT}.service -f
  systemctl restart ${COMPONENT}.service

AMI note:
  This service is enabled and will start automatically on boot.
EOF
}

main() {
    require_root
    normalize_component
    require_ubuntu
    require_systemd
    install_packages

    TMP_DIR="$(mktemp -d)"

    local extract_dir
    extract_dir="$(download_and_extract "$TMP_DIR")"

    local src_dir
    src_dir="$(find_articles_dir "$extract_dir")"

    log "Detected articles directory: ${src_dir}"

    validate_extracted_files "$src_dir"
    stop_existing_services
    install_articles "$src_dir"
    run_install_sh_if_needed
    verify_binary
    verify_env
    write_systemd_service
    start_and_verify_service
    print_summary
}

main "$@"
