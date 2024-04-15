#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# Required environment variables
: "${CHANGE_TYPE:? "CHANGE_TYPE environment variable must be set"}"
: "${MANAGEMENT_ACCOUNT:? "MANAGEMENT_ACCOUNT environment variable must be set"}"
: "${BRANCH:? "BRANCH environment variable must be set"}"
: "${INFRA_LIVE_REPO:? "INFRA_LIVE_REPO environment variable must be set"}"
: "${WORKING_DIRECTORY:? "WORKING_DIRECTORY environment variable must be set"}"
: "${COMMAND:? "COMMAND environment variable must be set"}"

# Optional environment variables
ARGS="${ARGS:-}"
NEW_ACCOUNT_NAME="${NEW_ACCOUNT_NAME:-}"
TEAM_ACCOUNT_NAMES="${TEAM_ACCOUNT_NAMES:-}"
CHILD_ACCOUNT_ID="${CHILD_ACCOUNT_ID:-}"
PRESIGN_TOKEN="${PRESIGN_TOKEN:-false}"
NEW_ACCOUNTS="${NEW_ACCOUNTS:-}"

check_pipeline_is_installed() {
    if ! command -v pipelines &> /dev/null; then
        echo "pipelines CLI not installed"
        exit 1
    fi
}

presign_caller_identity_token() {
    check_pipeline_is_installed

    pipelines auth presign
}

append_presigned_caller_identity_token() {
    local -r workflow_inputs="$1"
    local -r presigned_caller_identity="$2"

    echo "$workflow_inputs" | jq -c --arg presigned_caller_identity "$presigned_caller_identity" '. + {presigned_caller_identity: $presigned_caller_identity}'
}

handle_account_request() {
    local -r management_account="$1"
    local -r new_account_name="$2"
    local -r branch="$3"
    local -r infra_live_repo="$4"
    local -r working_directory="$5"
    local -r terragrunt_command="$6"
    local -r presign_token="$7"

    echo "workflow=account-factory-1-provision.yml" >> "$GITHUB_OUTPUT"
    workflow_inputs="$(jq -c -n \
        --arg management_account "$management_account" \
        --arg new_account_name "$new_account_name" \
        --arg branch "$branch" \
        --arg infra_live_repo "$infra_live_repo" \
        --arg working_directory "$working_directory" \
        --arg terragrunt_command "$terragrunt_command" \
        '{
            "management_account": $management_account,
            "team_account_names": [$new_account_name],
            "branch": $branch,
            "infra_live_repo": $infra_live_repo,
            "working_directory": $working_directory,
            "terragrunt_command": $terragrunt_command
        }'
    )"
    if [[ $presign_token == "true" ]]; then
        presigned_caller_identity="$(presign_caller_identity_token)"
        workflow_inputs="$(append_presigned_caller_identity_token "$workflow_inputs" "$presigned_caller_identity")"
        echo "::add-mask::$presigned_caller_identity"
    fi
    echo "workflow_inputs=$workflow_inputs" >> "$GITHUB_OUTPUT"
}

handle_account_added() {
    local -r management_account="$1"
    local -r branch="$2"
    local -r infra_live_repo="$3"
    local -r working_directory="$4"
    local -r terragrunt_command="$5"
    local -r new_accounts="$6"
    local -r presign_token="$7"

    echo "workflow=account-factory-2-run-baselines.yml" >> "$GITHUB_OUTPUT"
    workflow_inputs="$(jq -c -n \
        --arg management_account "$management_account" \
        --arg branch "$branch" \
        --arg infra_live_repo "$infra_live_repo" \
        --arg working_directory "$working_directory" \
        --arg terragrunt_command "$terragrunt_command" \
        --arg new_accounts "$new_accounts" \
        '{
            "management_account": $management_account,
            "branch": $branch,
            "infra_live_repo": $infra_live_repo,
            "working_directory": $working_directory,
            "terragrunt_command": $terragrunt_command,
            "new_accounts": $new_accounts
        }'
    )"
    if [[ $presign_token == "true" ]]; then
        presigned_caller_identity="$(presign_caller_identity_token)"
        workflow_inputs="$(append_presigned_caller_identity_token "$workflow_inputs" "$presigned_caller_identity")"
        echo "::add-mask::$presigned_caller_identity"
    fi
    echo "workflow_inputs=$workflow_inputs" >> "$GITHUB_OUTPUT"
}

handle_team_accounts_requested() {
    local -r management_account="$1"
    local -r branch="$2"
    local -r infra_live_repo="$3"
    local -r working_directory="$4"
    local -r terragrunt_command="$5"
    local -r team_account_names="$6"
    local -r presign_token="$7"

    echo "workflow=account-factory-1-provision.yml" >> "$GITHUB_OUTPUT"
    workflow_inputs="$(jq -c -n \
        --arg management_account "$management_account" \
        --arg branch "$branch" \
        --arg infra_live_repo "$infra_live_repo" \
        --arg working_directory "$working_directory" \
        --arg terragrunt_command "$terragrunt_command" \
        --arg team_account_names "$team_account_names" \
        '{
            "management_account": $management_account,
            "branch": $branch,
            "infra_live_repo": $infra_live_repo,
            "working_directory": $working_directory,
            "terragrunt_command": $terragrunt_command,
            "team_account_names": $team_account_names
        }'
    )"
    if [[ $presign_token == "true" ]]; then
        presigned_caller_identity="$(presign_caller_identity_token)"
        workflow_inputs="$(append_presigned_caller_identity_token "$workflow_inputs" "$presigned_caller_identity")"
        echo "::add-mask::$presigned_caller_identity"
    fi
    echo "workflow_inputs=$workflow_inputs" >> "$GITHUB_OUTPUT"
}

handle_default() {
    local -r management_account="$1"
    local -r branch="$2"
    local -r infra_live_repo="$3"
    local -r working_directory="$4"
    local -r terragrunt_command="$5"
    local -r pipelines_change_type="$6"
    local -r child_account_id="$7"
    local -r presign_token="$8"

    echo "workflow=terragrunt-executor.yml" >> "$GITHUB_OUTPUT"
    workflow_inputs="$(jq -c -n \
        --arg account "$management_account" \
        --arg branch "$branch" \
        --arg infra_live_repo "$infra_live_repo" \
        --arg working_directory "$working_directory" \
        --arg terragrunt_command "$terragrunt_command" \
        --arg pipelines_change_type "$pipelines_change_type" \
        --arg child_account_id "$child_account_id" \
        '{
            "account": $account,
            "branch": $branch,
            "infra_live_repo": $infra_live_repo,
            "working_directory": $working_directory,
            "terragrunt_command": $terragrunt_command,
            "pipelines_change_type": $pipelines_change_type,
            "child_account_id": $child_account_id
        }'
    )"
    if [[ $presign_token == "true" ]]; then
        presigned_caller_identity="$(presign_caller_identity_token)"
        workflow_inputs="$(append_presigned_caller_identity_token "$workflow_inputs" "$presigned_caller_identity")"
        echo "::add-mask::$presigned_caller_identity"
    fi
    echo "workflow_inputs=$workflow_inputs" >> "$GITHUB_OUTPUT"
}

case "$CHANGE_TYPE" in
    AccountRequested)
        handle_account_request "$MANAGEMENT_ACCOUNT" "$NEW_ACCOUNT_NAME" "$BRANCH" "$INFRA_LIVE_REPO" "$WORKING_DIRECTORY" "$COMMAND $ARGS" "$PRESIGN_TOKEN"
        ;;
    AccountAdded|TeamAccountsAdded)
        handle_account_added "$MANAGEMENT_ACCOUNT" "$BRANCH" "$INFRA_LIVE_REPO" "$WORKING_DIRECTORY" "$COMMAND $ARGS" "$NEW_ACCOUNTS" "$PRESIGN_TOKEN"
        ;;
    TeamAccountsRequested)
        handle_team_accounts_requested "$MANAGEMENT_ACCOUNT" "$BRANCH" "$INFRA_LIVE_REPO" "$WORKING_DIRECTORY" "$COMMAND $ARGS" "$TEAM_ACCOUNT_NAMES" "$PRESIGN_TOKEN"
        ;;
    *)
        handle_default "$MANAGEMENT_ACCOUNT" "$BRANCH" "$INFRA_LIVE_REPO" "$WORKING_DIRECTORY" "$COMMAND $ARGS" "$CHANGE_TYPE" "$CHILD_ACCOUNT_ID" "$PRESIGN_TOKEN"
        ;;
esac
