## Deploy the Voting App

Run `deploy.sh` from this directory. It uses the CloudFormation stack templates
in this directory to create the top level global stack and all the service stacks.

When the script is finished, it will display the Voting App public URL.

### Manual deployment

If you want to deploy the stacks manually, here is the order:

```
aws cloudformation deploy --stack-name=voteapp --template-file=voteapp.yml --capabilities=CAPABILITY_IAM
aws cloudformation deploy --stack-name=voteapp-database --template-file=database.yml
aws cloudformation deploy --stack-name=voteapp-queue --template-file=queue.ymlM
aws cloudformation deploy --stack-name=voteapp-votes --template-file=votes.yml
aws cloudformation deploy --stack-name=voteapp-reports --template-file=reports.yml
aws cloudformation deploy --stack-name=voteapp-api --template-file=web.yml
```

## Vote and view results

```sh
WEB_URI=$(aws cloudformation describe-stacks --stack-name voteapp \
    --query 'Stacks[0].Outputs[?OutputKey==`ExternalUrl`].OutputValue' --output text)
docker run -it --rm -e WEB_URI=$WEB_URI subfuzion/voter CMD
```

where CMD is either `vote` or `results`.

Vote

```sh
docker run -it --rm -e WEB_URI=$WEB_URI subfuzion/voter vote
```

See results

```sh
docker run -it --rm -e WEB_URI=$WEB_URI subfuzion/voter results
```

