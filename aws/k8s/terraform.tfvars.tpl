cluster_name = "${cluster_name}"
efs_id       = "${efs_id}"
region       = "${region}"
tr_domain    = "${tr_domain}"
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



