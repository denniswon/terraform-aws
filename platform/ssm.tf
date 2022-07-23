resource aws_ssm_parameter private_ssl_cert {
  name  = "PRIVATE_SSL_CERT"
  type  = "SecureString"
  value = tls_self_signed_cert.private_alb.cert_pem
}