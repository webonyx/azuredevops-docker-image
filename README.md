# azuredevops-docker-image

Public docker image available at [webonyx/azuredevops-toolbox](https://hub.docker.com/r/webonyx/azuredevops-toolbox)

Example usage:

```yaml
pool:
  vmImage: 'ubuntu-latest'

container: webonyx/azuredevops-toolbox:latest

steps:
  - script: |
      rover --version
      kustomize version
      xh --version

```
