#!/usr/bin/env bash
# vim:syn=sh:ts=4:sw=4:et:ai

# Only us-west-2 is supported right now.
: ${AWS_DEFAULT_REGION:=us-west-2}

stacks=(
    "voteapp"
    "database"
    "queue"
    "worker"
    "reports"
    "votes"
    "web"
)

sanity_check() {
    if [ "$AWS_DEFAULT_REGION" != "us-west-2" ]; then
        err "Only us-west-2 is supported at this time.  (Current default region: $AWS_DEFAULT_REGION)"
    fi
}

setup() {
    errors=0
    i=0
    total=${#stacks[@]}
    for s in ${stacks[@]}; do
        ((i++))
        printf "\nDeploying $i of $total: $s.yml"
        if [ "$s" == "voteapp" ]; then
            aws cloudformation deploy --stack-name=voteapp --template-file=$s.yml --capabilities=CAPABILITY_IAM
        else
            aws cloudformation deploy --stack-name=voteapp-$s --template-file=$s.yml
        fi

        if [ $? -gt 0 ]; then ((errors++)); fi
    done
    return $errors
}

printinfo() {
    errors=$1
    if [ $errors -gt 0 ]; then
        echo "FAIL: $errors error(s)"
        exit $errors
    fi

    ep=$(aws cloudformation describe-stacks --stack-name voteapp \
        --query 'Stacks[0].Outputs[?OutputKey==ExternalUrl].OutputValue' --output text)
    printf "\nSuccess: voteapp deployed, public endpoint:\n%s\n" "$ep"

    printf "\nTo vote, run:\n%s\n" "docker run -it --rm -e VOTE_API_URI=\"${ep}\" subfuzion/voter vote"
    printf "\nTo get vote results, run:\n%s\n" "docker run -it --rm -e VOTE_API_URI=\"${ep}\" subfuzion/voter results"
}

# deploy stacks and print results
sanity_check
setup
errors=$?
printinfo $errors
