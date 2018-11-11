The following steps assume you have this repo cloned or at least have the CloudFormation files in this directory.

### Step 1: Setup
Create resources such as the VPC, subnets and security groups. Wait for it to finish before the next step.
```
aws cloudformation deploy --stack-name=voteapp --template-file=setup.yml --capabilities=CAPABILITY_IAM
aws cloudformation wait stack-create-complete --stack-name=voteapp
```

### Step 2: Database and Queue
Run database and queue:
```
aws cloudformation deploy --stack-name=voteapp-database --template-file=database.yml --capabilities=CAPABILITY_IAM
aws cloudformation deploy --stack-name=voteapp-queue --template-file=queue.yml --capabilities=CAPABILITY_IAM
```
In two windows, run watch to wait for them to finish:
```
aws cloudformation wait stack-create-complete --stack-name=voteapp-database
```
```
aws cloudformation wait stack-create-complete --stack-name=voteapp-queue
```

### Step 3: Votes and Reports
Run votes and reports:
```
aws cloudformation deploy --stack-name=voteapp-votes --template-file=votes.yml --capabilities=CAPABILITY_IAM
aws cloudformation deploy --stack-name=voteapp-reports --template-file=reports.yml --capabilities=CAPABILITY_IAM
```
In two windows, run watch to wait for them to finish:
```
aws cloudformation wait stack-create-complete --stack-name=voteapp-votes
```
```
aws cloudformation wait stack-create-complete --stack-name=voteapp-reports
```

### Step 4: API
Run API:
```
aws cloudformation deploy --stack-name=voteapp-api --template-file=api.yml --capabilities=CAPABILITY_IAM
aws cloudformation wait stack-create-complete --stack-name=voteapp-api
```

### Step 5: Vote!
VOTE_API_URI=$(aws cloudformation describe-stacks --stack-name voteapp \
--query 'Stacks[0].Outputs[?OutputKey==`ExternalUrl`].OutputValue' --output text)

Vote
```
docker run -it --rm -e VOTE_API_URI=${VOTE_API_URI} subfuzion/voter vote
```
See results
```
docker run -it --rm -e VOTE_API_URI=${VOTE_API_URI} subfuzion/voter results
```
