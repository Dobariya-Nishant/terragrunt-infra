# DocumentDB cluster endpoint (used to connect)
output "endpoint" {
  description = "DocumentDB cluster endpoint (for MongoDB connections)"
  value       = aws_docdb_cluster.this.endpoint
}

# Port (usually 27017)
output "port" {
  description = "DocumentDB port"
  value       = aws_docdb_cluster.this.port
}

# Full connection string for convenience
output "connection_string" {
  description = "MongoDB connection string to connect from apps"
  value       = "mongodb://nishant:SuperSecret123!@${aws_docdb_cluster.this.endpoint}:${aws_docdb_cluster.this.port}/?ssl=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
  sensitive   = true
}
