## Applying the Lattice configurations

### Update the AWS CLI

If you haven't updated your AWS CLI for the latest service mesh model, run the following
command from this directory:

    $ aws configure add-model --service-name appmesh --service-model file://aws-cli-model.json

### Update environment

You will need environment variables to be set. It is recommended that you create a shell script
to export the following variables and then source it into your shell:

It is recommended that you use the `gamma` environment for the `LATTICE_FRONTEND` for now.

*meshvars.sh*

```sh
# User
export AWS_PROFILE="your-aws-profile"
export AWS_ACCOUNT_ID="your-aws-account-id"

# Lattice
export LATTICE_FRONTEND="https://frontend.us-west-2.beta.lattice.aws.a2z.com/"
export EMS_HOST="AWSLa-LoadB-IJ2ARZX9B4CO-ae2e9ff7acb5328c.elb.us-west-2.amazonaws.com"
export EMS_PORT=80

# App
export MESH_NAME="voting-app"
export MESH_ROLE="voting-app-role"
export CLIENT_TOKEN="voting-app-token"
```

    $ source meshvars.sh


**Note:**

* `meshvars.sh` is automatically sourced by the `deploy.sh` script in the current directory.
* `meshvars.sh` will not be included in your commits (it's excluded by `.gitignore` for the current directory).

## Apply the service mesh configuration

Run `deploy.sh` under the `servicemesh` directory.


## Current port assignments

| Service | Port |
| web | 8010 |
| votes | 8020 |
| reports | 8030 |
| worker | 8040 |
| queue | 6379 |
| database | 27017|

