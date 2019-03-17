/*** WEB SERVER ***/

resource "google_compute_instance_template" "webserver" {
  name        = "webserver-template"
  description = "This template is used to create webserver instances."

  labels = {
    environment = "dev"
  }

  instance_description = "description assigned to instances"
  machine_type         = "f1-micro"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = "centos-cloud/centos-7"
    auto_delete  = true
    boot         = true
  }

  // Use an existing disk resource
  //  disk {
  //    // Instance Templates reference disks by name, not self link
  //    source      = "${google_compute_disk.webserver.name}"
  //    auto_delete = false
  //    boot        = false
  //  }

  network_interface {
    network = "${google_compute_network.fd1-net.name}"

    access_config {
      // Ephemeral IP
    }

  }

  //  metadata = {
  //    foo = "bar"
  //  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    email = "${google_service_account.webserver.email}"
  }
}

/***** BACKEND *******/

resource "google_compute_instance_template" "backend" {
  name        = "backend-template"
  description = "This template is used to create backend instances."

  labels = {
    environment = "dev"
  }

  instance_description = "description assigned to instances"
  machine_type         = "f1-micro"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = "centos-cloud/centos-7"
    auto_delete  = true
    boot         = true
  }

  // Use an existing disk resource
  //  disk {
  //    // Instance Templates reference disks by name, not self link
  //    source      = "${google_compute_disk.webserver.name}"
  //    auto_delete = false
  //    boot        = false
  //  }

  network_interface {
    network = "${google_compute_network.fd1-net.name}"
  }

  //  metadata = {
  //    foo = "bar"
  //  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    email = "${google_service_account.backend.email}"
  }
}

/***** DATABASE *******/

resource "google_compute_instance_template" "database" {
  name        = "database-template"
  description = "This template is used to create database instances."

  labels = {
    environment = "dev"
  }

  instance_description = "description assigned to instances"
  machine_type         = "f1-micro"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = "centos-cloud/centos-7"
    auto_delete  = true
    boot         = true
  }

  // Use an existing disk resource
  //  disk {
  //    // Instance Templates reference disks by name, not self link
  //    source      = "${google_compute_disk.webserver.name}"
  //    auto_delete = false
  //    boot        = false
  //  }

  network_interface {
    network = "${google_compute_network.fd1-net.name}"
  }

  //  metadata = {
  //    foo = "bar"
  //  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    email = "${google_service_account.database.email}"
  }
}


/***** ZOOKEEPER *******/

resource "google_compute_instance_template" "zookeeper" {
  name        = "zookeeper-template"
  description = "This template is used to create zookeeper instances."

  labels = {
    environment = "dev"
  }

  instance_description = "description assigned to instances"
  machine_type         = "f1-micro"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = "centos-cloud/centos-7"
    auto_delete  = true
    boot         = true
  }

  // Use an existing disk resource
  //  disk {
  //    // Instance Templates reference disks by name, not self link
  //    source      = "${google_compute_disk.webserver.name}"
  //    auto_delete = false
  //    boot        = false
  //  }

  network_interface {
    network = "${google_compute_network.fd1-net.name}"
  }

  //  metadata = {
  //    foo = "bar"
  //  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    email = "${google_service_account.zookeeper.email}"
  }
}