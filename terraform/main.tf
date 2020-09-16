provider "google" {
  version = "~> 3.37.0"
}

provider "google-beta" {
  region = var.region
}

provider "random" {
  version = "~> 2.3"
}

resource "random_string" "prefix" {
  length  = 4
  upper   = false
  special = false
}

resource "google_storage_bucket" "uploaded_audio" {
  name          = "${random_pet.main.id}_uploaded_audio"
  force_destroy = true
  location      = var.region
  project       = var.project_id
  storage_class = "REGIONAL"
}


resource "google_storage_bucket" "staging_bucket" {
  name          = "${random_pet.main.id}_staging"
  force_destroy = true
  location      = var.region
  project       = var.project_id
  storage_class = "REGIONAL"
}

module "bigquery" {
  source  = "terraform-google-modules/bigquery/google"
  version = "~> 4.3"

  dataset_id   = "${random_pet.main.id}_saf"
  dataset_name = "${random_pet.main.id}_saf"
  description  = "SAF Dataset"
  project_id   = var.project_id
  location     = "US"
}

module "pubsub" {
  source  = "terraform-google-modules/pubsub/google"
  version = "~> 1.4"

  topic      = "${random_pet.main.id}-saf"
  project_id = var.project_id
}

resource "random_pet" "main" {
  length    = 2
  separator = ""
}

module "localhost_function" {
  source      = "terraform-google-modules/event-function/google"
  description = "Triggers processing of audio files."
  entry_point = "safLongRunJobFunc"
  event_trigger = {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.uploaded_audio.id
  }

  name             = "${random_pet.main.id}-saf"
  project_id       = var.project_id
  region           = var.region
  source_directory = "../saf-longrun-job-func"
  runtime          = "nodejs8"
}


module "container_build" {
  source          = "terraform-google-modules/gcloud/google"
  version         = "~> 2.0"
  platform        = "linux"
  create_cmd_body = "builds submit --tag ${var.saf_flex_template_image} ../saf-longrun-job-dataflow"
}

module "template_build" {
  source                = "terraform-google-modules/gcloud/google"
  version               = "~> 2.0"
  platform              = "linux"
  additional_components = ["beta"]
  gcloud_sdk_version    = "308.0.0"
  create_cmd_body       = <<END
  beta dataflow flex-template build --project ${var.project_id} gs://${google_storage_bucket.staging_bucket.name}/saf_flex_template \
    --image ${var.saf_flex_template_image} \
    --sdk-language PYTHON --metadata-file ../saf-longrun-job-dataflow/metadata.json
  END
}

resource "google_dataflow_flex_template_job" "saf_flex_template_job" {
  provider                = google-beta
  project                 = var.project_id
  name                    = "${random_pet.main.id}-saf"
  container_spec_gcs_path = "gs://${google_storage_bucket.staging_bucket.name}/saf_flex_template"
  parameters = {
    input_topic = "projects/${var.project_id}/topics/${random_pet.main.id}-saf"
    output_bigquery = "${module.bigquery.project}:${module.bigquery.bigquery_dataset.dataset_id}.${random_pet.main.id}_saf"
  }

  depends_on = [ module.container_build, module.template_build ]
}
