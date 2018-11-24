
//https://medium.com/@yagonobre/automatically-invalidate-cloudfront-cache-for-site-hosted-on-s3-3c7818099868
exports.handler = (event, context, callback) => {

    // Get request and request headers
    // console.log(123);
    // console.log(event);
    const request = event.Records[0].cf.request;

    console.log(JSON.stringify(event));

    if (!'phuonghqh.booppi.website.htaccess') {
        console.log(`Bucket not defined (key is empty) => ignore`);
        callback(null, request);
        return;
    }

    readRestrictedFiles(files => {
        console.log(files);

        // const headers = request.headers;
        //
        // const authUser = 'test';
        // const authPass = 'test';
        //
        // // Construct the Basic Auth string
        // const authString = 'Basic ' + new Buffer(authUser + ':' + authPass).toString('base64');
        //
        // // // Require Basic authentication
        // if (typeof headers.authorization === 'undefined' || headers.authorization[0].value !== authString) {
        //     const body = 'Unauthorized';
        //     const response = {
        //         status: '401',
        //         statusDescription: 'Unauthorized',
        //         body: body,
        //         headers: {
        //             'www-authenticate': [{key: 'WWW-Authenticate', value:'Basic'}]
        //         },
        //     };
        //     callback(null, response);
        // }

        callback(null, request);
    });
};

function readRestrictedFiles(onFileContent) {
    const AWS = require('aws-sdk');
    const s3 = new AWS.S3();
    var params = { Bucket: 'phuonghqh.booppi.website.htaccess', Key: 'htaccess.json' };
    s3.getObject(params, function (err, data) {
        if (err) {
            console.log(err);
        }
        onFileContent(data.Body.toString());
    });

}




// exports.handler = (event, context, callback) => {
//     var bucketName = process.env.bucketName;
//     var keyName = event.Records[0].s3.object.key;
//
//     readFile(bucketName, keyName, readFileContent, onError);
// };

// function readFile(bucketName, filename, onFileContent, onError) {
//     var params = { Bucket: bucketName, Key: filename };
//     s3.getObject(params, function (err, data) {
//         if (!err)
//             onFileContent(filename, data.Body.toString());
//         else
//             console.log(err);
//     });
// }
//
// function readFileContent(filename, content) {
//     //do something with the content of the file
// }
//
// function onError (err) {
//     console.log('error: ' + err);
// }