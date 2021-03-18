# GitHub Actions Self Hosted Runners on Anthos

> Build and deploy GitHub Actions [self hosted runners](https://help.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners) to Google Cloud [Anthos GKE](https://cloud.google.com/anthos/gke), making them available to a given GitHub repository.

[![awesome-runners](https://img.shields.io/badge/listed%20on-awesome--runners-blue.svg)](https://github.com/jonico/awesome-runners)![Build status](https://github.com/github-developer/self-hosted-runners-anthos/workflows/Self%20Hosted%20Runner%20CI/CD/badge.svg)

## About

This project accompanies the "GitHub Actions self-hosted runners on Google Cloud" [blog post](https://github.blog/2020-08-04-github-actions-self-hosted-runners-on-google-cloud/).

![image](https://github.blog/wp-content/uploads/2020/08/hybrid-runners-with-anthos.png?resize=1024%2C654?w=1384)

A Continuous Integration [job](https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions#jobs) builds the image and publishes it to Google Container Registry, and a Continuous Deployment job deploys it to Google Kubernetes Engine (GKE). The self hosted runners in this cluster are made available to the GitHub repository configured via the `GITHUB_REPO` environment variable below.

Because a Docker-in-Docker sidecar pod has been used in this project, these self-hosted runners can also run container builds. Though this approach offers build flexibility, it requires a [`privileged` security context](https://github.com/github-developer/self-hosted-runners-anthos/blob/cb2ee160def13ec3fff256ea43804cafe9fb7e20/deployment.yml#L55) and therefore extends the trust boundary to the whole cluster. Extra caution is recommended with this approach or [removing the sidecar](https://github.com/github-developer/self-hosted-runners-anthos/blob/cb2ee160def13ec3fff256ea43804cafe9fb7e20/deployment.yml#L45) if your application doesn’t require container builds.

⚠️ Note that this use case is considered experimental and _not officially supported by GitHub at this time_. Additionally [it’s recommended](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners) not to use self-hosted runners on public repositories for a number of security reasons. 

## Setup

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
    container.googleapis.com \
    anthos.googleapis.com
```

* Create GKE cluster ([docs](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster))

```
gcloud container clusters create self-hosted-runner-test-cluster
```

* Register cluster to the environ [docs](https://cloud.google.com/anthos/docs/setup/cloud#gcloud)
```
gcloud container hub memberships register self-hosted-anthos-membership \
  --project=self-hosted-runner-test-myid \
  --gke-uri=https://container.googleapis.com/v1/projects/self-hosted-runner-test-myid/locations/us-west1/clusters/self-hosted-runner-test-cluster \
  --service-account-key-file=/path-to/service-account-key.json
```

* Get the credentails for this cluster
```
gcloud container clusters get-credentials self-hosted-runner-test-cluster --region us-west1
```

* Use [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to provide a Personal Access Token (`TOKEN`) and repository/organization (`GITHUB_REPO`) as environment variables available to your pods.

```
kubectl create secret generic self-hosted-runner-creds \
    --from-literal=GITHUB_REPO='<owner>/<repo>' \
    --from-literal=TOKEN='token'
```

* Set these as secrets in your GitHub repository:
  * `GCP_PROJECT`: ID of your Google Cloud Platform project, eg. `self-hosted-runner-test-897234`
  * `GCP_KEY`: Download your [Service Account JSON credentials](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) and Base64 encode them, eg. output of `cat ~/path/to/my/credentials.json | base64`
  * `TOKEN`: Personal Access Token. From the [documentation](https://developer.github.com/v3/actions/self_hosted_runners/), "Access tokens require `repo scope` for private repos and `public_repo scope` for public repos".

* Update these environment variables in [`cicd.yml`](.github/workflows/cicd.yml) according to the specific names you chose for your project:
  * `GKE_CLUSTER`: Name of your GKE cluster chosen above, eg. `self-hosted-runner-test-cluster`
  * `GKE_SECRETS`: Name of your secret configuration group, eg. `self-hosted-runner-creds`
  * `GCP_REGION`: The region your cluster is in, eg. `us-central1`
  * `IMAGE`: Name of your image used in [`ci.yml`](.github/workflows/ci.yml) and [`deployment.yml`](.github/workflows/deployment.yml)
  * `GITHUB_REPO`: `owner/repo` of the repository that will use the self hosted runner, eg. `octocat/sandbox`

#### Automation
* Upon push of any image-related code to any branch, [`ci.yml`](.github/workflows/ci.yml) will kick off to build and push the Docker image.
* Upon push of any code to master branch, [`cd.yml`](.github/workflows/cd.yml) will kick off to deploy to Google Cloud.

## Future improvements
* Replace Docker-in-Docker with Tekton, Buildah, etc.

## Contributions

We welcome contributions! See [how to contribute](CONTRIBUTING.md).

## License

[MIT](LICENSE)
