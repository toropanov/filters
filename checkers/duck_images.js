import fs from 'fs';
import cheerio from 'cheerio';
import phantom from "phantom";

import { exec } from 'child_process';

const hosts = fs.readFileSync('/etc/hosts');
const query = encodeURIComponent('');
const parseURL = `https://safe.duckduckgo.com/?q=${query}&kae=-1&kp=1&iax=images&ia=images`;

(async function() {
    const instance = await phantom.create();
    const page = await instance.createPage();

    const status = await page.open(parseURL);

    if (status == "success") {
      console.log('Page is loaded');
      scrollPage(instance, page);
    }
}());

async function scrollPage(instance, page) {
  const executingScript = "function(){ window.scrollBy(0, 10000); return { scrolled: document.documentElement.classList.contains('has-footer'), height: document.body.scrollHeight, content: document.documentElement.innerHTML }; }";
  const { scrolled, height, content } = await page.evaluateJavaScript(executingScript);
  if (scrolled) {
    parseContent(content);
    instance.exit();
  } else {
    setTimeout(function() {
      console.log(`Page scrolled to ${height}`);
      scrollPage(instance, page);
    }, 1000);
  }
}

function parseContent(content) {
  const $ = cheerio.load(content);
  const links = $('span.tile--img__domain');
  const notBlockedLinks = [];
  const handledDomains = [];

  $(links).each(function(i, linkEl){
    const pageURL = $(linkEl).attr('title');
    const siteURL = $(linkEl).text();

    if (!hosts.includes(siteURL) && !handledDomains.includes(siteURL)) {
      console.log('PUSH', pageURL);
      notBlockedLinks.push(pageURL);
      const command = `open -a "Google Chrome" ${pageURL}`;
      
      exec(command);
      
      handledDomains.push(siteURL);
    }
  });
  console.log('NOT BLOCKED', notBlockedLinks);
}
