
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

//https://medium.com/@yagonobre/automatically-invalidate-cloudfront-cache-for-site-hosted-on-s3-3c7818099868
exports.handler = async (event, context, callback) => {

    // Get request and request headers
    // console.log(123);
    // console.log(event);
    const request = event.Records[0].cf.request;

    console.log(JSON.stringify(event));

    if (!'${BUCKET_NAME}') {
        console.log(`Bucket not defined (key is empty) => ignore`);
        callback(null, request);
        return;
    }

    try {
        const files = await readRestrictedFiles();
        console.log(files);

        // const headers = request.headers;
        //
        // const authUser = '${BASIC_USER}';
        // const authPass = '${BASIC_PASSWORD}';
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
        console.log(6);
        callback(null, request);
    }
    catch(e) {
        console.error(e);
    }

    console.log(4);
};

async function readRestrictedFiles() {
    const params = { Bucket: '${BUCKET_NAME}', Key: '${BUCKET_KEY}' };
    const data =  await s3.getObject(params).promise();
    return data.Body.toString();


    // return new Promise((rs, rj) => {
    //     console.log(1);

    //     var params = { Bucket: '${BUCKET_NAME}, Key: '${BUCKET_KEY} };
    //     console.log(2);
    //     console.log(s3);
    //     console.log(s3.getObject);
    //     // s3.getObject(params, function (err, data) {
    //     //     console.log(5);
    //     //     if (err) {
    //     //         console.error(err);
    //     //         return rj(err);
    //     //     }
    //     //     console.log(data);

    //     //     //onFileContent(err, );
    //     //     rs(data.Body.toString());
    //     // });
    //     console.log(3);
    // });


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