// const REVIEWS_URL = "http://www.theneedledrop.com/articles?category=Reviews"
const REVIEWS_URL = "https://www.theneedledrop.com/articles?offset=1405588008000&category=Reviews"
const { chromium } = require('playwright');
const hl = require('highland')
const bluebird = require('bluebird')
const _ = require('lodash')
const requestPromise = require('request-promise')

async function fetchReviewsPage(url) {
  const browser = await chromium.launch()
  const page = await browser.newPage()
  await page.goto(url)
  return page.evaluate(()=> {
      const reviews = Array.prototype.map.call(document.querySelectorAll('article'), (a)=> {
        const reviewSelector = a.querySelector('h1 a')
        const timeSelector = a.querySelector('time')
        const iframeSelector = a.querySelector('iframe')
        var youtubeIdMatch
        if (iframeSelector){
           youtubeIdMatch = iframeSelector.src.match(/www.youtube.com\/embed\/([\w\-]+)/)
        }
        const youtubeId = youtubeIdMatch ? youtubeIdMatch[1] : null;
        if (youtubeId) {
          return {
            review_name: reviewSelector.textContent,
            youtube_id: youtubeId,
            created_at: new Date(timeSelector.getAttribute('datetime')),
            review_url: reviewSelector.href
          }
        } else { return null }
      }).filter((review)=> !!review)
      const olderReviewPageSelector = document.querySelector('.pagination .older a')
      const olderReviewPage = olderReviewPageSelector ? olderReviewPageSelector.href : null
      return [reviews, olderReviewPage]
    })
    .then(([reviews, olderReviewPage])=>{
      return {
        reviews,
        olderReviewPage
      }
    })
    .then((reviewsResponse)=>{
      return bluebird.each(reviewsResponse.reviews, (review)=>{
        if (!review.youtube_id) return bluebird.resolve(review);
        const url = getYoutubeVideoData(review.youtube_id)
        return requestPromise.get(url, {json:true})
          .then((response)=>{
            review.youtube_description = _.get(response, "items[0].snippet.description", "")
            review.rank = extractRankFromYt(review.youtube_description)
            review.artist_name = extractArtistName(review.review_name)
            review.album_name = extractAlbumName(review.review_name)
          })
      }).then(()=>{
        return reviewsResponse
      })
    })
    .catch((err)=> console.error(err))
    .finally(()=> {
      page.close()
    })
}

function extractArtistName(reviewName) {
  return reviewName.split(" - ")[0]
}

function extractAlbumName(reviewName) {
  return reviewName.split(" - ")[1]
}

function extractRankFromYt(youtubeDescription) {
  const rank = _.get(youtubeDescription.match(/(\d\d?)\/10/), "[1]")
  if(rank) {
    return parseInt(rank, 10)
  }
}

function getYoutubeVideoData(id) {
  return `https://www.googleapis.com/youtube/v3/videos?part=snippet&id=${id}&key=${process.env.YOUTUBE_API_KEY}`;
}

function scrapeReviews(url, reviewsStream, pageNum=1){
  console.log('fetching url: ', url, "page: ", pageNum)
  fetchReviewsPage(url)
    .then((result)=> {
      result.reviews.forEach((review)=> reviewsStream.write(review))
      if (result.olderReviewPage) {
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
