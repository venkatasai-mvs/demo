module "bom" {
  source = "../../bom"
}

module "lambda" {
  source = "../../lambda/"

  short_prefix      = "${var.short_prefix}-s3-obj-frw"
  long_prefix       = "${var.long_prefix}-s3api-object-forward"
  role              = var.role
  content           = <<NODEJS
const aws = require('aws-sdk');
const codepipeline = new aws.CodePipeline({apiVersion: '${module.bom.versions.aws-api.code_pipeline}'});
const s3 = new aws.S3({apiVersion: '${module.bom.versions.aws-api.s3}'})

${file("${path.module}/../../nodejs/connection.js")}

exports.handler = async (request) => {
  console.log("REQUEST: " + JSON.stringify(request));
  const awsConnection = getConnection(request);
  try {
    const awsRequest = awsConnection.request
    console.log("FORWARD REQUEST: " + JSON.stringify(awsRequest));
    const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '))
    var getObjectRequest = {
      Bucket: event.Records[0].s3.bucket.name,
      Key: key
    };
    console.log("GET OBJECT REQUEST: " + JSON.stringify(getObjectRequest));
    const getObjectResult = await s3.getObject(getObjectRequest).promise();
    console.log("GET OBJECT RESULT: " + JSON.stringify(getObjectResult));
    const body = getObjectResult["Body"].toString('utf-8');
    console.log("BODY: "+body);
    const putRequest = {
      Bucket               = "${var.dst.bucket}"
      Key                  = "${var.dst.key}"
      Body                 = body
      ServerSideEncryption = "aws:kms"
    }
    const putObjectResult = await s3.upload(awsRequest).promise();
    console.log("PUT OBJECT RESULT: " + JSON.stringify(putObjectResult));
    return await awsConnection.success(putObjectResult);
  } catch (error) {
    return await awsConnection.failure(error);
  }
};
NODEJS
  retention_in_days = var.retention_in_days
  timeout           = 30
  tags              = var.tags
}

resource "aws_s3_bucket_notification" "trigger" {
  bucket = var.src.bucket

  lambda_function {
    lambda_function_arn = module.lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.src.key
  }
}

resource "aws_lambda_permission" "lambda" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = module.lambda.arn
}
