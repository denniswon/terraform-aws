resource aws_kms_key ssm_s3 {
  deletion_window_in_days = 10
  description = "ssm encrypt & decrypt"
}