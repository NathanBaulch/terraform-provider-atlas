terraform {
  required_providers {
    atlas = {
      version = "0.0.1"
      source  = "github.com/ariga/atlas"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.16.0"
    }
  }
}

provider "atlas" {}
provider "docker" {
}

resource "docker_image" "mysql" {
  name = "mysql:8"
}

resource "docker_container" "dev" {
  image = docker_image.mysql.latest
  name  = "devdb"
  env = [
    "MYSQL_ROOT_PASSWORD=pass",
    "MYSQL_DATABASE=test",
  ]
  ports {
    external = 3307
    internal = 3306
  }
}

resource "docker_container" "prod" {
  image = docker_image.mysql.latest
  name  = "proddb"
  env = [
    "MYSQL_ROOT_PASSWORD=pass",
    "MYSQL_DATABASE=test",
  ]
  ports {
    external = 3306
    internal = 3306
  }
}

data "atlas_schema" "at_schema" {
  depends_on = [ docker_container.dev ]
  dev_db_url = "mysql://root:pass@tcp(localhost:3307)/test"
  src = file("${path.module}/schema.hcl")
}

resource "atlas_schema" "mydb" {
  depends_on = [ docker_container.prod ]
  hcl = data.atlas_schema.at_schema.content
  url = "mysql://root:pass@tcp(localhost:3306)/test"  
}
