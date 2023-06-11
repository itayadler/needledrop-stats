const hl = require('highland')
const fs = require('fs')
const getAllReviewsStream = require('./lib/reviews_scraper').getAllReviewsStream
const { create, createDb } = require('./lib/review_model')

function saveAllReviewsToFile(filePath){
  const reviewsStream = getAllReviewsStream()
    .filter((review)=> review.rank > -1)
    .map((review)=> JSON.stringify(review))
    .intersperse(',')
  const resultReviewsStream = hl(['[']).concat(reviewsStream).append(']')
  resultReviewsStream.pipe(fs.createWriteStream(filePath))
}

async function saveAllReviewsToDb(dbPath) {
  const db = await createDb(dbPath)
  console.log(db)
  getAllReviewsStream()
    .filter((review)=> review.rank > -1)
    .each((review)=> create(db, review))

}

// saveAllReviewsToFile("reviews.json")
saveAllReviewsToDb("./tndstats.db")
