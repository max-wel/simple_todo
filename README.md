# Simple Todo: AWS-hosted Jenkins CI/CD

This project demonstrates a small Spring Boot Todo API alongside the infrastructure that runs its CI/CD system. Terraform provisions an AWS Jenkins host and its persistent storage, Ansible configures the host and runs Jenkins in Docker, and Jenkins executes the application's Maven test pipeline.

## Architecture

```text
Terraform (persistent)              Terraform (disposable)
VPC, public subnet, routing     ──► EC2 Jenkins server + IAM + security group
S3 bucket + S3 File Storage          │
        │                             │ Ansible
        └─────────────────────────────┤
                                      ▼
                       Docker: Jenkins controller
                       /var/jenkins_home ↔ mounted S3 filesystem
                                      │
                                      ▼
                         Jenkinsfile → Maven test container
                                      │
                                      ▼
                         Spring Boot Todo application
```

## What the infrastructure does

- `iac/terraform/persistent` creates the VPC, public subnet, internet routing, versioned S3 bucket, S3 File Storage filesystem, access point, mount target, security groups, and IAM permissions.
- `iac/terraform/disposable` launches an Amazon Linux `t3.micro` EC2 instance for Jenkins. It attaches an instance profile for filesystem access and limits HTTP, HTTPS, and SSH ingress to `my_ip`.
- `iac/ansible/configure_jenkins.yml` discovers the EC2 server, mounts the S3 filesystem at `/home/ec2-user/workspace`, installs Docker, and starts `jenkins/jenkins:latest-jdk21`. The mounted directory is mapped to Jenkins' `/var/jenkins_home`, preserving Jenkins state independently of the EC2 instance.

The persistent and disposable Terraform directories are deliberately separate: the Jenkins server can be replaced without removing the network and persistent Jenkins data.

## CI/CD pipeline

The `Jenkinsfile` runs the Spring Boot test suite in `maven:3.9.16-eclipse-temurin-25`. It also contains `test` and `deploy` stages as extension points for the rest of the delivery workflow.

## Application

The application is a Spring Boot 4 Todo API using MySQL, Spring Data JPA, and Flyway. The initial migration creates the `todo` table.

| Endpoint | Description |
| --- | --- |
| `GET /todos` | Lists todos. |
| `POST /todos` | Creates a todo, e.g. `{"task":"Buy milk"}`. |

## Local development

Requirements: Java 25 and a local MySQL instance using the configured `root` / `admin` credentials. The application connects to `jdbc:mysql://localhost:3306/simple_todo` and creates the database when needed.

```bash
./mvnw spring-boot:run
./mvnw test
```

## Provisioning flow

Prerequisites: configured AWS credentials, Terraform, Ansible with the AWS EC2 inventory and Docker collections, and an SSH public key at `~/.ssh/id_rsa.pub`.

1. Apply the durable infrastructure in `iac/terraform/persistent`.
2. Note the filesystem ID and access-point ID, and make them available to Ansible in the ignored `iac/ansible/vars_file`.
3. Apply `iac/terraform/disposable`, supplying `my_ip` and `filesys_bucket_name` through an ignored `.tfvars` file or Terraform variables.
4. From `iac/ansible`, run `ansible-playbook configure_jenkins.yml` to mount storage and start Jenkins.
5. Open the EC2 host on port 80, complete Jenkins setup, and create a pipeline from this repository's `Jenkinsfile`.

> The persistent S3 bucket is configured with `force_destroy = true`; review this setting carefully before destroying that Terraform stack.
