# microkonf

This tool takes in the kubeconfig YAML output by `microk8s config` of your
current cndi cluster, transforms it so to be used by `kubectl` and writes it to
`~/.kube/config`.

## usage

After adding the `microkonf.sh` file to your path and making it executable (eg.
`chmod +x microkonf.sh`), you can run the following command to update your
`~/.kube/config` file:

```bash
export MICROK8S_HOST='ec2-44-199-250-39.compute-1.amazonaws.com'; 
k=$(ssh -i 'cndi_rsa' "ubuntu@$MICROK8S_HOST" -t 'sudo microk8s config') && echo "$k" | microkonf
```

## dependencies

- `kubectl` used to query, update, and delete `~/.kube/config` data

## transformations

- updates the `server` field to the public address passed in the `MICROK8S_HOST`
  environment variable
- removes the `certificate-authority-data` field
- adds the `insecure-skip-tls-verify: true` field
- adds an `'admin'` `user` with corresponding `client-certificate-data` and
  `client-key-data`

## notes

All microk8s `clusters` are simply named `microk8s-cluster` in the
`~/.kube/config` file, so if you have an existing microk8s cluster present, you
will be asked if it should be overwritten. The same applied to `users`, where
they are also exported from `micork8s config`.

### why the weird $k variable?

We only want to pass the result of the `ssh` execution if it is successful.

See [https://stackoverflow.com/a/31424574](https://stackoverflow.com/a/31424574)
