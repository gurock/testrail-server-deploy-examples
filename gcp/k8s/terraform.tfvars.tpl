project_id   = "${project_id}"
cluster_name = "${cluster_name}"
app_name     = "${app_name}"
region       = "${region}"
tr_domain    = "${tr_domain}"
network      = "${network}"
email        = "${email}"
tls          = "${tls}"
tr_resources = {
  %{ for key, value in tr_resources ~}
  ${key} = {
      %{ for n_key, n_value in value ~}
        ${n_key} = "${n_value}"
      %{ endfor ~}
  }
  %{ endfor ~}
}
