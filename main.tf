provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region = var.aws_region  
}

#Data Source

data "aws_availability_zones" "all" {
  state = "available"
}


######
resource "aws_vpc" "aws-3-Tier-VPC" {
    cidr_block = var.vpc_cidr_block
  
}

resource "aws_subnet" "aws-3-tier-web-subnet-1" {
    vpc_id = aws_vpc.aws-3-Tier-VPC.id
    cidr_block = var.vpc_subnets_cide_blocks[0]
    availability_zone = data.aws_availability_zones.all.names[0]
  
}
resource "aws_subnet" "aws-3-tier-web-subnet-2" {
    vpc_id = aws_vpc.aws-3-Tier-VPC.id
    cidr_block = var.vpc_subnets_cide_blocks[1]
    availability_zone = data.aws_availability_zones.all.names[1]
  
}
resource "aws_subnet" "aws-3-tier-app-subnet-1" {
    vpc_id = aws_vpc.aws-3-Tier-VPC.id
    cidr_block = var.vpc_subnets_cide_blocks[2]
    availability_zone = data.aws_availability_zones.all.names[0]
  
}
resource "aws_subnet" "aws-3-tier-app-subnet-2" {
    vpc_id = aws_vpc.aws-3-Tier-VPC.id
    cidr_block = var.vpc_subnets_cide_blocks[3]
    availability_zone = data.aws_availability_zones.all.names[1]
  
}
resource "aws_subnet" "aws-3-tier-db-subnet-1" {
    vpc_id = aws_vpc.aws-3-Tier-VPC.id
    cidr_block = var.vpc_subnets_cide_blocks[4]
    availability_zone = data.aws_availability_zones.all.names[0]
  
}
resource "aws_subnet" "aws-3-tier-db-subnet-2" {
    vpc_id = aws_vpc.aws-3-Tier-VPC.id
    cidr_block = var.vpc_subnets_cide_blocks[5]
    availability_zone = data.aws_availability_zones.all.names[1]
  
}

resource "aws_route_table" "aws-3-tier-web-route-table-rt-1" {
    vpc_id = aws_vpc.aws-3-Tier-VPC.id
  
}
resource "aws_route_table" "aws-3-tier-app-route-table-rt-1" {
    vpc_id = aws_vpc.aws-3-Tier-VPC.id
  
}

resource "aws_route_table_association" "web-association-1" {
  subnet_id = aws_subnet.aws-3-tier-web-subnet-1.id
  route_table_id = aws_route_table.aws-3-tier-web-route-table-rt-1.id

}
resource "aws_route_table_association" "web-association-2" {
  subnet_id = aws_subnet.aws-3-tier-web-subnet-2.id
  route_table_id = aws_route_table.aws-3-tier-web-route-table-rt-1.id

}
resource "aws_route_table_association" "app-association-1" {
  subnet_id = aws_subnet.aws-3-tier-app-subnet-1.id
  route_table_id = aws_route_table.aws-3-tier-app-route-table-rt-1.id
}
resource "aws_route_table_association" "app-association-2" {
  subnet_id = aws_subnet.aws-3-tier-app-subnet-2.id
  route_table_id = aws_route_table.aws-3-tier-app-route-table-rt-1.id
}

resource "aws_internet_gateway" "aws-3-tier-ig" {
    vpc_id = aws_vpc.aws-3-Tier-VPC.id
  
}

resource "aws_route" "web-route" {
  route_table_id = aws_route_table.aws-3-tier-web-route-table-rt-1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.aws-3-tier-ig.id
}
resource "aws_eip" "aws-3-tier-eip" {
    vpc = true
  
}
resource "aws_nat_gateway" "aws-3-tier-NAT-gateway-1" {
    subnet_id = aws_subnet.aws-3-tier-web-subnet-1.id
    connectivity_type = "public"
    allocation_id = aws_eip.aws-3-tier-eip.id
    tags = {
        Name = "NAT GW 1"
    }
  
}

resource "aws_route" "app-route" {
    route_table_id = aws_route_table.aws-3-tier-app-route-table-rt-1.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.aws-3-tier-NAT-gateway-1.id
  
}

resource "aws_security_group" "external-lb-sg" {
  name = "external-lb-sg"
  description = "allow traffic to external LB"
  vpc_id = aws_vpc.aws-3-Tier-VPC.id

  ingress {
    from_port = 80
    to_port =   80
    protocol = "tcp"
    cidr_blocks = [aws_vpc.aws-3-Tier-VPC.cidr_block]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "aws-3-tier-web-sg" {
    name = "aws-3-tier-web-sg"
    vpc_id = aws_vpc.aws-3-Tier-VPC.id
    description = "Allow access for web security group"
    ingress {
        to_port = 80
        from_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.external-lb-sg.id]
    }
    egress {
        to_port = 0
        from_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

}


resource "aws_security_group" "aws-internal-load-balancer-sg" {
    name = "aws-internal-load-balancer-sg"
    description = "aws-internal-load-balancer-sg"
    vpc_id = aws_vpc.aws-3-Tier-VPC.id
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.aws-3-tier-web-sg.id]
    }
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "aws-app-security-group" {
    name = "aws-app-security-group"
    description = "aws-app-security-group"
    vpc_id = aws_vpc.aws-3-Tier-VPC.id
    ingress {
        from_port = 4000
        to_port = 4000
        protocol = "tcp"
        security_groups = [ aws_security_group.aws-internal-load-balancer-sg.id ]
    }
    ingress {
        from_port = 4000
        to_port = 4000
        protocol = "tcp"
        cidr_blocks = [aws_vpc.aws-3-Tier-VPC.cidr_block]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    } 
}

resource "aws_security_group" "db_security_group" {
    name = "db_security_group"
    description = "security group for database server"
    vpc_id = aws_vpc.aws-3-Tier-VPC.id
    ingress {
        to_port = 3306
        from_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.aws-app-security-group.id]
    }
    egress {
        to_port = 0
        from_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
 
}
