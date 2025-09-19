












server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled           = true
  network_interface = "enX1"   # <-- use your actual interface name
  options = {
    "driver.raw_exec.enable" = "1"
  }
}

data_dir = "/opt/nomad"
bind_addr = "0.0.0.0"
