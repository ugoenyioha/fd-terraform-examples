/****** NETWORK *******/

resource "google_compute_network" "fd1-net" {
  name = "fd1-network"
  auto_create_subnetworks = true
}

//variable "fd1-ip-range" {
//  description = "The CIDR from which to allocate cluster node IPs"
//  type        = "string"
//  default     = "10.0.1.0/24"
//}
//
//resource "google_compute_subnetwork" "fd1-subnet" {
//  name          = "fd1-subnet"
//  ip_cidr_range = "${var.fd1-ip-range}"
//  region        = "us-central1"
//  network       = "${google_compute_network.fd1-net.self_link}"
//  private_ip_google_access = true
//}

/***** WEB SERVER / FRONTEND *******/

resource "google_service_account" "webserver" {
  account_id   = "webserver-service-account"
  display_name = "web server service account"
}

resource "google_compute_global_forwarding_rule" "webserver-forwarding-rule" {
  name = "frontend-forwarder"
  port_range = "80"
  target = "${google_compute_target_http_proxy.webserver.self_link}"
}

//resource "google_compute_global_forwarding_rule" "webserver-forwarding-rule" {
//  name = "frontend-forwarder"
//  port_range = "443"
//  target = "${google_compute_target_https_proxy.webserver.self_link}"
//}
//
//
//resource "google_compute_target_https_proxy" "webserver" {
//  name = "webserver-proxy"
//  url_map = "${google_compute_url_map.webserver.self_link}"
//  ssl_certificates = []
//}

resource "google_compute_target_http_proxy" "webserver" {
  name = "webserver-proxy"
  url_map = "${google_compute_url_map.webserver.self_link}"
}

resource "google_compute_url_map" "webserver" {
  name        = "fd-external-frontend"
  default_service = "${google_compute_backend_service.webserver.self_link}"

  host_rule {
    hosts        = ["mysite.com"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = "${google_compute_backend_service.webserver.self_link}"

    path_rule {
      paths   = ["/*"]
      service = "${google_compute_backend_service.webserver.self_link}"
    }
  }
}

resource "google_compute_backend_service" "webserver" {
  name             = "fd-external-webserver"
  description      = "webserver load balancer"
  port_name        = "http"
  protocol         = "HTTP"
  timeout_sec      = 10
  session_affinity = "CLIENT_IP"
  enable_cdn       = true

  backend {
    group = "${google_compute_region_instance_group_manager.webserver.instance_group}"
  }

  health_checks = ["${google_compute_health_check.webserver.self_link}"]
}

resource "google_compute_health_check" "webserver" {
  name               = "webserver-health-check"
  check_interval_sec = 1
  timeout_sec        = 1

  tcp_health_check {
    port = "80"
  }

}

resource "google_compute_region_instance_group_manager" "webserver" {
  name = "webserver-igm"
  provider = "google-beta"

  base_instance_name         = "webserver"

  version {
    name = "frontend"
    instance_template = "${google_compute_instance_template.webserver.self_link}"
  }

  region                     = "us-central1"
  distribution_policy_zones  = ["us-central1-a", "us-central1-b", "us-central1-c"]

  target_size  = 3

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = "${google_compute_health_check.webserver.self_link}"
    initial_delay_sec = 300
  }
}

/***** BACKEND *******/

resource "google_service_account" "backend" {
  account_id   = "backend"
  display_name = "backend service account"
}

resource "google_compute_forwarding_rule" "backend-forwarding-rule" {
  name = "backend-forwarder"
  backend_service = "${google_compute_region_backend_service.backend.self_link}"
  load_balancing_scheme = "INTERNAL"
  ports = ["443"]
  network = "${google_compute_network.fd1-net.self_link}"
}

resource "google_compute_region_backend_service" "backend" {
  name             = "fd-internal-backend"
  description      = "backend load balancer"
  protocol         = "TCP"
  timeout_sec      = 10
  session_affinity = "CLIENT_IP"

  backend {
    group = "${google_compute_region_instance_group_manager.backend.instance_group}"
  }

  health_checks = ["${google_compute_health_check.backend.self_link}"]
}

resource "google_compute_health_check" "backend" {
  name               = "backend-health-check"
  check_interval_sec = 1
  timeout_sec        = 1

  tcp_health_check {
    port = "443"
  }
}

resource "google_compute_region_instance_group_manager" "backend" {
  name = "backend-igm"
  provider = "google-beta"

  base_instance_name         = "backend"

  version {
    name = "backend"
    instance_template = "${google_compute_instance_template.backend.self_link}"
  }

  region                     = "us-central1"
  distribution_policy_zones  = ["us-central1-a", "us-central1-b", "us-central1-c"]

  target_size  = 3

  named_port {
    name = "ssl"
    port = 443
  }

  auto_healing_policies {
    health_check      = "${google_compute_health_check.backend.self_link}"
    initial_delay_sec = 300
  }
}

/***** DATABASE *******/

resource "google_service_account" "database" {
  account_id   = "database"
  display_name = "database service account"
}

resource "google_compute_forwarding_rule" "database-forwarding-rule" {
  name = "databse-forwarder"
  backend_service = "${google_compute_region_backend_service.database.self_link}"
  load_balancing_scheme = "INTERNAL"
  ports = ["3306"]
  network = "${google_compute_network.fd1-net.self_link}"
}

resource "google_compute_region_backend_service" "database" {
  name             = "fd-internal-database"
  description      = "database load balancer"
  protocol         = "TCP"
  timeout_sec      = 10
  session_affinity = "CLIENT_IP"

  backend {
    group = "${google_compute_region_instance_group_manager.database.instance_group}"
  }

  health_checks = ["${google_compute_health_check.database.self_link}"]
}

resource "google_compute_health_check" "database" {
  name               = "database-health-check"
  check_interval_sec = 1
  timeout_sec        = 1

  tcp_health_check {
    port = "3309"
  }
}

resource "google_compute_region_instance_group_manager" "database" {
  name = "database-igm"
  provider = "google-beta"

  base_instance_name         = "database"

  version {
    name = "backend"
    instance_template = "${google_compute_instance_template.database.self_link}"
  }

  region                     = "us-central1"
  distribution_policy_zones  = ["us-central1-a", "us-central1-b", "us-central1-c"]

  target_size  = 3

  named_port {
    name = "mysql"
    port = 3306
  }

  auto_healing_policies {
    health_check      = "${google_compute_health_check.database.self_link}"
    initial_delay_sec = 300
  }
}

/***** ZOOKEEPER *******/
resource "google_service_account" "zookeeper" {
  account_id   = "zookeeper"
  display_name = "zookeeper service account"
}

resource "google_compute_forwarding_rule" "zookeeper-forwarding-rule" {
  name = "zookeeper-forwarder"
  backend_service = "${google_compute_region_backend_service.zookeeper.self_link}"
  load_balancing_scheme = "INTERNAL"
  ports = ["2888", "3888", "2181"]
  network = "${google_compute_network.fd1-net.self_link}"
}

resource "google_compute_region_backend_service" "zookeeper" {
  name             = "fd-internal-zookeeper"
  description      = "zookeeper load balancer"
  protocol         = "TCP"
  timeout_sec      = 10
  session_affinity = "CLIENT_IP"

  backend {
    group = "${google_compute_region_instance_group_manager.zookeeper.instance_group}"
  }

  health_checks = ["${google_compute_health_check.zookeeper.self_link}"]
}

resource "google_compute_health_check" "zookeeper" {
  name               = "zookeeper-health-check"
  check_interval_sec = 1
  timeout_sec        = 1

  tcp_health_check {
    port = "2181"
  }
}

resource "google_compute_region_instance_group_manager" "zookeeper" {
  name = "zookeeper-igm"
  provider = "google-beta"

  base_instance_name         = "zookeeper"

  version {
    name = "backend"
    instance_template = "${google_compute_instance_template.zookeeper.self_link}"
  }

  region                     = "us-central1"
  distribution_policy_zones  = ["us-central1-a", "us-central1-b", "us-central1-c"]

  target_size  = 2

  named_port {
    name = "zookeeper"
    port = 2181
  }

  auto_healing_policies {
    health_check      = "${google_compute_health_check.zookeeper.self_link}"
    initial_delay_sec = 300
  }
}

