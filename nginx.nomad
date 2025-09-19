
job "nginx" {
  datacenters = ["dc1"]

  group "web" {
    network {
      port "http" {
        static = 80
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:latest"
        ports = ["http"]
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}

