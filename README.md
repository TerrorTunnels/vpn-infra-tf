# VPN Infrastructure Terraform

This repository contains the Terraform configuration for deploying a personal OpenVPN server on AWS. It's part of a larger project created during a sabbatical in Taipei to build a complete VPN solution with iOS app control. The infrastructure code was generated with assistance from AI tools (ChatGPT and Claude).

## Overview

This Terraform configuration creates a complete VPN infrastructure in AWS, including:
- VPC with public subnet
- EC2 instance running OpenVPN
- Security groups
- Elastic IP for stable connectivity

The infrastructure is designed to work with:
- [VPNControl iOS App](https://github.com/rjamestaylor/VPNControl-ios) for remote management
- [VPN Control API](https://github.com/rjamestaylor/vpn-control-api) AWS Lambda function for instance control
- API Gateway for secure access

## Architecture

The infrastructure creates:
- VPC (10.0.0.0/16)
- Public Subnet (10.0.1.0/24)
- Internet Gateway
- Security Group allowing:
  - UDP 1194 (OpenVPN)
  - TCP 22 (SSH)
- t4g.micro EC2 instance with Amazon Linux 2
- Elastic IP for persistent addressing

## Prerequisites

- AWS Account
- Terraform installed (v1.0.0+)
- AWS CLI configured
- SSH key pair in your target AWS region

## Quick Start

1. Clone the repository:
```bash
git clone git@github.com:rjamestaylor/vpn-infra-tf.git
cd vpn-infra-tf
```

2. Update variables:
```hcl
# Create a terraform.tfvars file
aws_region    = "us-west-2"  # or your preferred region
ssh_key_name  = "your-key-name"
```

3. Initialize and apply:
```bash
terraform init
terraform plan
terraform apply
```

## Configuration Details

### Variables

```hcl
variable "aws_region" {
  description = "AWS region to deploy the VPN"
  default     = "us-west-2"
}

variable "ssh_key_name" {
  description = "SSH key name for EC2 instance admin"
  default     = "your-ssh-key-name"
}
```

### Important Notes

1. AMI Selection:
```hcl
ami = "ami-0b16505c55f9802f9"  # Amazon Linux 2 arm64 - us-west-2
```
- This AMI ID is for us-west-2 (Oregon)
- Check for the latest Amazon Linux 2 arm64 AMI in your region
- The instance type (t4g.micro) is ARM-based for cost efficiency

2. Security Groups:
```hcl
ingress {
  from_port   = 1194
  to_port     = 1194
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]
}
```
- UDP 1194 is the default OpenVPN port
- SSH access (port 22) is enabled for administration
- Consider restricting SSH access to your IP range

3. User Data Script:
- Installs OpenVPN and dependencies
- Uses Angristan's OpenVPN installer
- Runs in automated mode

## Post-Deployment Steps

1. Access the EC2 instance:
```bash
ssh -i your-key.pem ec2-user@<output_ip_address>
```

2. Get the OpenVPN client configuration:
- Client config is in `/root/client.ovpn`
- Copy this file for use with OpenVPN clients

3. Set up the control interface:
- Deploy the associated Lambda function
- Configure API Gateway
- Set up the iOS app

## Cost Considerations

This infrastructure uses:
- t4g.micro instance (~$3.50/month)
- Elastic IP (free when attached to running instance)
- VPC components (minimal cost)
- Data transfer fees apply for VPN usage

## Security Considerations

1. Network Security:
- VPC isolates the VPN server
- Security groups limit access to necessary ports
- All traffic is encrypted via OpenVPN

2. Access Control:
- SSH key required for server access
- OpenVPN certificates for client authentication
- API key required for control interface

## Related Projects

This infrastructure works with:
- [VPNControl iOS App](https://github.com/rjamestaylor/VPNControl-ios)
- [VPN Control Lambda](https://github.com/rjamestaylor/vpn-control-api)

## Maintenance

### Updating OpenVPN

SSH into the instance and run:
```bash
sudo ./openvpn-install.sh
```

### Infrastructure Updates

1. Update Terraform code:
```bash
terraform plan
terraform apply
```

2. Instance replacement:
- New instances will run the initialization script
- Transfer necessary certificates/keys
- Update DNS/IP references

## Troubleshooting

1. OpenVPN Installation:
- Check `/var/log/cloud-init-output.log` for initialization errors
- Verify security group allows UDP 1194

2. Connectivity:
- Ensure elastic IP is attached
- Verify route tables and internet gateway
- Check VPN client configuration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- OpenVPN for the VPN software
- Angristan for the OpenVPN installer script
- AWS for the infrastructure platform
- ChatGPT and Claude for infrastructure code generation

## Contact

For questions or suggestions, please open an issue in the repository.