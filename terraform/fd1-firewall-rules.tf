resource "google_compute_firewall" "webserver-rules" {
  name = "webserver-rules"
  network = "${google_compute_network.fd1-net.name}"
  description = "allow the webservers reach the backend"

  allow {
    protocol = "tcp"
    ports = ["443"]
  }

  source_service_accounts = ["${google_service_account.webserver.email}"]
  target_service_accounts = ["${google_service_account.backend.email}"]
}

resource "google_compute_firewall" "zookeeper-rules" {
  name = "zookeeper-rules"
  network = "${google_compute_network.fd1-net.name}"
  description = "allow the backend reach zookeeper"

  allow {
    protocol = "tcp"
    ports = ["2888", "3888", "2181"]
  }

  source_service_accounts = ["${google_service_account.backend.email}"]
  target_service_accounts = ["${google_service_account.zookeeper.email}"]
}

resource "google_compute_firewall" "db-rules" {
  name = "db-rules"
  network = "${google_compute_network.fd1-net.name}"
  description = "allow the database receive traffic from the backend"

  allow {
    protocol = "tcp"
    ports =
       [
         "1521",
         "1521",
         "1630",
         "3938",
         "5580",
         "5640-5670"
       ]
  }

  source_service_accounts = ["${google_service_account.backend.email}"]
  target_service_accounts = ["${google_service_account.database.email}"]
}

resource "google_compute_firewall" "webserver-icmp" {
  name = "webserver-icmp"
  network = "${google_compute_network.fd1-net.name}"
  description = "allow webservers to ping the backend"

  allow {
    protocol = "icmp"
  }

  source_service_accounts = ["${google_service_account.webserver.email}"]
  target_service_accounts = ["${google_service_account.backend.email}"]
}

resource "google_compute_firewall" "backend-icmp" {
  name = "backend-icmp"
  network = "${google_compute_network.fd1-net.name}"
  description = "allow backend to ping zookeeper"

  allow {
    protocol = "icmp"
  }

  source_service_accounts = ["${google_service_account.backend.email}"]
  target_service_accounts = ["${google_service_account.zookeeper.email}"]
}
