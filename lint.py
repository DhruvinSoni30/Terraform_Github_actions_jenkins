import glob
import re
import os
import hcl

file = glob.glob('terraform.tfvars')
region_validator = re.compile('(us(-gov)?|ap|ca|cn|eu|sa)-(central|(north|south)?(east|west)?)-?(1|2)')
cidr_validator = re.compile('^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$')


for f in file:
    with open(f, 'r') as fp:
        obj = hcl.load(fp)
        errors = []

        if 'region' not in obj:
            errors.append("The variable 'region' not defined")

        region = obj['region']
        if region_validator.search(region) is None:
            errors.append("Invalid Region")

        if 'name' not in obj:
            errors.append("Tag is not defined")

        if 'cidr_block' and 'cidr_block_subnet' not in obj:
            errors.append("CIDR blocks are not defined")
        
        cidr =  obj['cidr_block']
        if cidr_validator.search(cidr) is None:
            errors.append("Invalid CIDR block for VPC")

        cidr_subnet = obj['cidr_block_subnet']
        if cidr_validator.search(cidr_subnet) is None:
            errors.append("Invalid CIDR block for Subnet")

        if 'instance_type' not in obj:
            errors.append("Instance type is not defned")
        
        if 'tenancy' not in obj:
            errors.append("Tenancy is not defined")
fp.close()

if len(errors) > 0:
    for error in errors:
        print(error)
    exit(1)
else:
    print("All the check passed!")
