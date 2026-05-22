resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "sample-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"  
  tags = {
    Name = "Public-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "sample-route-table"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "web-sg" {
  vpc_id = aws_vpc.main.id
  ingress {
    description      = "Allow HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "web-sg"
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-0236922087fa98b6e"  # Amazon Linux 2 AMI (for us-east-1, adjust as needed)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.web-sg.id]  # Use security group ID instead of name
  key_name               = "db"
  associate_public_ip_address = true  # Ensure correct spelling
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<html><h1>Hello, Terraform HTTP Server V2</h1></html>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "sample-web-server"
  }
}

output "ec2_public_ip" {
  value = aws_instance.web.public_ip
  description = "Public IP of the EC2 instance"
}
