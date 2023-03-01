# Azure TAP

## Pre-reqs

1. Azure CLI (`az login` needed before running `terraform apply`)

## terraform verbose output

### Windows

`$Env:TF_LOG = "TRACE"`

or (in decreasing order of verbosity): DEBUG, INFO, WARN, ERROR

### Azure quotas

The default for the cluster nodes is "standard_f4s_v2". Since this has 4 vCPUs, we need to make sure our quota allows for the maximum. 3 nodes / cluster + Control pane = 16 vCPUs a cluster x 3 is a max of 48 vCPus - so make your quota 50. But this will incur costs - so shut it down when finished.

### Service account

AKS works better with service accounts. To make one with all permissions - make one that manages your subscription. NOTE: This wouldn't be done outside of testing/dev environments.