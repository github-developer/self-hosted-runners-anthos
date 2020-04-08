# GitHub Actions Self Hosted Runners on Anthos

This project shows an example configuration and usage of GitHub Actions self hosted runners on Anthos, using the [self hosted runners API](https://developer.github.com/v3/actions/self_hosted_runners/). [Contributions](CONTRIBUTING.md) are welcome!

A Continuous Integration [job](https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions#jobs) builds the image and publishes it to Google Container Registry, and a Continuous Deployment job deploys it to Google Kubernetes Engine (GKE). The self hosted runners in this cluster are made available to the GitHub repository configured via the `GITHUB_REPO` environment variable below.

## Usage

### Local

#### Setup

Set these in an `.env` file at the top level. Inject these into the Docker container at runtime; do _not_ check them in to Git in plaintext.
* `GITHUB_REPO` - repository to allow to use the self hosted runner (eg. `octocat/spoon-knife`)
* `TOKEN`: [Personal Access Token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) or [OAuth app token](https://developer.github.com/apps/building-oauth-apps/authorizing-oauth-apps/) with `administration` permission, which is necessary for interacting with the [Self Hosted Runner API](https://developer.github.com/v3/actions/self_hosted_runners/). [`GITHUB_TOKEN`](https://help.github.com/en/actions/configuring-and-managing-workflows/authenticating-with-the-github_token) does not have `administration` permission.

#### Run Docker container
* `docker build -t self-hosted-runner .`
* `docker run --env-file=.env -v /var/run/docker.sock:/var/run/docker.sock self-hosted-runner` (Docker-in-Docker not recommended for production)

### Google Kubernetes Engine 

#### Setup
* Create a new Google Cloud Platform project ([docs](https://cloud.google.com/sdk/gcloud/reference/projects/create))

```
gcloud projects create self-hosted-runner-test --name "Self Hosted Runner Test"
```

* Create a new Service Account ([docs](https://cloud.google.com/iam/docs/creating-managing-service-accounts))

```
gcloud iam service-accounts create runner-admin \
    --description "Runner administrator"
```

* Grant roles to Service Account ([docs](https://cloud.google.com/iam/docs/granting-roles-to-service-accounts)). Note: should be restricted in production environments.

```
gcloud projects add-iam-policy-binding self-hosted-runner-test \
  --member serviceAccount:runner-admin@self-hosted-runner-test.iam.gserviceaccount.com \
  --role roles/admin
```

* Enable APIs ([docs](https://cloud.google.com/endpoints/docs/openapi/enable-api))

```
gcloud services enable \
    stackdriver.googleapis.com \
    compute.googleapis.com \
    stackdriver.googleapis.com \
    container.googleapis.com
```

* Create GKE cluster ([docs](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster))

```
gcloud container clusters create self-hosted-runner-test-cluster \
    --zone us-central1
```

* Instead of setting these values in a local `.env` file as above, create [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/) available to your pods at runtime.

```
kubectl create secret generic self-hosted-runner-creds \
    --from-literal=GITHUB_REPO='https://github.com/<owner>/<repo>' \
    --from-literal=GITHUB_TOKEN='token'
```

* Set these as secrets in your GitHub repository:
  * `GCP_PROJECT`: Name of your Google Cloud Platform project, eg. `self-hosted-runner-test`
  * `GCP_EMAIL`: Service Account email, eg. `runner-admin@self-hosted-runner-test.iam.gserviceaccount.com`
  * `GCP_KEY`: Download your [Service Account JSON credentials](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) and Base64 encode them, eg. output of `cat ~/path/to/my/credentials.json | base64`
  * `TOKEN`: Personal Access Token. From the [documentation](https://developer.github.com/v3/actions/self_hosted_runners/), "Access tokens require `repo scope` for private repos and `public_repo scope` for public repos".

* Update these environment variables in [`cicd.yml`](.github/workflows/cicd.yml) according to the specific names you chose for your project:
  * `GKE_CLUSTER`: Name of your GKE cluster chosen above, eg. `self-hosted-runner-test-cluster`
  * `GKE_SECRETS`: Name of your secret configuration group, eg. `self-hosted-runner-creds`
  * `GCP_REGION`: The region your cluster is in, eg. `us-central1`
  * `IMAGE`: Name of your image used in [`ci.yml`](.github/workflows/ci.yml) and [`deployment.yml`](.github/workflows/deployment.yml)
  * `GITHUB_REPO`: `owner/repo` of the repository that will use the self hosted runner, eg. `octocat/sandbox`

* Update values in `deployment.yml` to reflect your image name and desired configuration

#### Automation
* Upon push of any image-related code to any branch, [`ci.yml`](.github/workflows/ci.yml) will kick off to build and push the Docker image.
* Upon push of any code to master branch, [`cd.yml`](.github/workflows/cd.yml) will kick off to deploy to Google Cloud.

## Future improvements
* Replace Docker-in-Docker with Tekton, Buildah, etc.