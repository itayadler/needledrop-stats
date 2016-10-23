const nightmare = require('nightmare');
const hl = require('highland');
const bluebird = require('bluebird');
const REVIEWS_URL = "http://www.theneedledrop.com/articles?category=Reviews";
const fs = require('fs');

function fetchUrl(url) {
  return nightmare({ show: true })
    .goto(url)
}

function fetchReviewsPage(url) {
  console.log('fetching url: ', url);
  return fetchUrl(url)
    .evaluate(()=> {
      const reviews = Array.prototype.map.call(document.querySelectorAll('article h1 a'), (a)=> {
        return {url: a.href, album_name: a.textContent};
      });
      const olderReviewPage = document.querySelector('.pagination .older a').href;
      return [reviews, olderReviewPage];
    })
    .then(([reviews, olderReviewPage])=>{
      console.log(reviews, olderReviewPage);
      return {
        reviews,
        olderReviewPage
      };
    });
}

function scrapeReviews(startUrl, reviewsStream){
  fetchReviewsPage(startUrl)
    .then((result)=> {
      if (result.reviews.length > 0) {
        reviewsStream.write(result.reviews);
        scrapeReviews(result.olderReviewPage, reviewsStream)
      } else {
        reviewsStream.end();
      }
    })
}

const reviewsStream = hl();
scrapeReviews(REVIEWS_URL, reviewsStream);

reviewsStream
  .collect()
  .pipe(fs.createWriteStream("./reviews.json"))
