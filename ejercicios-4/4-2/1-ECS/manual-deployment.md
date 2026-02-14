

## 1. Build Docker Image

```bash
# Build the image
docker build -t fastapi-image .
```

## 2. Test Container Locally

```bash
# Run container locally
docker run -d -p 8000:8000  --name fastapi-container fastapi-image

# Check container is running
docker ps

# Check logs
docker logs fastapi-container

# Commands only used when you want to clean up your computer.

# Delete the container (if you want)
docker stop fastapi-container && docker rm fastapi-container

# Delete the image (if you want)
docker rmi fastapi-image:latest
```

## 3. Test API Endpoints
Test these endpoints using Postman (the container must be running)

http://localhost:8000/

http://localhost:8000/items

http://localhost:8000/items/2?count=1000

```
# Check logs after testing the api
docker logs fastapi-container
```

## 4. Push image to Amazon ECR (Elastic container repository)

### Create ECR Repository via Console

- Go to AWS ECR Console

- Click "Create repository"

- Namespace: dev

- Name: fastapi-repo

- Keep default settings

- Click "Create repository"

- Open the repository and click the "push commands" button


```bash
# Follow the push commands, at the end you should have the image in the repo
# Example of push commands:

    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 211125524079.dkr.ecr.us-west-2.amazonaws.com

    docker build -t dev/fastapi-repo .

    docker tag dev/fastapi-repo:latest 211125524079.dkr.ecr.us-west-2.amazonaws.com/dev/fastapi-repo:latest

    docker push 211125524079.dkr.ecr.us-west-2.amazonaws.com/dev/fastapi-repo:latest

```

Now is time to create the orquestation ...

## 5. Create an ECS Task Definition

Go to ECS Console

Create an ECS task definition that describes what is needed to run the API.

- Create a VPC with a public subnet
- Allow public ip
- Allow all traffic, https, tcp, and check the ports that are needed.

More information:

https://catalog.us-east-1.prod.workshops.aws/workshops/ed1a8610-c721-43be-b8e7-0f300f74684e/en-US/ecs/deploy-the-container-using-aws-fargate


## 6. Create ECS Service
Go to ECS Console

More information:

https://catalog.us-east-1.prod.workshops.aws/workshops/ed1a8610-c721-43be-b8e7-0f300f74684e/en-US/ecs/deploy-the-container-using-aws-fargate


## Example of task definition

```bash
{
    "taskDefinitionArn": "arn:aws:ecs:us-west-2:211125524079:task-definition/fastapi-task-definition-family-2:1",
    "containerDefinitions": [
        {
            "name": "fastapi-container-2",
            "image": "211125524079.dkr.ecr.us-west-2.amazonaws.com/dev/fastapi-repo:latest",
            "cpu": 0,
            "portMappings": [
                {
                    "name": "8000",
                    "containerPort": 8000,
                    "hostPort": 8000,
                    "protocol": "tcp",
                    "appProtocol": "http"
                }
            ],
            "essential": true,
            "environment": [],
            "environmentFiles": [],
            "mountPoints": [],
            "volumesFrom": [],
            "ulimits": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/fastapi-task-definition-family-2",
                    "mode": "non-blocking",
                    "awslogs-create-group": "true",
                    "max-buffer-size": "25m",
                    "awslogs-region": "us-west-2",
                    "awslogs-stream-prefix": "ecs"
                },
                "secretOptions": []
            },
            "systemControls": []
        }
    ],
    "family": "fastapi-task-definition-family-2",
    "taskRoleArn": "arn:aws:iam::211125524079:role/ecsTaskExecutionRole",
    "executionRoleArn": "arn:aws:iam::211125524079:role/ecsTaskExecutionRole",
    "networkMode": "awsvpc",
    "revision": 1,
    "volumes": [],
    "status": "ACTIVE",
    "requiresAttributes": [
        {
            "name": "com.amazonaws.ecs.capability.logging-driver.awslogs"
        },
        {
            "name": "ecs.capability.execution-role-awslogs"
        },
        {
            "name": "com.amazonaws.ecs.capability.ecr-auth"
        },
        {
            "name": "com.amazonaws.ecs.capability.docker-remote-api.1.19"
        },
        {
            "name": "com.amazonaws.ecs.capability.docker-remote-api.1.28"
        },
        {
            "name": "com.amazonaws.ecs.capability.task-iam-role"
        },
        {
            "name": "ecs.capability.execution-role-ecr-pull"
        },
        {
            "name": "com.amazonaws.ecs.capability.docker-remote-api.1.18"
        },
        {
            "name": "ecs.capability.task-eni"
        },
        {
            "name": "com.amazonaws.ecs.capability.docker-remote-api.1.29"
        }
    ],
    "placementConstraints": [],
    "compatibilities": [
        "EC2",
        "FARGATE"
    ],
    "requiresCompatibilities": [
        "FARGATE"
    ],
    "cpu": "1024",
    "memory": "3072",
    "runtimePlatform": {
        "cpuArchitecture": "X86_64",
        "operatingSystemFamily": "LINUX"
    },
    "registeredAt": "2024-12-13T08:55:45.574Z",
    "registeredBy": "arn:aws:iam::211125524079:root",
    "enableFaultInjection": false,
    "tags": []
}
```

## Open the public ip

```
# CLUSTER_TASK_PUBLIC_IP:PORT
# Example:

http://18.236.100.90:8000/
```
