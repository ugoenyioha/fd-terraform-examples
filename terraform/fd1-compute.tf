/****** NETWORK *******/

resource "google_compute_network" "fd1-net" {
  name = "fd1-network"
  auto_create_subnetworks = false
}

variable "fd1-ip-range" {
  description = "The CIDR from which to allocate cluster node IPs"
  type        = "string"
  default     = "10.0.1.0/24"
}

resource "google_compute_subnetwork" "fd1-subnet" {
  name          = "fd1-subnet"
  ip_cidr_range = "${var.fd1-ip-range}"
  region        = "us-central1"
  network       = "${google_compute_network.fd1-net.self_link}"
  private_ip_google_access = true
}

/***** WEB SERVER *******/

resource "google_service_account" "webserver" {
  account_id   = "webserver-service-account"
  display_name = "web server service account"
}

resource "google_compute_instance" "webserver-1" {
  name         = "webserver-1"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.fd1-subnet.self_link}"

    access_config {
      // Ephemeral IP
    }
  }

  allow_stopping_for_update = true

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    email = "${google_service_account.webserver.email}"
  }
}

resource "google_compute_instance" "webserver-2" {
  name         = "webserver-2"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.fd1-subnet.self_link}"

    access_config {
      // Ephemeral IP
    }
  }

  allow_stopping_for_update = true


  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    email = "${google_service_account.webserver.email}"
  }
}

/***** BACKEND *******/

resource "google_service_account" "backend" {
  account_id   = "backend"
  display_name = "backend service account"
}

resource "google_compute_instance" "backend-1" {
  name         = "backend-1"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.fd1-subnet.self_link}"

    access_config {
      // Ephemeral IP
    }
  }

  allow_stopping_for_update = true


  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    email = "${google_service_account.backend.email}"
  }
}

resource "google_compute_instance" "backend-2" {
  name         = "backend-2"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.fd1-subnet.self_link}"

    access_config {
      // Ephemeral IP
    }
  }

  allow_stopping_for_update = true


  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    email = "${google_service_account.backend.email}"
  }
}

/***** DATABASE *******/

resource "google_service_account" "database" {
  account_id   = "database"
  display_name = "database service account"
}

resource "google_compute_instance" "database-1" {
  name         = "database-1"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.fd1-subnet.self_link}"

    access_config {
      // Ephemeral IP
    }
  }

  allow_stopping_for_update = true

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    email = "${google_service_account.database.email}"
  }
}

resource "google_compute_instance" "database-2" {
  name         = "database-2"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.fd1-subnet.self_link}"

    access_config {
      // Ephemeral IP
    }
  }

  allow_stopping_for_update = true


  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    email = "${google_service_account.database.email}"
  }
}

/***** ZOOKEEPER *******/
resource "google_service_account" "zookeeper" {
  account_id   = "zookeeper"
  display_name = "zookeeper service account"
}

resource "google_compute_instance" "zookeeper-1" {
  name         = "zookeeper-1"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.fd1-subnet.self_link}"

    access_config {
      // Ephemeral IP
    }
  }

  allow_stopping_for_update = true

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    email = "${google_service_account.zookeeper.email}"
  }
}

resource "google_compute_instance" "zookeeper-2" {
  name         = "zookeeper-2"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.fd1-subnet.self_link}"

    access_config {
      // Ephemeral IP
    }
  }

  allow_stopping_for_update = true

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    email = "${google_service_account.zookeeper.email}"
  }
}

