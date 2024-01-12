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
: "${ARGS:? "ARGS environment variable must be set"}"

# Optional environment variables
NEW_ACCOUNT_NAME="${NEW_ACCOUNT_NAME:-}"
TEAM_ACCOUNT_NAMES="${TEAM_ACCOUNT_NAMES:-}"
CHILD_ACCOUNT_ID="${CHILD_ACCOUNT_ID:-}"
PIPELINES_AUTH_ROLE="${PIPELINES_AUTH_ROLE:-}"
TEAM_ACCOUNT_DATA="${TEAM_ACCOUNT_DATA:-}"

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
    readonly workflow_inputs="$1"

    presigned_caller_identity="$(presign_caller_identity_token)"
    jq --arg presigned_caller_identity "$presigned_caller_identity" '. + {presigned_caller_identity: $presigned_caller_identity}' <<< "$workflow_inputs"
}

handle_account_request() {
    readonly management_account="$1"
    readonly new_account_name="$2"
    readonly branch="$3"
    readonly infra_live_repo="$4"
    readonly working_directory="$5"
    readonly terragrunt_command="$6"
    readonly pipelines_auth_role="$7"

    echo "workflow=create-account-and-generate-baselines.yml" >> "$GITHUB_OUTPUT"
    workflow_inputs="$(jq -c -n \
        --arg management_account "$management_account" \
        --arg new_account_name "$new_account_name" \
        --arg branch "$branch" \
        --arg infra_live_repo "$infra_live_repo" \
        --arg working_directory "$working_directory" \
        --arg terragrunt_command "$terragrunt_command" \
        '{
            "management_account": $management_account,
            "new_account_name": $new_account_name,
            "branch": $branch,
            "infra_live_repo": $infra_live_repo,
            "working_directory": $working_directory,
            "terragrunt_command": $terragrunt_command
        }'
    )"
    if [[ -n "${pipelines_auth_role:-}" ]]; then
        workflow_inputs="$(append_presigned_caller_identity_token "$workflow_inputs")"
    fi
    echo "workflow_inputs=$workflow_inputs" >> "$GITHUB_OUTPUT"
}

handle_account_added() {
    readonly management_account="$1"
    readonly child_account="$2"
    readonly branch="$3"
    readonly infra_live_repo="$4"
    readonly working_directory="$5"
    readonly terragrunt_command="$6"
    readonly pipelines_auth_role="$7"

    echo "workflow=apply-new-account-baseline.yml" >> "$GITHUB_OUTPUT"
    workflow_inputs="$(jq -c -n \
        --arg management_account "$management_account" \
        --arg child_account "$child_account" \
        --arg branch "$branch" \
        --arg infra_live_repo "$infra_live_repo" \
        --arg working_directory "$working_directory" \
        --arg terragrunt_command "$terragrunt_command" \
        '{
            "management_account": $management_account,
            "child_account": $child_account,
            "branch": $branch,
            "infra_live_repo": $infra_live_repo,
            "working_directory": $working_directory,
            "terragrunt_command": $terragrunt_command
        }'
    )"
    if [[ -n "${pipelines_auth_role:-}" ]]; then
        workflow_inputs="$(append_presigned_caller_identity_token "$workflow_inputs")"
    fi
    echo "workflow_inputs=$workflow_inputs" >> "$GITHUB_OUTPUT"
}

handle_team_accounts_requested() {
    readonly management_account="$1"
    readonly branch="$2"
    readonly infra_live_repo="$3"
    readonly working_directory="$4"
    readonly terragrunt_command="$5"
    readonly team_account_names="$6"
    readonly pipelines_auth_role="$7"

    echo "workflow=create-sdlc-accounts-and-generate-baselines.yml" >> "$GITHUB_OUTPUT"
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
    if [[ -n "${pipelines_auth_role:-}" ]]; then
        workflow_inputs="$(append_presigned_caller_identity_token "$workflow_inputs")"
    fi
    echo "workflow_inputs=$workflow_inputs" >> "$GITHUB_OUTPUT"
}

handle_team_accounts_added() {
    readonly management_account="$1"
    readonly branch="$2"
    readonly infra_live_repo="$3"
    readonly working_directory="$4"
    readonly terragrunt_command="$5"
    readonly team_account_data="$6"
    readonly pipelines_auth_role="$7"

    echo "workflow=apply-new-sdlc-accounts-baseline.yml" >> "$GITHUB_OUTPUT"
    workflow_inputs=$(jq -c -n \
        --arg management_account "$management_account" \
        --arg branch "$branch" \
        --arg infra_live_repo "$infra_live_repo" \
        --arg working_directory "$working_directory" \
        --arg terragrunt_command "$terragrunt_command" \
        --arg team_account_data "$team_account_data" \
        '{
            "management_account": $management_account,
            "branch": $branch,
            "infra_live_repo": $infra_live_repo,
            "working_directory": $working_directory,
            "terragrunt_command": $terragrunt_command,
            "team_account_data": $team_account_data
        }'
    )
    if [[ -n "${pipelines_auth_role:-}" ]]; then
        workflow_inputs="$(append_presigned_caller_identity_token "$workflow_inputs")"
    fi
    echo "workflow_inputs=$workflow_inputs" >> "$GITHUB_OUTPUT"
}

handle_default() {
    readonly management_account="$1"
    readonly branch="$2"
    readonly infra_live_repo="$3"
    readonly working_directory="$4"
    readonly terragrunt_command="$5"
    readonly pipelines_change_type="$6"
    readonly child_account_id="$7"

    echo "workflow=terragrunt-executor.yml" >> "$GITHUB_OUTPUT"
    workflow_inputs=$(jq -c -n \
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
    )
    if [[ -n "${pipelines_auth_role:-}" ]]; then
        workflow_inputs="$(append_presigned_caller_identity_token "$workflow_inputs")"
    fi
    echo "workflow_inputs=$workflow_inputs" >> "$GITHUB_OUTPUT"
}

case "$CHANGE_TYPE" in
    AccountRequested)
        handle_account_request "$MANAGEMENT_ACCOUNT" "$NEW_ACCOUNT_NAME" "$BRANCH" "$INFRA_LIVE_REPO" "$WORKING_DIRECTORY" "$COMMAND $ARGS" "$PIPELINES_AUTH_ROLE"
        ;;
    AccountAdded)
        handle_account_added "$MANAGEMENT_ACCOUNT" "$NEW_ACCOUNT_NAME" "$BRANCH" "$INFRA_LIVE_REPO" "$WORKING_DIRECTORY" "$COMMAND $ARGS" "$PIPELINES_AUTH_ROLE"
        ;;
    TeamAccountsRequested)
        handle_team_accounts_requested "$MANAGEMENT_ACCOUNT" "$BRANCH" "$INFRA_LIVE_REPO" "$WORKING_DIRECTORY" "$COMMAND $ARGS" "$TEAM_ACCOUNT_NAMES" "$PIPELINES_AUTH_ROLE"
        ;;
    TeamAccountsAdded)
        handle_team_accounts_added "$MANAGEMENT_ACCOUNT" "$BRANCH" "$INFRA_LIVE_REPO" "$WORKING_DIRECTORY" "$COMMAND $ARGS" "$TEAM_ACCOUNT_DATA" "$PIPELINES_AUTH_ROLE"
        ;;
    *)
        handle_default "$MANAGEMENT_ACCOUNT" "$BRANCH" "$INFRA_LIVE_REPO" "$WORKING_DIRECTORY" "$COMMAND $ARGS" "$CHANGE_TYPE" "$CHILD_ACCOUNT_ID" "$PIPELINES_AUTH_ROLE"
        ;;
esac
