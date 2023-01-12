terraform {
  required_providers {
    rediscloud = {
      source = "RedisLabs/rediscloud"
      version = "1.0.1"
    }
  }
}

provider "rediscloud" {}
