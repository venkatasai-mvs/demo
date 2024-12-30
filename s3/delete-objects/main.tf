resource "null_resource" "delete_objects" {
  triggers = {
    bucket_name = var.bucket_name
  }
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["pwsh", "-Command"]
    command     = <<COMMAND
    $BUCKET="${lookup(self.triggers, "bucket_name", "")}"
    ${file("${path.module}/delete-objects.ps1")}
    COMMAND
  }
}
