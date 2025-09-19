












job "hello-world" {
  datacenters = ["dc1"]
  type = "service"

  group "hello-world-group" {
    count = 1

    network {
      port "http" {
        static = 8080  # Or leave this out to let Nomad assign a dynamic port
      }
    }

    task "web" {
      driver = "docker"

      config {
        image = "nginx:latest"
        ports = ["http"]  # Tell Nomad this task uses the "http" port defined in the network block
      }

      resources {
        cpu    = 500
        memory = 256
      }

      service {
        name = "hello-world"
        port = "http"
        tags = ["urlprefix-/"]
      }
    }
  }
}
