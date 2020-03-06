#-------------------------------------------------------------------------------
# Set up routing in the VPC for the operations subnet, which uses the
# VPC's default routing table.
#
# The routing for the private subnets is configured in
# private_routing.tf.
# -------------------------------------------------------------------------------

# Default route table (used by operations subnets)
resource "aws_default_route_table" "operations" {
  provider = aws.provisionassessment

  default_route_table_id = aws_vpc.assessment.default_route_table_id
  tags                   = var.tags
}

# Route all COOL Shared Services traffic through the transit gateway
resource "aws_route" "cool_route" {
  provider = aws.provisionassessment

  route_table_id         = aws_default_route_table.operations.id
  destination_cidr_block = local.cool_shared_services_cidr_block
  transit_gateway_id     = local.transit_gateway_id
}

# Route all external (outside this VPC and outside the COOL) traffic
# through the internet gateway
resource "aws_route" "external_route" {
  provider = aws.provisionassessment

  route_table_id         = aws_default_route_table.operations.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.assessment.id
}
