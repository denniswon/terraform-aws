# terraform aws


## Setup
- Install terraform https://www.terraform.io/
- create `s3://tf-interopera-dev` bucket on dev aws account
- initilise terraform
    ```
    cd deploy-dev
    terraform init
    terraform apply
    ```
## Structure
- `components`: shared tf library modules (vpc, security-group)
- `deploy-***`: target env to deploy
- `platform`: main tf module components to be created in all env