//resource "google_compute_region_backend_service" "fd1-webserver-lb" {
//  name             = "fd1-internal-lb"
//  description      = "fd1 internal load balancer"
//  protocol         = "TCP"
//  timeout_sec      = 10
//  session_affinity = "CLIENT_IP"
//
//  backend {
//    group = "${google_compute_region_instance_group_manager.foo.instance_group}"
//  }
//
//  health_checks = ["${google_compute_health_check.default.self_link}"]
//}
//
//resource "google_compute_region_instance_group_manager" "foo" {
//  name               = "terraform-test"
//  instance_template  = "${google_compute_instance_template.foobar.self_link}"
//  base_instance_name = "foobar"
//  region             = "us-central1"
//  target_size        = 1
//}