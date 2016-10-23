const hl = require('highland')
const fs = require('fs')
const getAllReviewsStream = require('./lib/reviews_scraper').getAllReviewsStream

function saveAllReviewsToFile(){
  const reviewsStream = getAllReviewsStream()
    .map((review)=> JSON.stringify(review))
    .intersperse(',')
  const resultReviewsStream = hl(['[']).concat(reviewsStream).append(']')
  resultReviewsStream.pipe(fs.createWriteStream('reviews.json'))
}

saveAllReviewsToFile()
