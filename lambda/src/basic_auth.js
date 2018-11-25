
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

//https://medium.com/@yagonobre/automatically-invalidate-cloudfront-cache-for-site-hosted-on-s3-3c7818099868
exports.handler = async (event, context, callback) => {
    const request = event.Records[0].cf.request;
    const uri = request.uri;

    if (!'${BUCKET_NAME}') {
        console.log(`Bucket not defined (key is empty) => ignore`);
        callback(null, request);
        return;
    }

    try {
        const filesStr = await readRestrictedFiles();
        if (!filesStr) {
            console.log(`empty protect files => ignore`);
            return callback(null, request);
        }

        const rawFiles = JSON.parse(await readRestrictedFiles());
        if (!Array.isArray(rawFiles)) {
            console.log('${BUCKET_KEY} is not any array => ignore');
            return callback(null, request);
        }
        const files = rawFiles.map(f => f.startsWith('/') ? f : '/' + f);
        if (!files.includes(uri)) {
            console.log(uri + ` not protected`);
            return callback(null, request);
        }

        const headers = request.headers;

        const authUser = '${BASIC_USER}';
        const authPass = '${BASIC_PWD}';

        const authString = 'Basic ' + new Buffer(authUser + ':' + authPass).toString('base64');
        if (typeof headers.authorization === 'undefined' || headers.authorization[0].value !== authString) {
            const body = 'Unauthorized';
            const response = {
                status: '401',
                statusDescription: 'Unauthorized',
                body: body,
                headers: {
                    'www-authenticate': [{key: 'WWW-Authenticate', value:'Basic'}]
                },
            };
            return callback(null, response);
        }

        return callback(null, request);
    }
    catch(e) {
        console.error(e);
    }
};

async function readRestrictedFiles() {
    const params = { Bucket: '${BUCKET_NAME}', Key: '${BUCKET_KEY}' };
    const data =  await s3.getObject(params).promise();
    return data.Body.toString();
}