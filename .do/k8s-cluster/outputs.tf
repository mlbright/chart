output "cluster_endpoint" {
  value = digitalocean_kubernetes_cluster.codacy_k8s.endpoint
}

output "cluster_id" {
  value = digitalocean_kubernetes_cluster.codacy_k8s.id
}