const REVIEWS_URL = "http://www.theneedledrop.com/articles?category=Reviews"
// const REVIEWS_URL = "https://www.theneedledrop.com/articles?offset=1405588008000&category=Reviews"
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
            const {artist_name, album_name} = extractArtistAndAlbum(review.review_name)
            review.artist_name = artist_name
            review.album_name = album_name
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

function extractArtistAndAlbum(reviewName) {
  let [artist_name, album_name] = reviewName.split(" - ")
  if (!album_name) {
    [artist, album] = reviewName.split("- ")
    artist_name = artist
    album_name = album
    console.log(artist_name, album_name)
  }

  return {artist_name, album_name}
}

function extractRankFromYt(youtubeDescription) {
  const rawRank = youtubeDescription.match(/((([+-]?\d+(\.\d+))\/10)$)|(((\d\d?|classic)\/10)(?:\s))/gmi)

  if(!rawRank) {
    console.log("No match for rank", youtubeDescription)
    return -1
  }
  const rawRankParts = rawRank[0].split("/")
  if(rawRankParts[0].toLowerCase() == "classic") {
    return -10
  }
  const rank = parseFloat(rawRankParts[0], 10)
  if(rank < 0 || rank > 10) {
    console.log("Something went wrong with parsing the rank")
    return -1
  }
  return rank
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

function wait(delay){
  return new Promise((resolve) => setTimeout(resolve, delay));
}

function fetchRetry(url, delay, tries, fetchOptions = {}) {
  function onError(err){
      triesLeft = tries - 1;
      if(!triesLeft){
          throw err;
      }
      return wait(delay).then(() => fetchRetry(url, delay, triesLeft, fetchOptions));
  }
  return fetch(url,fetchOptions).catch(onError);
}

async function pitchforkSearch(query, skipRank) {
  const removeSpecialChars = (str) => str.replace(/[^\w\s]/gi, '');
  const cleanQuery = removeSpecialChars(query).replace(" and ", "")
  let result = await fetchRetry("https://pitchfork.com/api/v2/search/faceted/?query=" + encodeURIComponent(cleanQuery), 30000, 5, {
    "headers": {
      "accept": "application/json",
      "accept-language": "he;q=0.8",
      "sec-ch-ua": "\"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"108\", \"Brave\";v=\"108\"",
      "sec-ch-ua-mobile": "?0",
      "sec-ch-ua-platform": "\"macOS\"",
      "sec-fetch-dest": "empty",
      "sec-fetch-mode": "cors",
      "sec-fetch-site": "same-origin",
      "sec-gpc": "1"
    },
    "referrer": "https://pitchfork.com/search/?query=radiohead",
    "referrerPolicy": "strict-origin-when-cross-origin",
    "body": null,
    "method": "GET",
    "mode": "cors",
    "credentials": "include"
  });
  result = await result.json()
  const review = result.results.albumreviews.items.at(-1)
  if (!review) return null
  result = {
    pitchfork_genre: review.genres[0] ? review.genres[0].slug : "experimental",
  }
  if(!skipRank) {
    result = Object.assign(result, {
      pitchfork_rank: parseFloat(review.tombstone.albums[0].rating.rating),
    })
  }
  return result
}

exports.extractRankFromYt = extractRankFromYt
exports.getAllReviewsStream = getAllReviewsStream
exports.extractArtistAndAlbum = extractArtistAndAlbum
exports.pitchforkSearch = pitchforkSearch

//pitchforkSearch("Billie Eilish Happier Than Ever")
