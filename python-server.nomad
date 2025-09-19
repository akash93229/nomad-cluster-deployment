



job "python-server" {
  datacenters = ["dc1"]
  type = "service"

  group "web" {
    count = 1

    task "web" {
      driver = "docker"

      config {
        image = "python:3.8"
      }

      env = {
        MY_ENV_VAR = "some_value"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}

