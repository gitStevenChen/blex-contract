
hash = "0xe47fe6cd5b389423f2b7465877d7f29de3da6af701521e91ce8395d4488d2faf"

const https = require('https');

function getJsonFromUrl(txHash) {
    return new Promise((resolve, reject) => {
        https.get(`https://api.tenderly.co/api/v1/public-contract/43113/tx/${txHash}`, response => {
            let data = '';
            response.on('data', chunk => {
                data += chunk;
            });
            response.on('end', () => {
                try {
                    const json = JSON.parse(data);
                    resolve(json);
                } catch (error) {
                    reject(error);
                }
            });
        }).on('error', error => {
            reject(error);
        });
    });
}

getJsonFromUrl(hash)
    .then(json => {
        console.log(json["error_message"]);
    })
    .catch((error) => {
    console.error(error)
    process.exitCode = 1
})

