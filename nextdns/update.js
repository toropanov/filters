require('dotenv').config();
const request = require('request');

if (!process.env.NEXTDNS_ENABLE) return;

const accounts = [{
  device: 'iPhone',
  id: process.env.NEXTDNS_IPHONE_ID,
  key: process.env.NEXTDNS_IPHONE_API_KEY,
}, {
  device: 'iPad',
  id: process.env.NEXTDNS_IPAD_ID,
  key: process.env.NEXTDNS_IPAD_API_KEY,
}];

const apiRequest = ({ url, headers, method = 'GET', body }) => new Promise((resolve, reject) => {
  request({
    url,
    body,
    method,
    json: true, 
    headers,
  }, function(error, response, resBody){
    if ([200, 204].includes(response.statusCode)) {
      resolve(resBody);
    } else {
      reject(error);
    }
  });
});

const fetchDenylist  = () => new Promise((resolve, reject) => {
  apiRequest({
    url: 'https://raw.githubusercontent.com/toropanov/filters/master/blocked.json',
  }).then((response) => {
    resolve(response);
  }, (error) => {
    reject(error);
  });
});

const replaceDenylist  = ({ id, key, body }) => new Promise((resolve, reject) => {
  apiRequest({
    url: `https://api.nextdns.io/profiles/${id}/denylist`,
    method: 'PUT',
    body,
    headers: {
      'X-Api-Key': key
    }
  }).then((response) => {
    resolve(response);
  }, (error) => {
    reject(error);
  });
});

accounts.forEach(({ id, key, device }) => {
  fetchDenylist().then(({ domains: commonDomains, domains_only_mobile, domains_only_tablet }) => {
    const domains = [...new Set([
      ...commonDomains,
      ...(
        device === 'iPhone'
          ? domains_only_mobile
          : domains_only_tablet
      )
    ])];

    const body = domains.map(id => ({ active: true, id }));

    replaceDenylist({
      id,
      key,
      body,
    }).then(() => {
      console.log(`${device} | Added ${body.length} domains`)
    }, (error) => {
      console.log(`${device} | ${error}`);
    });
  });
});
