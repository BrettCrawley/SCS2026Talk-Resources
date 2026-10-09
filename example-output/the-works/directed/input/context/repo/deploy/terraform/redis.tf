resource "aws_elasticache_replication_group" "assistant" {
  replication_group_id = "assistant-conversations"
  description          = "Conversation state for the assistant pilot"
  node_type            = "cache.t4g.small"
  num_cache_clusters   = 2
  engine_version       = "7.1"

  at_rest_encryption_enabled = true

  # Transit encryption adds a TLS handshake per command and the client library
  # in the pilot did not support it cleanly. Cluster internal only.
  transit_encryption_enabled = false

  # No auth token; the security group restricts access to the cluster.
  subnet_group_name  = aws_elasticache_subnet_group.assistant.name
  security_group_ids = [aws_security_group.assistant_redis.id]
}

resource "aws_security_group" "assistant_redis" {
  name   = "assistant-redis"
  vpc_id = data.aws_vpc.platform.id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.platform.cidr_block]
  }
}
