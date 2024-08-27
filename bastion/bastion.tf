resource "random_string" "bastion_admin_username" {
  length  = 16
  special = false
  number  = false
  lower   = true
  upper   = true
}

resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_compute_instance" "bastion" {
  name                      = "${var.app_name}-bastion"
  machine_type              = "e2-highmem-4"
  project                   = var.project
  allow_stopping_for_update = true
  tags = [
    "allow-ssh",
  ]

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20221201"
      size  = 40
    }
  }

  network_interface {
    network    = var.network.self_link
    subnetwork = var.private_subnet.name

    access_config {
      nat_ip = google_compute_address.bastion.address
    }
  }

  metadata = {
    ssh-keys = "${split("@", random_string.bastion_admin_username.result)[0]}:${tls_private_key.ssh-key.public_key_openssh}"
  }

  connection {
    host        = google_compute_address.bastion.address
    type        = "ssh"
    user        = random_string.bastion_admin_username.result
    private_key = tls_private_key.ssh-key.private_key_pem
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }
}

resource "null_resource" "install" {
  triggers = {
    on_creation = google_compute_instance.bastion.instance_id
  }

  connection {
    host        = google_compute_address.bastion.address
    type        = "ssh"
    user        = random_string.bastion_admin_username.result
    private_key = tls_private_key.ssh-key.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get install -y docker.io",
      "sudo -E curl -L https://github.com/docker/compose/releases/download/1.27.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "(sudo groupadd docker || true)",
      "(sudo usermod -aG docker $USER || true)",
      "sudo chmod 666 /var/run/docker.sock",
      "sudo apt-get -y install postgresql postgresql-contrib"
    ]
  }

  #create create service account credential file
  provisioner "file" {
    content     = base64decode(google_service_account_key.bastion.private_key)
    destination = "/home/${random_string.bastion_admin_username.result}/auth_token.json"
  }

  #install kubectl
  provisioner "remote-exec" {
    inline = [
      "mkdir /home/${random_string.bastion_admin_username.result}/.kube/ ; sudo snap install --classic kubectl",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"⌛️ Installing GCP CLI\"",
      "echo '⌛️ Updating kubectl config...'",

      # Update dependencies
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list",

      # Install kubectl for x86_64
      "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
      "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256",
      "echo \"$(cat kubectl.sha256)  kubectl\" | sha256sum --check",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",

      #Install Kustomize
      "curl -sfLo kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v3.1.0/kustomize_3.1.0_linux_amd64",
      "chmod u+x ./kustomize",


      # add GCloud CLI Distribution URI as a trusted source
      "echo \"deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main\" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list",
      "curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -",

      # install gcp cli
      "sudo apt-get update && sudo apt-get install google-cloud-cli",

      # authenticate using service account
      "echo \"Authenticating GCP CLI Login\"",
      "gcloud auth activate-service-account -q --key-file=/home/${random_string.bastion_admin_username.result}/auth_token.json",
      "gcloud config set project ${var.project} -q",

      # install gke auth plugin
      "sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin",

    ]
  }

  depends_on = [google_compute_instance.bastion]
}

resource "null_resource" "update" {
  triggers = {
    server  = google_compute_instance.bastion.instance_id
    install = null_resource.install.id
    # config_hash             = var.config_hash
    # deployment_cache_buster = var.deployment_cache_buster
    service_account = base64decode(google_service_account_key.bastion.private_key)
  }

  connection {
    type        = "ssh"
    user        = random_string.bastion_admin_username.result
    host        = google_compute_address.bastion.address
    private_key = tls_private_key.ssh-key.private_key_pem
  }

  # update service account credential file
  provisioner "file" {
    content     = base64decode(google_service_account_key.bastion.private_key)
    destination = "/home/${random_string.bastion_admin_username.result}/auth_token.json"
  }


  #install gcloud and login
  provisioner "remote-exec" {
    inline = [
      "echo \"⌛️ Updating kubectl config...\"",

      # update dependencies
      "sudo apt-get -y update && sudo apt-get -y --only-upgrade install kubectl google-cloud-sdk-package-go-module google-cloud-sdk-skaffold google-cloud-sdk-app-engine-go google-cloud-sdk-cbt google-cloud-sdk-terraform-tools google-cloud-sdk-bigtable-emulator google-cloud-sdk-local-extract google-cloud-sdk-anthos-auth google-cloud-sdk-gke-gcloud-auth-plugin google-cloud-sdk-firestore-emulator google-cloud-sdk-spanner-emulator google-cloud-sdk-nomos google-cloud-sdk-datastore-emulator google-cloud-sdk-minikube google-cloud-sdk google-cloud-sdk-pubsub-emulator google-cloud-sdk-kubectl-oidc google-cloud-sdk-app-engine-python-extras google-cloud-sdk-app-engine-grpc google-cloud-sdk-cloud-run-proxy google-cloud-sdk-config-connector google-cloud-sdk-app-engine-java google-cloud-sdk-cloud-build-local google-cloud-sdk-datalab google-cloud-sdk-log-streaming google-cloud-sdk-app-engine-python google-cloud-sdk-kpt google-cloud-sdk-harbourbridge",

      # authenticate using service account
      "gcloud auth activate-service-account -q --key-file=/home/${random_string.bastion_admin_username.result}/auth_token.json",
      "gcloud config set project ${var.project} -q",

      # update kubectl config
      "gcloud container clusters get-credentials --region ${var.region} ${var.codematic_cluster.name}",
      "kubectl config set-context codematic --cluster=${var.codematic_cluster.name} --namespace=codematic",

      "echo \"✅ Updated kubectl config.\"",
    ]
  }

  depends_on = [google_compute_instance.bastion, null_resource.install]
}
