# Infrastructure for SMCTF v2

See [SMCTF Docs](https://github.com/nullforu/smctf-docs) for more information about SMCTF and how to use this repository.

## AWS Architecture Diagram

![AWS Architecture Diagram](./assets/architecture.png)

## Sandboxd-O Cluster

```
sbxadm create cluster smctf-cluster \
  --version 0.4.0 \
  --vpc-id vpc-0afa3d83ef5c9bc61 \
  --public-subnet subnet-0a9a3ee47cc8eb252,subnet-07863bc7edfb79e2c \
  --private-subnet subnet-040c0b74983e5813b,subnet-026d8e565beedff70 \
  --region ap-northeast-2 \
  --orch-instance t3.xlarge \
  --orch-public-endpoint \
  --orch-root-volume-size 16Gi

sbxadm create worker smctf-worker-1 \
  --cluster smctf-cluster \
  --version 0.4.0 \
  --instance t3.xlarge \
  --root-volume-size 64Gi \
  --ecr-repos "*"

sbxadm update-sbxctl-config smctf-cluster
```
