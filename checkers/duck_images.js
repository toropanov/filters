import fs from 'fs';
import cheerio from 'cheerio';
import phantom from "phantom";

const hosts = fs.readFileSync('/etc/hosts');
// const query = 'красивая девушка';
// const parseURL = encodeURIComponent(`https://safe.duckduckgo.com/?q=${query}&kae=-1&kp=1&iax=images&ia=images`);

(async function() {
    const instance = await phantom.create();
    const page = await instance.createPage();

    const status = await page.open('https://safe.duckduckgo.com/?q=%D0%B4%D0%B5%D0%B2%D1%83%D1%88%D0%BA%D0%B0+%D0%B4%D0%BD%D1%8F&kae=-1&kp=1&iax=images&ia=images&pn=8');

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
  console.log(links.count)

  $(links).each(async function(i, linkEl){
    const pageURL = await $(linkEl).attr('title');
    const siteURL = await $(linkEl).text();

    const isBlocked = hosts.includes(siteURL);
    console.log(`${pageURL} is blocked - ${isBlocked}`);
  });
}
// var uSet = new Set(array);
// console.log([...uSet]); // Back to array
