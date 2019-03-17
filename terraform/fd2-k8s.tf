resource "google_compute_network" "fd-2" {
  name                    = "fd2-network"
  auto_create_subnetworks = false
}

variable "fd2-ip-range" {
  description = "The CIDR from which to allocate cluster node IPs"
  type        = "string"
  default     = "10.0.96.0/22"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "external" "shell" {
  program = ["./ip.sh"]
}

variable "fd2-secondary-ip-range" {
  // See https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips
  description = "The CIDR from which to allocate pod IPs for IP Aliasing."
  type        = "string"
  default     = "10.0.92.0/22"
}

resource "google_compute_subnetwork" "fd-2-subnet" {
  name          = "${google_compute_network.fd-2.name}"
  ip_cidr_range = "${var.fd2-ip-range}"
  region        = "us-central1"
  network       = "${google_compute_network.fd-2.self_link}"
  private_ip_google_access = true
  project = "${var.project}"

  // A named secondary range is mandatory for a private cluster, this creates it.
  secondary_ip_range {
    range_name    = "secondary-range"
    ip_cidr_range = "${var.fd2-secondary-ip-range}"
  }
}

data "google_container_engine_versions" "default" {
  zone = "${var.zone}"
}

resource "google_service_account" "kube-cluster" {
  account_id   = "kube-cluster"
  display_name = "kube-cluster service account"
}


resource "google_container_cluster" "fd2-k8s-cluster" {
  provider = "google-beta"

  name               = "fd2-k8s-cluster"
  region               = "${var.region}"  // creates a regional cluster of 3
  initial_node_count = 1
  min_master_version = "${data.google_container_engine_versions.default.latest_master_version}"
  network            = "${google_compute_network.fd-2.self_link}"
  subnetwork         = "${google_compute_subnetwork.fd-2-subnet.self_link}"

  // Wait for the GCE LB controller to cleanup the resources.
  provisioner "local-exec" {
    when    = "destroy"
    command = "sleep 90"
  }

  addons_config {
    kubernetes_dashboard {
      disabled = true
    }

    horizontal_pod_autoscaling {
      disabled = true
    }
    istio_config {
      disabled = true
    }
  }

  // In a private cluster, the master has two IP addresses, one public and one
  // private. Nodes communicate to the master through this private IP address.
  private_cluster_config {
    enable_private_nodes   = true
    enable_private_endpoint = false           // allows the master node to be public so terraorm can configure it.
    master_ipv4_cidr_block = "10.0.40.0/28"
  }

  // (Required for private cluster, optional otherwise) Configuration for cluster IP allocation.
  // As of now, only pre-allocated subnetworks (custom type with
  // secondary ranges) are supported. This will activate IP aliases.
  ip_allocation_policy {
    cluster_secondary_range_name = "secondary-range"
  }

  // (Required for private cluster, optional otherwise) network (cidr) from which cluster is accessible
  master_authorized_networks_config {
    cidr_blocks = [
      {
        display_name = "direct"
        cidr_block = "${chomp(data.http.myip.body)}/32"
      },
      {
        display_name = "shell"
        cidr_block = "${lookup(data.external.shell.result, "shell-address")}/32"
      }
    ]
  }

  //  network_policy {
  //    enabled = true
  //    provider = "CALICO"
  //  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/userinfo.email"
    ]

    service_account = "${google_service_account.kube-cluster.email}"

    machine_type = "n1-highmem-4"

    image_type   = "COS"

    workload_metadata_config {
      node_metadata = "SECURE"
    }
  }

  lifecycle {
    ignore_changes = ["ip_allocation_policy", "network", "subnetwork", "node_config"]
  }
}

data "google_client_openid_userinfo" "provider_identity" {}

data "google_client_config" "provider" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.fd2-k8s-cluster.endpoint}"
  token                  = "${data.google_client_config.provider.access_token}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.fd2-k8s-cluster.master_auth.0.cluster_ca_certificate)}"
}

resource "kubernetes_cluster_role_binding" "user" {
  metadata {
    name = "provider-user-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind = "User"
    name = "${data.google_client_openid_userinfo.provider_identity.email}"
  }

  depends_on = ["google_container_cluster.fd2-k8s-cluster"]
}

resource "kubernetes_cluster_role_binding" "default" {
  metadata {
    name = "default"
  }

  subject {
    kind = "User"
    name = "system:serviceaccount:kube-system:default"
  }

  role_ref {
    kind  = "ClusterRole"
    name = "cluster-admin"
    api_group = ""
  }

  depends_on = ["google_container_cluster.fd2-k8s-cluster"]
}

resource "null_resource" "deploy-microservices-app" {
  triggers {
    cluster_ep = "${google_container_cluster.fd2-k8s-cluster.endpoint}"
  }

  provisioner "local-exec" {
    command = <<EOT
        echo "$${CA_CERTIFICATE}" > ${path.module}/k8s/ca.crt

        kubectl config --kubeconfig=${path.module}/k8s/ci set-cluster my-cluster --server=$${K8S_SERVER} --certificate-authority=${path.module}/k8s/ca.crt
        kubectl config --kubeconfig=${path.module}/k8s/ci set-credentials admin --token=$${K8S_TOKEN}
        kubectl config --kubeconfig=${path.module}/k8s/ci set-context gke --cluster=my-cluster --user=admin
        kubectl config --kubeconfig=${path.module}/k8s/ci use-context gke
        kubectl config current-context

        kubectl --kubeconfig=${path.module}/k8s/ci --context gke get cs

        gcloud auth configure-docker
        pushd ${path.module}/../microservices-demo
        skaffold run -p gcb --default-repo=gcr.io/${var.project}
        popd

      EOT

    environment {
      CA_CERTIFICATE = "${base64decode(google_container_cluster.fd2-k8s-cluster.master_auth.0.cluster_ca_certificate)}"
      K8S_SERVER = "https://${google_container_cluster.fd2-k8s-cluster.endpoint}"
      KUBERNETES_MASTER = "https://${google_container_cluster.fd2-k8s-cluster.endpoint}"
      K8S_TOKEN = "${data.google_client_config.provider.access_token}"
      GCP_PROJECT = "${var.project}"
      GCP_ZONE = "${google_container_cluster.fd2-k8s-cluster.zone}"
      GOOGLE_APPLICATION_CREDENTIALS = "${path.module}/terraform.json"
      KUBECONFIG="${path.module}/k8s/ci"
    }
  }

  depends_on = ["kubernetes_cluster_role_binding.default", "kubernetes_cluster_role_binding.user"]

}

