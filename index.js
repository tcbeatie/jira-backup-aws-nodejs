const AWS = require('aws-sdk'),
  region = "us-east-1",
  secretName = "Jira_API";
var secret, myToken, myEmail, myHost;
var smc = new AWS.SecretsManager({
  region: region
});

const fs = require('fs');
var s3 = new AWS.S3();

var today = new Date();

var epochHours = Math.floor(Math.floor(today/1000)/3600);

var dd = String(today.getDate()).padStart(2, '0');
var mm = String(today.getMonth() + 1).padStart(2, '0');
var yyyy = today.getFullYear();
today = mm + '-' + dd + '-' + yyyy;

const backupFile = 'JIRA-backup-' + today + '.zip';
const filePath = '/tmp/' + backupFile;

var backupPath, storageClass, bucketName;
if (dd === "01" || dd === "02") {
  backupPath = 'monthly/' + backupFile;
  storageClass = 'ONEZONE_IA';
} else {
  backupPath = 'daily/' + backupFile;
  storageClass = 'STANDARD';
}

exports.myHandler = function(event, context, callback) {

  if ((epochHours % 49) != 0) {
    console.log(epochHours + ' is not a multiple of 49 hours since epoch.. Exiting.');
    return;
  }

  smc.getSecretValue({SecretId: secretName}, function(err, data) {
    if (err) {
      throw err;
    } else {
      if ('SecretString' in data) {
        secret = JSON.parse(data.SecretString);
        myToken = secret.API_token;
        myEmail = secret.API_email;
        myHost = secret.API_host;
        bucketName = secret.S3_bucket;
      }
    }

    const exec = require('child_process').exec;
    var command = './backup-jira-api-token.sh ' + myHost + ' ' + myEmail + ' ' + myToken + ' ' + backupFile;
//    console.log('command is: ' + command);
    exec(command, (error, stdout, stderr) => {
      if (error) {
        callback(error);
      }
      console.log("stdout : " + stdout);
      console.log("stderr : " + stderr);
      callback(null, stdout);
      uploadFile(filePath, bucketName, storageClass, backupPath);
    });
  });

  const uploadFile = (filePath, bucketName, storageClass, backupPath) => {
    fs.readFile(filePath, (err, data) => {
      if (err) console.error(err);
 
      var params = {
        Bucket: bucketName,
        Key: backupPath,
        StorageClass: storageClass,
        Body: data
      };

      s3.upload(params, (err, data) => {
        if (err) console.error(`Upload Error ${err}`);
        console.log('Upload Completed');
      });
    });
  };

};
