+++
date = '2025-02-28T09:29:34Z'
draft = false
title = "EC2 NTP"
+++

Recently I needed to block all public egress from our VPC. I could see we still have some NTP traffic going out to
`time.aws.com`. Initially I started following AWS documentation
[Set the time reference ...](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configure-ec2-ntp.html), but quickly
realized it is outdated for amazon linux instances.

This article describe how to set NTP on EC2 (Amazon Linux 2023) to only link local NPT server. By default, EC2 instances
is set with both, public and link local NPT servers.

For impatient, this is the configuration in terraform:

```terraform
resource "aws_vpc_dhcp_options_association" "this" {
  vpc_id          = var.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.this.id
}

# only difference from default is ntp_servers, we want to make sure all traffic stays within VPC
resource "aws_vpc_dhcp_options" "this" {
  domain_name         = format("%s.compute.internal", var.region)
  domain_name_servers = ["AmazonProvidedDNS"]
  ntp_servers         = ["169.254.169.123"]

  tags = {
    Name = var.vpc_name
  }
}
```

Options to change NPT are listed in `/etc/chrony.d/README` on EC2 instance itself. I went with option 2. Domain name and
domain name servers (in the above terraform code snippet) are exactly the same as default dhcp option associated with
the VPC. The only change is ntp servers section, where we restrict (remove default public `time.aws.com` server) ntp
server to link local `169.254.169.123`.

After this change is applied, you can restart EC2 instance and verify only this ntp server is in configuration on EC2
`ls -l /run/chrony.d/` (view content of the listed files to verify). These configurations are loaded in `/etc/chrony.conf`.
