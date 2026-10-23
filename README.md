# Drify production on EC2

Account `068657603153`, region `us-west-1`. The AWS provider refuses any other
account (`allowed_account_ids`).

## Layout

- VPC `172.30.0.0/16`: three public subnets, two private subnets, no NAT gateway.
- App EC2 (`t3.xlarge`, Elastic IP): Nginx, Node 22 with PM2, plus RabbitMQ and
  Redis 7.2 in Docker, both bound to `127.0.0.1`. Docker Hub has no 7.1 image. Runs the 15 customer processes
  (`ecosystem.config.cjs`), rider on `5001`, admin on `5002`. Only ports 80 and
  443 are open.
- Runner EC2 (`t3.medium`): self-hosted GitHub Actions runner for
  `sagar-drify/drify-v2`, labels `drify` and `prod`. No inbound ports.
- Both servers use the existing `ssm-iam-role`; Terraform adds one inline
  policy, `drify-prod-deploy`. Access is through SSM Session Manager, not SSH.
- Private RDS PostgreSQL `db.t3.small` (database `drifyv2`), reachable only
  from the app server. Redis runs on that same server, not ElastiCache.

## Secrets Manager

| Secret | Contents |
|---|---|
| `drify-prod/postgres` | Master credentials |
| `drify-prod/redis` | Password for the local Redis container |
| `drify-prod/rabbitmq` | Broker credentials |

The three `.env` files are private objects in the artifact bucket:

- `s3://drify-prod-deploy-artifacts-068657603153/env/customer.env`
- `s3://drify-prod-deploy-artifacts-068657603153/env/rider.env`
- `s3://drify-prod-deploy-artifacts-068657603153/env/admin.env`

Terraform uploads each file once and does not overwrite later edits. Add
third-party keys there; build artifacts expire after 30 days, these files do not.

## Deploy flow

1. Push to `master_customer`, `master_rider`, or `master_admin`.
2. The runner installs and builds, then uploads a tarball to
   `drify-prod-deploy-artifacts-068657603153`.
3. The runner calls the `drify-prod-deploy` SSM document on the app server,
   which copies `.env` from S3, syncs the code into
   `/opt/drify/<app>/app`, reloads PM2, and fails if a process is not online.

Prisma migrations run only from a manual `workflow_dispatch` of the customer
workflow with `run_migrations` checked.

## Operate

```sh
aws ssm start-session --profile sagar --region us-west-1 --target <app_instance_id>
sudo -u drify -i pm2 ls
sudo -u drify -i pm2 logs <name> --lines 100
```

Public domains are `prod-api.drify.com`, `prod-rider.drify.com`, and
`prod-admin.drify.com`. Point each one at the load balancer DNS name. ACM
validates the certificate through the CNAME records in
`terraform output acm_validation_records`. `drify.com` is not hosted in this
account, so those DNS records are added at the existing DNS provider. The old
names `api.drify.com`, `rider.drify.com`, and `admin-api.drify.com` are not
used.
