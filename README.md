# Voting App

Example containerized microservices Voting App based on the original Docker version.

For an orientation to this version of the Voting App, see [this presentation](https://docs.google.com/presentation/d/1FLDaRlQOy2cXcudR8322pUjW5s-eJkHkX6w12mDWiiY/edit?usp=sharing).

## Quick Start

Get Docker for free from the [Docker Store](https://www.docker.com/community-edition#/download).
This app will work with versions from either the Stable or the Edge channels.

> If you're using [Docker for Windows](https://docs.docker.com/docker-for-windows/) on Windows 10 pro or later, you must also switch to [Linux containers](https://docs.docker.com/docker-for-windows/#switch-between-windows-and-linux-containers).

Run in this directory:

    $ docker-compose up

You can test it with the `voter` CLI
```
$ docker run -it --rm --network=host subfuzion/voter vote
? What do you like better? (Use arrow keys)
  (quit)
❯ cats
  dogs
```

You can print voting results:

```
$ docker run -it --rm --network=host subfuzion/voter results
Total votes -> cats: 4, dogs: 0 ... CATS WIN!
```

When you are finished:

Press `Ctrl-C` to stop the stack, then enter:

    $ docker-compose -f docker-compose.yml rm -f

### Kubernetes

Kubernetes and Helm chart support has been added to the repo (under `kubernetes` directory).

### Amazon ECS with Fargate

Deploy to [AWS ECS with Fargate](https://read.acloud.guru/deploy-the-voting-app-to-aws-ecs-with-fargate-cb75f226408f)

## About the Voting App

![Voting app architecture](https://raw.githubusercontent.com/aws-samples/voting-app/master/images/voting-app-arch-3.png?token=AAJv-qxh3tUiCw5UmU2TPxx5N7_qopy-ks5cCYsGwA%3D%3D)

This app is based on the original [Docker](https://docker.com) [Example Voting App](https://github.com/dockersamples/example-voting-app).

## License

This library is licensed under the Apache 2.0 License. 
