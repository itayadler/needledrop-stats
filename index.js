const hl = require('highland')
const fs = require('fs')
const getAllReviewsStream = require('./lib/reviews_scraper').getAllReviewsStream

function saveAllReviewsToFile(filePath){
  const reviewsStream = getAllReviewsStream()
    .filter((review)=> review.rank > -1)
    .map((review)=> JSON.stringify(review))
    .intersperse(',')
  const resultReviewsStream = hl(['[']).concat(reviewsStream).append(']')
  resultReviewsStream.pipe(fs.createWriteStream(filePath))
}

saveAllReviewsToFile("reviews.json")
