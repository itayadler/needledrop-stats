const { loadDb, all, update } = require('./lib/review_model')
const { extractRankFromYt } = require('./lib/reviews_scraper')
const spotify = require("spotify-web-api-node")
const spotifyApi = new spotify()
const bluebird = require('bluebird')
spotifyApi.setAccessToken(process.env.SPOTIFY_ACCESS_TOKEN)

async function getArtistData(artistName) {
	const resp = await spotifyApi.searchArtists(artistName)
	const firstResult = resp.body.artists?.items[0]
	if (firstResult) {
		return {
			spotify_followers: firstResult.followers.total,
			spotify_artist_id: firstResult.id,
			spotify_artist_url: firstResult.href,
			spotify_artist_image: firstResult.images[0]?.url,
			spotify_genre: firstResult.genres[0]
		}
	} else {
		return null
	}
}

async function saveAllArtistsToDb(dbPath) {
  const db = await loadDb(dbPath)
	const data = await all(db)
	bluebird.each(data, async (artistData)=> {
		const {youtube_id, artist_name, album_name, review_name, youtube_description} = artistData
		console.log("get artist data for: ", artist_name)
		const rank = extractRankFromYt(youtube_description)
		await update(db, youtube_id, {rank})
		console.log("saved artist data to db!")
	})
}

saveAllArtistsToDb("./public/tndstats.db")
