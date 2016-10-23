var REVIEWS_URL = "http://www.theneedledrop.com/articles?category=Reviews"
//REVIEWS_URL = "http://www.theneedledrop.com/articles/?offset=1434808886435&category=Reviews"
const nightmare = require('nightmare')
const hl = require('highland')
const bluebird = require('bluebird')
const _ = require('lodash')
const querystring = require('querystring')
const requestPromise = require('request-promise')

function fetchUrl(url) {
  return nightmare({ show: true })
    .goto(url)
}

function fetchReviewsPage(url) {
  return fetchUrl(url)
    .evaluate(()=> {
      const reviews = Array.prototype.map.call(document.querySelectorAll('article'), (a)=> {
        const reviewSelector = a.querySelector('h1 a')
        const timeSelector = a.querySelector('time')
        const embedUrl = a.querySelector('iframe').src
        const youtubeId = embedUrl.match(/www.youtube.com\/embed\/([\w\-]+)/)[1]
        return {
          review_name: reviewSelector.textContent,
          youtube_id: youtubeId,
          created_at: timeSelector.getAttribute('datetime'),
          review_url: reviewSelector.href
        }
      })
      const olderReviewPage = document.querySelector('.pagination .older a').href
      return [reviews, olderReviewPage]
    })
    .end()
    .then(([reviews, olderReviewPage])=>{
      return {
        reviews,
        olderReviewPage
      }
    })
    .then((reviewsResponse)=>{
      return bluebird.each(reviewsResponse.reviews, (review)=>{
        const url = getYoutubeVideoData(review.youtube_id)
        return requestPromise.get(url, {json:true})
          .then((response)=>{
            review.youtube_description = _.get(response, "items[0].snippet.description")
          })
      }).then(()=>{
        return reviewsResponse
      })
    })
    .catch((err)=> console.error(err))
}

function getYoutubeVideoData(id) {
  return `https://www.googleapis.com/youtube/v3/videos?part=snippet&id=${id}&key=${process.env.YOUTUBE_API_KEY}`;
}

function scrapeReviews(url, reviewsStream, pageNum=1){
  console.log('fetching url: ', url, "page: ", pageNum)
  fetchReviewsPage(url)
    .then((result)=> {
      if (result.reviews.length > 0) {
        result.reviews.forEach((review)=> reviewsStream.write(review))
        scrapeReviews(result.olderReviewPage, reviewsStream, ++pageNum)
      } else {
        console.log('end')
        reviewsStream.end()
      }
    })
  return reviewsStream
}

function getAllReviewsStream() {
  return scrapeReviews(REVIEWS_URL, hl())
}

exports.getAllReviewsStream = getAllReviewsStream
