# Pipelines Dispatch GitHub Action

This GitHub Action, named "Pipelines Dispatch," is designed to dispatch Terragrunt plan/apply/destroy jobs using Gruntwork Pipelines. It facilitates infrastructure change management by triggering the appropriate jobs in the customer's `infrastructure-pipelines` repository. The Action also adds a link to the logs in pull requests for easy reference.

## Inputs

- `account_id` (required): The AWS Account ID in which the action will run.
- `repo` (required): The name of the `infrastructure-pipelines` repository where jobs should be dispatched.
- `repo_owner` (required): The owner of the `infrastructure-pipelines` repository.
- `branch` (required): The branch against which Pipelines will run the action.
- `working_directory` (required): The directory in which Terragrunt will run the action.
- `command` (required): The command (e.g., plan, apply, destroy) for Terragrunt to execute.
- `args` (required): The arguments to pass into Terragrunt.
- `token` (required): GitHub Personal Access Token (PAT) to clone the pipelines repo.
- `change_type` (required): The type of infrastructure change that occurred.
- `additional_data` (optional): Additional data related to the change type.
- `actor` (required): The GitHub actor responsible for the change.
- `polling_interval_ms` (optional): "The interval, in milliseconds, to poll for the status of the dispatched job. Keep in mind that each poll will count against your GitHub Actions API rate limit. The default is 1 minute(60000 milliseconds)"

### Pipelines Presign Inputs

If these inputs are provided, the action will download the `pipelines` binary and run `pipelines auth presign` to generate a presigned `GetCallerIdentity` request for the specified role and region. The presigned request will be passed to the `infrastructure-pipelines` workflow as an additional input. This is a useful, additional layer of security to ensure that the `infrastructure-pipelines` workflow is being called by a repo it trusts.

- `presign_token` (optional): Determines if this action should generate a presigned `GetCallerIdentity` request. If not set to `true`, the action will not generate a presigned request for verification in `infrastructure-pipelines`.
- `install_pipelines_cli` (optional): Determines if this action should download the `pipelines` CLI binary. Defaults to `true`. Ignored if `pipelines_token` is not `true`.
- `assume_auth_role` (optional): Determines if this action should assume a role when running `pipelines auth presign`. Defaults to `true`. Ignored if `pipelines_token` is not `true`.
- `pipelines_token` (optional): GitHub PAT to download `pipelines` binary. Ignored if `presign_token` and `install_pipelines_cli` are not `true`.
- `pipelines_cli_version` (optional): The version of the `pipelines` binary to download. If not provided, a default version will be used.
- `pipelines_auth_role` (optional): The IAM role to assume when running the `pipelines auth presign`. Ignored if `presign_token` and `assume_auth_role` are not `true`.
- `pipelines_auth_region` (optional): The AWS region in which to perform the `pipelines auth presign`. If not provided, the `us-east-1` region will be used. Ignored if `presign_token` and `assume_auth_role` are not `true`.

## Usage

To use this GitHub Action, add the following code to your workflow YAML file:

```yaml
name: Pipeline Dispatch Workflow

on:
  pull_request:

jobs:
  dispatch_job:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Run Pipelines Dispatch
        uses: gruntwork-io/pipelines-dispatch@v1.0.0
        with:
          account_id: ${{ secrets.ACCOUNT_ID }}
          repo: "infrastructure-pipelines"
          repo_owner: "your-company-name"
          branch: "main"
          working_directory: "path-to-your-working-directory"
          command: "plan"
          args: "-destroy"
          token: ${{ secrets.GITHUB_TOKEN }}
          change_type: "AccountAdded"
          additional_data: '{"AccountName": "NewAccount"}'
          actor: ${{ github.actor }}
```

## Outputs

This GitHub Action provides the following outputs:

- `run_id`: The ID of the workflow run.

## Notes

- The action dispatches the appropriate job(s) based on the change type.
- Logs for Terragrunt plan are added as pull request comments.
- In case of apply failure, an issue is created with relevant details.
- If the change type is 'AccountRequested' or 'AccountAdded', additional account-specific steps are performed.
