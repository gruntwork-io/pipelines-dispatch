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
        uses: path-to-your-action-repo@v1
        with:
          account_id: ${{ secrets.ACCOUNT_ID }}
          repo: 'infrastructure-pipelines'
          repo_owner: 'your-company-name'
          branch: 'main'
          working_directory: 'path-to-your-working-directory'
          command: 'plan'
          args: '-destroy'
          token: ${{ secrets.GITHUB_TOKEN }}
          change_type: 'AccountAdded'
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
