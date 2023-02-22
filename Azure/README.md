# Azure TAP

## Pre-reqs

1. Azure CLI (`az login` needed before running `terraform apply`)

## terraform verbose output

`$Env:TF_LOG = "TRACE"`

```bash
Terraform has detailed logs that you can enable by setting the TF_LOG environment variable to any value. Enabling this setting causes detailed logs to appear on stderr.

You can set TF_LOG to one of the log levels (in order of decreasing verbosity) TRACE, DEBUG, INFO, WARN or ERROR to change the verbosity of the logs.

Setting TF_LOG to JSON outputs logs at the TRACE level or higher, and uses a parseable JSON encoding as the formatting.

```

## Required specs

[https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/prerequisites.html]